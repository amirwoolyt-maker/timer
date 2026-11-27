// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scenes.dart';
import 'features/appearance/appearance_page.dart';
import 'core/platform/platform_services.dart';
import 'data/repositories/providers.dart';
import 'features/feature_pages.dart';
import 'features/online/account_page.dart';
import 'features/online/profile_setup_page.dart';
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
    theme: buildAppTheme(
      dark: ref.watch(darkModeProvider),
      scene: ref.watch(appSceneProvider),
    ),
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
  bool _offlineTools = false;
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

  Widget _connectionNotice({bool profilePending = false}) {
    final english = ref.watch(languageProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48),
                const SizedBox(height: 18),
                Text(
                  profilePending
                      ? (english
                            ? 'Connect to finish your profile'
                            : 'برای تکمیل پروفایل آنلاین شو')
                      : (english
                            ? 'Could not check your account'
                            : 'بررسی حساب انجام نشد'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  english
                      ? 'Check your connection. Your personal tools are also available offline.'
                      : 'اتصال اینترنت را بررسی کن. ابزارهای شخصی را می‌توانی آفلاین هم استفاده کنی.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.8),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => ref.invalidate(cloudUserProvider),
                  child: Text(english ? 'Try again' : 'تلاش دوباره'),
                ),
                TextButton(
                  onPressed: () => setState(() => _offlineTools = true),
                  child: Text(
                    english
                        ? 'Continue with offline tools'
                        : 'ادامه با ابزارهای آفلاین',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(onlineBackendProvider) == null) return const AppShell();
    // A scheduled ringing alarm must remain dismissible even while signed out.
    if (_ringing) return const Scaffold(body: SafeArea(child: AlarmsPage()));
    final session = ref.watch(cloudUserProvider);
    final user = session.asData?.value;
    // Keep observing authentication while using offline tools, so a subsequent
    // successful sign-in still requires its own complete account profile.
    if (_offlineTools && (user == null || user.isOffline)) {
      return const AppShell();
    }
    return session.when(
      data: (user) {
        if (user == null) return const AccountLanding();
        if (user.profile.complete) return const AppShell();
        if (user.isOffline) return _connectionNotice(profilePending: true);
        return ProfileSetupPage(key: ValueKey(user.id), user: user);
      },
      loading: () => const AccountLanding(loading: true),
      error: (_, _) => _connectionNotice(),
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
    ref.read(studyTimerProvider);
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
    if (state == AppLifecycleState.resumed) {
      _checkNativeAlarm();
      ref.read(studyTimerProvider.notifier).refresh();
    }
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
      if (userId == null &&
          !saved.any((preference) => preference.key == 'profile.grade')) {
        final profile = await _selectEducationGrade(
          initialGrade: saved
              .where((p) => p.key == 'profile.grade')
              .firstOrNull
              ?.value,
        );
        if (profile == null || !mounted) return;
        await db.transaction(() async {
          await db.savePreference('profile.grade', profile.grade);
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
            ListTile(
              key: const Key('open-appearance'),
              leading: const Icon(Icons.palette_outlined),
              title: Text(
                ref.watch(languageProvider)
                    ? 'Themes and backgrounds'
                    : 'تم و پس‌زمینه',
              ),
              subtitle: Text(ref.watch(appSceneProvider).title),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(this.context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AppearancePage(),
                  ),
                );
              },
            ),
            SwitchListTile.adaptive(
              value: ref.watch(darkModeProvider),
              onChanged: (value) async {
                await ref
                    .read(databaseProvider)
                    .savePreference('darkMode', '$value');
                ref.read(darkModeProvider.notifier).state = value;
              },
              title: const Text('حالت تیره'),
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

/// Compatibility wrapper shared by the signed-out landing and the app shell.
class CosmicGlow extends ConsumerWidget {
  const CosmicGlow(this.progress, {this.dark = true, super.key});
  final double progress;
  final bool dark;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SceneBackground(
    scene: ref.watch(appSceneProvider),
    progress: progress,
    dark: dark,
  );
}
