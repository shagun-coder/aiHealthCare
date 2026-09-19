
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const VitalsApp());
}

// -----------------------------------------------------------------------------
// THEME
// -----------------------------------------------------------------------------

class VitalsColors {
  static const background = Color(0xFF080C0D);
  static const surface = Color(0xFF0D1415);
  static const surface2 = Color(0xFF111A1B);
  static const border = Color(0xFF314044);
  static const ivory = Color(0xFFF2E5C8);
  static const gold = Color(0xFFD7B77A);
  static const sage = Color(0xFF9EBB9A);
  static const muted = Color(0xFF98A5A5);
  static const warning = Color(0xFFE1B66B);
}

class VitalsApp extends StatelessWidget {
  const VitalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: VitalsColors.background,
        colorScheme: const ColorScheme.dark(
          surface: VitalsColors.surface,
          primary: VitalsColors.gold,
          secondary: VitalsColors.sage,
        ),
        fontFamily: 'Georgia',
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// DOMAIN MODEL
// Replace this model with your actual sensor stream / BLE / Wear OS channel.
// -----------------------------------------------------------------------------

class VitalsSnapshot {
  final int heartRate;
  final int spo2;
  final double temperature;
  final int respiratoryRate;
  final int hrv;
  final double sleepHours;
  final int stress;
  final int activity;

  const VitalsSnapshot({
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.respiratoryRate,
    required this.hrv,
    required this.sleepHours,
    required this.stress,
    required this.activity,
  });
}

class PersonalBaseline {
  final double heartRate;
  final double temperature;
  final double hrv;
  final double respiratoryRate;
  final double sleepHours;

  const PersonalBaseline({
    required this.heartRate,
    required this.temperature,
    required this.hrv,
    required this.respiratoryRate,
    required this.sleepHours,
  });
}

// -----------------------------------------------------------------------------
// ON-DEVICE AI INTEGRATION POINT
//
// In production, implement this interface with your hardware AI runtime:
// - TensorFlow Lite / LiteRT
// - ONNX Runtime
// - native C/C++ inference through FFI
// - your own MCU/NPU model
//
// The UI never needs to know which inference engine is being used.
// -----------------------------------------------------------------------------

abstract class OnDeviceWellnessEngine {
  Future<WellnessPrediction> predict({
    required VitalsSnapshot current,
    required PersonalBaseline baseline,
    required List<VitalsSnapshot> history,
  });
}

class DemoOnDeviceWellnessEngine implements OnDeviceWellnessEngine {
  @override
  Future<WellnessPrediction> predict({
    required VitalsSnapshot current,
    required PersonalBaseline baseline,
    required List<VitalsSnapshot> history,
  }) async {
    // Simulate a tiny hardware inference delay.
    await Future<void>.delayed(const Duration(milliseconds: 180));

    double score = 78;

    final hrDelta = (current.heartRate - baseline.heartRate).abs();
    final hrvDelta = current.hrv - baseline.hrv;

    if (hrDelta > 12) score -= 7;
    if (hrvDelta > 5) score += 4;
    if (hrvDelta < -10) score -= 8;
    if (current.stress > 65) score -= 7;
    if (current.sleepHours >= baseline.sleepHours) score += 4;
    if (current.sleepHours < baseline.sleepHours - 1) score -= 8;

    score = score.clamp(0, 100);

    final confidence = 0.78 + math.min(history.length / 100, 0.15);

    return WellnessPrediction(
      score: score.round(),
      confidence: confidence,
      headline: score >= 75 ? 'Your wellness is on track' : 'Your body may need recovery',
      factors: [
        PredictionFactor(
          label: 'Heart-rate pattern',
          positive: hrDelta < 10,
          detail: hrDelta < 10 ? 'Close to your baseline' : 'Above your usual range',
        ),
        PredictionFactor(
          label: 'Heart-rate variability',
          positive: current.hrv >= baseline.hrv,
          detail: current.hrv >= baseline.hrv ? 'Recovery signal is stable' : 'Lower than your baseline',
        ),
        PredictionFactor(
          label: 'Sleep recovery',
          positive: current.sleepHours >= baseline.sleepHours - 0.5,
          detail: current.sleepHours >= baseline.sleepHours - 0.5
              ? 'Supporting recovery'
              : 'Below your usual duration',
        ),
        PredictionFactor(
          label: 'Stress indicators',
          positive: current.stress < 55,
          detail: current.stress < 55 ? 'Low today' : 'Slightly elevated',
        ),
      ],
    );
  }
}

class PredictionFactor {
  final String label;
  final bool positive;
  final String detail;

