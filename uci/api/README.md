# AIOVY UCI risk-classification API

FastAPI server for the Random Forest trained in `ml_model/uci/notebooks/03_uci_nested_cv_and_shap.ipynb`
(`models/aiovy_uci_random_forest.joblib`, trained on `data/Maternal_Health_Risk_no_duplicates.csv`).
The Flutter app calls it through `lib/services/api_risk_classifier.dart`.

| Endpoint | Purpose |
|---|---|
| `GET /health` | Model name, dataset, record counts and feature list |
| `POST /classify` | Risk level, class probabilities and SHAP contributions for one record |
| `GET /docs` | Interactive API documentation |

`POST /classify` takes the six features in the training units (`BS` in mmol/L, `BodyTemp` in °F):

```json
{"Age": 32, "SystolicBP": 142, "DiastolicBP": 92, "BS": 5.6, "BodyTemp": 98.4, "HeartRate": 82}
```

and returns:

```json
{"risk_level": "high",
 "probabilities": {"low": 0.0819, "moderate": 0.2695, "high": 0.6486},
 "model_name": "Random Forest (UCI)",
 "feature_contributions": {"Age": 0.0352, "SystolicBP": 0.4376, "DiastolicBP": -0.0167,
                           "BS": -0.1484, "BodyTemp": -0.0121, "HeartRate": 0.0188}}
```

`feature_contributions` are SHAP values (`TreeExplainer`, same setup as notebook 03) for the
**predicted class**, in probability units. The model's average probability for that class plus the
six contributions equals the predicted probability; the server checks this on every request. All six
fields are required and must be JSON numbers; anything else returns HTTP 422.

## 1. Start the server (Windows)

Open a terminal in `ml_model\uci` and run:

```bat
cd ml_model\uci
.venv\Scripts\python -m pip install -r requirements.txt
.venv\Scripts\python -m uvicorn api.main:app --host 0.0.0.0 --port 8000
```

The `pip install` line is needed only once. The server is ready when it prints
`Uvicorn running on http://0.0.0.0:8000`. Stop it with `Ctrl+C`.

Check it in a browser: <http://localhost:8000/health>

The first time, Windows Defender Firewall may ask whether Python can accept connections. Allow it on
**Private networks**. A phone on the same Wi-Fi needs this; Chrome and the emulator do not.

## 2. Check the API against the notebook

With the server running, in a second terminal:

```bat
cd ml_model\uci
.venv\Scripts\python api\check_api.py
```

It sends all 92 locked-test records from `reports/final_model/heldout_test_predictions.csv` to the
API and checks that the predicted class and all three probabilities match the notebook's saved
predictions. It ends with `PASS` (exit code 0) or `FAIL` and the failing rows. Use
`--url http://<address>:8000` to check a different address.

## 3. Run the Flutter app against the API

From the project root (the folder with `pubspec.yaml`). Without `USE_API=true` the app uses the
built-in demo classifier.

| Target | Command |
|---|---|
| Chrome | `flutter run -d chrome --dart-define=USE_API=true --dart-define=API_URL=http://localhost:8000` |
| Android emulator | `flutter run --dart-define=USE_API=true` (default `API_URL` is `http://10.0.2.2:8000`, the emulator's address for the PC) |
| Android phone on the same Wi-Fi | `flutter run --dart-define=USE_API=true --dart-define=API_URL=http://<PC IP>:8000` |

To find the PC's IP for the phone, run `ipconfig` and use the **IPv4 Address** of the Wi-Fi adapter,
for example `192.168.1.20`. Check it first by opening `http://<PC IP>:8000/health` in the phone's browser.
If that does not load, the firewall rule or the network is blocking it. Guest and university Wi-Fi
networks often block device-to-device traffic.

Plain HTTP is allowed only in Android **debug** builds (`android/app/src/debug/AndroidManifest.xml`),
which is what `flutter run` uses. Release builds need an HTTPS API address.

If the server cannot be reached, or does not answer within 10 seconds, the processing screen shows the
reason with **Try Again** and **Edit Indicators** buttons. The entered values are kept.

## 4. Test the app by hand with `app_test_cases.csv`

`app_test_cases.csv` has 9 records from the locked test set, which the model never saw during
training or tuning: 3 per actual class, 2 predicted correctly and 1 not (T3, T6, T9). All values are
inside the app's input ranges, and none of the records shares its measurements with a differently
labelled record.

For each row:

1. Start the server and the app with `USE_API=true` (steps 1 and 3).
2. Start a new assessment from the Home screen. Leave the Settings units at their defaults
   (**mmol/L** and **°F**), or convert the values first.
3. Enter Age, SystolicBP, DiastolicBP, BS, BodyTemp and HeartRate from the row, then tap **Assess Risk**.
4. On the result screen, check:
   - the risk level matches `expected_predicted_risk` (`low` = Low Risk, `moderate` = Moderate Risk,
     `high` = High Risk);
   - the probabilities match `expected_prob_low` / `_moderate` / `_high`. The app shows whole
     percentages, so 0.7026 appears as 70%;
   - no "Demo output" tag is shown, and the model is "Random Forest (UCI)".
5. Tap **Why this result?** and check that the legend reads "Supports <level>" / "Against <level>".
   The largest bar is listed first.

`actual_risk` is the dataset label, and `model_correct` says whether the model gets the row right.
For T3, T6 and T9 the app *should* show the wrong level: that is the model's real output, not a bug.

| Case | Expected result | Shown as |
|---|---|---|
| T1 | low | Low 70% · Moderate 27% · High 3% |
| T2 | low | Low 59% · Moderate 27% · High 14% |
| T3 | moderate (actual low) | Low 45% · Moderate 48% · High 7% |
| T4 | moderate | Low 16% · Moderate 52% · High 32% |
| T5 | moderate | Low 14% · Moderate 74% · High 12% |
| T6 | low (actual moderate) | Low 43% · Moderate 31% · High 27% |
| T7 | high | Low 12% · Moderate 29% · High 58% |
| T8 | high | Low 0% · Moderate 3% · High 97% |
| T9 | moderate (actual high) | Low 13% · Moderate 48% · High 39% |
