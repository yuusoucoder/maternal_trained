"""Check the running API against the notebook's saved test-set predictions.

Sends every row of reports/final_model/heldout_test_predictions.csv
(written by notebooks/03_uci_nested_cv_and_shap.ipynb) to POST /classify
and confirms that the predicted class and all three probabilities match.

Usage (from ml_model/uci, with the API running):
    .venv\\Scripts\\python api\\check_api.py [--url http://127.0.0.1:8000]
"""

import argparse
import json
import math
import sys
import urllib.error
import urllib.request
from pathlib import Path

import pandas as pd

UCI_DIR = Path(__file__).resolve().parents[1]
PREDICTIONS_CSV = UCI_DIR / "reports" / "final_model" / "heldout_test_predictions.csv"

FEATURES = ["Age", "SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate"]
APP_LEVELS = {"low risk": "low", "mid risk": "moderate", "high risk": "high"}
PROB_COLUMNS = {"low": "prob_low_risk", "moderate": "prob_mid_risk", "high": "prob_high_risk"}

# Same model and inputs, so only floating-point noise is allowed
PROB_TOLERANCE = 1e-9


def request(url, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as res:
        return json.load(res)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", default="http://127.0.0.1:8000")
    base = parser.parse_args().url.rstrip("/")

    try:
        health = request(f"{base}/health")
    except (urllib.error.URLError, OSError) as e:
        sys.exit(f"FAIL: API not reachable at {base} ({e})")
    print(f"API: {health['model_name']} | dataset {health['dataset']} "
          f"({health['dataset_records']} records)")

    expected = pd.read_csv(PREDICTIONS_CSV)
    print(f"Checking {len(expected)} rows from {PREDICTIONS_CSV.relative_to(UCI_DIR)}\n")

    failures, max_diff = [], 0.0
    for row in expected.itertuples(index=False):
        payload = {f: float(getattr(row, f)) for f in FEATURES}
        try:
            got = request(f"{base}/classify", payload)
        except (urllib.error.URLError, OSError) as e:
            failures.append((row.source_row_index, f"request failed: {e}"))
            continue

        problems = []
        want_level = APP_LEVELS[row.predicted_risk]
        if got["risk_level"] != want_level:
            problems.append(f"class {got['risk_level']} != {want_level}")
        for level, column in PROB_COLUMNS.items():
            diff = abs(got["probabilities"][level] - getattr(row, column))
            max_diff = max(max_diff, diff)
            if not diff <= PROB_TOLERANCE:
                problems.append(f"P({level}) differs by {diff:.2e}")
        if not math.isclose(sum(got["probabilities"].values()), 1.0, abs_tol=1e-9):
            problems.append("probabilities do not sum to 1")
        if sorted(got["feature_contributions"]) != sorted(FEATURES):
            problems.append("feature_contributions keys are wrong")
        if problems:
            failures.append((row.source_row_index, "; ".join(problems)))

    passed = len(expected) - len(failures)
    print(f"Predicted class and probabilities match: {passed}/{len(expected)} rows")
    print(f"Largest probability difference: {max_diff:.2e} (tolerance {PROB_TOLERANCE:.0e})")
    for index, problem in failures:
        print(f"  FAIL row {index}: {problem}")
    print("\nPASS" if not failures else f"\nFAIL ({len(failures)} rows)")
    sys.exit(0 if not failures else 1)


if __name__ == "__main__":
    main()
