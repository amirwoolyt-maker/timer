part of '../../feature_pages.dart';

final studyTimerProvider =
    NotifierProvider<StudyTimerController, StudyTimerState>(
      StudyTimerController.new,
    );

class StudyTimerState {
  const StudyTimerState({
    this.mode = 'pomodoro',
    this.clock = const StudyClock(),
    this.workMinutes = 25,
    this.breakMinutes = 5,
    this.breakPhase = false,
    this.subject = '',
    this.sessionId = '',
    this.cycles = 0,
    this.focusMode = false,
    this.ready = false,
    this.error,
  });
  final String mode, subject, sessionId;
  final StudyClock clock;
  final int workMinutes, breakMinutes, cycles;
  final bool breakPhase, focusMode, ready;
  final String? error;
  bool get running => clock.running;
  bool get countingUp => mode != 'pomodoro';
  int get duration => (breakPhase ? breakMinutes : workMinutes) * 60;
  int secondsAt(DateTime now) =>
      countingUp ? clock.elapsedAt(now) : clock.remainingAt(now, duration);
  StudyTimerState copyWith({
    String? mode,
    String? subject,
    String? sessionId,
    StudyClock? clock,
    int? workMinutes,
    int? breakMinutes,
    int? cycles,
    bool? breakPhase,
    bool? focusMode,
    bool? ready,
    String? error,
  }) => StudyTimerState(
    mode: mode ?? this.mode,
    clock: clock ?? this.clock,
    workMinutes: workMinutes ?? this.workMinutes,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    breakPhase: breakPhase ?? this.breakPhase,
    subject: subject ?? this.subject,
    sessionId: sessionId ?? this.sessionId,
    cycles: cycles ?? this.cycles,
    focusMode: focusMode ?? this.focusMode,
    ready: ready ?? this.ready,
    error: error,
  );
}

