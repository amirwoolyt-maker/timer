part of '../../feature_pages.dart';

class StudyTimerPage extends ConsumerStatefulWidget {
  const StudyTimerPage({super.key});
  @override
  ConsumerState<StudyTimerPage> createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends ConsumerState<StudyTimerPage> {
  Timer? timer;
  int seconds = 1500;
  int initial = 1500;
  bool active = false;
  bool stopwatch = false;
  final subject = TextEditingController(text: 'مطالعه امروز');

  @override
  void dispose() {
    timer?.cancel();
    subject.dispose();
    super.dispose();
  }

  void _toggle() {
    if (active) {
      timer?.cancel();
      setState(() => active = false);
      return;
    }
    setState(() => active = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (seconds <= 0) {
        timer?.cancel();
        setState(() => active = false);
        _saveSession();
      } else {
        setState(() => seconds += stopwatch ? 1 : -1);
      }
    });
  }

  Future<void> _saveSession() async {
    final elapsed = stopwatch ? seconds : initial - seconds;
    if (elapsed < 60) return;
    final db = ref.read(databaseProvider);
    await db
        .into(db.studySessions)
        .insert(
          StudySessionsCompanion.insert(
            id: const Uuid().v4(),
            subject: Value(
              subject.text.trim().isEmpty ? 'مطالعه آزاد' : subject.text.trim(),
            ),
            durationMinutes: elapsed ~/ 60,
            startedAt: DateTime.now().subtract(Duration(seconds: elapsed)),
          ),
        );
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'هر دقیقه، یک قدم به هدفت نزدیک‌تر.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 15),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('پومودورو')),
            ButtonSegment(value: true, label: Text('کرنومتر')),
          ],
          selected: {stopwatch},
          onSelectionChanged: (values) => setState(() {
            stopwatch = values.first;
            seconds = stopwatch ? 0 : 1500;
            initial = seconds;
          }),
        ),
        const SizedBox(height: 17),
        _timerCard(),
        const SectionTitle('تنظیم سریع'),
        Row(
          children: [
            for (final mins in [15, 25, 45, 60])
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 5),
                  child: OutlinedButton(
                    onPressed: active || stopwatch
                        ? null
                        : () => setState(() {
                            seconds = mins * 60;
                            initial = seconds;
                          }),
                    child: Text(
                      '${faDigits(mins)} دقیقه',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SectionTitle('آمار امروز'),
        FutureBuilder<List<StudySession>>(
          future: ref.read(databaseProvider).sessionsForToday(),
          builder: (context, snapshot) {
            final sum =
                snapshot.data?.fold<int>(
                  0,
                  (value, item) => value + item.durationMinutes,
                ) ??
                0;
            return InfoTile(
              icon: Icons.insights_rounded,
              title: '${faDigits(sum)} دقیقه مطالعه ثبت شده',
              subtitle: 'هدف امروز: ۱۸۰ دقیقه',
              color: AppColors.emerald,
            );
          },
        ),
      ],
    ),
  );

  Widget _timerCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 25),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Text(
          stopwatch ? 'کرنومتر آزاد' : 'جلسه تمرکز',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 11),
        Text(
          formatDuration(seconds),
          style: const TextStyle(
            fontSize: 55,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 205,
          child: TextField(
            controller: subject,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'موضوع مطالعه'),
          ),
        ),
        const SizedBox(height: 17),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: active
                  ? null
                  : () => setState(() {
                      seconds = stopwatch ? 0 : 1500;
                      initial = seconds;
                    }),
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _toggle,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                minimumSize: const Size(60, 60),
                backgroundColor: AppColors.emerald,
                foregroundColor: const Color(0xFF061B13),
              ),
              child: Icon(
                active ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 31,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () async {
                await _saveSession();
                timer?.cancel();
                if (mounted) {
                  setState(() {
                    active = false;
                    seconds = stopwatch ? 0 : 1500;
                  });
                }
              },
              icon: const Icon(Icons.stop_rounded, color: AppColors.red),
            ),
          ],
        ),
      ],
    ),
  );
}

class FocusModePage extends ConsumerStatefulWidget {
  const FocusModePage({super.key});
  @override
  ConsumerState<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends ConsumerState<FocusModePage> {
  bool active = false;
  int seconds = 25 * 60;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (active) {
      timer?.cancel();
      setState(() => active = false);
      return;
    }
    setState(() => active = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (seconds <= 1) {
        timer?.cancel();
        setState(() {
          seconds = 0;
          active = false;
        });
        _saveSession(25);
      } else {
        setState(() => seconds--);
      }
    });
  }

  Future<void> _saveSession(int minutes) async {
    if (minutes <= 0) return;
    final db = ref.read(databaseProvider);
    await db
        .into(db.studySessions)
        .insert(
          StudySessionsCompanion.insert(
            id: const Uuid().v4(),
            subject: const Value('جلسه تمرکز'),
            durationMinutes: minutes,
            startedAt: DateTime.now().subtract(Duration(minutes: minutes)),
          ),
        );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !active,
    onPopInvokedWithResult: (didPop, _) async {
      if (!didPop && active) {
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('آیا مطمئنی؟'),
            content: const Text('با خروج از حالت تمرکز، جلسه متوقف می‌شود.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ادامه'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('خروج'),
              ),
            ],
          ),
        );
        if (leave == true && mounted) {
          timer?.cancel();
          setState(() => active = false);
        }
      }
    },
    child: PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حالت تمرکز',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'یک بازه بساز و همه حواست را به هدفت بده.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 25),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: .35),
                  width: 11,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatDuration(seconds),
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
                  ),
                  Text(
                    'دقیقه تمرکز',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _toggle,
              icon: Icon(active ? Icons.pause : Icons.play_arrow),
              label: Text(active ? 'مکث جلسه' : 'شروع تمرکز'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: AppColors.emerald,
                foregroundColor: const Color(0xFF041B12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: active ? null : () => setState(() => seconds = 25 * 60),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('شروع دوباره جلسه'),
          ),
          const SizedBox(height: 12),
          const InfoTile(
            icon: Icons.notifications_off_outlined,
            title: 'اعلان‌های داخل برنامه خاموش‌اند',
            subtitle: 'خاموش‌کردن اعلان‌های سیستم نیازمند دسترسی دستگاه است.',
            color: AppColors.emerald,
          ),
        ],
      ),
    ),
  );
}
