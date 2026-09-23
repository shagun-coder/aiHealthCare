# Vitals Flutter

Vitals is a secure, real-time monitoring prototype. It presents live wearable signals, environmental conditions, public safety alerts, and current risk status before a pattern becomes an emergency.

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
- Live vitals dashboard for heart rate, HRV, body temperature, and oxygen saturation.
- Personal baseline comparison and an all-time real-time tracker.
- Wearable connection status with live-monitoring language.
- Patterns page for heart rate, HRV, air quality, heat index, flood alerts, and offline-reading continuity.
- Alerts page for heatwaves, harmful local conditions, government sources, and current risk status.
- Day/night accessibility switch: beige-black day mode and dark navy-silver night mode.
- Settings entry points for account, device, alert sources, notifications, and accessibility.

This is a monitoring device, not a wellness device. Sleep, stress, breathing, blood-pressure tracking, and wellness scoring are intentionally outside this version's scope.

## Architecture

- `VitalsController`: owns current readings, personal baseline, history, and prediction state.
- `VitalsSnapshot`: represents a single set of wearable readings.
- `PersonalBaseline`: represents the individual's expected signal range.
- `OnDeviceRiskEngine`: replaceable interface for native or hardware inference.
- `DemoOnDeviceRiskEngine`: deterministic rule-based demo inference using heart rate, HRV, oxygen saturation, and temperature deviation.
- UI screens: Login, Live Vitals, Patterns, Alerts, and Settings.
- `RiskStatusCard` and `WearableStatusCard`: make the dashboard useful for live risk monitoring.
- `RealTimeTrackerCard`: communicates continuous monitoring and signal recency.
- `PublicAlertRow`: presents government or external hazard messages with source and severity.
- `ThemeModeTile`: switches between the accessible day and night palettes.
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

### On-device risk analysis

Implement the existing inference interface with TensorFlow Lite/LiteRT, ONNX Runtime, native C/C++ through FFI, or a wearable NPU/DSP runtime:

```dart
class HardwareRiskEngine implements OnDeviceRiskEngine {
  // Call the native or hardware risk inference layer here.
}
```

The production model should return a risk score, confidence, explainable factors, and an appropriate alert level. It should not present a medical diagnosis or a wellness score.

### Government and environment feeds

Replace the demonstration alert rows and environment history with trusted feeds from the relevant local or national authorities. Each alert should show its source, severity, last synchronization time, and whether the device is operating from cached data during a connectivity outage.

### Personal baseline

Build the baseline from a rolling 14-30 day window and update it gradually. A single abnormal reading should not immediately redefine the individual's normal range.

## Testing

Run static analysis and widget tests with:

```bash
flutter analyze
flutter test
```

The current widget test verifies that the Vitals login screen loads. Additional tests should cover risk scoring, baseline comparisons, wearable disconnection, day/night accessibility, government alert rendering, notification states, and the 7/30/90 day pattern selection.
