# UCI vs Mendeley: model comparison

This report compares Logistic Regression, Random Forest and XGBoost trained with the
same methodology on two datasets:

- **Mendeley:** `ml_model/data/processed/maternal_aiovy_candidate_6039.csv`, with results in `ml_model/reports/`.
- **UCI Maternal Health Risk:** `ml_model/uci/data/Maternal_Health_Risk_cleaned.csv`, with results in `ml_model/uci/reports/`.

The UCI numbers come from the executed notebooks `ml_model/uci/notebooks/02_uci_model_comparison.ipynb` and `03_uci_nested_cv_and_shap.ipynb`.

## Shared methodology

| | Mendeley | UCI |
|---|---|---|
| Records (train / locked test) | 6,039 (4,826 / 1,213) | 732 (585 / 147) |
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
| Logistic Regression | UCI | 0.6199 ± 0.0620 | 0.6180 ± 0.0605 | 0.6103 ± 0.0665 | 0.6069 ± 0.0652 | 0.7109 ± 0.1202 |
| | Mendeley | 0.5885 ± 0.0093 | – | – | 0.5802 ± 0.0098 | 0.4657 ± 0.0208 |
| Random Forest | UCI | 0.6484 ± 0.0353 | 0.6236 ± 0.0586 | 0.6316 ± 0.0421 | 0.6157 ± 0.0498 | **0.7991 ± 0.0672** |
| | Mendeley | 0.9219 ± 0.0082 | – | – | 0.9215 ± 0.0083 | **0.8670 ± 0.0182** |
| XGBoost | UCI | 0.6815 ± 0.0367 | 0.6748 ± 0.0577 | 0.6533 ± 0.0407 | 0.6429 ± 0.0485 | 0.7626 ± 0.0907 |
| | Mendeley | 0.9204 ± 0.0083 | – | – | 0.9199 ± 0.0085 | 0.8525 ± 0.0249 |

**UCI per-class recall (nested CV):**

| Model | Low | Mid | High |
|---|---|---|---|
| Logistic Regression | 0.70 | 0.42 | 0.71 |
| Random Forest | 0.79 | 0.30 | 0.80 |
| XGBoost | 0.88 | 0.32 | 0.76 |

## Selected model and held-out test

Random Forest was selected on both datasets under the same rule. On UCI, the re-tuned
hyperparameters were the same as Mendeley's: `n_estimators=100`, `max_depth=None`,
`min_samples_leaf=1`, `class_weight=None`.

| Metric | UCI RF (n = 147) | Mendeley RF (n = 1,213) |
|---|---|---|
| Accuracy | 0.6939 (95% CI 0.62–0.76) | 0.9291 |
| Macro Precision | 0.6825 | – |
| Macro Recall | 0.6694 | – |
| Macro F1 | 0.6408 | 0.9290 |
| High-Risk Recall | 0.8974 (35/39, 95% CI 0.76–0.96) | 0.8653 (347/401) |
| Missed high-risk | 4 (2 → mid, 2 → low) | 54 |

The UCI test confusion matrix (rows = actual, columns = predicted, order low / mid / high) is
`[[58, 5, 1], [29, 9, 6], [2, 2, 35]]`. The 95% intervals are Wilson intervals.

## Observations

1. **UCI is much harder once duplicates are controlled.** On UCI, macro F1 is about 0.61–0.64,
   compared with about 0.92 on Mendeley for the tree models. A diagnostic in notebook 02
   re-scores the default models with a naive `StratifiedKFold` that ignores groups. Accuracy
   then rises by 0.13 for Random Forest and 0.11 for XGBoost, because duplicated rows leak
   between folds. High UCI accuracies reported in the literature should be read with this in mind.
2. **The data caps achievable accuracy.** 35 UCI feature vectors (136 records) carry more than
   one label, mostly low and mid, which limits in-sample accuracy to 93.0%. This is consistent with
   mid-risk recall of only 0.20–0.42 across models. Most mid-risk records are predicted as low risk.
3. **The selection is less decisive on UCI.** RF beats XGBoost on mean high-risk recall
   (+0.036 ± 0.061 paired). However, RF was better in only 9 of 15 folds, and XGBoost is higher on
   accuracy, macro precision, macro recall and macro F1. On Mendeley, RF and XGBoost were also
   close (0.867 vs 0.853).
4. **Logistic Regression is much more competitive on UCI.** Its high-risk recall is 0.71 on UCI
   vs 0.47 on Mendeley. The gap between linear and tree models is far smaller on UCI.
5. **The held-out high-risk recall (0.90) is above the CV estimate (0.80).** With only 39
   high-risk test records, the interval is wide (0.76–0.96). The nested-CV value is the more
   reliable estimate.
6. **SHAP drivers differ by dataset.** For the UCI RF, the global mean |SHAP| ranking is
   BS > SystolicBP > BodyTemp > Age > HeartRate > DiastolicBP. For the Mendeley RF it is
   SBP > heart rate > temperature > DBP > age > glucose. UCI rankings are stable across
   group-aware folds: BS and SystolicBP are ranked 1st and 2nd in all 5 folds, and the mean
   pairwise Spearman ρ is 0.857 (min 0.60, max 1.00). Mendeley's summary values happen to
   be the same, but the fold-pair correlations themselves differ.

## Limitations

- **Small dataset.** The UCI data has 732 records and only 415 distinct feature vectors, and the
  locked test set has 147 records (39 high-risk). Fold-to-fold standard deviations are about 4–7×
  larger than Mendeley's, and test metrics have wide confidence intervals.
- **Duplicates kept on purpose.** The cleaned file keeps a random half of the extra duplicate
  occurrences. This means some feature vectors are weighted more heavily in training (the
  largest group has 21 copies). Group-aware splitting prevents leakage but not this re-weighting,
  and results depend on the specific `random_state=42` subsample.
- **Label provenance.** The UCI risk labels are not accompanied by a documented clinical
  labelling protocol. The conflicting labels for identical measurements suggest labels depend on
  information that is not among the six features. Mendeley label provenance is likewise unverified.
- **Not a like-for-like dataset comparison.** The datasets differ in population, size,
  measurement resolution and class balance. Mendeley temperature was converted to °C, while UCI
  stays in °F. The comparison is of methods applied consistently, not of datasets on equal footing.
- **Split method differs slightly.** The UCI hold-out is stratified (`StratifiedGroupKFold`)
  because an unstratified group split shifted the class mix by about 5 percentage points on
  this small dataset. Mendeley used plain `GroupShuffleSplit`.
- **Data quirks retained.** BodyTemp is 98 °F for 78% of records. Seven records are over 60
  years old and would fail the Mendeley "paper" age rule. Both were kept, as the cleaning
  was fixed in advance.
- **No clinical validation.** SHAP values describe model behaviour, not causal or clinical
  effects.
