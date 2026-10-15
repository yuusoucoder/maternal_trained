"""Shared configuration for the AIOVY UCI Maternal Health Risk pipeline.

Every UCI notebook imports this module so that features, label codes,
group IDs, the locked test split, model definitions, search spaces and
CV settings are defined once and are identical across notebooks.

The methodology mirrors the Mendeley pipeline in ml_model/notebooks/
(03_model_comparison.ipynb and 04_repeated_nested_cv.ipynb):
  * group IDs = hash of the six feature values (features only)
  * three base models with the same defaults and search spaces
  * RandomizedSearchCV (n_iter=10) scored on HIGH-risk recall
  * repeated nested CV: 3 repeats x 5 outer folds x 3 inner folds
  * no SMOTE
Deliberate differences are documented in the notebooks.
"""

from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    f1_score,
    make_scorer,
    precision_recall_fscore_support,
    precision_score,
    recall_score,
)
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from xgboost import XGBClassifier

# ---------------------------------------------------------------- paths
UCI_DIR = Path(__file__).resolve().parent
# Exact duplicate rows (all 7 columns) removed from the 732-row
# Maternal_Health_Risk_cleaned.csv, first occurrence kept. The 732-row
# run is archived in archive_732_rows/.
DATA_PATH = UCI_DIR / "data" / "Maternal_Health_Risk_no_duplicates.csv"
REPORTS_DIR = UCI_DIR / "reports"
MODELS_DIR = UCI_DIR / "models"
MENDELEY_REPORTS_DIR = UCI_DIR.parent / "reports"  # read-only

DATASET_NAME = DATA_PATH.name
EXPECTED_RECORDS = 451

# -------------------------------------------------------------- schema
# UCI column names are kept as feature names: they are exactly the
# keys the app sends (Indicator.featureKey in
# lib/models/maternal_indicators.dart).
FEATURES = ["Age", "SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate"]
TARGET = "RiskLevel"

FEATURE_UNITS = {
    "Age": "years",
    "SystolicBP": "mmHg",
    "DiastolicBP": "mmHg",
    "BS": "mmol/L",
    "BodyTemp": "degF",
    "HeartRate": "bpm",
}

# Fixed label mapping. The codes equal the alphabetical LabelEncoder
# codes the Mendeley model used, so high risk is class 0 in both.
LABEL_MAPPING = {"high risk": 0, "low risk": 1, "mid risk": 2}
CLASS_NAMES = sorted(LABEL_MAPPING, key=LABEL_MAPPING.get)
CLINICAL_ORDER = ["low risk", "mid risk", "high risk"]
HIGH_RISK_CODE = LABEL_MAPPING["high risk"]

# Fixed colours for plots (validated categorical slots 1-3).
CLASS_COLORS = {"low risk": "#2a78d6", "mid risk": "#eb6834", "high risk": "#1baf7a"}
MODEL_COLORS = {
    "Logistic Regression": "#2a78d6",
    "Random Forest": "#eb6834",
    "XGBoost": "#1baf7a",
}

# ------------------------------------------------------- reproducibility
RANDOM_STATE = 42
TEST_SIZE = 0.20

# Repeated nested CV, identical to Mendeley notebook 03
REPEAT_SEEDS = [42, 43, 44]
OUTER_SPLITS = 5
INNER_SPLITS = 3
INNER_SEED_OFFSET = 100
N_ITER = 10

# Final-model tuning, identical to Mendeley notebook 04
FINAL_CV_SPLITS = 5
SHAP_SAMPLE_SIZE = 200
STABILITY_FOLDS = 5


# ---------------------------------------------------------------- data
def load_data():
    df = pd.read_csv(DATA_PATH)
    assert list(df.columns) == FEATURES + [TARGET], df.columns.tolist()
    assert len(df) == EXPECTED_RECORDS, len(df)
    assert df.notna().all().all()
    assert set(df[TARGET]) == set(LABEL_MAPPING)
    return df


def make_group_ids(df):
    """One group per distinct six-feature vector (same as Mendeley).

    Still required without exact duplicates: some feature vectors carry
    more than one label, and those rows must stay on the same side of
    every split.
    """
    return pd.util.hash_pandas_object(df[FEATURES], index=False)


def encode_labels(labels):
    codes = pd.Series(labels).map(LABEL_MAPPING)
    assert codes.notna().all(), "Unknown risk label"
    return codes.to_numpy(dtype=int)


def locked_split(df, group_ids):
    """Group-aware, class-stratified 20% hold-out.

    StratifiedGroupKFold with 1 / TEST_SIZE = 5 folds; the first fold is
    the locked test set. Groups never straddle the split and the class
    mix is kept as close to the full data as whole groups allow.
    """
    splitter = StratifiedGroupKFold(
        n_splits=round(1 / TEST_SIZE),
        shuffle=True,
        random_state=RANDOM_STATE,
    )
    train_idx, test_idx = next(
        splitter.split(df[FEATURES], df[TARGET], groups=group_ids)
    )
    overlap = set(group_ids.iloc[train_idx]) & set(group_ids.iloc[test_idx])
    assert not overlap
    return train_idx, test_idx


def load_train_test():
    """Load the data and reproduce the locked split (used by all notebooks)."""
    df = load_data()
    group_ids = make_group_ids(df)
    train_idx, test_idx = locked_split(df, group_ids)
    return {
        "df": df,
        "group_ids": group_ids,
        "train_idx": train_idx,
        "test_idx": test_idx,
        "X_train": df[FEATURES].iloc[train_idx].reset_index(drop=True),
        "X_test": df[FEATURES].iloc[test_idx].reset_index(drop=True),
        "y_train": encode_labels(df[TARGET].iloc[train_idx]),
        "y_test": encode_labels(df[TARGET].iloc[test_idx]),
        "groups_train": group_ids.iloc[train_idx].to_numpy(),
        "groups_test": group_ids.iloc[test_idx].to_numpy(),
    }


