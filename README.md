# Vitals Flutter

Vitals is a secure, AI-powered personal health companion prototype. It presents live wearable signals, compares them with an individual's personal baseline, and highlights current risk status before a pattern becomes an emergency.

The experience is designed for continuous, privacy-preserving support during everyday conditions and disruption events such as heat waves, pollution events, floods, and other disasters common in India. The current project uses local demonstration data and a replaceable demo inference engine.

## Run

```bash
flutter pub get
flutter run -d chrome
```

For Windows desktop, install Visual Studio with the **Desktop development with C++** workload:

```bash
flutter run -d windows
```

For Android or Wear OS, select a device or emulator in Android Studio:

```bash
flutter devices
flutter run -d <device-id>
```

## Product experience

- Email and password demo authentication.
- Current risk status instead of a wellness score.
- Personal baseline comparison for heart rate, HRV, temperature, and oxygen saturation.
- Wearable connection status with live-monitoring language.
- On-device risk analysis with confidence and explainable factors.
- Notification affordance for high-risk monitoring alerts.
- Trends for heart rate and HRV over 7, 30, and 90 day views.
- Environment context in Trends: air-quality history, heat index, flood alerts, and offline-reading continuity.
- Personalized AI explanation below Trends that encourages the individual to learn more about their own signals.
- Settings entry points for account, security, device, notifications, and AI personalization.

This is a monitoring device, not a wellness device. Sleep, stress, breathing, and blood-pressure tracking are intentionally outside this version's scope.

## Architecture

- `VitalsController`: owns current readings, personal baseline, history, and prediction state.
- `VitalsSnapshot`: represents a single set of wearable readings.
- `PersonalBaseline`: represents the individual's expected signal range.
- `OnDeviceRiskEngine`: replaceable interface for native or hardware inference.
- `DemoOnDeviceRiskEngine`: deterministic rule-based demo inference using heart rate, HRV, oxygen saturation, and temperature deviation.
- UI screens: Login, Dashboard, Trends, AI Insight, and Settings.
- `RiskStatusCard` and `WearableStatusCard`: make the dashboard useful for live risk monitoring.
- `AiLearningCard`: explains the most relevant personal pattern below the trend charts.
- `MiniChartPainter`, `CelestialPainter`, and `StarfieldPainter`: provide the visual system without image dependencies.
- `EarlyWarningCard`: combines current risk status with heat, pollution-feed, and flood-continuity readiness.

## Privacy and safety

The UI is designed around on-device processing. In production, sensor data should remain on the wearable or device whenever possible, and any synchronized data must be encrypted and minimized. This allows core monitoring to continue when connectivity is unreliable during a flood or other disaster.

Risk status is informational and is not a medical diagnosis. Real physiological use requires sensor calibration, clinical validation, regulatory review, secure identity management, and careful handling of false positives and false negatives.

## Production integrations

### Authentication

Replace `LoginPage.login()` with a real identity provider. Store only a secure session or token; never store plaintext passwords.

### Wearable data

Replace the demonstration values in `VitalsController.current` with a stream from Bluetooth, Wear OS, Health Connect, or native platform channels.

Recommended abstraction:

```dart
Stream<VitalsSnapshot> watchVitalsStream();
```

The UI should subscribe to this stream and update risk analysis automatically as readings arrive. Manual prediction reruns are not part of the current real-time product flow.

### On-device AI

Implement the existing inference interface with TensorFlow Lite/LiteRT, ONNX Runtime, native C/C++ through FFI, or a wearable NPU/DSP runtime:

```dart
class HardwareRiskEngine implements OnDeviceRiskEngine {
  // Call the native or hardware risk inference layer here.
}
```

The production model should return a risk score, confidence, explainable factors, and an appropriate alert level. It should not present a medical diagnosis.

### Personal baseline

Build the baseline from a rolling 14-30 day window and update it gradually. A single abnormal reading should not immediately redefine the individual's normal range.

## Testing

Run static analysis and widget tests with:

```bash
flutter analyze
flutter test
```

The current widget test verifies that the Vitals login screen loads. Additional tests should cover risk scoring, baseline comparisons, wearable disconnection, notification states, and the 7/30/90 day trend selection.