  const PredictionFactor({
    required this.label,
    required this.positive,
    required this.detail,
  });
}

class WellnessPrediction {
  final int score;
  final double confidence;
  final String headline;
  final List<PredictionFactor> factors;

  const WellnessPrediction({
    required this.score,
    required this.confidence,
    required this.headline,
    required this.factors,
  });
}

// -----------------------------------------------------------------------------
// APP STATE
// -----------------------------------------------------------------------------

class VitalsController extends ChangeNotifier {
  VitalsController({OnDeviceWellnessEngine? engine})
      : engine = engine ?? DemoOnDeviceWellnessEngine();

  final OnDeviceWellnessEngine engine;

  final PersonalBaseline baseline = const PersonalBaseline(
    heartRate: 68,
    temperature: 36.6,
    hrv: 52,
    respiratoryRate: 14,
    sleepHours: 7.5,
  );

  VitalsSnapshot current = const VitalsSnapshot(
    heartRate: 72,
    spo2: 98,
    temperature: 36.6,
    respiratoryRate: 14,
    hrv: 48,
    sleepHours: 7.7,
    stress: 31,
    activity: 62,
  );

  final List<VitalsSnapshot> history = const [
    VitalsSnapshot(heartRate: 67, spo2: 98, temperature: 36.6, respiratoryRate: 14, hrv: 55, sleepHours: 7.2, stress: 28, activity: 55),
    VitalsSnapshot(heartRate: 70, spo2: 97, temperature: 36.7, respiratoryRate: 15, hrv: 51, sleepHours: 7.6, stress: 35, activity: 61),
    VitalsSnapshot(heartRate: 68, spo2: 98, temperature: 36.5, respiratoryRate: 14, hrv: 57, sleepHours: 7.8, stress: 24, activity: 70),
    VitalsSnapshot(heartRate: 71, spo2: 98, temperature: 36.6, respiratoryRate: 14, hrv: 54, sleepHours: 7.4, stress: 33, activity: 66),
    VitalsSnapshot(heartRate: 69, spo2: 98, temperature: 36.6, respiratoryRate: 13, hrv: 56, sleepHours: 7.9, stress: 27, activity: 72),
    VitalsSnapshot(heartRate: 73, spo2: 97, temperature: 36.7, respiratoryRate: 15, hrv: 49, sleepHours: 7.1, stress: 42, activity: 58),
    VitalsSnapshot(heartRate: 72, spo2: 98, temperature: 36.6, respiratoryRate: 14, hrv: 48, sleepHours: 7.7, stress: 31, activity: 62),
  ];

  WellnessPrediction? prediction;
  bool loadingPrediction = false;

  Future<void> refreshPrediction() async {
    loadingPrediction = true;
    notifyListeners();

    prediction = await engine.predict(
      current: current,
      baseline: baseline,
      history: history,
    );

    loadingPrediction = false;
    notifyListeners();
  }