class StudyTimerController extends Notifier<StudyTimerState> {
  Timer? _ticker;
  Future<void> _writes = Future.value();
  bool _finishing = false;
  @override
  StudyTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    Future.microtask(_restore);
    return const StudyTimerState();
  }

  Future<void> _restore() async {
    try {
      final db = ref.read(databaseProvider);
      final preference = await (db.select(
        db.appPreferences,
      )..where((p) => p.key.equals('activeStudyTimer'))).getSingleOrNull();
      if (!ref.mounted) return;
      if (preference != null) {
        final saved = jsonDecode(preference.value) as Map<String, dynamic>;
        final mode = saved['mode'] as String? ?? 'pomodoro';
        state = StudyTimerState(
          mode: ['pomodoro', 'study', 'stopwatch'].contains(mode)
              ? mode
              : 'pomodoro',
          clock: StudyClock(
            elapsedSeconds: (saved['elapsed'] as int? ?? 0).clamp(0, 31536000),
            runningSince: DateTime.tryParse(saved['since'] as String? ?? ''),
          ),
          workMinutes: (saved['work'] as int? ?? 25).clamp(1, 180),
          breakMinutes: (saved['break'] as int? ?? 5).clamp(1, 60),
          breakPhase: saved['breakPhase'] == true,
          subject: saved['subject'] as String? ?? '',
          sessionId: saved['id'] as String? ?? '',
          cycles: saved['cycles'] as int? ?? 0,
          focusMode: saved['focusMode'] == true,
          ready: true,
        );
      } else {
        state = state.copyWith(ready: true);
      }
      _ensureTicker();
      _tick();
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          ready: true,
          error: 'بازیابی زمان‌سنج ممکن نشد؛ می‌توانی جلسهٔ تازه‌ای شروع کنی.',
        );
      }
    }
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!ref.mounted || !state.running) return;
    if (!state.countingUp &&
        state.clock.elapsedAt(DateTime.now()) >= state.duration) {
      unawaited(_completePhase());
    } else {
      state = state.copyWith();
    }
  }

  Future<void> _persist() {
    final snapshot = state;
    final payload = jsonEncode({
      'mode': snapshot.mode,
      'elapsed': snapshot.clock.elapsedSeconds,
      'since': snapshot.clock.runningSince?.toIso8601String(),
      'work': snapshot.workMinutes,
      'break': snapshot.breakMinutes,
      'breakPhase': snapshot.breakPhase,
      'subject': snapshot.subject,
      'id': snapshot.sessionId,
      'cycles': snapshot.cycles,
      'focusMode': snapshot.focusMode,
    });
    final db = ref.read(databaseProvider);
    _writes = _writes
        .catchError((Object _) {})
        .then((_) => db.savePreference('activeStudyTimer', payload));
    return _writes;
  }

  Future<void> configure({
    String? mode,
    int? workMinutes,
    int? breakMinutes,
    String? subject,
    bool? focusMode,
  }) async {
    if (!state.ready || state.running || state.clock.elapsedSeconds > 0) return;
    state = state.copyWith(
      mode: mode,
      workMinutes: workMinutes,
      breakMinutes: breakMinutes,
      subject: subject,
      focusMode: focusMode,
      breakPhase: mode == null ? null : false,
    );
    await _persist();
  }

  Future<void> start({bool focusMode = false}) async {
    if (!state.ready || state.running || _finishing) return;
    state = state.copyWith(
      clock: state.clock.start(DateTime.now()),
      sessionId: state.sessionId.isEmpty ? const Uuid().v4() : state.sessionId,
      focusMode: focusMode,
    );
    _ensureTicker();
    if (focusMode) await PlatformServices.setFocusMode(true);
    await _persist();
  }

  Future<void> pause() async {
    if (!state.running) return;
    state = state.copyWith(clock: state.clock.pause(DateTime.now()));
    if (state.focusMode) await PlatformServices.setFocusMode(false);
    await _persist();
  }

  Future<void> reset() async {
    if (state.running || _finishing) return;
    state = state.copyWith(
      clock: const StudyClock(),
      sessionId: '',
      breakPhase: false,
    );
    await _persist();
  }

  Future<void> finish() async {
    if (_finishing) return;
    _finishing = true;
    final snapshot = state;
    state = state.copyWith(clock: state.clock.pause(DateTime.now()));
    if (snapshot.focusMode) await PlatformServices.setFocusMode(false);
    try {
      if (!snapshot.breakPhase) {
        await _saveSession(snapshot, snapshot.clock.elapsedAt(DateTime.now()));
      }
      if (!ref.mounted) return;
      state = state.copyWith(
        clock: const StudyClock(),
        sessionId: '',
        breakPhase: false,
        focusMode: false,
      );
      await _persist();
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(error: 'ذخیرهٔ جلسه انجام نشد؛ دوباره تلاش کن.');
      }
    } finally {
      _finishing = false;
    }
  }

  Future<void> _saveSession(StudyTimerState snapshot, int seconds) async {
    if (seconds < 60 || snapshot.sessionId.isEmpty) return;
    final db = ref.read(databaseProvider);
    // Stable session ID makes retrying a failed save safe.
    await db
        .into(db.studySessions)
        .insertOnConflictUpdate(
          StudySessionsCompanion.insert(
            id: snapshot.sessionId,
            subject: Value(
              snapshot.subject.trim().isEmpty
                  ? 'مطالعه آزاد'
                  : snapshot.subject.trim(),
            ),
            durationMinutes: seconds ~/ 60,
            startedAt: DateTime.now().subtract(Duration(seconds: seconds)),
          ),
        );
  }

  Future<void> _completePhase() async {
    if (_finishing) return;
    _finishing = true;
    final snapshot = state;
    state = state.copyWith(clock: StudyClock(elapsedSeconds: state.duration));
    if (snapshot.focusMode) await PlatformServices.setFocusMode(false);
    try {
      if (!snapshot.breakPhase) await _saveSession(snapshot, snapshot.duration);
      if (!ref.mounted) return;
      state = state.copyWith(
        clock: const StudyClock(),
        sessionId: '',
        breakPhase: !snapshot.breakPhase,
        cycles: snapshot.cycles + (snapshot.breakPhase ? 0 : 1),
      );
      await _persist();
      unawaited(SystemSound.play(SystemSoundType.alert));
      unawaited(HapticFeedback.mediumImpact());
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          error: 'ذخیرهٔ جلسه انجام نشد؛ دکمهٔ پایان را بزن.',
        );
      }
    } finally {
      _finishing = false;
    }
  }
}

