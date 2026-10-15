"""AIOVY UCI risk-classification API.

Serves the Random Forest trained in ml_model/uci/notebooks/03 and explains
each prediction with SHAP, using the same TreeExplainer setup as that
notebook (via uci_common). The request/response contract is the one
documented in lib/services/api_risk_classifier.dart.

Start it from ml_model/uci (see api/README.md):
    .venv\\Scripts\\python -m uvicorn api.main:app --host 0.0.0.0 --port 8000
"""

import json
import logging
import sys
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Annotated, Literal

import joblib
import numpy as np
import pandas as pd
import sklearn
from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict, Field

UCI_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(UCI_DIR))

import uci_common as uc  # noqa: E402  (needs UCI_DIR on sys.path)

MODEL_PATH = uc.MODELS_DIR / "aiovy_uci_random_forest.joblib"
CONFIG_PATH = uc.MODELS_DIR / "aiovy_uci_random_forest_config.json"

# Dataset labels -> the app's RiskLevel names
APP_LEVELS = {"low risk": "low", "mid risk": "moderate", "high risk": "high"}

# Base value + sum of SHAP contributions must reproduce the probability
ADDITIVITY_TOLERANCE = 1e-6

log = logging.getLogger("aiovy.api")

# Filled once at startup by lifespan()
state = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    with open(CONFIG_PATH, encoding="utf-8") as f:
        config = json.load(f)

    trained_with = config["versions"]["scikit_learn"]
    if sklearn.__version__ != trained_with:
        log.warning("scikit-learn %s is installed but the model was trained with %s",
                    sklearn.__version__, trained_with)

    bundle = joblib.load(MODEL_PATH)
    assert bundle["features"] == uc.FEATURES == config["features"], bundle["features"]
    assert bundle["label_mapping"] == uc.LABEL_MAPPING, bundle["label_mapping"]

    model = bundle["model"]
    classes = bundle["label_encoder"].classes_.tolist()  # index = class code
    assert list(model.classes_) == list(range(len(classes)))

    state.update(
        config=config,
        model=model,
        classes=classes,
        model_name=f"{config['model']} (UCI)",
        # background_X is only used for Logistic Regression
        explainer=uc.make_shap_explainer(config["model"], model, background_X=None),
    )
    log.info("Loaded %s from %s", state["model_name"], MODEL_PATH.name)
    yield
    state.clear()


app = FastAPI(title="AIOVY UCI risk classifier", version="1.0", lifespan=lifespan)

# `flutter run -d chrome` serves the app from http://localhost:<random port>.
# Phones and emulators are not browsers, so CORS does not apply to them.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)

@app.exception_handler(RequestValidationError)
async def validation_error(request: Request, exc: RequestValidationError):
    """FastAPI's 422 body without the echoed input, which may be NaN and
    cannot be serialised to JSON (the default handler then fails with 500)."""
    errors = [{k: e[k] for k in ("type", "loc", "msg") if k in e} for e in exc.errors()]
    return JSONResponse(status_code=422, content={"detail": errors})


# Strict: JSON numbers only (no strings or booleans), no NaN / Infinity
Number = Annotated[float, Field(strict=True, allow_inf_nan=False)]


class ClassifyRequest(BaseModel):
    """The six features in canonical units (MaternalIndicators.toFeatureMap)."""

    model_config = ConfigDict(extra="forbid")

    Age: Number = Field(description="years")
    SystolicBP: Number = Field(description="mmHg")
    DiastolicBP: Number = Field(description="mmHg")
    BS: Number = Field(description="blood glucose, mmol/L")
    BodyTemp: Number = Field(description="°F")
    HeartRate: Number = Field(description="bpm")


class Probabilities(BaseModel):
    low: float
    moderate: float
    high: float


class ClassifyResponse(BaseModel):
    risk_level: Literal["low", "moderate", "high"]
    probabilities: Probabilities
    model_name: str
    feature_contributions: dict[str, float]


@app.get("/health")
def health():
    config = state["config"]
    return {
        "status": "ok",
        "model_name": state["model_name"],
        "dataset": config["dataset"],
        "dataset_records": config["dataset_records"],
        "training_records": config["training_records"],
        "locked_test_records": config["locked_test_records"],
        "features": config["features"],
        "feature_units": config["feature_units"],
    }


@app.post("/classify", response_model=ClassifyResponse)
def classify(request: ClassifyRequest):
    model, classes = state["model"], state["classes"]

    # Exact training column order
    X = pd.DataFrame([[getattr(request, f) for f in uc.FEATURES]],
                     columns=uc.FEATURES, dtype=float)

    probabilities = model.predict_proba(X)[0]
    predicted = int(model.predict(X)[0])

    # SHAP for the predicted class, in probability units (as in notebook 03)
    explanation = uc.shap_explain(state["config"]["model"], model, state["explainer"], X)
    contributions = explanation.values[0, :, predicted]
    base_value = float(explanation.base_values[0, predicted])

    error = abs(base_value + contributions.sum() - probabilities[predicted])
    if not np.isfinite(error) or error > ADDITIVITY_TOLERANCE:
        log.error("SHAP additivity check failed (error %.3g) for %s", error, request)
        raise HTTPException(status_code=500, detail="SHAP additivity check failed")

    return ClassifyResponse(
        risk_level=APP_LEVELS[classes[predicted]],
        probabilities=Probabilities(**{
            APP_LEVELS[name]: float(p) for name, p in zip(classes, probabilities)}),
        model_name=state["model_name"],
        feature_contributions={
            f: float(v) for f, v in zip(uc.FEATURES, contributions)},
    )
