part of '../../feature_pages.dart';

class MoreGrid extends ConsumerWidget {
  const MoreGrid({required this.onSelect, super.key});
  final ValueChanged<String> onSelect;
  static const items = [
    ('dashboard', 'داشبورد آمار', 'آمار و پیشرفت', Icons.bar_chart_rounded),
    ('calendar', 'تقویم', 'تقویم جلالی', Icons.calendar_month_rounded),
    ('studyTimer', 'تایمر درس', 'ثبت زمان مطالعه', Icons.school_rounded),
    (
      'league',
      'مطالعهٔ همراهان',
      'پیشرفت و رقابت شخصی',
      Icons.emoji_events_rounded,
    ),
    ('projects', 'پروژه‌ها', 'مدیریت پروژه', Icons.folder_copy_rounded),
    ('studyRoom', 'اتاق مطالعه', 'فضای مطالعه و گفت‌وگو', Icons.groups_rounded),
    ('templates', 'الگوها', 'قالب کار', Icons.dashboard_customize_rounded),
    ('trash', 'سطل زباله', 'بازیابی آیتم‌ها', Icons.delete_sweep_rounded),
    ('resources', 'منابع درسی', 'سایت‌های آموزشی', Icons.menu_book_rounded),
    (
      'uniRanking',
      'شناخت دانشگاه‌ها',
      'فهرست و علاقه‌مندی‌ها',
      Icons.account_balance_rounded,
    ),
    ('chat', 'چت با کنکوری‌ها', 'چت و گروه', Icons.forum_rounded),
    ('focus', 'حالت تمرکز', 'تمرکز کامل', Icons.psychology_rounded),
    ('location', 'یادآور مکان', 'یادآوری مکان', Icons.location_on_rounded),
    ('smartAlarm', 'بیدار شو!', 'آلارم هوشمند', Icons.wb_sunny_rounded),
    ('period', 'چرخه پریود', 'چرخه سلامت', Icons.spa_rounded),
    ('profile', 'پروفایل', '', Icons.person_rounded),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = ref.watch(languageProvider);
    const englishNames = [
      'Statistics dashboard',
      'Calendar',
      'Study timer',
      'Study league',
      'Projects',
      'Study rooms',
      'Templates',
      'Trash',
      'Study resources',
      'University directory',
      'Exam community',
      'Focus mode',
      'Place reminders',
      'Smart alarm',
      'Cycle tracker',
      'Profile',
    ];
    const englishDescriptions = [
      'Stats and progress',
      'Jalali dates',
      'Record study time',
      'Study progress',
      'Project planning',
      'Group study',
      'Task templates',
      'Restore deleted items',
      'Learning websites',
      'Directory and favorites',
      'Chat and groups',
      'Full focus',
      'Location reminders',
      'Math challenge alarm',
      'Cycle tracking',
      '',
    ];
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            english ? 'All your tools, together' : 'همه ابزارها، یک‌جا',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            english
                ? 'Everything for a better day.'
                : 'هر چیزی که برای ساختن یک روز بهتر لازم داری.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              mainAxisExtent:
                  146 + (MediaQuery.textScalerOf(context).scale(12) - 12) * 2.5,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () => onSelect(item.$1),
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          item.$4,
                          color: AppColors.emerald,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: english ? englishNames[index] : item.$2,
                        child: Text(
                          english ? englishNames[index] : item.$2,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if ((english ? englishDescriptions[index] : item.$3)
                          .isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          english ? englishDescriptions[index] : item.$3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class FeaturePage extends ConsumerWidget {
  const FeaturePage({required this.feature, super.key});
  final String feature;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(onlineConfigProvider).enabled) {
      final collection = {
        'league': 'scores',
        'studyRoom': 'rooms',
        'chat': 'messages',
      }[feature];
      if (collection != null) return CloudHubPage(mode: collection);
    }
    return switch (feature) {
      'dashboard' => const DashboardPage(),
      'calendar' => const JalaliCalendarPage(),
      'projects' => const ProjectsPage(),
      'trash' => const TrashPage(),
      'smartAlarm' => const AlarmsPage(),
      'focus' => const FocusModePage(),
      'profile' => const ProfilePage(),
      'account' => const AccountPage(),
      'studyTimer' => const StudyTimerPage(),
      'league' => const LeaguePage(),
      'studyRoom' => const StudyRoomsPage(),
      'templates' => const TemplatesPage(),
      'resources' => const ResourcesPage(),
      'uniRanking' => const UniversityDirectoryPage(),
      'chat' => const LocalChatPage(),
      'location' => const PlaceRemindersPage(),
      'period' => const CycleTrackerPage(),
      _ => const SizedBox.shrink(),
    };
  }
}

final _allStudySessionsProvider = StreamProvider<List<StudySession>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.studySessions,
  )..orderBy([(row) => OrderingTerm.desc(row.startedAt)])).watch();
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final sessions = ref.watch(_allStudySessionsProvider);
    final english = ref.watch(languageProvider);
    return PageFrame(
      child: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Text('خواندن آمار ممکن نشد. دوباره تلاش کن.'),
        data: (items) => sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => const Text('خواندن جلسه‌های مطالعه ممکن نشد.'),
          data: (history) {
            final done = items.where((task) => task.completed).length;
            final minutes = history.fold<int>(
              0,
              (sum, item) => sum + item.durationMinutes,
            );
            final xp = done * 20 + minutes * 2;
            final level = (xp ~/ 500 + 1).clamp(1, 8);
            const names = [
              'تازه‌کار',
              'جوینده',
              'پرتلاش',
              'هدفمند',
              'پیشرو',
              'حرفه‌ای',
              'قهرمان',
              'اسطوره',
            ];
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final activeDays = history
                .map(
                  (item) => DateTime(
                    item.startedAt.year,
                    item.startedAt.month,
                    item.startedAt.day,
                  ),
                )
                .toSet();
            for (final task in items) {
              final date = task.completedAt;
              if (task.completed && date != null) {
                activeDays.add(DateTime(date.year, date.month, date.day));
              }
            }
            var cursor = activeDays.contains(today)
                ? today
                : today.subtract(const Duration(days: 1));
            var streak = 0;
            while (activeDays.contains(cursor)) {
              streak++;
              cursor = cursor.subtract(const Duration(days: 1));
            }
            final days = List.generate(
              7,
              (i) => today.subtract(Duration(days: 6 - i)),
            );
            final totals = days
                .map(
                  (day) => history
                      .where(
                        (s) =>
                            s.startedAt.year == day.year &&
                            s.startedAt.month == day.month &&
                            s.startedAt.day == day.day,
                      )
                      .fold<int>(0, (sum, s) => sum + s.durationMinutes),
                )
                .toList();
            final peak = <int, int>{};
            for (final session in history) {
              peak.update(
                session.startedAt.hour,
                (v) => v + session.durationMinutes,
                ifAbsent: () => session.durationMinutes,
              );
            }
            final hours = peak.keys.toList()
              ..sort((a, b) => peak[b]!.compareTo(peak[a]!));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  english ? 'Your progress' : 'رشدت را ببین',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  english
                      ? 'Calculated from your saved activity.'
                      : 'همه آمار از کارها و جلسه‌های واقعی تو محاسبه می‌شود.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    StatCard(
                      label: english ? 'Experience' : 'امتیاز تجربه',
                      value: faDigits(xp),
                      icon: Icons.bolt_rounded,
                      color: AppColors.amber,
                    ),
                    const SizedBox(width: 8),
                    StatCard(
                      label: english
                          ? 'Level $level / 8'
                          : 'سطح ${faDigits(level)} از ۸ · ${names[level - 1]}',
                      value: faDigits(level),
                      icon: Icons.military_tech_rounded,
                      color: AppColors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatCard(
                      label: english ? 'Completed tasks' : 'کار تکمیل‌شده',
                      value: faDigits(done),
                      icon: Icons.check_circle_outline,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 8),
                    StatCard(
                      label: english ? 'Study minutes' : 'دقیقه مطالعه',
                      value: faDigits(minutes),
                      icon: Icons.schedule,
                      color: AppColors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InfoTile(
                  icon: Icons.local_fire_department_outlined,
                  title: english
                      ? '$streak day streak'
                      : '${faDigits(streak)} روز پیوستگی',
                  subtitle: english
                      ? 'Based on your study sessions and completed tasks.'
                      : 'با ثبت مطالعه یا تکمیل کار، زنجیره‌ات را ادامه بده.',
                  color: AppColors.amber,
                ),
                SectionTitle(
                  english
                      ? 'Study during the last 7 days'
                      : 'مطالعه در هفت روز گذشته',
                ),
                _ToolPanel(
                  child: Column(
                    children: List.generate(
                      days.length,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 92,
                              child: Text(
                                formatJalali(days[i]),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: totals.every((v) => v == 0)
                                    ? 0
                                    : totals[i] /
                                          totals.reduce(
                                            (a, b) => a > b ? a : b,
                                          ),
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 48,
                              child: Text(
                                faDigits(totals[i]),
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InfoTile(
                  icon: Icons.wb_sunny_outlined,
                  title: english ? 'Peak study hour' : 'ساعت اوج مطالعه',
                  subtitle: hours.isEmpty
                      ? (english
                            ? 'Save a study session to see this insight.'
                            : 'بعد از اولین جلسهٔ مطالعه نمایش داده می‌شود.')
                      : '${faDigits(hours.first.toString().padLeft(2, '0'))}:۰۰ · ${faDigits(peak[hours.first]!)} دقیقه',
                  color: AppColors.emerald,
                ),
                const SectionTitle('عادت‌های روزانه'),
                const _HabitsPanel(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class JalaliCalendarPage extends ConsumerStatefulWidget {
  const JalaliCalendarPage({super.key});
  @override
  ConsumerState<JalaliCalendarPage> createState() => _JalaliCalendarPageState();
}

class _JalaliCalendarPageState extends ConsumerState<JalaliCalendarPage> {
  Jalali month = Jalali.now(), selected = Jalali.now();
  @override
  Widget build(BuildContext context) {
    final first = month.copy(day: 1).toDateTime(),
        offset = (first.weekday + 1) % 7,
        length = month.monthLength;
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => month = month.addMonths(-1)),
                icon: const Icon(Icons.chevron_right),
              ),
              Expanded(
                child: Text(
                  formatJalali(month.toDateTime()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => month = month.addMonths(1)),
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']
                      .map(
                        (value) => Text(
                          value,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: length + offset,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemBuilder: (context, index) {
                    if (index < offset) return const SizedBox.shrink();
                    final day = index - offset + 1,
                        value = month.copy(day: day),
                        active =
                            value.year == selected.year &&
                            value.month == selected.month &&
                            value.day == selected.day;
                    return InkWell(
                      onTap: () => setState(() => selected = value),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? AppColors.emerald : null,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          faDigits(day),
                          style: TextStyle(
                            color: active
                                ? const Color(0xFF041B12)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SectionTitle(
            'برنامه انتخاب‌شده',
            action: '+ کار جدید',
            onTap: () => _calendarTask(context),
          ),
          ref
              .watch(tasksProvider)
              .when(
                data: (tasks) {
                  final day = selected.toDateTime();
                  final list = tasks
                      .where(
                        (task) =>
                            task.dueAt != null &&
                            task.dueAt!.year == day.year &&
                            task.dueAt!.month == day.month &&
                            task.dueAt!.day == day.day,
                      )
                      .toList();
                  return list.isEmpty
                      ? const Text(
                          'برای این روز کاری ثبت نشده.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        )
                      : Column(
                          children: list
                              .map(
                                (task) => InfoTile(
                                  icon: Icons.check_circle_outline_rounded,
                                  title: task.title,
                                  subtitle: task.completed
                                      ? 'تکمیل‌شده'
                                      : formatClock(task.dueAt!),
                                  color: AppColors.emerald,
                                ),
                              )
                              .toList(),
                        );
                },
                error: (error, _) => Text('$error'),
                loading: () =>
                    const LinearProgressIndicator(color: AppColors.emerald),
              ),
        ],
      ),
    );
  }

  Future<void> _calendarTask(BuildContext context) async {
    final values = await _toolForm(
      context,
      title: 'کار جدید برای ${formatJalali(selected.toDateTime())}',
      fields: [('title', 'عنوان کار'), ('description', 'توضیحات')],
    );
    if (values == null || !mounted) return;
    final db = ref.read(databaseProvider);
    final id = const Uuid().v4();
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: id,
            title: values['title']!,
            description: Value(values['description']!),
            dueAt: Value(selected.toDateTime().add(const Duration(hours: 9))),
            createdAt: DateTime.now(),
          ),
        );
    final task = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals(id))).getSingle();
    final reminder = await TaskReminders.sync(task, requestPermission: true);
    if (context.mounted &&
        {
          ReminderResult.failed,
          ReminderResult.permissionDenied,
        }.contains(reminder)) {
      _toolNotice(
        context,
        'کار ثبت شد، اما مجوز یا زمان‌بندی یادآوری فعال نیست.',
      );
    }
  }
}

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'پروژه‌های تو',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        const SizedBox(height: 5),
        const Text(
          'کارهای بزرگ را به مسیرهای کوچک تبدیل کن.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('پروژه جدید'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: const Color(0xFF041B12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ref
            .watch(projectsProvider)
            .when(
              data: (items) => items.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_open,
                      title: 'پروژه‌ای نساخته‌ای',
                      subtitle: 'برای هر هدفی یک پروژه بساز.',
                      action: 'پروژه جدید',
                      onTap: () => _add(context, ref),
                    )
                  : Column(
                      children: items
                          .map(
                            (item) => _ProjectTile(
                              project: item,
                              onDelete: () => ref
                                  .read(databaseProvider)
                                  .softDeleteProject(item.id),
                            ),
                          )
                          .toList(),
                    ),
              error: (error, _) => Text('$error'),
              loading: () =>
                  const CircularProgressIndicator(color: AppColors.emerald),
            ),
      ],
    ),
  );
  static Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController(), description = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پروژه جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'نام پروژه'),
            ),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'توضیحات'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بی‌خیال'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, name.text.trim().isNotEmpty),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final db = ref.read(databaseProvider);
      await db
          .into(db.projects)
          .insert(
            ProjectsCompanion.insert(
              id: const Uuid().v4(),
              name: name.text.trim(),
              description: Value(description.text.trim()),
            ),
          );
    }
  }
}

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سطل زباله',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'آیتم‌های حذف‌شده را بازیابی کن.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 13),
        ref
            .watch(trashedTasksProvider)
            .when(
              data: (items) => Column(
                children: items
                    .map(
                      (item) => _TrashTile(
                        title: item.title,
                        type: 'کار',
                        onRestore: () async {
                          await ref.read(databaseProvider).restoreTask(item.id);
                          final result = await TaskReminders.sync(
                            item.copyWith(deletedAt: const Value(null)),
                            requestPermission: true,
                          );
                          if (context.mounted &&
                              {
                                ReminderResult.failed,
                                ReminderResult.permissionDenied,
                              }.contains(result)) {
                            _toolNotice(
                              context,
                              'کار بازیابی شد، اما یادآوری فعال نشد.',
                            );
                          }
                        },
                        onDelete: () => ref
                            .read(databaseProvider)
                            .deleteTaskPermanently(item.id),
                      ),
                    )
                    .toList(),
              ),
              error: (error, _) => Text('$error'),
              loading: () => const LinearProgressIndicator(),
            ),
        ref
            .watch(trashedNotesProvider)
            .when(
              data: (items) => Column(
                children: items
                    .map(
                      (item) => _TrashTile(
                        title: item.title,
                        type: 'یادداشت',
                        onRestore: () => _restoreNote(context, ref, item.id),
                        onDelete: () => ref
                            .read(databaseProvider)
                            .deleteNotePermanently(item.id),
                      ),
                    )
                    .toList(),
              ),
              error: (error, _) => Text('$error'),
              loading: () => const SizedBox.shrink(),
            ),
        ref
            .watch(trashedProjectsProvider)
            .when(
              data: (items) => Column(
                children: items
                    .map(
                      (item) => _TrashTile(
                        title: item.name,
                        type: 'پروژه',
                        onRestore: () =>
                            ref.read(databaseProvider).restoreProject(item.id),
                        onDelete: () => ref
                            .read(databaseProvider)
                            .deleteProjectPermanently(item.id),
                      ),
                    )
                    .toList(),
              ),
              error: (error, _) => Text('$error'),
              loading: () => const SizedBox.shrink(),
            ),
        const _ToolTrashPanel(),
      ],
    ),
  );
}

