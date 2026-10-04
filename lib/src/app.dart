import 'package:flutter/material.dart';

import 'ai/ai_assistant_service.dart';
import 'app_state.dart';
import 'data/lucentvisit_repository.dart';
import 'notifications/reminder_service.dart';
import 'screens/ai_screen.dart';
import 'screens/appointment_screen.dart';
import 'screens/health_log_screen.dart';
import 'screens/medication_screen.dart';
import 'screens/measurement_screen.dart';
import 'screens/settings_screen.dart';

class LucentVisitApp extends StatefulWidget {
  const LucentVisitApp({
    required this.repository,
    this.reminders,
    this.aiService,
    super.key,
  });

  final LucentVisitRepository repository;
  final ReminderService? reminders;
  final AiAssistantService? aiService;

  @override
  State<LucentVisitApp> createState() => _LucentVisitAppState();
}

class _LucentVisitAppState extends State<LucentVisitApp> {
  late final AppState state;

  @override
  void initState() {
    super.initState();
    state = AppState(widget.repository, reminders: widget.reminders)..load();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => MaterialApp(
        title: 'LucentVisit',
        debugShowCheckedModeBanner: false,
        themeMode: state.themeMode,
        theme: _lucentVisitTheme(Brightness.light),
        darkTheme: _lucentVisitTheme(Brightness.dark),
        home: HomeShell(state: state, aiService: widget.aiService),
      ),
    );
  }

  ThemeData _lucentVisitTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF02569B),
      brightness: brightness,
    );
    final scaffold = isDark ? const Color(0xFF06131F) : const Color(0xFFF4FAFF);
    final surface = isDark ? const Color(0xFF0D2233) : Colors.white;
    final surfaceVariant = isDark
        ? const Color(0xFF12324A)
        : const Color(0xFFE1F3FF);
    final outline = isDark ? const Color(0xFF284B63) : const Color(0xFFCFE8F8);
    final textColor = isDark
        ? const Color(0xFFEAF6FF)
        : const Color(0xFF0B1F33);

    return ThemeData(
      colorScheme: colors.copyWith(
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        outline: outline,
      ),
      scaffoldBackgroundColor: scaffold,
      useMaterial3: true,
      textTheme: _readableTextTheme(brightness, textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 68,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          minimumSize: const Size(64, 48),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: surface,
        indicatorColor: surfaceVariant,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: states.contains(WidgetState.selected) ? 29 : 27,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Color(0xFF02569B), width: 2),
        ),
        alignLabelWithHint: true,
      ),
    );
  }

  TextTheme _readableTextTheme(Brightness brightness, Color textColor) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return base
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.16,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 18, height: 1.42),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 16.5, height: 1.42),
          bodySmall: base.bodySmall?.copyWith(fontSize: 14.5, height: 1.38),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        )
        .apply(bodyColor: textColor, displayColor: textColor);
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({required this.state, this.aiService, super.key});

  final AppState state;
  final AiAssistantService? aiService;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedIndex = 0;

  void _goHome() {
    if (selectedIndex != 0) setState(() => selectedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeContentsScreen(
        onSelectSection: (index) => setState(() => selectedIndex = index),
      ),
      AppointmentScreen(state: widget.state),
      MedicationScreen(state: widget.state),
      HealthLogScreen(state: widget.state),
      MeasurementScreen(state: widget.state),
      AiScreen(state: widget.state, service: widget.aiService),
      SettingsScreen(state: widget.state),
    ];
    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: selectedIndex == 0
              ? null
              : IconButton(
                  key: const Key('section-back-button'),
                  tooltip: 'Back to Home',
                  onPressed: _goHome,
                  icon: const Icon(Icons.arrow_back),
                ),
          titleSpacing: selectedIndex == 0 ? 16 : 0,
          title: Semantics(
            button: true,
            label: 'LucentVisit logo, go to Home',
            child: InkWell(
              key: const Key('home-logo-button'),
              onTap: _goHome,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LucentVisitMark(),
                    SizedBox(width: 10),
                    Text('LucentVisit'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(child: screens[selectedIndex]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (value) =>
              setState(() => selectedIndex = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              icon: Icon(Icons.event_note),
              label: 'Visits',
            ),
            NavigationDestination(icon: Icon(Icons.medication), label: 'Meds'),
            NavigationDestination(icon: Icon(Icons.edit_note), label: 'Notes'),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart),
              label: 'Vitals',
            ),
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              label: 'Text',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _LucentVisitMark extends StatelessWidget {
  const _LucentVisitMark();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const SizedBox.square(
      dimension: 38,
      child: Icon(
        Icons.health_and_safety_rounded,
        color: Colors.white,
        size: 24,
      ),
    ),
  );
}

class HomeContentsScreen extends StatelessWidget {
  const HomeContentsScreen({required this.onSelectSection, super.key});

  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF54C5F8), Color(0xFF02569B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withAlpha(34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where would you like to go?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose a section below. LucentVisit keeps your information organized on this device.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(240),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ContentsCard(
          icon: Icons.event_note_outlined,
          title: 'Prepare for a visit',
          subtitle: 'Appointments, questions, symptoms, and documents.',
          onTap: () => onSelectSection(1),
        ),
        _ContentsCard(
          icon: Icons.medication_outlined,
          title: 'Medication list',
          subtitle: 'Names, doses, timing, notes, and print-friendly lists.',
          onTap: () => onSelectSection(2),
        ),
        _ContentsCard(
          icon: Icons.edit_note_outlined,
          title: 'Health notes',
          subtitle: 'A dated symptom journal with items to raise next visit.',
          onTap: () => onSelectSection(3),
        ),
        _ContentsCard(
          icon: Icons.monitor_heart_outlined,
          title: 'Vitals and tracking',
          subtitle: 'Blood sugar, blood pressure, weight, pain, and more.',
          onTap: () => onSelectSection(4),
        ),
        _ContentsCard(
          icon: Icons.article_outlined,
          title: 'Text helper prototype',
          subtitle: 'Organize pasted text or create reviewable drafts.',
          onTap: () => onSelectSection(5),
        ),
        _ContentsCard(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Theme and app preferences.',
          onTap: () => onSelectSection(6),
        ),
      ],
    );
  }
}

class _ContentsCard extends StatelessWidget {
  const _ContentsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(icon, size: 30, color: colors.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.34,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right, color: colors.primary, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