class StudyTimerPage extends ConsumerWidget {
  const StudyTimerPage({this.focusOnly = false, super.key});
  final bool focusOnly;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyTimerProvider);
    final controller = ref.read(studyTimerProvider.notifier);
    final english = ref.watch(languageProvider);
    String tr(String fa, String en) => english ? en : fa;
    String digits(Object value) => english ? '$value' : faDigits(value);
    final seconds = state.secondsAt(DateTime.now());
    final locked = state.running || state.clock.elapsedSeconds > 0;
    final sessions = ref.watch(_todayStudySessionsProvider);
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(
              'هر دقیقه، یک قدم به هدفت نزدیک‌تر.',
              'One focused minute at a time.',
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (!focusOnly)
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'pomodoro',
                  label: Text(tr('پومودورو', 'Pomodoro')),
                ),
                ButtonSegment(
                  value: 'study',
                  label: Text(tr('تایمر درس', 'Study')),
                ),
                ButtonSegment(
                  value: 'stopwatch',
                  label: Text(tr('کرنومتر', 'Stopwatch')),
                ),
              ],
              selected: {state.mode},
              onSelectionChanged: locked || !state.ready
                  ? null
                  : (values) => controller.configure(mode: values.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: .28),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  state.breakPhase ? Icons.coffee_outlined : Icons.spa_outlined,
                  color: AppColors.emerald,
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  state.breakPhase
                      ? tr('زمان استراحت', 'Break time')
                      : state.running
                      ? tr('در حال تمرکز', 'Focus in progress')
                      : tr('برای تمرکز آماده‌ای؟', 'Ready to focus?'),
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      english
                          ? formatDuration(seconds).replaceAllMapped(
                              RegExp('[۰-۹]'),
                              (m) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(m[0]!).toString(),
                            )
                          : formatDuration(seconds),
                      key: const Key('timer-display'),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (!state.countingUp)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 1 - seconds / state.duration,
                      backgroundColor: AppColors.emerald.withValues(alpha: .12),
                      color: AppColors.emerald,
                      minHeight: 5,
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: locked
                        ? null
                        : () => _subject(context, ref, state.subject),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(
                      state.subject.isEmpty
                          ? tr('انتخاب درس یا موضوع', 'Choose a subject')
                          : state.subject,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('timer-toggle'),
                        onPressed: !state.ready
                            ? null
                            : () => state.running
                                  ? controller.pause()
                                  : controller.start(focusMode: focusOnly),
                        icon: Icon(
                          state.running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          state.running
                              ? tr('مکث', 'Pause')
                              : state.clock.elapsedSeconds > 0
                              ? tr('ادامه', 'Resume')
                              : tr('شروع', 'Start'),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('timer-finish'),
                        onPressed:
                            !state.ready ||
                                (!state.running &&
                                    state.clock.elapsedSeconds == 0)
                            ? null
                            : controller.finish,
                        icon: const Icon(Icons.stop_rounded, size: 19),
                        label: Text(tr('پایان و ثبت', 'Finish and save')),
                      ),
                    ),
                    IconButton(
                      tooltip: tr('شروع دوباره', 'Reset'),
                      onPressed: state.running ? null : controller.reset,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ),
              ],
            ),
          ),
          if (state.mode == 'pomodoro') ...[
            SectionTitle(tr('زمان کار و استراحت', 'Work and break duration')),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: locked ? null : () => _settings(context, ref),
                    icon: const Icon(Icons.tune_rounded, size: 17),
                    label: Text(
                      '${digits(state.workMinutes)} ${tr('کار', 'work')} / ${digits(state.breakMinutes)} ${tr('استراحت', 'break')}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${digits(state.cycles)} ${tr('چرخه', 'cycles')}',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final minutes in [15, 25, 45, 60])
                  ChoiceChip(
                    label: Text('${digits(minutes)} ${tr('دقیقه', 'min')}'),
                    selected: state.workMinutes == minutes,
                    onSelected: locked
                        ? null
                        : (_) => controller.configure(workMinutes: minutes),
                  ),
              ],
            ),
          ],
          SectionTitle(tr('مطالعهٔ امروز', 'Today’s study')),
          sessions.when(
            data: (items) => Column(
              children: [
                InfoTile(
                  icon: Icons.insights_rounded,
                  title:
                      '${digits(items.fold<int>(0, (sum, item) => sum + item.durationMinutes))} ${tr('دقیقه مطالعه ثبت‌شده', 'minutes recorded')}',
                  subtitle: tr(
                    'جلسه‌های یک دقیقه‌ای و بیشتر به آمار اضافه می‌شوند.',
                    'Sessions of one minute or more count toward your progress.',
                  ),
                  color: AppColors.emerald,
                ),
                ...items
                    .take(8)
                    .map(
                      (session) => InfoTile(
                        icon: Icons.history_rounded,
                        title: session.subject,
                        subtitle:
                            '${digits(session.durationMinutes)} ${tr('دقیقه', 'min')} · ${formatClock(session.startedAt)}',
                        color: AppColors.blue,
                      ),
                    ),
              ],
            ),
            error: (_, _) => Text(
              tr('خواندن آمار ممکن نشد.', 'Could not load study history.'),
            ),
            loading: () => const LinearProgressIndicator(),
          ),
          if (focusOnly && PlatformServices.supportsBackgroundAlarms)
            OutlinedButton.icon(
              onPressed: () async {
                await PlatformServices.requestFocusPermission();
              },
              icon: const Icon(Icons.notifications_off_outlined, size: 18),
              label: Text(
                tr('دسترسی حالت مزاحم نشوید', 'Do Not Disturb permission'),
              ),
            ),
          if (focusOnly)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                tr(
                  'برای خروج از جلسهٔ فعال، تأیید لازم است. برای سکوت اعلان‌های سیستم از حالت مزاحم نشوید دستگاه استفاده کن.',
                  'Leaving an active focus session requires confirmation. Use your device’s Do Not Disturb setting for system notifications.',
                ),
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _subject(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final text = TextEditingController(text: current);
    final books = await ref
        .read(databaseProvider)
        .select(ref.read(databaseProvider).books)
        .get();
    if (!context.mounted) {
      text.dispose();
      return;
    }
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('موضوع مطالعه'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: text,
                autofocus: true,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'درس یا موضوع دلخواه',
                ),
              ),
              if (books.isNotEmpty)
                Wrap(
                  spacing: 5,
                  children: books
                      .map(
                        (book) => ActionChip(
                          label: Text(book.title),
                          onPressed: () => text.text = book.title,
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text.trim()),
            child: const Text('انتخاب'),
          ),
        ],
      ),
    );
    text.dispose();
    if (saved != null) {
      await ref.read(studyTimerProvider.notifier).configure(subject: saved);
    }
  }

  Future<void> _settings(BuildContext context, WidgetRef ref) async {
    final state = ref.read(studyTimerProvider);
    var work = state.workMinutes.toDouble(),
        rest = state.breakMinutes.toDouble();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('زمان دلخواه'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('مطالعه: ${faDigits(work.round())} دقیقه'),
              Slider(
                value: work,
                min: 1,
                max: 180,
                divisions: 179,
                onChanged: (v) => setDialog(() => work = v),
              ),
              Text('استراحت: ${faDigits(rest.round())} دقیقه'),
              Slider(
                value: rest,
                min: 1,
                max: 60,
                divisions: 59,
                onChanged: (v) => setDialog(() => rest = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await ref
          .read(studyTimerProvider.notifier)
          .configure(workMinutes: work.round(), breakMinutes: rest.round());
    }
  }
}

final _todayStudySessionsProvider = StreamProvider<List<StudySession>>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now(), start = DateTime.now();
  final midnight = DateTime(start.year, start.month, start.day);
  return (db.select(db.studySessions)
        ..where(
          (row) =>
              row.startedAt.isBiggerOrEqualValue(midnight) &
              row.startedAt.isSmallerThanValue(
                DateTime(now.year, now.month, now.day + 1),
              ),
        )
        ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]))
      .watch();
});

class FocusModePage extends ConsumerWidget {
  const FocusModePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PopScope(
    canPop: !ref.watch(studyTimerProvider).running,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('آیا مطمئنی؟'),
          content: const Text(
            'با خروج، جلسهٔ تمرکز مکث می‌شود و پیشرفتت باقی می‌ماند.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ادامهٔ تمرکز'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('خروج'),
            ),
          ],
        ),
      );
      if (leave == true) await ref.read(studyTimerProvider.notifier).pause();
    },
    child: const StudyTimerPage(focusOnly: true),
  );
}
