// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/platform/platform_services.dart';
import 'data/repositories/providers.dart';
import 'features/feature_pages.dart';
import 'features/online/account_page.dart';
import 'data/online/online_backend.dart';

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
    home: const SessionGate(),
    builder: (context, child) => Directionality(
      textDirection: ref.watch(languageProvider)
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

class SessionGate extends ConsumerStatefulWidget {
  const SessionGate({super.key});
  @override
  ConsumerState<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<SessionGate>
    with WidgetsBindingObserver {
  Timer? _alarmCheck;
  bool _ringing = false, _checking = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (ref.read(onlineBackendProvider) != null &&
        PlatformServices.supportsBackgroundAlarms) {
      _alarmCheck = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _checkAlarm(),
      );
      _checkAlarm();
    }
  }

  Future<void> _checkAlarm() async {
    if (_checking) return;
    _checking = true;
    try {
      final ringing = await PlatformServices.pendingAlarmId() != null;
      if (mounted && ringing != _ringing) {
        if (ringing) Navigator.of(context).popUntil((route) => route.isFirst);
        setState(() => _ringing = ringing);
      }
    } finally {
      _checking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _alarmCheck != null) {
      _checkAlarm();
    }
  }

  @override
  void dispose() {
    _alarmCheck?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(onlineBackendProvider) == null) return const AppShell();
    // A scheduled ringing alarm must remain dismissible even while signed out.
    if (_ringing) return const Scaffold(body: SafeArea(child: AlarmsPage()));
    return ref
        .watch(cloudUserProvider)
        .when(
          data: (user) =>
              user == null ? const AccountLanding() : const AppShell(),
          loading: () => const AccountLanding(loading: true),
          error: (_, _) => const AccountLanding(),
        );
  }
}

class AccountLanding extends StatefulWidget {
  const AccountLanding({this.loading = false, super.key});
  final bool loading;
  @override
  State<AccountLanding> createState() => _AccountLandingState();
}