class _TrashTile extends StatelessWidget {
  const _TrashTile({
    required this.title,
    required this.type,
    required this.onRestore,
    required this.onDelete,
  });
  final String title, type;
  final VoidCallback onRestore, onDelete;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: AlignmentDirectional.centerEnd,
    children: [
      InfoTile(
        icon: Icons.delete_outline,
        title: title,
        subtitle: type,
        color: AppColors.muted,
      ),
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: onRestore, child: const Text('بازیابی')),
            IconButton(
              onPressed: onDelete,
              tooltip: 'حذف دائمی',
              icon: const Icon(
                Icons.delete_forever_outlined,
                color: AppColors.red,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.onDelete});
  final Project project;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsetsDirectional.only(
      start: 13,
      end: 4,
      top: 4,
      bottom: 4,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.folder_copy_rounded, color: AppColors.emerald),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                project.description.isEmpty
                    ? 'بدون توضیح'
                    : project.description,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onDelete,
          tooltip: 'انتقال به سطل زباله',
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.muted,
            size: 19,
          ),
        ),
      ],
    ),
  );
}

class AlarmsPage extends ConsumerStatefulWidget {
  const AlarmsPage({super.key});
  @override
  ConsumerState<AlarmsPage> createState() => _AlarmsPageState();
}

class _AlarmsPageState extends ConsumerState<AlarmsPage> {
  Timer? _alarmTimer;
  Timer? _challengeSoundLoop, _challengePlaybackCheck, _challengeCooldownTicker;
  bool _prompting = false, _checking = false;
  final Set<String> _handled = {};
  @override
  void initState() {
    super.initState();
    _alarmTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkAlarms(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAlarms());
  }

  @override
  void dispose() {
    _alarmTimer?.cancel();
    _challengeSoundLoop?.cancel();
    _challengePlaybackCheck?.cancel();
    _challengeCooldownTicker?.cancel();
    super.dispose();
  }

  Future<void> _checkAlarms() async {
    if (!mounted || _prompting || _checking) return;
    _checking = true;
    try {
      final pending = await PlatformServices.pendingAlarmId();
      if (!mounted) return;
      final now = DateTime.now();
      final rows = ref
          .read(alarmsProvider)
          .maybeWhen(data: (rows) => rows, orElse: () => const <Alarm>[]);
      for (final alarm in rows) {
        final dayKey = '${alarm.id}:${now.year}-${now.month}-${now.day}';
        if (alarm.id == pending ||
            (alarm.enabled &&
                (alarm.hour == now.hour &&
                    alarm.minute == now.minute &&
                    !_handled.contains(dayKey)))) {
          _handled.add(dayKey);
          await _challenge(alarm);
          break;
        }
      }
    } finally {
      _checking = false;
    }
  }

  bool _easyOnly() {
    final prefs = ref
        .read(preferencesProvider)
        .maybeWhen(data: (rows) => rows, orElse: () => const <AppPreference>[]);
    final grade =
        prefs.where((r) => r.key == 'profile.grade').firstOrNull?.value ??
        'elementary';
    return {
      'elementary',
      '7',
      '8',
      '9',
      'ابتدایی',
      'هفتم',
      'هشتم',
      'نهم',
    }.contains(grade);
  }

  Future<void> _schedule(Alarm alarm, bool enabled) async {
    final db = ref.read(databaseProvider);
    try {
      if (enabled) {
        if (PlatformServices.supportsBackgroundAlarms) {
          final permissions = await PlatformServices.requestAlarmPermissions();
          if (!permissions) {
            throw StateError('Alarm permissions were not granted.');
          }
          final scheduled = await PlatformServices.scheduleAlarm(
            alarm.id,
            alarm.hour,
            alarm.minute,
            alarm.label,
          );
          if (!scheduled) throw StateError('The alarm could not be scheduled.');
        }
      } else {
        if (PlatformServices.supportsBackgroundAlarms) {
          await PlatformServices.unscheduleAlarm(alarm.id);
        }
      }
      await (db.update(db.alarms)..where((r) => r.id.equals(alarm.id))).write(
        AlarmsCompanion(enabled: Value(enabled)),
      );
    } catch (_) {
      if (mounted) {
        _toolNotice(
          context,
          'آلارم تغییر نکرد؛ مجوز اعلان و آلارم دقیق را بررسی کن و دوباره تلاش کن.',
        );
      }
    }
  }

