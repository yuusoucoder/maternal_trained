# UCI vs Mendeley: model comparison

This report compares Logistic Regression, Random Forest and XGBoost trained with the
same methodology on two datasets:

- **Mendeley:** `ml_model/data/processed/maternal_aiovy_candidate_6039.csv`, with results in `ml_model/reports/`.
- **UCI Maternal Health Risk:** `ml_model/uci/data/Maternal_Health_Risk_no_duplicates.csv`, with results in `ml_model/uci/reports/`.

The UCI numbers come from the executed notebooks `ml_model/uci/notebooks/02_uci_model_comparison.ipynb` and `03_uci_nested_cv_and_shap.ipynb`.

## UCI dataset

The UCI file has 451 records and no exact duplicate rows. It was derived from the
author's 732-row cleaned file (`Maternal_Health_Risk_cleaned.csv`) by removing exact
duplicate rows across all seven columns, keeping the first occurrence. Every row is
distinct, but the 451 rows contain only 415 distinct six-feature vectors: 35 vectors
(71 records) occur with more than one risk label. Group-aware splitting is therefore
still used throughout. Class counts are 233 low, 106 mid and 112 high risk
(51.7% / 23.5% / 24.8%).

The earlier run on the 732-row file is archived in `ml_model/uci/archive_732_rows/`.

## Shared methodology

| | Mendeley | UCI |
|---|---|---|
| Records (train / locked test) | 6,039 (4,826 / 1,213) | 451 (359 / 92) |
| Distinct feature vectors (= groups) | 5,491 | 415 |
| Group IDs | hash of six features | same |
| Locked test split | `GroupShuffleSplit(0.20, rs=42)` | `StratifiedGroupKFold(5, rs=42)`, first fold (group-aware **and** stratified) |
| Models, defaults, search spaces | LR (+scaler), RF, XGBoost | identical |
| Repeated nested CV | 3 repeats × 5 outer × 3 inner, `RandomizedSearchCV(n_iter=10)` on high-risk recall | identical |
| Selection rule | highest mean high-risk recall | identical (macro-F1 tie-break made explicit) |
| Final model | re-tuned with 5-fold group CV on full training set | identical |
| SMOTE | no | no |
| Temperature unit | °C (converted) | °F (no conversion, matches the app) |

## Repeated nested CV (mean ± std over 15 outer folds)

The Mendeley summary did not record macro precision or macro recall. Those columns are UCI-only.

| Model | Dataset | Accuracy | Macro Precision | Macro Recall | Macro F1 | High-Risk Recall |
|---|---|---|---|---|---|---|
| Logistic Regression | UCI | 0.5961 ± 0.0542 | 0.5604 ± 0.0599 | 0.5523 ± 0.0378 | 0.5438 ± 0.0487 | 0.6632 ± 0.0834 |
| | Mendeley | 0.5885 ± 0.0093 | – | – | 0.5802 ± 0.0098 | 0.4657 ± 0.0208 |
| Random Forest | UCI | 0.6918 ± 0.0341 | 0.6656 ± 0.0618 | 0.6348 ± 0.0360 | 0.6220 ± 0.0380 | **0.8100 ± 0.1025** |
| | Mendeley | 0.9219 ± 0.0082 | – | – | 0.9215 ± 0.0083 | **0.8670 ± 0.0182** |
| XGBoost | UCI | 0.7288 ± 0.0365 | 0.7066 ± 0.0709 | 0.6566 ± 0.0464 | 0.6522 ± 0.0513 | 0.7915 ± 0.1032 |
| | Mendeley | 0.9204 ± 0.0083 | – | – | 0.9199 ± 0.0085 | 0.8525 ± 0.0249 |

**UCI per-class recall (nested CV):**

| Model | Low | Mid | High |
|---|---|---|---|
| Logistic Regression | 0.70 | 0.29 | 0.66 |
| Random Forest | 0.83 | 0.27 | 0.81 |
| XGBoost | 0.91 | 0.27 | 0.79 |

## Selected model and held-out test

Random Forest was selected on both datasets under the same rule. On UCI, the re-tuned
hyperparameters were `n_estimators=300`, `max_depth=12`, `min_samples_leaf=4`,
`class_weight="balanced"`. Mendeley's were `n_estimators=100`, `max_depth=None`,
`min_samples_leaf=1`, `class_weight=None`.

| Metric | UCI RF (n = 92) | Mendeley RF (n = 1,213) |
|---|---|---|
| Accuracy | 0.6957 (95% CI 0.60–0.78) | 0.9291 |
| Macro Precision | 0.6597 | – |
| Macro Recall | 0.6455 | – |
| Macro F1 | 0.6512 | 0.9290 |
| High-Risk Recall | 0.6522 (15/23, 95% CI 0.45–0.81) | 0.8653 (347/401) |
| Missed high-risk | 8 (7 → mid, 1 → low) | 54 |

