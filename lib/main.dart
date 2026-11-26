// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/platform/platform_services.dart';
import 'data/repositories/providers.dart';
import 'features/feature_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
    ),
  );
  runApp(const ProviderScope(child: RahyarApp()));
}

class RahyarApp extends ConsumerWidget {
  const RahyarApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'راهیار',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(dark: ref.watch(darkModeProvider)),
    locale: Locale(ref.watch(languageProvider) ? 'en' : 'fa'),
    supportedLocales: const [Locale('fa'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const AppShell(),
    builder: (context, child) => Directionality(
      textDirection: ref.watch(languageProvider)
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AppTab selected = AppTab.tasks;
  String? feature;
  late final AnimationController glow;
  Timer? alarmMonitor;
  String? storageError;
  bool changingPage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _loadPreferences();
    alarmMonitor = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkNativeAlarm(),
    );
  }

  Future<void> _checkNativeAlarm() async {
    final pending = await PlatformServices.pendingAlarmId();
    if (mounted && pending != null && feature != 'smartAlarm') {
      setState(() => feature = 'smartAlarm');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkNativeAlarm();
  }

  Future<void> _loadPreferences() async {
    try {
      final db = ref.read(databaseProvider);
      final saved = await db.select(db.appPreferences).get();
      if (!mounted) return;
      for (final preference in saved) {
        if (preference.key == 'darkMode') {
          ref.read(darkModeProvider.notifier).state =
              preference.value == 'true';
        } else if (preference.key == 'languageEn') {
          ref.read(languageProvider.notifier).state =
              preference.value == 'true';
        }
      }
      final alarms = await db.select(db.alarms).get();
      for (final alarm in alarms.where((alarm) => alarm.enabled)) {
        await PlatformServices.scheduleAlarm(
          alarm.id,
          alarm.hour,
          alarm.minute,
          alarm.label,
        );
      }
      final tasks = await db.watchActiveTasks().first;
      for (final task in tasks.where(
        (task) => !task.completed && task.dueAt != null,
      )) {
        await PlatformServices.scheduleTask(
          task.id,
          task.title,
          task.dueAt!,
          body: task.description,
        );
      }
    } catch (error) {
      if (mounted) setState(() => storageError = '$error');
    }
  }

  Future<void> _navigate({AppTab? tab, String? destination}) async {
    if (changingPage) return;
    changingPage = true;
    try {
      final timer = ref.read(studyTimerProvider);
      if (feature == 'focus' && timer.running && timer.focusMode) {
        final english = ref.read(languageProvider);
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(english ? 'Are you sure?' : 'آیا مطمئنی؟'),
            content: Text(
              english
                  ? 'Your focus session will be paused.'
                  : 'جلسهٔ تمرکزت متوقف می‌شود.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(english ? 'Keep focusing' : 'ادامهٔ تمرکز'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(english ? 'Leave' : 'خروج'),
              ),
            ],
          ),
        );
        if (leave != true || !mounted) return;
        await ref.read(studyTimerProvider.notifier).pause();
        await PlatformServices.setFocusMode(false);
      }
      if (mounted) {
        setState(() {
          if (tab != null) selected = tab;
          feature = destination;
        });
      }
    } finally {
      changingPage = false;
    }
  }

  @override
  void dispose() {
    glow.dispose();
    alarmMonitor?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = feature != null
        ? FeaturePage(feature: feature!)
        : switch (selected) {
            AppTab.tasks => const TasksPage(),
            AppTab.timer => const StudyTimerPage(),
            AppTab.notes => const NotesPage(),
            AppTab.social => const CommunityPage(),
            AppTab.more => MoreGrid(
              onSelect: (value) => _navigate(destination: value),
            ),
          };
    return PopScope(
      canPop: feature == null && selected == AppTab.tasks,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigate(tab: feature == null ? AppTab.tasks : selected);
      },
      child: Scaffold(
        body: Stack(
          key: const ValueKey('app-body'),
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: glow,
                builder: (context, _) =>
                    CosmicGlow(glow.value, dark: ref.watch(darkModeProvider)),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Row(
                          children: [
                            if (feature == null)
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(
                                    alpha: .12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.emerald,
                                ),
                              )
                            else
                              IconButton(
                                onPressed: () => _navigate(),
                                tooltip: ref.watch(languageProvider)
                                    ? 'Back'
                                    : 'بازگشت',
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature == null
                                    ? (ref.watch(languageProvider)
                                          ? 'Rahyar'
                                          : 'راهیار')
                                    : (ref.watch(languageProvider)
                                              ? featureTitlesEn[feature]
                                              : featureTitles[feature]) ??
                                          'بیشتر',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _settings(context),
                              icon: const Icon(Icons.tune_rounded, size: 21),
                            ),
                          ],
                        ),
                      ),
                      if (storageError != null)
                        MaterialBanner(
                          content: Text(
                            ref.watch(languageProvider)
                                ? 'Local storage could not open. Please retry.'
                                : 'ذخیره‌سازی باز نشد. دوباره تلاش کن.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                setState(() => storageError = null);
                                _loadPreferences();
                              },
                              child: Text(
                                ref.watch(languageProvider)
                                    ? 'Retry'
                                    : 'تلاش دوباره',
                              ),
                            ),
                          ],
                        ),
                      Expanded(
                        child: KeyedSubtree(
                          key: ValueKey(feature ?? selected.name),
                          child: page,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AppNavigation(
                selected: selected,
                onSelect: (value) => _navigate(tab: value),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _settings(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تنظیمات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SwitchListTile.adaptive(
              value: ref.watch(darkModeProvider),
              onChanged: (value) async {
                await ref
                    .read(databaseProvider)
                    .savePreference('darkMode', '$value');
                ref.read(darkModeProvider.notifier).state = value;
              },
              title: const Text('تم تیره کهکشانی'),
              secondary: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.emerald,
              ),
            ),
            SwitchListTile.adaptive(
              value: ref.watch(languageProvider),
              onChanged: (value) async {
                await ref
                    .read(databaseProvider)
                    .savePreference('languageEn', '$value');
                ref.read(languageProvider.notifier).state = value;
              },
              title: const Text('رابط انگلیسی'),
              secondary: const Icon(
                Icons.translate_rounded,
                color: AppColors.emerald,
              ),
            ),
            const ListTile(
              leading: Icon(Icons.storage_rounded, color: AppColors.emerald),
              title: Text('ذخیره‌سازی آفلاین'),
              subtitle: Text('پایگاه داده SQLite محلی'),
            ),
          ],
        ),
      ),
    ),
  );
}

class CosmicGlow extends StatelessWidget {
  const CosmicGlow(this.progress, {this.dark = true, super.key});
  final double progress;
  final bool dark;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: _GlowPainter(progress, dark)),
  );
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.progress, this.dark);
  final double progress;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? AppColors.background : const Color(0xFFF4F8F6),
    );
    final center = Offset(size.width * .8, size.height * .1);
    canvas.drawCircle(
      center,
      size.width * .75,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppColors.emerald.withValues(alpha: .06 + progress * .04),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * .75),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dark != dark;
}