# -------------------------------------------------------------- models
def build_models():
    """Base pipelines with the same defaults as Mendeley notebook 03."""
    return {
        "Logistic Regression": Pipeline([
            ("scaler", StandardScaler()),
            ("model", LogisticRegression(max_iter=2000, random_state=RANDOM_STATE)),
        ]),
        "Random Forest": Pipeline([
            ("model", RandomForestClassifier(
                n_estimators=200, random_state=RANDOM_STATE, n_jobs=-1
            )),
        ]),
        "XGBoost": Pipeline([
            ("model", XGBClassifier(
                n_estimators=200,
                max_depth=4,
                learning_rate=0.05,
                objective="multi:softprob",
                eval_metric="mlogloss",
                random_state=RANDOM_STATE,
                n_jobs=2,
            )),
        ]),
    }


# Same search spaces as Mendeley notebook 03
PARAMETER_SPACES = {
    "Logistic Regression": {
        "model__C": [0.01, 0.1, 1, 10, 100],
        "model__class_weight": [None, "balanced"],
    },
    "Random Forest": {
        "model__n_estimators": [100, 200, 300],
        "model__max_depth": [None, 8, 12, 20],
        "model__min_samples_leaf": [1, 2, 4],
        "model__class_weight": [None, "balanced"],
    },
    "XGBoost": {
        "model__n_estimators": [100, 200, 300],
        "model__max_depth": [3, 4, 6],
        "model__learning_rate": [0.03, 0.05, 0.1],
        "model__subsample": [0.8, 1.0],
        "model__colsample_bytree": [0.8, 1.0],
    },
}


# ------------------------------------------------------------- metrics
def high_risk_recall(y_true, y_pred):
    return recall_score(
        y_true, y_pred, labels=[HIGH_RISK_CODE], average="macro", zero_division=0
    )


HIGH_RISK_RECALL_SCORER = make_scorer(high_risk_recall)

METRIC_COLUMNS = [
    "Accuracy",
    "Macro Precision",
    "Macro Recall",
    "Macro F1",
    "High-Risk Recall",
]


def compute_metrics(y_true, y_pred):
    """Headline metrics used everywhere in the UCI pipeline."""
    return {
        "Accuracy": accuracy_score(y_true, y_pred),
        "Macro Precision": precision_score(
            y_true, y_pred, average="macro", zero_division=0
        ),
        "Macro Recall": recall_score(y_true, y_pred, average="macro", zero_division=0),
        "Macro F1": f1_score(y_true, y_pred, average="macro", zero_division=0),
        "High-Risk Recall": high_risk_recall(y_true, y_pred),
    }


def per_class_metrics(y_true, y_pred):
    """Per-class precision / recall / F1 / support in clinical order."""
    codes = [LABEL_MAPPING[c] for c in CLINICAL_ORDER]
    p, r, f, s = precision_recall_fscore_support(
        y_true, y_pred, labels=codes, zero_division=0
    )
    return pd.DataFrame({
        "Class": CLINICAL_ORDER,
        "Precision": p,
        "Recall": r,
        "F1": f,
        "Support": s,
    })


def mean_std(values):
    return f"{np.mean(values):.4f} ± {np.std(values, ddof=1):.4f}"


# ---------------------------------------------------------------- SHAP
def shap_output_space(model_name):
    """Units of the SHAP values for each model family."""
    return {
        "Logistic Regression": "log-odds (decision function)",
        "Random Forest": "predicted probability",
        "XGBoost": "log-odds (raw margin)",
    }[model_name]


def make_shap_explainer(model_name, fitted_pipeline, background_X):
    """TreeExplainer for RF / XGBoost, LinearExplainer for LR.

    background_X is only used by LinearExplainer (training data).
    """
    import shap

    clf = fitted_pipeline.named_steps["model"]
    if model_name == "Logistic Regression":
        scaled = fitted_pipeline.named_steps["scaler"].transform(background_X)
        masker = shap.maskers.Independent(scaled, max_samples=len(scaled))
        return shap.LinearExplainer(clf, masker)
    return shap.TreeExplainer(clf)


def shap_explain(model_name, fitted_pipeline, explainer, X):
    """SHAP Explanation (samples, features, classes) with raw feature values."""
    import shap

    X_in = X
    if model_name == "Logistic Regression":
        X_in = fitted_pipeline.named_steps["scaler"].transform(X)
    raw = explainer(X_in)
    return shap.Explanation(
        values=raw.values,
        base_values=raw.base_values,
        data=X.to_numpy(),
        feature_names=FEATURES,
    )


def model_output(model_name, fitted_pipeline, X):
    """Model output in the same space as the SHAP values (for additivity)."""
    if model_name == "Random Forest":
        return fitted_pipeline.predict_proba(X)
    if model_name == "XGBoost":
        return fitted_pipeline.named_steps["model"].predict(X, output_margin=True)
    return fitted_pipeline.decision_function(X)


# --------------------------------------------------------------- plots
def set_plot_style():
    import matplotlib as mpl

    mpl.rcParams.update({
        "figure.dpi": 110,
        "savefig.dpi": 300,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.edgecolor": "#8a8984",
        "axes.labelcolor": "#0b0b0b",
        "axes.titleweight": "bold",
        "axes.grid": True,
        "grid.color": "#e4e3df",
        "grid.linewidth": 0.6,
        "xtick.color": "#52514e",
        "ytick.color": "#52514e",
        "font.size": 10,
    })