class _AccountLandingState extends State<AccountLanding>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stars = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _stars.stop();
    } else if (!_stars.isAnimating) {
      _stars.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _stars.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _stars,
            builder: (context, _) => CosmicGlow(
              _stars.value,
              dark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: widget.loading
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.emerald,
                          size: 44,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'راهیار',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 20),
                        CircularProgressIndicator(),
                      ],
                    )
                  : const AccountPage(),
            ),
          ),
        ),
      ],
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      glow.stop();
    } else if (!glow.isAnimating) {
      glow.repeat(reverse: true);
    }
  }

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
      final userId = ref.read(cloudUserProvider).asData?.value?.id;
      final genderKey = userId == null
          ? 'profile.gender'
          : 'profile.gender:$userId';
      if (!saved.any((preference) => preference.key == 'profile.grade') ||
          (userId != null && !saved.any((p) => p.key == genderKey))) {
        final profile = await _selectEducationGrade(
          askGender: userId != null,
          initialGrade: saved
              .where((p) => p.key == 'profile.grade')
              .firstOrNull
              ?.value,
        );
        if (profile == null || !mounted) return;
        await db.transaction(() async {
          await db.savePreference('profile.grade', profile.grade);
          if (userId != null) {
            await db.savePreference(genderKey, profile.gender);
          }
        });
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

  Future<({String grade, String gender})?> _selectEducationGrade({
    bool askGender = false,
    String? initialGrade,
  }) {
    String? selected = educationGrades.containsKey(initialGrade)
        ? initialGrade
        : null;
    String? gender;
    final english = ref.read(languageProvider);
    return showDialog<({String grade, String gender})>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(
              askGender
                  ? (english ? 'Complete your profile' : 'پروفایلت را کامل کن')
                  : english
                  ? 'Set your study level'
                  : 'پایهٔ تحصیلی‌ات را انتخاب کن',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    english
                        ? 'We use this to choose suitable math alarm challenges. You can edit it later in Profile.'
                        : 'برای انتخاب سؤال مناسب آلارم ریاضی است. هر وقت بخواهی از پروفایل می‌توانی تغییرش بدهی.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('onboarding-grade'),
                    isExpanded: true,
                    initialValue: selected,
                    hint: Text(english ? 'Choose a level' : 'انتخاب پایه'),
                    items: educationGrades.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              english
                                  ? (entry.key == 'elementary'
                                        ? 'Elementary (grades 1–6)'
                                        : entry.key == 'student'
                                        ? 'University'
                                        : 'Grade ${entry.key}')
                                  : entry.value,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => update(() => selected = value),
                  ),
                  if (askGender) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const Key('onboarding-gender'),
                      isExpanded: true,
                      initialValue: gender,
                      decoration: InputDecoration(
                        labelText: english ? 'Gender' : 'جنسیت',
                      ),
                      hint: Text(english ? 'Choose an option' : 'انتخاب کن'),
                      items: [
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(english ? 'Female' : 'دختر / زن'),
                        ),
                        DropdownMenuItem(
                          value: 'male',
                          child: Text(english ? 'Male' : 'پسر / مرد'),
                        ),
                        DropdownMenuItem(
                          value: 'unspecified',
                          child: Text(
                            english
                                ? 'Prefer not to say'
                                : 'ترجیح می‌دهم نگویم',
                          ),
                        ),
                      ],
                      onChanged: (value) => update(() => gender = value),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      english
                          ? 'This choice stays private on this device and can be changed in Profile.'
                          : 'این انتخاب خصوصی روی همین دستگاه ذخیره می‌شود و از پروفایل قابل تغییر است.',
                      style: const TextStyle(fontSize: 12, height: 1.8),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: selected == null || (askGender && gender == null)
                    ? null
                    : () => Navigator.pop(dialogContext, (
                        grade: selected!,
                        gender: gender ?? 'unspecified',
                      )),
                child: Text(english ? 'Continue' : 'ادامه'),
              ),
            ],
          ),
        ),
      ),
    );
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
                              tooltip: ref.watch(languageProvider)
                                  ? 'Account'
                                  : 'حساب کاربری',
                              onPressed: () =>
                                  _navigate(destination: 'account'),
                              icon: const Icon(
                                Icons.person_outline_rounded,
                                size: 22,
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
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, .025),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: KeyedSubtree(
                            key: ValueKey(feature ?? selected.name),
                            child: page,
                          ),
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
    final lower = Offset(size.width * .12, size.height * .7);
    canvas.drawCircle(
      lower,
      size.width * .65,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF6457C9).withValues(alpha: dark ? .10 : .04),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: lower, radius: size.width * .65),
            ),
    );
    final random = math.Random(1947);
    final count = (size.width * size.height / 4000).round().clamp(55, 160);
    for (var i = 0; i < count; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = .45 + random.nextDouble() * 1.15;
      final phase = random.nextDouble() * math.pi * 2;
      final alpha =
          (.28 + .38 * (.5 + .5 * math.sin(progress * math.pi * 2 + phase))) *
          (dark ? 1 : .7);
      final color = (dark ? const Color(0xFFD5EFE9) : const Color(0xFF426E66))
          .withValues(alpha: alpha);
      if (radius > 1.4) {
        canvas.drawCircle(
          point,
          radius * 3,
          Paint()..color = color.withValues(alpha: alpha * .11),
        );
        final sparkle = Paint()
          ..color = color.withValues(alpha: alpha * .5)
          ..strokeWidth = .6;
        canvas.drawLine(
          point - const Offset(0, 3.5),
          point + const Offset(0, 3.5),
          sparkle,
        );
        canvas.drawLine(
          point - const Offset(3.5, 0),
          point + const Offset(3.5, 0),
          sparkle,
        );
      }
      canvas.drawCircle(point, radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dark != dark;
}