  void simulateSensorReading() {
    final random = math.Random();
    current = VitalsSnapshot(
      heartRate: 68 + random.nextInt(9),
      spo2: 97 + random.nextInt(2),
      temperature: 36.4 + random.nextDouble() * .5,
      respiratoryRate: 13 + random.nextInt(4),
      hrv: 46 + random.nextInt(16),
      sleepHours: current.sleepHours,
      stress: 20 + random.nextInt(40),
      activity: current.activity,
    );
    notifyListeners();
    refreshPrediction();
  }
}

// -----------------------------------------------------------------------------
// LOGIN
// -----------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void login() {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password.')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: Starfield()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      const CelestialLogo(size: 118),
                      const SizedBox(height: 22),
                      Text(
                        'Vitals',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontFamily: 'Georgia',
                              color: VitalsColors.ivory,
                              letterSpacing: 1,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'FUTURE PREDICTIONS.\nPERSONALIZED.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: VitalsColors.gold,
                          fontSize: 11,
                          letterSpacing: 2.2,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 42),
                      VitalsTextField(
                        controller: email,
                        hint: 'you@example.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      VitalsTextField(
                        controller: password,
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        obscureText: obscure,
                        suffix: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: login,
                          style: FilledButton.styleFrom(
                            backgroundColor: VitalsColors.ivory,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Log In',
                            style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: VitalsColors.border),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'New here? Create an account',
                          style: TextStyle(color: VitalsColors.gold),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Demo authentication only — connect your identity provider before production.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VitalsColors.muted, fontSize: 10, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MAIN SHELL
// -----------------------------------------------------------------------------

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final controller = VitalsController();
  int index = 0;

  final pages = const [
    DashboardPage(),
    TrendsPage(),
    InsightPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    controller.refreshPrediction();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: pages[index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            backgroundColor: VitalsColors.surface,
            indicatorColor: VitalsColors.border.withOpacity(.55),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Trends'),
              NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'AI Insight'),
              NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'More'),
            ],
          ),
          floatingActionButton: index == 0
              ? FloatingActionButton.small(
                  onPressed: controller.simulateSensorReading,
                  backgroundColor: VitalsColors.ivory,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.sync),
                )
              : null,
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// DASHBOARD
// -----------------------------------------------------------------------------

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeShellState>()!;
    final c = state.controller;
    final v = c.current;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PageHeader(title: 'Vitals', subtitle: 'Today')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                BaselineHeartCard(
                  value: v.heartRate,
                  baseline: c.baseline.heartRate,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: MetricCard(icon: Icons.water_drop_outlined, label: 'SpO₂', value: '${v.spo2}%', baseline: 'Typical 97–99%')),
                    const SizedBox(width: 10),
                    Expanded(child: MetricCard(icon: Icons.thermostat_outlined, label: 'Temp', value: '${v.temperature.toStringAsFixed(1)}°', baseline: 'Your avg ${c.baseline.temperature.toStringAsFixed(1)}°')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: MetricCard(icon: Icons.air, label: 'Breaths', value: '${v.respiratoryRate}', baseline: 'per min')),
                    const SizedBox(width: 10),
                    Expanded(child: MetricCard(icon: Icons.nights_stay_outlined, label: 'Sleep', value: '${v.sleepHours.toStringAsFixed(1)}h', baseline: 'Last night')),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(icon: Icons.graphic_eq, title: 'Personal baseline'),
                      const SizedBox(height: 12),
                      BaselineLine(
                        label: 'HRV',
                        value: '${v.hrv} ms',
                        difference: v.hrv - c.baseline.hrv,
                      ),
                      BaselineLine(
                        label: 'Stress',
                        value: '${v.stress}%',
                        difference: v.stress - 35,
                        invert: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AiPreviewCard(prediction: c.prediction),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// AI INSIGHT
// -----------------------------------------------------------------------------

class InsightPage extends StatelessWidget {
  const InsightPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeShellState>()!;
    final c = state.controller;
    final p = c.prediction;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PageHeader(title: 'AI Insight', subtitle: 'On-device prediction')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SectionCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CelestialLogo(size: 74),
                      const SizedBox(height: 16),
                      Text(
                        p?.headline ?? 'Analyzing your signals…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 25,
                          color: VitalsColors.ivory,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your AI compares current signals against your personal baseline rather than a population average.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VitalsColors.muted, fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 22),
                      if (p != null)
                        PredictionGauge(score: p.score)
                      else
                        const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      if (p != null)
                        Text(
                          '${(p.confidence * 100).round()}% model confidence',
                          style: const TextStyle(color: VitalsColors.muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (p != null)
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(icon: Icons.insights_outlined, title: 'Key factors'),
                        const SizedBox(height: 8),
                        ...p.factors.map(
                          (factor) => FactorRow(factor: factor),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.memory_outlined, color: VitalsColors.gold),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Powered by on-device AI. Sensor data used for prediction can remain on the watch instead of being sent to the cloud.',
                          style: TextStyle(color: VitalsColors.muted, fontSize: 11, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: c.refreshPrediction,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-run prediction'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Wellness prediction is informational and is not a medical diagnosis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: VitalsColors.muted, fontSize: 10),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TRENDS
// -----------------------------------------------------------------------------

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  int range = 7;

  @override
  Widget build(BuildContext context) {
    final c = context.findAncestorStateOfType<_HomeShellState>()!.controller;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PageHeader(title: 'Trends', subtitle: 'Personal history')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7 Days')),
                    ButtonSegment(value: 30, label: Text('30 Days')),
                    ButtonSegment(value: 90, label: Text('90 Days')),
                  ],
                  selected: {range},
                  onSelectionChanged: (s) => setState(() => range = s.first),
                ),
                const SizedBox(height: 14),
                TrendCard(
                  title: 'Heart Rate',
                  average: '${c.baseline.heartRate.round()} bpm',
                  icon: Icons.favorite_border,
                  values: c.history.map((e) => e.heartRate.toDouble()).toList(),
                  min: 55,
                  max: 90,
                ),
                const SizedBox(height: 12),
                TrendCard(
                  title: 'HRV',
                  average: '${c.baseline.hrv.round()} ms',
                  icon: Icons.graphic_eq,
                  values: c.history.map((e) => e.hrv.toDouble()).toList(),
                  min: 30,
                  max: 70,
                ),
                const SizedBox(height: 12),
                TrendCard(
                  title: 'Sleep',
                  average: '${c.baseline.sleepHours.toStringAsFixed(1)} h',
                  icon: Icons.nights_stay_outlined,
                  values: c.history.map((e) => e.sleepHours).toList(),
                  min: 0,
                  max: 10,
                  bars: true,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SETTINGS
// -----------------------------------------------------------------------------

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PageHeader(title: 'Settings', subtitle: 'Your Vitals system')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SectionCard(
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: VitalsColors.border,
                      child: Icon(Icons.person_outline, color: VitalsColors.ivory),
                    ),
                    title: Text('Alex Carter', style: TextStyle(color: VitalsColors.ivory)),
                    subtitle: Text('alex@vitals.com', style: TextStyle(color: VitalsColors.muted)),
                  ),
                ),
                const SizedBox(height: 12),
                SettingsTile(icon: Icons.person_outline, title: 'Account', onTap: () {}),
                SettingsTile(icon: Icons.shield_outlined, title: 'Security', onTap: () {}),
                SettingsTile(icon: Icons.watch_outlined, title: 'Device', onTap: () {}),
                SettingsTile(icon: Icons.notifications_none, title: 'Notifications', onTap: () {}),
                SettingsTile(icon: Icons.auto_awesome_outlined, title: 'AI & Personalization', onTap: () {}),
                SettingsTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
                const SizedBox(height: 20),
                const SectionCard(
                  child: Text(
                    'Vitals\nA healthier tomorrow, predicted today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 19,
                      color: VitalsColors.ivory,
                      height: 1.5,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REUSABLE UI
// -----------------------------------------------------------------------------

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: [
          const CelestialLogo(size: 42),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, color: VitalsColors.ivory),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: VitalsColors.muted),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.account_circle_outlined, color: VitalsColors.ivory),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: VitalsColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VitalsColors.border),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionTitle({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: VitalsColors.gold),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontFamily: 'Georgia', color: VitalsColors.ivory, fontSize: 16),
        ),
      ],
    );
  }
}

class VitalsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const VitalsTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: VitalsColors.ivory),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: VitalsColors.muted),
        prefixIcon: Icon(icon, size: 19, color: VitalsColors.muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: VitalsColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VitalsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VitalsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VitalsColors.gold),
        ),
      ),
    );
  }
}

class BaselineHeartCard extends StatelessWidget {
  final int value;
  final double baseline;

  const BaselineHeartCard({super.key, required this.value, required this.baseline});

  @override
  Widget build(BuildContext context) {
    final delta = value - baseline;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Heart Rate', style: TextStyle(color: VitalsColors.muted)),
              const Spacer(),
              Icon(Icons.favorite_border, size: 18, color: VitalsColors.ivory.withOpacity(.8)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 145,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 142,
                  height: 142,
                  child: CircularProgressIndicator(
                    value: .76,
                    strokeWidth: 7,
                    backgroundColor: VitalsColors.border,
                    valueColor: const AlwaysStoppedAnimation(VitalsColors.sage),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(fontFamily: 'Georgia', fontSize: 40, color: VitalsColors.ivory),
                    ),
                    const Text('bpm', style: TextStyle(color: VitalsColors.muted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta.abs() <= 6 ? 'Adjusting to your baseline…' : 'Outside your usual range',
            style: const TextStyle(color: VitalsColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            'Your baseline: ${baseline.round()} bpm',
            style: const TextStyle(color: VitalsColors.gold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String baseline;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.baseline,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: VitalsColors.sage),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, color: VitalsColors.ivory)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: VitalsColors.muted, fontSize: 11)),
          const SizedBox(height: 8),
          Text(baseline, style: const TextStyle(color: VitalsColors.muted, fontSize: 9)),
        ],
      ),
    );
  }
}