  Future<void> _add() async {
    final db = ref.read(databaseProvider);
    final rows = await db.select(db.alarms).get();
    if (!mounted) return;
    if (rows.length >= 5) {
      _toolNotice(context, 'حداکثر پنج آلارم می‌توانی داشته باشی.');
      return;
    }
    final label = TextEditingController(text: 'آلارم صبحگاهی');
    var selected = const TimeOfDay(hour: 7, minute: 0);
    var level = 'آسان';
    final easyOnly = _easyOnly();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('آلارم جدید'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: label,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'عنوان',
                      counterText: '',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'عنوان را وارد کن.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: selected,
                      );
                      if (time != null) update(() => selected = time);
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      '${faDigits(selected.hour.toString().padLeft(2, '0'))}:${faDigits(selected.minute.toString().padLeft(2, '0'))}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    items: (easyOnly ? ['آسان'] : ['آسان', 'متوسط', 'سخت'])
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    decoration: const InputDecoration(labelText: 'سطح چالش'),
                    onChanged: (value) {
                      if (value != null) update(() => level = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    easyOnly
                        ? 'برای پایه نهم و پایین‌تر، فقط ضرب و تقسیم ساده فعال است.'
                        : 'آسان: ضرب و تقسیم · متوسط: توان و معادله · سخت: مثلثات و ریشه',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
    final title = label.text.trim();
    Future<void>.delayed(const Duration(milliseconds: 350), label.dispose);
    if (saved != true || !mounted) return;
    final id = const Uuid().v4();
    var inserted = false;
    try {
      if (PlatformServices.supportsBackgroundAlarms &&
          !await PlatformServices.requestAlarmPermissions()) {
        if (!mounted) return;
        _toolNotice(
          context,
          'مجوز اعلان، آلارم دقیق و نمایش تمام‌صفحه لازم است تا زنگ در پس‌زمینه اجرا شود.',
        );
        return;
      }
      await db
          .into(db.alarms)
          .insert(
            AlarmsCompanion.insert(
              id: id,
              label: title,
              hour: selected.hour,
              minute: selected.minute,
              challengeLevel: Value(level),
            ),
          );
      inserted = true;
      if (PlatformServices.supportsBackgroundAlarms) {
        final scheduled = await PlatformServices.scheduleAlarm(
          id,
          selected.hour,
          selected.minute,
          title,
        );
        if (!scheduled) throw StateError('The alarm could not be scheduled.');
      }
      if (mounted) {
        _toolNotice(
          context,
          PlatformServices.supportsBackgroundAlarms
              ? 'آلارم روزانه ذخیره و زمان‌بندی شد.'
              : 'آلارم ذخیره شد؛ در این دستگاه فقط هنگام باز بودن برنامه بررسی می‌شود.',
        );
      }
    } catch (_) {
      if (inserted) {
        await (db.delete(db.alarms)..where((r) => r.id.equals(id))).go();
      }
      await PlatformServices.cancelAlarm(id);
      if (mounted) {
        _toolNotice(
          context,
          'ذخیره یا زمان‌بندی آلارم ممکن نشد؛ مجوزهای دستگاه را بررسی کن.',
        );
      }
    }
  }

  Future<void> _challenge(Alarm alarm, {bool test = false}) async {
    if (_prompting || !mounted) return;
    _prompting = true;
    final cooldownKey = 'alarmCooldown:${alarm.id}';
    String? cooldownDeadline;
    try {
      final db = ref.read(databaseProvider);
      final preference = await (db.select(
        db.appPreferences,
      )..where((p) => p.key.equals(cooldownKey))).getSingleOrNull();
      cooldownDeadline = preference?.value;
    } catch (_) {
      _prompting = false;
      if (mounted) {
        _toolNotice(context, 'خواندن وضعیت چالش ممکن نشد؛ دوباره تلاش کن.');
      }
      return;
    }
    if (!mounted) {
      _prompting = false;
      return;
    }
    final input = TextEditingController();
    final seed = DateTime.now().microsecondsSinceEpoch;
    final level = _easyOnly() ? 'آسان' : alarm.challengeLevel;
    final challenge = createAlarmChallenge(level, seed);
    final question = challenge.question;
    final answer = challenge.answer;
    var failures = alarm.wrongAttempts;
    var cooldown = remainingAlarmCooldown(cooldownDeadline, DateTime.now());
    String? error;
    String? playbackError;
    StateSetter? updateDialog;
    Future<void> ring() async {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }

    if (PlatformServices.supportsBackgroundAlarms) {
      if (!await PlatformServices.startAlarmChallenge(alarm.id)) {
        playbackError =
            'زنگ آزمایشی شروع نشد؛ اگر زنگ دیگری در حال پخش است، اول آن را حل کن.';
      }
    } else {
      await ring();
    }
    final soundLoop = PlatformServices.supportsBackgroundAlarms
        ? null
        : Timer.periodic(const Duration(seconds: 30), (_) => ring());
    _challengeSoundLoop = soundLoop;
    final playbackCheck = PlatformServices.supportsBackgroundAlarms
        ? Timer.periodic(const Duration(seconds: 2), (_) async {
            final message = await PlatformServices.pendingAlarmError();
            if (message != null &&
                message.isNotEmpty &&
                message != playbackError) {
              playbackError = message;
              if (mounted) updateDialog?.call(() {});
            }
          })
        : null;
    _challengePlaybackCheck = playbackCheck;
    final cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (cooldown > 0) {
        final remaining = remainingAlarmCooldown(
          cooldownDeadline,
          DateTime.now(),
        );
        updateDialog?.call(
          () => cooldown = remaining < cooldown ? remaining : cooldown - 1,
        );
      }
    });
    _challengeCooldownTicker = cooldownTicker;
    bool? solved;
    try {
      if (!mounted) return;
      solved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) {
            updateDialog = update;
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: Text(test ? 'آزمایش چالش بیداری' : 'وقت بیدار شدن است!'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        color: AppColors.amber,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question,
                        key: const Key('alarm-question'),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (playbackError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'صدای زنگ: $playbackError',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (level == 'آسان')
                        const Text(
                          'راهنما: ضرب یعنی جمع چندباره؛ تقسیم، عکس ضرب است.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('alarm-answer'),
                        controller: input,
                        enabled: cooldown == 0,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'پاسخ',
                          errorText: error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cooldown > 0
                            ? 'پس از شش خطا، ${faDigits(cooldown)} ثانیه صبر کن؛ زنگ خاموش نشده است.'
                            : '${faDigits(failures)} پاسخ نادرست',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  FilledButton(
                    onPressed: cooldown > 0
                        ? null
                        : () async {
                            if (int.tryParse(_toolAscii(input.text.trim())) ==
                                answer) {
                              Navigator.pop(ctx, true);
                              return;
                            }
                            failures++;
                            update(() {
                              error = 'پاسخ درست نیست؛ دوباره تلاش کن.';
                              input.clear();
                              if (failures % 6 == 0) {
                                cooldown = 30;
                                cooldownDeadline = DateTime.now()
                                    .add(const Duration(seconds: 30))
                                    .toIso8601String();
                              }
                            });
                            final db = ref.read(databaseProvider);
                            try {
                              await db.transaction(() async {
                                await (db.update(
                                  db.alarms,
                                )..where((r) => r.id.equals(alarm.id))).write(
                                  AlarmsCompanion(
                                    wrongAttempts: Value(failures),
                                  ),
                                );
                                if (failures % 6 == 0) {
                                  await db.savePreference(
                                    cooldownKey,
                                    cooldownDeadline!,
                                  );
                                }
                              });
                            } catch (_) {
                              if (mounted) {
                                _toolNotice(
                                  context,
                                  'ثبت تعداد خطا ممکن نشد؛ چالش همچنان فعال است.',
                                );
                              }
                            }
                          },
                    key: const Key('alarm-answer-submit'),
                    child: const Text('بررسی پاسخ'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } finally {
      updateDialog = null;
      soundLoop?.cancel();
      playbackCheck?.cancel();
      cooldownTicker.cancel();
      Future<void>.delayed(const Duration(milliseconds: 350), input.dispose);
      _prompting = false;
    }
    if (solved == true) {
      final db = ref.read(databaseProvider);
      await db.savePreference(cooldownKey, '');
      await (db.update(db.alarms)..where((r) => r.id.equals(alarm.id))).write(
        const AlarmsCompanion(wrongAttempts: Value(0)),
      );
      await PlatformServices.stopAlarm(alarm.id);
      if (mounted) {
        _toolNotice(
          context,
          test ? 'آزمایش موفق بود.' : 'آفرین! زنگ خاموش شد.',
        );
      }
    }
  }

  String _alarmDurationLabel(int milliseconds) {
    final seconds = (milliseconds / 1000).floor().clamp(0, 1 << 31);
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  Future<void> _pickAlarmSound(Alarm alarm, {required bool record}) async {
    if (!PlatformServices.supportsBackgroundAlarms) {
      _toolNotice(context, 'انتخاب و ضبط صدای زنگ در اندروید در دسترس است.');
      return;
    }
    var editingSound = false;
    var committed = false;
    try {
      final sound = await PlatformServices.pickAlarmSound(
        alarm.id,
        record: record,
      );
      editingSound = sound != null;
      if (sound == null || !mounted) {
        if (mounted) {
          _toolNotice(
            context,
            'صدایی انتخاب نشد؛ برنامهٔ فایل یا ضبط صدای دستگاه را بررسی کن.',
          );
        }
        return;
      }
      final duration = await PlatformServices.alarmSoundDuration(alarm.id);
      if (duration == null || duration <= 0) {
        if (mounted) {
          _toolNotice(
            context,
            'مدت فایل خوانده نشد؛ فایل صوتی دیگری انتخاب کن.',
          );
        }
        return;
      }
      if (!mounted) return;
      final maxStartSeconds = ((duration - 30000).clamp(0, duration) ~/ 1000);
      var startSeconds = 0;
      String? previewStatus;
      final selectedStart = await showDialog<int>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: const Text('بازهٔ ۳۰ثانیه‌ای صدای زنگ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('مدت فایل: ${_alarmDurationLabel(duration)}'),
                  const SizedBox(height: 10),
                  Text(
                    maxStartSeconds == 0
                        ? 'این فایل کوتاه‌تر از ۳۰ ثانیه است و کامل تکرار می‌شود.'
                        : 'شروع پخش: ${_alarmDurationLabel(startSeconds * 1000)} تا ${_alarmDurationLabel((startSeconds + 30) * 1000)}',
                    textAlign: TextAlign.center,
                  ),
                  Slider(
                    key: const Key('alarm-clip-start'),
                    value: startSeconds.toDouble(),
                    min: 0,
                    max: maxStartSeconds.toDouble(),
                    divisions: maxStartSeconds > 0 ? maxStartSeconds : null,
                    label: _alarmDurationLabel(startSeconds * 1000),
                    onChanged: maxStartSeconds == 0
                        ? null
                        : (value) => update(() => startSeconds = value.round()),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final saved = await PlatformServices.setAlarmSoundStart(
                        alarm.id,
                        startSeconds * 1000,
                      );
                      if (!dialogContext.mounted) return;
                      if (!saved) {
                        update(
                          () => previewStatus = 'ذخیرهٔ نقطهٔ شروع ممکن نشد.',
                        );
                        return;
                      }
                      final started = await PlatformServices.startAlarmPreview(
                        alarm.id,
                      );
                      if (!dialogContext.mounted) {
                        await PlatformServices.stopAlarmPreview(alarm.id);
                        return;
                      }
                      if (!started) {
                        update(
                          () => previewStatus =
                              'پیش‌نمایش شروع نشد؛ اگر زنگی فعال است، اول آن را حل کن.',
                        );
                        return;
                      }
                      update(
                        () =>
                            previewStatus = 'پیش‌نمایش تا ۳۰ ثانیه پخش می‌شود.',
                      );
                      await Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      );
                      final error = await PlatformServices.pendingAlarmError();
                      if (!dialogContext.mounted) return;
                      if (error != null && error.isNotEmpty) {
                        update(
                          () => previewStatus = 'پخش صدا ناموفق بود: $error',
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('پیش‌نمایش این بازه'),
                  ),
                  if (previewStatus != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      previewStatus!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            previewStatus!.contains('ناموفق') ||
                                previewStatus!.contains('نشد')
                            ? AppColors.red
                            : AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, startSeconds),
                child: const Text('ذخیرهٔ بازه'),
              ),
            ],
          ),
        ),
      );
      await PlatformServices.stopAlarmPreview(alarm.id);
      if (selectedStart == null || !mounted) return;
      final saved = await PlatformServices.setAlarmSoundStart(
        alarm.id,
        selectedStart * 1000,
      );
      if (saved) {
        committed = await PlatformServices.finishAlarmSoundEdit(
          alarm.id,
          commit: true,
        );
      }
      if (mounted) {
        _toolNotice(
          context,
          committed
              ? 'بازهٔ ${_alarmDurationLabel(selectedStart * 1000)} تا ${_alarmDurationLabel(((selectedStart + 30) * 1000).clamp(0, duration))} ذخیره شد.'
              : 'ذخیرهٔ بازهٔ صدا ممکن نشد؛ فایل را دوباره انتخاب کن.',
        );
      }
    } catch (_) {
      await PlatformServices.stopAlarmPreview(alarm.id);
      if (mounted) {
        _toolNotice(context, 'فایل صدا آماده نشد؛ فایل دیگری را امتحان کن.');
      }
    } finally {
      await PlatformServices.stopAlarmPreview(alarm.id);
      if (editingSound && !committed) {
        await PlatformServices.finishAlarmSoundEdit(alarm.id, commit: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToolHeading(
          _toolText(ref, 'بیدار شو!', 'Smart alarm'),
          _toolText(
            ref,
            'آلارم روزانه با چالش ریاضی و حداکثر پنج زنگ.',
            'Daily math-challenge alarms, up to five alarms.',
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: ref.watch(preferencesProvider).hasValue ? _add : null,
            icon: const Icon(Icons.add),
            label: const Text('آلارم جدید'),
          ),
        ),
        const SizedBox(height: 12),
        ref
            .watch(alarmsProvider)
            .when(
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text('خواندن آلارم‌ها ممکن نشد.'),
              data: (rows) => Column(
                children: [
                  if (rows.isEmpty)
                    const InfoTile(
                      icon: Icons.alarm_add_outlined,
                      title: 'اولین آلارمت را بساز',
                      subtitle: 'دکمهٔ بالا را بزن و زمان و چالش را انتخاب کن.',
                      color: AppColors.amber,
                    ),
                  ...rows.map(
                    (alarm) => _ToolPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.alarm, color: AppColors.amber),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${faDigits(alarm.hour.toString().padLeft(2, '0'))}:${faDigits(alarm.minute.toString().padLeft(2, '0'))}',
                                      style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      alarm.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: alarm.enabled,
                                onChanged: (enabled) =>
                                    _schedule(alarm, enabled),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'هر روز · چالش ${_easyOnly() ? 'آسان' : alarm.challengeLevel}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => _challenge(alarm, test: true),
                                icon: const Icon(Icons.play_arrow, size: 17),
                                label: const Text('آزمایش چالش'),
                              ),
                              const Spacer(),
                              PopupMenuButton<String>(
                                tooltip: 'صدای زنگ',
                                icon: const Icon(
                                  Icons.music_note_outlined,
                                  size: 19,
                                ),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'file',
                                    child: Text('انتخاب صدای دلخواه'),
                                  ),
                                  PopupMenuItem(
                                    value: 'record',
                                    child: Text('ضبط ویس'),
                                  ),
                                  PopupMenuItem(
                                    value: 'reset',
                                    child: Text('صدای پیش‌فرض'),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'reset') {
                                    await PlatformServices.stopAlarmPreview(
                                      alarm.id,
                                    );
                                    await PlatformServices.resetAlarmSound(
                                      alarm.id,
                                    );
                                    if (context.mounted) {
                                      _toolNotice(
                                        context,
                                        'صدای پیش‌فرض انتخاب شد.',
                                      );
                                    }
                                    return;
                                  }
                                  await _pickAlarmSound(
                                    alarm,
                                    record: value == 'record',
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'حذف آلارم',
                                onPressed: () async {
                                  if (!await _toolConfirm(
                                    context,
                                    'این آلارم حذف شود؟',
                                  )) {
                                    return;
                                  }
                                  await PlatformServices.cancelAlarm(alarm.id);
                                  final db = ref.read(databaseProvider);
                                  await (db.delete(
                                    db.alarms,
                                  )..where((r) => r.id.equals(alarm.id))).go();
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 19,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        const InfoTile(
          icon: Icons.info_outline,
          title: 'مجوزهای آلارم',
          subtitle:
              'در اندروید، مجوز اعلان و آلارم دقیق را فعال کن. روی وب، زنگ فقط هنگام باز بودن برنامه بررسی می‌شود. محدودیت باتری یا توقف اجباری سیستم ممکن است بر اجرای پس‌زمینه اثر بگذارد.',
          color: AppColors.blue,
        ),
      ],
    ),
  );
}

List<Map<String, dynamic>> _toolRecords(
  WidgetRef ref,
  String key, {
  List<Map<String, dynamic>> defaults = const [],
  bool listen = true,
}) {
  final prefs =
      (listen ? ref.watch(preferencesProvider) : ref.read(preferencesProvider))
          .maybeWhen(
            data: (rows) => rows,
            orElse: () => const <AppPreference>[],
          );
  final found = prefs.where((row) => row.key == key);
  if (found.isEmpty) {
    return defaults.map((row) => Map<String, dynamic>.from(row)).toList();
  }
  try {
    final decoded = jsonDecode(found.first.value);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> _saveToolRecords(
  WidgetRef ref,
  String key,
  List<Map<String, dynamic>> rows,
) => ref.read(databaseProvider).savePreference(key, jsonEncode(rows));

String _toolText(WidgetRef ref, String fa, String en) =>
    ref.watch(languageProvider) ? en : fa;

class _ToolPanel extends StatelessWidget {
  const _ToolPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _ToolHeading extends StatelessWidget {
  const _ToolHeading(this.title, this.description);
  final String title, description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.8,
          ),
        ),
      ],
    ),
  );
}

class _ToolLoading extends ConsumerWidget {
  const _ToolLoading({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(preferencesProvider)
      .when(
        data: (_) => child,
        error: (_, _) => const Padding(
          padding: EdgeInsets.all(24),
          child: Text('ذخیره‌سازی در دسترس نیست. برنامه را دوباره باز کن.'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      );
}

Future<Map<String, String>?> _toolForm(
  BuildContext context, {
  required String title,
  required List<(String, String)> fields,
  Map<String, String> initial = const {},
  Set<String> optional = const {'description', 'notes'},
  Set<String> multiline = const {'description', 'notes', 'tasks'},
  String submit = 'ذخیره',
}) async {
  final controllers = {
    for (final field in fields)
      field.$1: TextEditingController(text: initial[field.$1] ?? ''),
  };
  final key = GlobalKey<FormState>();
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields
                  .map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        key: Key('tool-field-${field.$1}'),
                        controller: controllers[field.$1],
                        minLines: multiline.contains(field.$1) ? 3 : 1,
                        maxLines: multiline.contains(field.$1) ? 6 : 1,
                        maxLength: field.$1 == 'tasks' ? 5000 : 1000,
                        decoration: InputDecoration(
                          labelText: field.$2,
                          counterText: '',
                        ),
                        validator: (value) =>
                            !optional.contains(field.$1) &&
                                (value == null || value.trim().isEmpty)
                            ? 'این قسمت را کامل کن.'
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(dialogContext, true);
            }
          },
          key: const Key('tool-save'),
          child: Text(submit),
        ),
      ],
    ),
  );
  final result = saved == true
      ? controllers.map(
          (key, controller) => MapEntry(key, controller.text.trim()),
        )
      : null;
  // The dialog owns fields until its closing animation completes.
  Future<void>.delayed(const Duration(milliseconds: 350), () {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  });
  return result;
}

Future<bool> _toolConfirm(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('آیا مطمئنی؟'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأیید'),
          ),
        ],
      ),
    ) ??
    false;

void _toolNotice(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

Future<void> _toolOpenUrl(BuildContext context, String address) async {
  final uri = Uri.tryParse(address);
  if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
    _toolNotice(context, 'نشانی معتبر نیست.');
    return;
  }
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      _toolNotice(context, 'باز کردن پیوند ممکن نشد.');
    }
  } catch (_) {
    if (context.mounted) {
      _toolNotice(context, 'باز کردن پیوند ممکن نشد. اتصال را بررسی کن.');
    }
  }
}

