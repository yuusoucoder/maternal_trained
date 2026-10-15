[README.md](https://github.com/user-attachments/files/33516551/README.md)
# AIOVY – Flutter UI Prototype

**AIOVY: Maternal Health Risk Classification Using Logistic Regression, Random Forest and XGBoost with Explainable AI**

This is a mobile-first Flutter prototype of the AIOVY Stitch design. Everything runs on mock data. There is **no trained model or real SHAP computation yet**, and every output is labelled as demo data.

---

## 1. Run it

Requires Flutter **3.24 or newer** (Dart 3.5+).

```bash
cd aiovy
flutter create . --platforms=android,ios --project-name aiovy   # generates android/ & ios/ folders, keeps lib/
flutter pub get
flutter run
```

`flutter create .` only adds the missing platform folders. It does not overwrite the existing `lib/` or `pubspec.yaml`.

Run the unit tests with `flutter test`, and check the code with `flutter analyze`.

> **Fonts:** Inter is loaded with `google_fonts`, which downloads it on first run.
> Debug builds have internet permission by default. For a **release APK**, either add
> `<uses-permission android:name="android.permission.INTERNET"/>` to
> `android/app/src/main/AndroidManifest.xml`, or bundle the Inter `.ttf` files (see the google_fonts docs).
> Without the font, the app falls back to the system sans-serif.

**Demo login:** the email and password come pre-filled. Any non-empty values work.

---

## 2. Screen map (Stitch → Flutter)

| Stitch screen | Flutter file | Navigation |
|---|---|---|
| splash_intro | `screens/splash/splash_screen.dart` | Get Started → Login |
| doctor_login | `screens/login/login_screen.dart` | Sign In → Home |
| home_dashboard | `screens/home/home_screen.dart` (tab) | Assess New Patient → Assessment · recent card → Patient Profile · View All → Patients |
| patient_assessment_input | `screens/assessment/assessment_input_screen.dart` | Assess Risk → Processing |
| assessment_processing | `screens/processing/processing_screen.dart` | auto → Result |
| risk_classification_result | `screens/result/result_screen.dart` | Why this result → SHAP · Save → Patient Profile + snackbar |
| explainable_ai_shap | `screens/shap/shap_screen.dart` | Done → Result |
| patients_list | `screens/patients/patients_screen.dart` (tab) | card → Patient Profile |
| patient_profile_history | `screens/patient_profile/patient_profile_screen.dart` | New assessment · View result & SHAP |
| doctor_profile | `screens/profile/doctor_profile_screen.dart` (tab) | Settings · How AIOVY Works · Sign out |
| settings | `screens/settings/settings_screen.dart` | back |
| how_aiovy_works_research_dashboard | `screens/research/research_screen.dart` | back / Return to profile |

Bottom navigation: **Home ↔ Patients ↔ Profile** (`navigation/main_shell.dart`). "Assess Patient" is the hero button on Home, not a tab.

---

## 3. Project structure

```
lib/
  main.dart                 ← picks the classifier (swap Mock → API here)
  app.dart                  ← MaterialApp + AppScope
  core/
    theme/                  ← colours, text styles, spacing, ThemeData (from Stitch tokens)
    constants/              ← shared copy
    utils/formatters.dart   ← dates, units (mmol/L↔mg/dL, °F↔°C), percentages
  models/                   ← RiskLevel, MaternalIndicators, RiskResult, FeatureContribution,
                              Assessment, Patient, Clinician, Research models
  data/
    mock/                   ← MockPatients, MockResearch, MockClinician
    repositories/           ← PatientRepository (in-memory), AppSettings
  services/
    risk_classifier.dart        ← interface the UI depends on
    mock_risk_classifier.dart   ← demo heuristic (NOT a real model)
    api_risk_classifier.dart    ← stub + suggested API contract for later
  state/app_scope.dart      ← provides repository/settings/classifier to all screens
  navigation/               ← AppNavigator helpers, MainShell (bottom tabs)
  widgets/                  ← reusable UI: cards, pills, risk badge, header, bottom nav, buttons, fields…
  screens/                  ← one folder per screen
test/app_test.dart          ← classifier + repository tests
```

No state-management package is used. `AppScope` (an InheritedWidget) and `ChangeNotifier` keep the code easy to follow.

---

## 4. Connecting the real model later

The UI only talks to `RiskClassifier`:

```dart
abstract class RiskClassifier {
  String get modelName;
  Future<RiskResult> classify(MaternalIndicators indicators);
}
```

`RiskResult` already has the four fields the ML system will return: **riskLevel, probabilities, modelName, featureContributions**.

To connect the real model:
1. Serve the selected model plus SHAP from Python (e.g. FastAPI). The request and response shape is documented in `api_risk_classifier.dart`.
2. Implement `ApiRiskClassifier.classify` (add the `http` package).
3. In `main.dart`, replace `const MockRiskClassifier()` with `ApiRiskClassifier(baseUrl: ...)`.
4. Set `isDemo: false` in the results so the "demo" labels disappear.
5. Put the real metrics into `data/mock/mock_research.dart`, or load them from the API. They stay `null` ("Pending Evaluation") until then.

The six features use the dataset column names: `Age, SystolicBP, DiastolicBP, BS, BodyTemp, HeartRate`. They're stored in the dataset's units (mmol/L, °F).

---

## 5. Where this differs from Stitch, and why

The layout, colours, type scale, cards, pills and navigation follow Stitch. The changes below are small fixes from the accessibility and usability review:

- **Same patient, same numbers everywhere.** Each mock record is run through one classifier, so P‑0014's vitals and risk level match on every screen.
- **Blood Glucose is shown on Result, Profile and History.** The result shows "6 of 6".
- **Assessment fields hold real values, never placeholder look-alikes.** Validation runs live (range checks, and diastolic must be below systolic). "Valid" only appears for valid input.
- **Risk colours are consistent:** green = Low, amber = Moderate, red = High, always shown with an icon and text. Moderate text uses a slightly darker amber (#94560B) to pass contrast.
- **Text and fields are easier to see.** Grey meta text is darker (#7A6369 instead of #897177), the smallest labels are 12 px instead of 10–11 px, fields have a visible border and focus ring, and the "Bedside Triage" pill is darker.
- **Screen readers get proper names.** Icon buttons have tooltips/labels, and headings, toggles and filter chips announce their state.
- **Full patient IDs on the Patients list**, never truncated. Gestational age appears only as labelled "not a model input" context. FHR and proteinuria were removed.
- **Probabilities show demo percentages** instead of "Pending", labelled *Demo output · Pending thesis evaluation*.
- **Research page:** one 7-stage pipeline (as specified), model cards with all five metrics including Precision and Recall, and no duplicated sections.
- **Settings:** the mislabeled "Institutional Data Privacy / mmHg" row is now "Blood Pressure / mmHg", and the "Production" badge is now "Prototype". Unit toggles really convert values across the app.
- The 👋 emoji and the stock photos are replaced by brand and icon treatments, since there are no network images.

Please double-check the second reference on the research page (Ahmed et al., 2020, the source of the UCI Maternal Health Risk dataset) against your own bibliography.