class BaselineLine extends StatelessWidget {
  final String label;
  final String value;
  final double difference;
  final bool invert;

  const BaselineLine({
    super.key,
    required this.label,
    required this.value,
    required this.difference,
    this.invert = false,
  });

  @override
  Widget build(BuildContext context) {
    final good = invert ? difference <= 0 : difference >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 54, child: Text(label, style: const TextStyle(color: VitalsColors.muted, fontSize: 11))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: .62 + (difference.abs().clamp(0, 15) / 100),
                minHeight: 5,
                backgroundColor: VitalsColors.border,
                valueColor: AlwaysStoppedAnimation(good ? VitalsColors.sage : VitalsColors.warning),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(color: VitalsColors.ivory, fontSize: 11)),
        ],
      ),
    );
  }
}

class AiPreviewCard extends StatelessWidget {
  final WellnessPrediction? prediction;

  const AiPreviewCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: Icons.auto_awesome, title: 'AI Insight'),
          const SizedBox(height: 12),
          Text(
            prediction?.headline ?? 'Analyzing your signals…',
            style: const TextStyle(fontFamily: 'Georgia', fontSize: 20, color: VitalsColors.ivory),
          ),
          const SizedBox(height: 8),
          Text(
            prediction == null
                ? 'Your on-device AI is comparing today against your personal baseline.'
                : 'Tomorrow wellness prediction: ${prediction!.score}%',
            style: const TextStyle(color: VitalsColors.muted, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 14),
          if (prediction != null)
            LinearProgressIndicator(
              value: prediction!.score / 100,
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: VitalsColors.border,
              valueColor: const AlwaysStoppedAnimation(VitalsColors.sage),
            ),
        ],
      ),
    );
  }
}

class PredictionGauge extends StatelessWidget {
  final int score;

  const PredictionGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      height: 155,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 155,
            height: 155,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: VitalsColors.border,
              valueColor: const AlwaysStoppedAnimation(VitalsColors.sage),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: const TextStyle(fontFamily: 'Georgia', fontSize: 37, color: VitalsColors.ivory),
              ),
              const Text('HIGH WELLNESS', style: TextStyle(fontSize: 9, letterSpacing: 1.4, color: VitalsColors.gold)),
            ],
          ),
        ],
      ),
    );
  }
}

class FactorRow extends StatelessWidget {
  final PredictionFactor factor;