Future<void> _trashToolRecord(
  WidgetRef ref,
  String source,
  Map<String, dynamic> row,
  List<Map<String, dynamic>> records,
) async {
  final trash = _toolRecords(ref, 'tools.trash', listen: false);
  trash.insert(0, {
    'id': const Uuid().v4(),
    'source': source,
    'data': row,
    'title': row['title'] ?? row['name'] ?? '',
    'deletedAt': DateTime.now().toIso8601String(),
  });
  final db = ref.read(databaseProvider);
  await db.transaction(() async {
    await db.savePreference('tools.trash', jsonEncode(trash));
    await db.savePreference(
      source,
      jsonEncode(records.where((item) => item['id'] != row['id']).toList()),
    );
  });
}

class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key});
  static const _key = 'tools.templates';
  static const _defaults = <Map<String, dynamic>>[
    {
      'id': 'school',
      'title': 'روز مدرسه',
      'description': 'مطالعه، تمرین و مرور روزانه',
      'tasks':
          'مرور درس امروز\nحل تمرین ریاضی\nمطالعه کتاب درسی\nآماده کردن کیف فردا',
    },
    {
      'id': 'exam',
      'title': 'مرور شب امتحان',
      'description': 'یک مسیر کوتاه برای جمع‌بندی',
      'tasks':
          'مرور خلاصه‌ها\nحل نمونه سؤال\nبررسی پاسخ‌های نادرست\nخواب به‌موقع',
    },
  ];
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> rows, [
    Map<String, dynamic>? row,
  ]) async {
    final values = await _toolForm(
      context,
      title: row == null ? 'الگوی جدید' : 'ویرایش الگو',
      fields: [
        ('title', 'نام الگو'),
        ('description', 'توضیحات'),
        ('tasks', 'عنوان کارها؛ هر کار در یک خط'),
      ],
      initial: row?.map((key, value) => MapEntry(key, value.toString())) ?? {},
    );
    if (values == null) return;
    final tasks = values['tasks']!
        .split('\n')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tasks.length > 50) {
      if (context.mounted) _toolNotice(context, 'هر الگو حداکثر ۵۰ کار دارد.');
      return;
    }
    final changed = <String, dynamic>{
      'id': row?['id'] ?? const Uuid().v4(),
      ...values,
      'tasks': tasks.join('\n'),
    };
    await _saveToolRecords(ref, _key, [
      ...rows.where((r) => r['id'] != row?['id']),
      changed,
    ]);
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> row,
  ) async {
    final lines = (row['tasks'] as String? ?? '')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (!await _toolConfirm(
      context,
      '${faDigits(lines.length)} کار از این الگو به کارهای امروز اضافه شود؟',
    )) {
      return;
    }
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      for (final title in lines) {
        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                id: const Uuid().v4(),
                title: title.trim(),
                createdAt: DateTime.now(),
                dueAt: Value(DateTime.now()),
                description: Value('از الگوی ${row['title']}'),
              ),
            );
      }
    });
    if (context.mounted) {
      _toolNotice(context, '${faDigits(lines.length)} کار اضافه شد.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = _toolRecords(ref, _key, defaults: _defaults);
    return _ToolLoading(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToolHeading(
              _toolText(ref, 'الگوهای روزانه', 'Task templates'),
              _toolText(
                ref,
                'برنامه‌ات را یک بار بساز و هر روز به کارهایت اضافه کن.',
                'Create a reusable plan and add its tasks whenever you need it.',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _edit(context, ref, rows),
                icon: const Icon(Icons.add),
                label: Text(_toolText(ref, 'الگوی جدید', 'New template')),
              ),
            ),
            const SizedBox(height: 14),
            ...rows.map(
              (row) => _ToolPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.dashboard_customize_outlined,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${row['title']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: 'ویرایش',
                          onPressed: () => _edit(context, ref, rows, row),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: 'انتقال به سطل زباله',
                          onPressed: () =>
                              _trashToolRecord(ref, _key, row, rows),
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ),
                    Text(
                      '${row['description'] ?? ''}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...('${row['tasks'] ?? ''}')
                        .split('\n')
                        .map(
                          (line) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 15,
                                  color: AppColors.emerald,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _apply(context, ref, row),
                      icon: const Icon(Icons.playlist_add, size: 18),
                      label: const Text('افزودن کارها به امروز'),
                    ),
                  ],
                ),
              ),
            ),
            if (rows.isEmpty) const Text('با دکمهٔ بالا اولین الگو را بساز.'),
          ],
        ),
      ),
    );
  }
}