The UCI test confusion matrix (rows = actual, columns = predicted, order low / mid / high) is
`[[39, 7, 1], [8, 10, 4], [1, 7, 15]]`. The 95% intervals are Wilson intervals.

## Observations

1. **UCI is much harder than Mendeley.** On UCI, macro F1 is about 0.54–0.65, compared with
   about 0.92 on Mendeley for the tree models. A diagnostic in notebook 02 re-scores the default
   models with a naive `StratifiedKFold` that ignores groups. With exact duplicates removed,
   the naive split no longer inflates the scores: Random Forest accuracy is 0.649 naive vs
   0.716 group-aware, and the differences for all three models mainly reflect the different
   fold partitions. On the 732-row file, which still contained duplicates, the naive split had
   overstated Random Forest accuracy by 0.13. High UCI accuracies reported in the literature
   should be read with this in mind, because the original 1,014-row file contains 562 duplicate
   occurrences.
2. **The data caps achievable accuracy.** 35 UCI feature vectors (71 records) carry more than
   one label, mostly low and mid, which limits in-sample accuracy to 92.0%. Mid risk is by far
   the hardest class, with nested-CV recall of only 0.27–0.29 across models.
3. **The selection is less decisive on UCI.** RF beats XGBoost on mean high-risk recall
   (+0.019 ± 0.055 paired). However, RF was better in only 6 of 15 folds (tied in 6, worse in 3),
   and XGBoost is higher on accuracy, macro precision, macro recall and macro F1. On Mendeley,
   RF and XGBoost were also close (0.867 vs 0.853).
4. **Logistic Regression does better on UCI than on Mendeley, but trails the tree models.** Its
   high-risk recall is 0.66 on UCI vs 0.47 on Mendeley. On UCI it is still about 0.13–0.15
   below the tree models on high-risk recall and about 0.08–0.11 below them on macro F1.
5. **The held-out high-risk recall (0.65) is below the CV estimate (0.81).** With only 23
   high-risk test records, the interval is wide (0.45–0.81). Seven of the eight missed
   high-risk records were predicted as mid risk. Test accuracy (0.70) agrees with the nested-CV
   accuracy (0.69). The nested-CV value is the more reliable estimate.
6. **SHAP drivers differ by dataset.** For the UCI RF, the global mean |SHAP| ranking is
   BS > SystolicBP > BodyTemp > Age > DiastolicBP > HeartRate. For the Mendeley RF it is
   SBP > heart rate > temperature > DBP > age > glucose. UCI rankings are stable across
   group-aware folds: BS and SystolicBP are ranked 1st and 2nd in all 5 folds, and the mean
   pairwise Spearman ρ is 0.857 (min 0.66, max 1.00). Mendeley's mean happens to be the same
   (0.857, min 0.60, max 1.00), but the fold-pair correlations themselves differ.

## Limitations

- **Small dataset.** The UCI data has 451 records and only 415 distinct feature vectors, and the
  locked test set has 92 records (23 high-risk). Fold-to-fold standard deviations are about 4–6×
  larger than Mendeley's, and test metrics have wide confidence intervals.
- **Deduplication choice.** Exact duplicate rows were removed and the first occurrence kept, so
  each distinct row counts once. The source does not document whether repeated rows are
  different patients with identical readings or repeated entries of the same record. If they
  are separate patients, deduplication changes the class balance relative to the population
  sampled. Conflicting-label rows (same measurements, different labels) were kept.
- **Label provenance.** The UCI risk labels are not accompanied by a documented clinical
  labelling protocol. The conflicting labels for identical measurements suggest labels depend on
  information that is not among the six features. Mendeley label provenance is likewise unverified.
- **Not a like-for-like dataset comparison.** The datasets differ in population, size,
  measurement resolution and class balance. Mendeley temperature was converted to °C, while UCI
  stays in °F. The comparison is of methods applied consistently, not of datasets on equal footing.
- **Split method differs slightly.** The UCI hold-out is stratified (`StratifiedGroupKFold`)
  because an unstratified group split shifted the class mix by about 8 percentage points on
  this small dataset. Mendeley used plain `GroupShuffleSplit`.
- **Data quirks retained.** BodyTemp is 98 °F for 78% of records. Seven records are over 60
  years old and would fail the Mendeley "paper" age rule. Both were kept, as the cleaning
  was fixed in advance.
- **No clinical validation.** SHAP values describe model behaviour, not causal or clinical
  effects.