  const FactorRow({super.key, required this.factor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            factor.positive ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 17,
            color: factor.positive ? VitalsColors.sage : VitalsColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(factor.label, style: const TextStyle(color: VitalsColors.ivory, fontSize: 12)),
                const SizedBox(height: 2),
                Text(factor.detail, style: const TextStyle(color: VitalsColors.muted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrendCard extends StatelessWidget {
  final String title;
  final String average;
  final IconData icon;
  final List<double> values;
  final double min;
  final double max;
  final bool bars;

  const TrendCard({
    super.key,
    required this.title,
    required this.average,
    required this.icon,
    required this.values,
    required this.min,
    required this.max,
    this.bars = false,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: VitalsColors.gold),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontFamily: 'Georgia', color: VitalsColors.ivory)),
              const Spacer(),
              Text('Avg. $average', style: const TextStyle(color: VitalsColors.muted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: MiniChartPainter(values: values, min: min, max: max, bars: bars),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniChartPainter extends CustomPainter {
  final List<double> values;
  final double min;
  final double max;
  final bool bars;

  MiniChartPainter({
    required this.values,
    required this.min,
    required this.max,
    required this.bars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = VitalsColors.border.withOpacity(.45)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.isEmpty) return;

        if (bars) {
      final bar = Paint()..color = VitalsColors.sage.withOpacity(.7);
      final gap = size.width / values.length;
      for (int i = 0; i < values.length; i++) {
        final normalized = ((values[i] - min) / (max - min)).clamp(0.0, 1.0);
        final h = normalized * size.height;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(i * gap + gap * .28, size.height - h, gap * .44, h),
            const Radius.circular(3),
          ),
          bar,
        );
      }
      return;
    }

    final line = Paint()
      ..color = VitalsColors.ivory
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final normalized = ((values[i] - min) / (max - min)).clamp(0.0, 1.0).toDouble();
      final y = size.height - normalized * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, line);

    final dot = Paint()..color = VitalsColors.gold;
    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final normalized = ((values[i] - min) / (max - min)).clamp(0.0, 1.0).toDouble();
      final y = size.height - normalized * size.height;
      canvas.drawCircle(Offset(x, y), 2.7, dot);
    }
  }

  @override
  bool shouldRepaint(covariant MiniChartPainter oldDelegate) => true;
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: VitalsColors.gold),
          title: Text(title, style: const TextStyle(color: VitalsColors.ivory, fontSize: 13)),
          trailing: const Icon(Icons.chevron_right, color: VitalsColors.muted),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CELESTIAL VISUALS
// -----------------------------------------------------------------------------

class CelestialLogo extends StatelessWidget {
  final double size;

  const CelestialLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: CelestialPainter(),
    );
  }
}

class CelestialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * .37;

    final gold = Paint()
      ..color = VitalsColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final muted = Paint()
      ..color = VitalsColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;

    canvas.drawCircle(center, r, gold);
    canvas.drawCircle(center, r * .68, muted);

    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final p1 = Offset(center.dx + math.cos(a) * r * .72, center.dy + math.sin(a) * r * .72);
      final p2 = Offset(center.dx + math.cos(a) * r * 1.12, center.dy + math.sin(a) * r * 1.12);
      canvas.drawLine(p1, p2, gold);
    }

    final sun = Paint()..color = VitalsColors.ivory;
    canvas.drawCircle(center, r * .18, sun);

    final ray = Paint()
      ..color = VitalsColors.gold
      ..strokeWidth = .9;

    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(
        Offset(center.dx + math.cos(a) * r * .22, center.dy + math.sin(a) * r * .22),
        Offset(center.dx + math.cos(a) * r * .34, center.dy + math.sin(a) * r * .34),
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Starfield extends StatelessWidget {
  const Starfield({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: StarfieldPainter());
  }
}

class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..color = VitalsColors.gold.withOpacity(.38);

    for (int i = 0; i < 70; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = .3 + random.nextDouble() * 1.1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