class LeaguePage extends ConsumerWidget {
  const LeaguePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(_allStudySessionsProvider);
    final tasks = ref
        .watch(tasksProvider)
        .maybeWhen(data: (rows) => rows, orElse: () => const <Task>[]);
    return PageFrame(
      child: sessions.when(
        loading: () => const CircularProgressIndicator(),
        error: (_, _) => const Text('خواندن آمار ممکن نشد.'),
        data: (rows) {
          final weekStart = DateTime.now().subtract(const Duration(days: 7));
          final recent = rows.where((s) => s.startedAt.isAfter(weekStart));
          final minutes = recent.fold<int>(
            0,
            (sum, s) => sum + s.durationMinutes,
          );
          final score =
              minutes * 2 +
              tasks
                      .where(
                        (t) =>
                            t.completed &&
                            t.completedAt != null &&
                            t.completedAt!.isAfter(weekStart),
                      )
                      .length *
                  20;
          final target =
              _toolRecords(
                    ref,
                    'tools.leagueGoal',
                    defaults: [
                      {'minutes': 600},
                    ],
                  ).firstOrNull?['minutes']
                  as int? ??
              600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ToolHeading(
                _toolText(ref, 'لیگ مطالعه', 'Study league'),
                _toolText(
                  ref,
                  'با عملکرد واقعی خودت رقابت کن؛ امتیاز ساختگی وجود ندارد.',
                  'Compete against your own actual study history.',
                ),
              ),
              Row(
                children: [
                  StatCard(
                    label: 'امتیاز این هفته',
                    value: faDigits(score),
                    icon: Icons.emoji_events,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 8),
                  StatCard(
                    label: 'دقیقه مطالعه',
                    value: faDigits(minutes),
                    icon: Icons.schedule,
                    color: AppColors.emerald,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _ToolPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هدف هفتگی: ${faDigits(target)} دقیقه',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (minutes / target).clamp(0, 1),
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final result = await _toolForm(
                          context,
                          title: 'هدف هفتگی',
                          fields: [('minutes', 'دقیقه مطالعه در هفته')],
                          initial: {'minutes': '$target'},
                        );
                        if (result == null) return;
                        final value = int.tryParse(
                          _toolAscii(result['minutes']!),
                        );
                        if (value == null || value < 1 || value > 10080) {
                          if (context.mounted) {
                            _toolNotice(
                              context,
                              'عددی بین ۱ تا ۱۰۰۸۰ وارد کن.',
                            );
                          }
                          return;
                        }
                        await _saveToolRecords(ref, 'tools.leagueGoal', [
                          {'minutes': value},
                        ]);
                      },
                      child: const Text('تغییر هدف'),
                    ),
                  ],
                ),
              ),
              const InfoTile(
                icon: Icons.cloud_off,
                title: 'رقابت شخصی روی این دستگاه',
                subtitle:
                    'رتبه‌بندی بین کاربران نیازمند اتصال به سرور و حساب کاربری است. این بخش رتبه یا کاربر خیالی نشان نمی‌دهد.',
                color: AppColors.blue,
              ),
              const SectionTitle('جلسه‌های هفت روز اخیر'),
              if (recent.isEmpty)
                const Text('تایمر را اجرا و یک جلسه ذخیره کن.')
              else
                ...recent
                    .take(20)
                    .map(
                      (s) => InfoTile(
                        icon: Icons.school_outlined,
                        title: s.subject,
                        subtitle:
                            '${faDigits(s.durationMinutes)} دقیقه · ${formatJalali(s.startedAt)}',
                        color: AppColors.emerald,
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

String _toolAscii(String value) {
  const persian = '۰۱۲۳۴۵۶۷۸۹', arabic = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(persian[i], '$i').replaceAll(arabic[i], '$i');
  }
  return value;
}

class StudyRoomsPage extends ConsumerWidget {
  const StudyRoomsPage({super.key});
  static const _key = 'tools.rooms';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = _toolRecords(ref, _key);
    return _ToolLoading(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToolHeading(
              _toolText(ref, 'اتاق‌های مطالعه', 'Study rooms'),
              _toolText(
                ref,
                'اتاق‌های شخصی برای نظم دادن به مطالعه؛ حضور چندنفره به سرور نیاز دارد.',
                'Personal study spaces. Live shared attendance requires a server connection.',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final result = await _toolForm(
                    context,
                    title: 'اتاق جدید',
                    fields: [
                      ('name', 'نام اتاق'),
                      ('description', 'موضوع و قوانین'),
                    ],
                  );
                  if (result == null) return;
                  await _saveToolRecords(ref, _key, [
                    ...rows,
                    {
                      'id': const Uuid().v4(),
                      ...result,
                      'createdAt': DateTime.now().toIso8601String(),
                    },
                  ]);
                },
                icon: const Icon(Icons.add),
                label: const Text('اتاق جدید'),
              ),
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              const InfoTile(
                icon: Icons.groups_outlined,
                title: 'اولین اتاقت را بساز',
                subtitle: 'اتاق‌ها پس از بستن برنامه هم نگه داشته می‌شوند.',
                color: AppColors.emerald,
              ),
            ...rows.map(
              (row) => _ToolPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${row['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف اتاق',
                          onPressed: () async {
                            if (await _toolConfirm(
                              context,
                              'این اتاق حذف شود؟',
                            )) {
                              await _saveToolRecords(
                                ref,
                                _key,
                                rows
                                    .where((r) => r['id'] != row['id'])
                                    .toList(),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ),
                    Text(
                      '${row['description']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: Text('${row['name']}')),
                            body: const StudyTimerPage(),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('ورود و شروع مطالعه'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalChatPage extends ConsumerStatefulWidget {
  const LocalChatPage({super.key});
  @override
  ConsumerState<LocalChatPage> createState() => _LocalChatPageState();
}

class _LocalChatPageState extends ConsumerState<LocalChatPage> {
  final _message = TextEditingController();
  String _group = 'گفت‌وگوی عمومی';
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send(List<Map<String, dynamic>> rows) async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    if (text.length > 2000) {
      _toolNotice(context, 'پیام باید کمتر از ۲۰۰۰ نویسه باشد.');
      return;
    }
    await _saveToolRecords(ref, 'tools.chat', [
      ...rows,
      {
        'id': const Uuid().v4(),
        'group': _group,
        'body': text,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ]);
    _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _toolRecords(ref, 'tools.chat');
    final custom = _toolRecords(ref, 'tools.chatGroups');
    final groups = {
      'گفت‌وگوی عمومی',
      'ریاضی',
      'تجربی',
      'انسانی',
      ...custom.map((g) => '${g['name']}'),
    }.toList();
    return _ToolLoading(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToolHeading(
              _toolText(ref, 'گفت‌وگو و گروه‌ها', 'Chat and groups'),
              _toolText(
                ref,
                'پیام‌های این بخش روی همین دستگاه ذخیره می‌شوند. ارسال به افراد دیگر نیازمند سرور است.',
                'Messages are saved on this device. Messaging other people requires a server connection.',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _group,
                    items: groups
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (g) {
                      if (g != null) setState(() => _group = g);
                    },
                    decoration: const InputDecoration(labelText: 'گروه'),
                  ),
                ),
                IconButton(
                  tooltip: 'گروه جدید',
                  onPressed: () async {
                    final result = await _toolForm(
                      context,
                      title: 'گروه جدید',
                      fields: [('name', 'نام گروه')],
                    );
                    if (result == null || groups.contains(result['name'])) {
                      return;
                    }
                    await _saveToolRecords(ref, 'tools.chatGroups', [
                      ...custom,
                      {'name': result['name']},
                    ]);
                    if (mounted) setState(() => _group = result['name']!);
                  },
                  icon: const Icon(
                    Icons.group_add_outlined,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...rows
                .where((r) => r['group'] == _group)
                .map(
                  (r) => _ToolPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['body']}',
                          style: const TextStyle(height: 1.8),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'شما · ${formatClock(DateTime.tryParse('${r['createdAt']}') ?? DateTime.now())}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'حذف پیام',
                              onPressed: () => _saveToolRecords(
                                ref,
                                'tools.chat',
                                rows.where((x) => x['id'] != r['id']).toList(),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            if (!rows.any((r) => r['group'] == _group))
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'اولین پیام این گروه را بنویس.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            TextField(
              controller: _message,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'پیام تو...',
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _send(rows),
                icon: const Icon(Icons.send, size: 17),
                label: const Text('ذخیره پیام'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _resourceCatalog = <Map<String, dynamic>>[
  {
    "id": "maz",
    "name": "مآز",
    "url": "https://www.maz.ir",
    "description":
        "پلتفرم آموزش ویدئویی با هزاران دوره آموزشی در زمینه‌های مختلف تحصیلی، کنکور و دانشگاهی. ویدئوهای باکیفیت از بهترین اساتید.",
    "category": "video",
  },
  {
    "id": "ala",
    "name": "آلاء",
    "url": "https://alaatv.com",
    "description":
        "پلتفرم آموزشی آلاء با ویدئوهای آموزشی رایگان و پولی برای مقاطع مختلف تحصیلی. یکی از قدیمی‌ترین سایت‌های آموزش ویدئویی.",
    "category": "video",
  },
  {
    "id": "mktb",
    "name": "مکتب‌خونه",
    "url": "https://www.maktabkhooneh.org",
    "description":
        "پلتفرم آموزش آنلاین با دوره‌های دانشگاهی و تخصصی. همکاری با دانشگاه‌های معتبر ایران و ارائه دوره‌های رایگان و پولی.",
    "category": "video",
  },
  {
    "id": "frd",
    "name": "فرادرس",
    "url": "https://faradars.org",
    "description":
        "بزرگترین پلتفرم آموزش ویدئویی ایران با هزاران دوره در زمینه‌های مختلف از برنامه‌نویسی و طراحی تا کنکور و زبان.",
    "category": "video",
  },
  {
    "id": "ostad",
    "name": "استادبانک",
    "url": "https://ostadbank.com",
    "description":
        "پلتفرم آموزشی ویدئویی با دوره‌های کنکور و دبیرستان. امکان مشاهده اولین جلسه هر دوره به صورت رایگان.",
    "category": "video",
  },
  {
    "id": "aparat",
    "name": "آپارات",
    "url": "https://www.aparat.com",
    "description":
        "بزرگترین سایت اشتراک ویدئو ایران با هزاران ویدئوی آموزشی در تمامی موضوعات. کانال‌های آموزشی اساتید معروف.",
    "category": "video",
  },
  {
    "id": "filimo",
    "name": "فیلیمو",
    "url": "https://www.filimo.com",
    "description":
        "پلتفرم استریم ویدئو ایران با بخش آموزشی گسترده. شامل دوره‌های آموزشی، مستند و فیلم‌های آموزشی.",
    "category": "video",
  },
  {
    "id": "fidibo",
    "name": "فیدیبو",
    "url": "https://www.fidibo.com",
    "description":
        "پلتفرم کتابخوان و آموزشی با صوت کتاب، کتاب الکترونیک و دوره‌های آموزشی در موضوعات مختلف.",
    "category": "video",
  },
  {
    "id": "kanoon",
    "name": "موسسه ثبت",
    "url": "https://www.kanoon.ir",
    "description":
        "سایت موسسه آموزشی ثبت با ویدئوهای آموزشی، آزمون‌های آزمایشی و منابع کنکور برای تمامی پایه‌ها.",
    "category": "video",
  },
  {
    "id": "sebtar",
    "name": "سیب ترش",
    "url": "https://www.sebtar.com",
    "description":
        "سامانه آموزش ویدئویی سیب ترش با دوره‌های تخصصی کنکور و دبیرستان. ویدئوهای تدریس اساتید برتر به صورت فصل به فصل.",
    "category": "video",
  },
  {
    "id": "darsnameh",
    "name": "درس‌نامه",
    "url": "https://www.darsnameh.com",
    "description":
        "پلتفرم آموزش آنلاین با ویدئوهای آموزشی درسی برای پایه‌های مختلف. مناسب دانش‌آموزان ابتدایی تا دبیرستان.",
    "category": "video",
  },
  {
    "id": "takbook",
    "name": "تک‌بوک",
    "url": "https://www.takbook.com",
    "description":
        "سایت آموزشی با ویدئوهای آموزشی، کتاب الکترونیک و منابع درسی برای کنکور و دبیرستان.",
    "category": "video",
  },
  {
    "id": "magerta",
    "name": "ماگرتا",
    "url": "https://magerta.ir",
    "description":
        "مرجع کامل پاسخنامه کتاب‌های درسی ایران. جواب تمامی کتاب‌های مدرسه از ابتدایی تا پیش‌دانشگاهی با توضیح کامل.",
    "category": "answer",
  },
  {
    "id": "gama",
    "name": "گاما",
    "url": "https://gama.ir",
    "description":
        "پلتفرم آموزشی با پاسخنامه کتاب‌های درسی، ویدئوهای آموزشی و آزمون آنلاین. مرجع کامل دانش‌آموزان ایرانی.",
    "category": "answer",
  },
  {
    "id": "padars",
    "name": "پادرس",
    "url": "https://padars.com",
    "description":
        "سامانه پاسخنامه کتاب‌های درسی با جواب‌نویسی مرحله به مرحله. مناسب دانش‌آموزان مقاطع متوسطه و ثانویه.",
    "category": "answer",
  },
  {
    "id": "gam_ir",
    "name": "گام‌آموز",
    "url": "https://www.gam.ir",
    "description":
        "سایت آموزشی با پاسخنامه و حل تمرین کتاب‌های درسی، ویدئوهای آموزشی و آزمون آنلاین.",
    "category": "answer",
  },
  {
    "id": "kelidestan",
    "name": "کلیدستان",
    "url": "https://www.kelidestan.com",
    "description":
        "سایت آموزشی با پاسخنامه کتاب‌های درسی، جزوات آموزشی و منابع کنکور برای تمامی پایه‌ها.",
    "category": "answer",
  },
  {
    "id": "khakdansh",
    "name": "خاک‌دانش",
    "url": "https://khakdansh.ir",
    "description":
        "سایت آموزشی با پاسخنامه و حل تمرین کتاب‌های درسی. مناسب برای تمرین و مرور دروس مختلف.",
    "category": "answer",
  },
  {
    "id": "didbook",
    "name": "دیدبوک",
    "url": "https://www.didbook.ir",
    "description":
        "پلتفرم آموزشی با پاسخنامه کتاب‌های درسی، ویدئوهای آموزشی و منابع کنکور برای دانش‌آموزان.",
    "category": "answer",
  },
  {
    "id": "daneshjooyar",
    "name": "دانشجویار",
    "url": "https://www.daneshjooyar.ir",
    "description":
        "سایت آموزشی با پاسخنامه کتاب‌های درسی دانشگاهی و دبیرستانی، جزوات و منابع آموزشی.",
    "category": "answer",
  },
  {
    "id": "talkisho",
    "name": "تالکیشو",
    "url": "https://www.talkisho.com",
    "description":
        "سایت آموزشی با پاسخنامه کتاب‌های درسی و منابع کنکور. مناسب برای دانش‌آموزان دبیرستانی.",
    "category": "answer",
  },
  {
    "id": "persianv",
    "name": "پرشین‌وی",
    "url": "https://www.persianv.com",
    "description":
        "پلتفرم آموزشی با پاسخنامه کتاب‌های درسی، ویدئوهای آموزشی و منابع کنکور.",
    "category": "answer",
  },
  {
    "id": "sanjesh",
    "name": "سازمان سنجش",
    "url": "https://www.sanjesh.org",
    "description":
        "سایت رسمی سازمان سنجش برای ثبت‌نام و نتایج آزمون‌های سراسری کنکور و سایر آزمون‌های ملی.",
    "category": "practice",
  },
  {
    "id": "mehrin",
    "name": "مهرین",
    "url": "https://mehrin.com",
    "description":
        "پلتفرم آزمون آنلاین با آزمون‌های آزمایشی کنکور، بررسی نقاط ضعف و نقاط قوی، و گزارش تحلیلی کامل.",
    "category": "practice",
  },
  {
    "id": "mirath",
    "name": "میراث",
    "url": "https://mirath.ir",
    "description":
        "سایت آزمون‌های آزمایشی آنلاین با تحلیل عملکرد و رتبه‌بندی. مناسب برای آمادگی کنکور.",
    "category": "practice",
  },
  {
    "id": "konkur1",
    "name": "کنکور",
    "url": "https://www.konkur.ir",
    "description":
        "سایت تخصصی کنکور با آزمون‌های آزمایشی، منابع آموزشی و مشاوره تحصیلی برای داوطلبان.",
    "category": "practice",
  },
  {
    "id": "kelaskonkur",
    "name": "کلاس کنکور",
    "url": "https://www.kelaskonkur.ir",
    "description":
        "پلتفرم آموزشی و آزمون آنلاین مخصوص کنکور با آزمون‌های آزمایشی و تحلیل رتبه.",
    "category": "practice",
  },
  {
    "id": "masterkonkur",
    "name": "مستر کنکور",
    "url": "https://www.masterkonkur.ir",
    "description":
        "سایت آزمون‌های آزمایشی کنکور با رتبه‌بندی، تحلیل عملکرد و منابع آموزشی.",
    "category": "practice",
  },
  {
    "id": "sana",
    "name": "سامانه سنا",
    "url": "https://www.sana.ir",
    "description":
        "سامانه آموزشی و آزمون آنلاین با آزمون‌های آزمایشی و منابع آموزشی برای کنکور.",
    "category": "practice",
  },
  {
    "id": "roshd",
    "name": "پایگاه آموزشی رشد",
    "url": "https://www.roshd.ir",
    "description":
        "پایگاه رسمی آموزش و پرورش با منابع آموزشی، ویدئوهای درسی و مطالب کمک‌آموزشی برای تمامی مقاطع.",
    "category": "other",
  },
  {
    "id": "medu",
    "name": "وزارت آموزش و پرورش",
    "url": "https://medu.ir",
    "description":
        "سایت رسمی وزارت آموزش و پرورش با اطلاعیه‌ها، منابع آموزشی و سامانه‌های مرتبط.",
    "category": "other",
  },
  {
    "id": "sharif",
    "name": "دانشگاه شریف",
    "url": "https://www.sharif.edu",
    "description":
        "سایت رسمی دانشگاه شریف با منابع آموزشی، اخبار و رویدادهای علمی. مناسب برای دانشجویان و داوطلبان کنکور.",
    "category": "other",
  },
  {
    "id": "schools_medu",
    "name": "سامانه مدارس",
    "url": "https://schools.medu.ir",
    "description":
        "سامانه مدارس وزارت آموزش و پرورش برای ثبت‌نام، نمرات و اطلاع‌رسانی‌های مدارس.",
    "category": "other",
  },
  {
    "id": "mehrnews",
    "name": "خبرگزاری مهر",
    "url": "https://www.mehrnews.com",
    "description":
        "خبرگزاری مهر با بخش آموزشی، اخبار کنکور، دانشگاه‌ها و تحلیل‌های آموزشی.",
    "category": "other",
  },
  {
    "id": "amuzesh",
    "name": "پایگاه آموزش",
    "url": "https://www.amuzesh.ir",
    "description":
        "پایگاه آموزشی با منابع آموزشی، ویدئوهای درسی و مطالب کمک‌آموزشی برای دانش‌آموزان.",
    "category": "other",
  },
  {
    "id": "dars_ir",
    "name": "درس",
    "url": "https://www.dars.ir",
    "description":
        "سایت آموزشی با ویدئوهای درسی، آزمون آنلاین و منابع آموزشی برای تمامی مقاطع.",
    "category": "other",
  },
  {
    "id": "encyclopedia",
    "name": "دانشنامه",
    "url": "https://www.encyclopedia.ir",
    "description":
        "دانشنامه آنلاین ایرانی با مقالات آموزشی در زمینه‌های مختلف علمی، ادبی و تاریخی.",
    "category": "other",
  },
  {
    "id": "khaandani",
    "name": "خواندنی‌ها",
    "url": "https://www.khaandani.ir",
    "description":
        "سایت مطالب خواندنی و آموزشی با مقالات متنوع در زمینه‌های علمی، تاریخی و فرهنگی.",
    "category": "other",
  },
  {
    "id": "irantracks",
    "name": "ایران‌تراکس",
    "url": "https://www.irantracks.com",
    "description":
        "سایت آموزشی و دانلود منابع درسی، جزوات و ویدئوهای آموزشی برای کنکور و دبیرستان.",
    "category": "other",
  },
  {
    "id": "talar",
    "name": "تالار",
    "url": "https://www.talar.id",
    "description":
        "پلتفرم آموزشی و اجتماعی با ویدئوهای آموزشی، وبینار و دوره‌های تخصصی.",
    "category": "other",
  },
  {
    "id": "ghadeedeasr",
    "name": "قضای عصر",
    "url": "https://www.ghadeedeasr.ir",
    "description":
        "سایت آموزشی و فرهنگی با مقالات، ویدئوهای آموزشی و منابع درسی.",
    "category": "other",
  },
  {
    "id": "ut",
    "name": "دانشگاه تهران",
    "url": "https://www.ut.ac.ir",
    "description":
        "قدیمی‌ترین و معتبرترین دانشگاه ایران. دانشگاه مادر کشور با رتبه اول در بسیاری از رشته‌ها.",
    "category": "other",
  },
  {
    "id": "sharif_uni",
    "name": "دانشگاه شریف",
    "url": "https://www.sharif.edu",
    "description":
        "برترین دانشگاه مهندسی ایران. معتبرترین مدرک مهندسی و علوم پایه.",
    "category": "other",
  },
  {
    "id": "aut",
    "name": "دانشگاه امیرکبیر",
    "url": "https://www.aut.ac.ir",
    "description":
        "دانشگاه تکنولوژی امیرکبیر - یکی از معتبرترین دانشگاه‌های مهندسی تهران.",
    "category": "other",
  },
  {
    "id": "sku",
    "name": "دانشگاه شهید بهشتی",
    "url": "https://www.sbu.ac.ir",
    "description":
        "دانشگاه شهید بهشتی - معتبر در رشته‌های علوم انسانی، حقوق و مدیریت.",
    "category": "other",
  },
  {
    "id": "ferdowsi",
    "name": "دانشگاه فردوسی مشهد",
    "url": "https://www.ferdowsi.um.ac.ir",
    "description":
        "یکی از بزرگترین و معتبرترین دانشگاه‌های ایران. برتر در منطقه شرق کشور.",
    "category": "other",
  },
  {
    "id": "tabrizu",
    "name": "دانشگاه تبریز",
    "url": "https://www.tabrizu.ac.ir",
    "description":
        "قدیمی‌ترین دانشگاه منطقه شمال غرب. معتبر در رشته‌های مختلف.",
    "category": "other",
  },
  {
    "id": "iust",
    "name": "دانشگاه علم و صنعت",
    "url": "https://www.iust.ac.ir",
    "description": "دانشگاه علم و صنعت ایران - تخصصی در مهندسی و فناوری.",
    "category": "other",
  },
  {
    "id": "khuisf",
    "name": "دانشگاه خوارزمی",
    "url": "https://www.khuisf.ac.ir",
    "description": "دانشگاه خوارزمی - معتبر در علوم تربیتی و روان‌شناسی.",
    "category": "other",
  },
  {
    "id": "umz",
    "name": "دانشگاه مازندران",
    "url": "https://www.umz.ac.ir",
    "description": "دانشگاه مازندران - بزرگترین دانشگاه شمال کشور.",
    "category": "other",
  },
  {
    "id": "guilan",
    "name": "دانشگاه گیلان",
    "url": "https://www.guilan.ac.ir",
    "description": "دانشگاه گیلان - معتبر در منطقه شمال.",
    "category": "other",
  },
  {
    "id": "um",
    "name": "دانشگاه اصفهان",
    "url": "https://www.ui.ac.ir",
    "description":
        "دانشگاه اصفهان - یکی از قدیمی‌ترین و معتبرترین دانشگاه‌های ایران.",
    "category": "other",
  },
  {
    "id": "znu",
    "name": "دانشگاه زنجان",
    "url": "https://www.znu.ac.ir",
    "description": "دانشگاه زنجان - در حال رشد و توسعه.",
    "category": "other",
  },
  {
    "id": "basu",
    "name": "دانشگاه بوعلی سینا",
    "url": "https://www.basu.ac.ir",
    "description": "دانشگاه بوعلی سینا همدان - معتبر در منطقه غرب.",
    "category": "other",
  },
  {
    "id": "put",
    "name": "دانشگاه صنعتی امیرکبیر",
    "url": "https://www.put.ac.ir",
    "description": "پلی‌تکنیک تهران - تخصصی در مهندسی و تکنولوژی.",
    "category": "other",
  },
  {
    "id": "iut",
    "name": "دانشگاه صنعتی اصفهان",
    "url": "https://www.iut.ac.ir",
    "description": "دانشگاه صنعتی اصفهان - معتبر در مهندسی و کشاورزی.",
    "category": "other",
  },
  {
    "id": "mui",
    "name": "دانشگاه علوم پزشکی اصفهان",
    "url": "https://www.mui.ac.ir",
    "description": "دانشگاه علوم پزشکی اصفهان - معتبر در پزشکی و علوم پزشکی.",
    "category": "other",
  },
  {
    "id": "kmu",
    "name": "دانشگاه علوم پزشکی کرمان",
    "url": "https://www.kmu.ac.ir",
    "description": "دانشگاه علوم پزشکی کرمان - معتبر در منطقه جنوب شرقی.",
    "category": "other",
  },
  {
    "id": "tums",
    "name": "دانشگاه علوم پزشکی تهران",
    "url": "https://www.tums.ac.ir",
    "description": "دانشگاه علوم پزشکی تهران - برترین دانشگاه پزشکی ایران.",
    "category": "other",
  },
  {
    "id": "sbmu",
    "name": "دانشگاه علوم پزشکی شهید بهشتی",
    "url": "https://www.sbmu.ac.ir",
    "description":
        "دانشگاه علوم پزشکی شهید بهشتی - یکی از معتبرترین دانشگاه‌های پزشکی.",
    "category": "other",
  },
  {
    "id": "msh",
    "name": "دانشگاه مشهد علوم پزشکی",
    "url": "https://www.mums.ac.ir",
    "description": "دانشگاه علوم پزشکی مشهد - معتبر در پزشکی و خدمات درمانی.",
    "category": "other",
  },
];

class ResourcesPage extends ConsumerStatefulWidget {
  const ResourcesPage({super.key});
  @override
  ConsumerState<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends ConsumerState<ResourcesPage> {
  String _query = '', _category = 'all';
  @override
  Widget build(BuildContext context) {
    final custom = _toolRecords(ref, 'tools.resources');
    final bookmarks = _toolRecords(ref, 'tools.resourceBookmarks');
    final rows = [..._resourceCatalog, ...custom]
        .where(
          (row) =>
              (_category == 'all' ||
                  (_category == 'saved'
                      ? bookmarks.any((b) => b['id'] == row['id'])
                      : row['category'] == _category)) &&
              '${row['name']} ${row['description']}'.contains(_query),
        )
        .toList();
    return _ToolLoading(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToolHeading(
              _toolText(ref, 'کتابخانهٔ منابع', 'Study resources'),
              _toolText(
                ref,
                'فهرست پیوندهای پروژهٔ اولیه؛ دسترسی هر سایت به اینترنت و شرایط همان سایت بستگی دارد.',
                'The original project’s link directory. Availability and terms depend on each website.',
              ),
            ),
            TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(
                hintText: 'جست‌وجوی منابع',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children:
                  const [
                        ('all', 'همه'),
                        ('video', 'ویدیو'),
                        ('answer', 'پاسخنامه'),
                        ('practice', 'آزمون'),
                        ('other', 'سایر'),
                        ('saved', 'نشان‌شده'),
                      ]
                      .map(
                        (category) => ChoiceChip(
                          label: Text(category.$2),
                          selected: _category == category.$1,
                          onSelected: (_) =>
                              setState(() => _category = category.$1),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final values = await _toolForm(
                  context,
                  title: 'منبع جدید',
                  fields: [
                    ('name', 'نام منبع'),
                    ('url', 'نشانی کامل سایت'),
                    ('description', 'توضیحات'),
                  ],
                );
                if (values == null) return;
                final uri = Uri.tryParse(values['url']!);
                if (uri == null ||
                    !{'https', 'http'}.contains(uri.scheme) ||
                    uri.host.isEmpty) {
                  if (context.mounted) {
                    _toolNotice(context, 'نشانی باید با https:// شروع شود.');
                  }
                  return;
                }
                await _saveToolRecords(ref, 'tools.resources', [
                  ...custom,
                  {'id': const Uuid().v4(), ...values, 'category': 'other'},
                ]);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('منبع جدید'),
            ),
            const SizedBox(height: 10),
            ...rows.map(
              (row) => _ToolPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${row['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: 'نشان‌کردن',
                          onPressed: () async {
                            final marked = bookmarks.any(
                              (b) => b['id'] == row['id'],
                            );
                            await _saveToolRecords(
                              ref,
                              'tools.resourceBookmarks',
                              marked
                                  ? bookmarks
                                        .where((b) => b['id'] != row['id'])
                                        .toList()
                                  : [
                                      ...bookmarks,
                                      {'id': row['id']},
                                    ],
                            );
                          },
                          icon: Icon(
                            bookmarks.any((b) => b['id'] == row['id'])
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            size: 20,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${row['description'] ?? ''}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () =>
                                _toolOpenUrl(context, '${row['url']}'),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('باز کردن سایت'),
                          ),
                        ),
                        IconButton(
                          tooltip: 'کپی پیوند',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: '${row['url']}'),
                            );
                            _toolNotice(context, 'پیوند کپی شد.');
                          },
                          icon: const Icon(Icons.copy, size: 17),
                        ),
                        if (custom.any((c) => c['id'] == row['id']))
                          IconButton(
                            tooltip: 'حذف منبع',
                            onPressed: () => _saveToolRecords(
                              ref,
                              'tools.resources',
                              custom
                                  .where((c) => c['id'] != row['id'])
                                  .toList(),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (rows.isEmpty) const Text('منبعی با این جست‌وجو پیدا نشد.'),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> _toolJalaliDate(
  BuildContext context, {
  DateTime? initial,
}) async {
  var selected = Jalali.fromDateTime(initial ?? DateTime.now());
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: const Text('انتخاب تاریخ شمسی'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selected.year,
                decoration: const InputDecoration(labelText: 'سال'),
                items: List.generate(16, (i) => Jalali.now().year - 10 + i)
                    .map(
                      (year) => DropdownMenuItem(
                        value: year,
                        child: Text(faDigits(year)),
                      ),
                    )
                    .toList(),
                onChanged: (year) {
                  if (year == null) return;
                  setDialog(() {
                    final first = Jalali(year, selected.month, 1);
                    selected = first.copy(
                      day: selected.day.clamp(1, first.monthLength),
                    );
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: selected.month,
                decoration: const InputDecoration(labelText: 'ماه'),
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(jalaliMonths[i]),
                  ),
                ),
                onChanged: (month) {
                  if (month == null) return;
                  setDialog(() {
                    final first = Jalali(selected.year, month, 1);
                    selected = first.copy(
                      day: selected.day.clamp(1, first.monthLength),
                    );
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                key: ValueKey('${selected.year}-${selected.month}'),
                initialValue: selected.day,
                decoration: const InputDecoration(labelText: 'روز'),
                items: List.generate(
                  selected.monthLength,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(faDigits(i + 1)),
                  ),
                ),
                onChanged: (day) {
                  if (day != null) {
                    setDialog(() => selected = selected.copy(day: day));
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selected.toDateTime()),
            child: const Text('انتخاب'),
          ),
        ],
      ),
    ),
  );
}

class CycleTrackerPage extends ConsumerWidget {
  const CycleTrackerPage({super.key});
  static const _key = 'tools.cycles';
  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> rows,
  ) async {
    final date = await _toolJalaliDate(context);
    if (date == null || !context.mounted) return;
    final today = DateTime.now();
    if (date.isAfter(DateTime(today.year, today.month, today.day))) {
      _toolNotice(context, 'تاریخ شروع نمی‌تواند در آینده باشد.');
      return;
    }
    final values = await _toolForm(
      context,
      title: 'ثبت شروع چرخه',
      fields: [
        ('cycleLength', 'طول چرخه به روز'),
        ('periodLength', 'مدت خون‌ریزی به روز'),
        ('symptoms', 'علائم'),
        ('notes', 'یادداشت'),
      ],
      initial: {'cycleLength': '28', 'periodLength': '5'},
      optional: {'symptoms', 'notes'},
      multiline: {'notes'},
    );
    if (values == null) return;
    final cycle = int.tryParse(_toolAscii(values['cycleLength']!)),
        period = int.tryParse(_toolAscii(values['periodLength']!));
    if (cycle == null ||
        period == null ||
        cycle < 15 ||
        cycle > 60 ||
        period < 1 ||
        period > 14 ||
        period >= cycle) {
      if (context.mounted) {
        _toolNotice(
          context,
          'طول چرخه ۱۵ تا ۶۰ و مدت خون‌ریزی ۱ تا ۱۴ روز باشد.',
        );
      }
      return;
    }
    if (rows.any((r) => DateTime.tryParse('${r['start']}') == date)) {
      if (context.mounted) {
        _toolNotice(context, 'برای این روز قبلاً چرخه ثبت شده.');
      }
      return;
    }
    await _saveToolRecords(ref, _key, [
      ...rows,
      {
        'id': const Uuid().v4(),
        'start': date.toIso8601String(),
        'cycleLength': cycle,
        'periodLength': period,
        'symptoms': values['symptoms'],
        'notes': values['notes'],
      },
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = _toolRecords(ref, _key)
      ..sort((a, b) => '${b['start']}'.compareTo('${a['start']}'));
    final latest = rows.firstOrNull;
    final start = latest == null
        ? null
        : DateTime.tryParse('${latest['start']}');
    final next = start?.add(
      Duration(days: (latest?['cycleLength'] as num?)?.toInt() ?? 28),
    );
    return _ToolLoading(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToolHeading(
              _toolText(ref, 'چرخه و خودمراقبتی', 'Cycle tracker'),
              _toolText(
                ref,
                'این اطلاعات خصوصی فقط روی دستگاه ذخیره می‌شود. پیش‌بینی تقریبی است و کاربرد تشخیصی یا پیشگیری ندارد.',
                'Private records stay on your device. Estimates are not medical advice or contraception.',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _add(context, ref, rows),
                icon: const Icon(Icons.add),
                label: const Text('ثبت چرخه جدید'),
              ),
            ),
            const SizedBox(height: 15),
            if (next != null)
              _ToolPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      color: AppColors.red,
                      size: 30,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'شروع بعدی تخمینی: ${formatJalali(next)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      next.isBefore(DateTime.now())
                          ? 'تاریخ پیش‌بینی گذشته؛ با شروع دورهٔ جدید آن را ثبت کن.'
                          : 'حدود ${faDigits(next.difference(DateTime.now()).inDays + 1)} روز دیگر',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (rows.isEmpty)
              const InfoTile(
                icon: Icons.calendar_today_outlined,
                title: 'هنوز چرخه‌ای ثبت نشده',
                subtitle: 'تاریخ شروع و طول چرخه را برای دیدن تخمین وارد کن.',
                color: AppColors.red,
              ),
            ...rows.map(
              (r) => _ToolPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatJalali(DateTime.parse('${r['start']}')),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف رکورد',
                          onPressed: () async {
                            if (await _toolConfirm(
                              context,
                              'این رکورد خصوصی برای همیشه حذف شود؟',
                            )) {
                              await _saveToolRecords(
                                ref,
                                _key,
                                rows.where((v) => v['id'] != r['id']).toList(),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ),
                    Text(
                      'طول چرخه ${faDigits(r['cycleLength']!)} روز · مدت ${faDigits(r['periodLength']!)} روز',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    if ('${r['symptoms'] ?? ''}'.isNotEmpty)
                      Text(
                        'علائم: ${r['symptoms']}',
                        style: const TextStyle(fontSize: 12, height: 1.8),
                      ),
                    if ('${r['notes'] ?? ''}'.isNotEmpty)
                      Text(
                        '${r['notes']}',
                        style: const TextStyle(fontSize: 12, height: 1.8),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceRemindersPage extends ConsumerStatefulWidget {
  const PlaceRemindersPage({super.key});
  @override
  ConsumerState<PlaceRemindersPage> createState() => _PlaceRemindersPageState();
}

class _PlaceRemindersPageState extends ConsumerState<PlaceRemindersPage> {
  Timer? _locationTimer;
  bool _checking = false;
  String? _status;
  final Set<String> _inside = {};
  @override
  void initState() {
    super.initState();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _check(auto: true),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<Position?> _position({bool request = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('مکان‌یابی دستگاه خاموش است.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'مجوز مکان لازم است؛ دسترسی را از تنظیمات دستگاه فعال کن.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<void> _check({bool auto = false}) async {
    if (_checking) return;
    final rows = _toolRecords(ref, 'tools.places', listen: false);
    if (auto && rows.every((r) => r['enabled'] != true)) return;
    setState(() => _checking = true);
    try {
      final position = await _position(request: !auto);
      if (position == null || !mounted) return;
      var nearby = 0;
      for (final row in rows.where((r) => r['enabled'] == true)) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          (row['latitude'] as num).toDouble(),
          (row['longitude'] as num).toDouble(),
        );
        if (distance <= (row['radius'] as num).toDouble()) {
          nearby++;
          if (_inside.add('${row['id']}')) {
            await SystemSound.play(SystemSoundType.alert);
            if (mounted) {
              _toolNotice(
                context,
                'رسیدی: ${row['title']} — ${row['description']}',
              );
            }
          }
        } else {
          _inside.remove('${row['id']}');
        }
      }
      if (mounted) {
        setState(
          () => _status =
              'مکان بررسی شد · ${faDigits(nearby)} یادآور در نزدیکی تو',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _status = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _add(List<Map<String, dynamic>> rows) async {
    final values = await _toolForm(
      context,
      title: 'یادآور مکان جدید',
      fields: [
        ('title', 'نام مکان'),
        ('description', 'وقتی رسیدم یادآوری کن'),
        ('radius', 'شعاع یادآوری به متر'),
      ],
      initial: {'radius': '150'},
      optional: {},
    );
    if (values == null) return;
    final radius = int.tryParse(_toolAscii(values['radius']!));
    if (radius == null || radius < 50 || radius > 10000) {
      if (mounted) _toolNotice(context, 'شعاع باید بین ۵۰ تا ۱۰۰۰۰ متر باشد.');
      return;
    }
    try {
      final position = await _position();
      if (position == null || !mounted) return;
      await _saveToolRecords(ref, 'tools.places', [
        ...rows,
        {
          'id': const Uuid().v4(),
          ...values,
          'radius': radius,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'enabled': true,
        },
      ]);
      if (mounted) _toolNotice(context, 'این مکان با موقعیت فعلی ذخیره شد.');
    } catch (error) {
      if (mounted) {
        _toolNotice(context, error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _toolRecords(ref, 'tools.places');
    return _ToolLoading(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToolHeading(
              _toolText(ref, 'یادآور مکان', 'Place reminders'),
              _toolText(
                ref,
                'مکان فعلی را ذخیره کن. بررسی خودکار هر ۳۰ ثانیه تا زمانی که این صفحه باز است انجام می‌شود؛ اجرای پس‌زمینه فعال نیست.',
                'Save your current location. Reminders are checked every 30 seconds while this page stays open; background monitoring is not enabled.',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _checking ? null : () => _add(rows),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('افزودن مکان فعلی'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _checking ? null : () => _check(),
              icon: const Icon(Icons.my_location, size: 17),
              label: Text(_checking ? 'در حال بررسی...' : 'بررسی مکان من'),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _status!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            ...rows.map(
              (row) => _ToolPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${row['title']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Switch(
                          value: row['enabled'] == true,
                          onChanged: (v) => _saveToolRecords(
                            ref,
                            'tools.places',
                            rows
                                .map(
                                  (r) => r['id'] == row['id']
                                      ? {...r, 'enabled': v}
                                      : r,
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${row['description']} · شعاع ${faDigits(row['radius']!)} متر',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _toolOpenUrl(
                              context,
                              'https://www.openstreetmap.org/?mlat=${row['latitude']}&mlon=${row['longitude']}#map=17/${row['latitude']}/${row['longitude']}',
                            ),
                            icon: const Icon(Icons.map_outlined, size: 17),
                            label: const Text('نمایش نقشه'),
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف یادآور',
                          onPressed: () => _saveToolRecords(
                            ref,
                            'tools.places',
                            rows.where((r) => r['id'] != row['id']).toList(),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (rows.isEmpty)
              const InfoTile(
                icon: Icons.location_on_outlined,
                title: 'مکانی ذخیره نشده',
                subtitle: 'در محل مورد نظر، افزودن مکان فعلی را بزن.',
                color: AppColors.emerald,
              ),
          ],
        ),
      ),
    );
  }
}

class _HabitsPanel extends ConsumerWidget {
  const _HabitsPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = _toolRecords(ref, 'tools.habits');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _ToolLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            key: const Key('add-habit'),
            onPressed: () async {
              final values = await _toolForm(
                context,
                title: 'عادت جدید',
                fields: [('title', 'نام عادت')],
              );
              if (values == null) return;
              await _saveToolRecords(ref, 'tools.habits', [
                ...rows,
                {
                  'id': const Uuid().v4(),
                  'title': values['title'],
                  'days': <String>[],
                },
              ]);
            },
            icon: const Icon(Icons.add, size: 17),
            label: const Text('عادت جدید'),
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'یک عادت کوچک بساز و هر روز انجامش بده.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ...rows.map((row) {
            final days = (row['days'] as List? ?? [])
                .map((d) => d.toString())
                .toSet();
            return _ToolPanel(
              child: Row(
                children: [
                  Checkbox(
                    value: days.contains(today),
                    onChanged: (completed) async {
                      if (completed == true) {
                        days.add(today);
                      } else {
                        days.remove(today);
                      }
                      await _saveToolRecords(
                        ref,
                        'tools.habits',
                        rows
                            .map(
                              (r) => r['id'] == row['id']
                                  ? {...r, 'days': days.toList()}
                                  : r,
                            )
                            .toList(),
                      );
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row['title']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${faDigits(days.length)} روز انجام‌شده',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'انتقال عادت به سطل زباله',
                    onPressed: () =>
                        _trashToolRecord(ref, 'tools.habits', row, rows),
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ToolTrashPanel extends ConsumerWidget {
  const _ToolTrashPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = _toolRecords(ref, 'tools.trash');
    return Column(
      children: rows
          .map(
            (row) => _ToolPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row['title']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    row['source'] == 'tools.habits'
                        ? 'عادت حذف‌شده'
                        : 'الگوی حذف‌شده',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final source = '${row['source']}';
                          if (!{
                            'tools.habits',
                            'tools.templates',
                          }.contains(source)) {
                            return;
                          }
                          final current = _toolRecords(
                            ref,
                            source,
                            listen: false,
                          );
                          final restored = Map<String, dynamic>.from(
                            row['data'] as Map,
                          );
                          final db = ref.read(databaseProvider);
                          await db.transaction(() async {
                            await db.savePreference(
                              source,
                              jsonEncode([
                                ...current.where(
                                  (r) => r['id'] != restored['id'],
                                ),
                                restored,
                              ]),
                            );
                            await db.savePreference(
                              'tools.trash',
                              jsonEncode(
                                rows
                                    .where((r) => r['id'] != row['id'])
                                    .toList(),
                              ),
                            );
                          });
                          if (context.mounted) {
                            _toolNotice(context, 'بازیابی شد.');
                          }
                        },
                        icon: const Icon(Icons.restore, size: 17),
                        label: const Text('بازیابی'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'حذف دائمی',
                        onPressed: () async {
                          if (await _toolConfirm(
                            context,
                            'برای همیشه حذف شود؟',
                          )) {
                            await _saveToolRecords(
                              ref,
                              'tools.trash',
                              rows.where((r) => r['id'] != row['id']).toList(),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.delete_forever,
                          color: AppColors.red,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
