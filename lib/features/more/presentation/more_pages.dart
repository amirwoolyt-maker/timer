part of '../../feature_pages.dart';

class MoreGrid extends ConsumerWidget {
  const MoreGrid({required this.onSelect, super.key});
  final ValueChanged<String> onSelect;
  static const items = [
    ('dashboard', 'داشبورد آمار', 'آمار و پیشرفت', Icons.bar_chart_rounded),
    ('calendar', 'تقویم', 'تقویم جلالی', Icons.calendar_month_rounded),
    ('studyTimer', 'تایمر درس', 'مطالعه رقابتی', Icons.school_rounded),
    ('league', 'لیگ رقابت', 'رتبه‌بندی کاربران', Icons.emoji_events_rounded),
    ('projects', 'پروژه‌ها', 'مدیریت پروژه', Icons.folder_copy_rounded),
    ('studyRoom', 'اتاق مطالعه', 'مطالعه گروهی', Icons.groups_rounded),
    ('templates', 'الگوها', 'قالب کار', Icons.dashboard_customize_rounded),
    ('trash', 'سطل زباله', 'بازیابی آیتم‌ها', Icons.delete_sweep_rounded),
    ('resources', 'منابع درسی', 'سایت‌های آموزشی', Icons.menu_book_rounded),
    (
      'uniRanking',
      'رتبه‌بندی دانشگاه‌ها',
      'بهترین دانشگاه‌ها',
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
      'University rankings',
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
      'Competitive study',
      'Community ranking',
      'Project planning',
      'Group study',
      'Task templates',
      'Restore deleted items',
      'Learning websites',
      'Top universities',
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
          const Text(
            'همه ابزارها، یک‌جا',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'هر چیزی که برای ساختن یک روز بهتر لازم داری.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: 1.23,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () => onSelect(item.$1),
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
                      Text(
                        english ? englishNames[index] : item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if ((english ? englishDescriptions[index] : item.$3)
                          .isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          english ? englishDescriptions[index] : item.$3,
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
  Widget build(BuildContext context, WidgetRef ref) => switch (feature) {
    'dashboard' => const DashboardPage(),
    'calendar' => const JalaliCalendarPage(),
    'projects' => const ProjectsPage(),
    'trash' => const TrashPage(),
    'smartAlarm' => const AlarmsPage(),
    'focus' => const FocusModePage(),
    'profile' => const ProfilePage(),
    'studyTimer' => const StudyTimerPage(),
    'league' => const SimpleFeaturePage(
      title: 'لیگ رقابت',
      subtitle: 'پیشرفتت را با جامعه‌ای از داوطلب‌ها بسنج.',
      items: [
        'رتبه اول · ۱٬۸۶۰ امتیاز',
        'رتبه دوم · ۱٬۶۱۰ امتیاز',
        'شما · ۱٬۲۸۰ امتیاز',
      ],
      icon: Icons.emoji_events_rounded,
    ),
    'studyRoom' => const SimpleFeaturePage(
      title: 'اتاق مطالعه',
      subtitle: 'در سکوت کنار آدم‌هایی درس بخوان.',
      items: ['کتابخانه مرکزی · ۱۲ نفر', 'شب‌زنده‌داران · ۷ نفر'],
      icon: Icons.groups_rounded,
    ),
    'templates' => const SimpleFeaturePage(
      title: 'الگوها',
      subtitle: 'برنامه‌های آماده را برای روزت انتخاب کن.',
      items: ['برنامه روز مدرسه · ۸ کار', 'مرور شب امتحان · ۵ کار'],
      icon: Icons.dashboard_customize_rounded,
    ),
    'resources' => const SimpleFeaturePage(
      title: 'منابع درسی',
      subtitle: 'منابع آموزشی را یک‌جا نگه دار.',
      items: ['ویدیوهای جمع‌بندی', 'آزمون‌های شبیه‌ساز', 'پاسخ تشریحی کتاب‌ها'],
      icon: Icons.menu_book_rounded,
    ),
    'uniRanking' => const SimpleFeaturePage(
      title: 'رتبه‌بندی دانشگاه‌ها',
      subtitle: 'برای آینده‌ای که می‌سازی، تصویر روشن‌تری داشته باش.',
      items: ['دانشگاه تهران', 'دانشگاه صنعتی شریف', 'دانشگاه شهید بهشتی'],
      icon: Icons.account_balance_rounded,
    ),
    'chat' => const SimpleFeaturePage(
      title: 'چت با کنکوری‌ها',
      subtitle: 'سؤال بپرس و تجربه بده.',
      items: ['گفت‌وگوی ریاضی · ۱٬۲۰۰ عضو', 'تجربی‌های پرتلاش · ۸۴۰ عضو'],
      icon: Icons.forum_rounded,
    ),
    'location' => const SimpleFeaturePage(
      title: 'یادآور مکان',
      subtitle: 'وقتی به مکانی رسیدی، کار مناسب را به یاد بیاور.',
      items: ['برای استفاده از مکان‌یاب، دسترسی مکان دستگاه را فعال کن.'],
      icon: Icons.location_on_rounded,
    ),
    'period' => const SimpleFeaturePage(
      title: 'چرخه پریود',
      subtitle: 'با آگاهی از بدنت، برنامه‌ات را مهربان‌تر بچین.',
      items: ['چرخه بعدی · ۱۲ روز دیگر', 'آب کافی بنوش و استراحت کن.'],
      icon: Icons.spa_rounded,
    ),
    _ => const SizedBox.shrink(),
  };
}

class SimpleFeaturePage extends StatelessWidget {
  const SimpleFeaturePage({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.icon,
    super.key,
  });
  final String title, subtitle;
  final List<String> items;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => InfoTile(
            icon: icon,
            title: item,
            subtitle: 'این بخش در پایگاه داده محلی آماده استفاده است.',
            color: AppColors.emerald,
          ),
        ),
      ],
    ),
  );
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageFrame(
    child: ref
        .watch(tasksProvider)
        .when(
          data: (tasks) {
            final done = tasks.where((task) => task.completed).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'رشدت را ببین',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                const Text(
                  'آمار از کارهای ذخیره‌شده‌ات محاسبه شده است.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    StatCard(
                      label: 'امتیاز تجربه',
                      value: faDigits(120 + done * 20),
                      icon: Icons.bolt_rounded,
                      color: AppColors.amber,
                    ),
                    const SizedBox(width: 8),
                    const StatCard(
                      label: 'سطح کنکوری',
                      value: '۳',
                      icon: Icons.military_tech_rounded,
                      color: AppColors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatCard(
                      label: 'کار تکمیل‌شده',
                      value: faDigits(done),
                      icon: Icons.check_circle_outline,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 8),
                    const StatCard(
                      label: 'پیوستگی',
                      value: '۷ روز',
                      icon: Icons.local_fire_department_outlined,
                      color: AppColors.red,
                    ),
                  ],
                ),
                const SectionTitle('پیشرفت هفتگی'),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']
                        .asMap()
                        .entries
                        .map(
                          (entry) => Column(
                            children: [
                              Container(
                                width: 25,
                                height: 20 + (entry.key * 13 % 45),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(
                                    alpha: .2 + entry.key % 4 * .12,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            );
          },
          error: (error, _) => Text('$error'),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.emerald),
          ),
        ),
  );
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
              color: AppColors.surface,
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
                                : AppColors.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SectionTitle('برنامه انتخاب‌شده'),
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
                        onRestore: () =>
                            ref.read(databaseProvider).restoreTask(item.id),
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
                        onRestore: () =>
                            ref.read(databaseProvider).restoreNote(item.id),
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
      color: AppColors.surface,
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
  Timer? alarmTimer;
  final Set<String> prompting = {};
  @override
  void initState() {
    super.initState();
    alarmTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _checkAlarms(),
    );
  }

  @override
  void dispose() {
    alarmTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAlarms() async {
    final now = TimeOfDay.now();
    final alarms = ref
        .read(alarmsProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Alarm>[]);
    for (final alarm in alarms) {
      if (alarm.enabled &&
          alarm.hour == now.hour &&
          alarm.minute == now.minute &&
          prompting.add(alarm.id)) {
        _ring(alarm);
      }
    }
  }

  Future<void> _ring(Alarm alarm) async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    if (!mounted) return;
    final solved = await _showChallenge(alarm);
    prompting.remove(alarm.id);
    if (!solved && mounted) {
      Timer(const Duration(seconds: 30), () {
        final current = ref
            .read(alarmsProvider)
            .maybeWhen(data: (items) => items, orElse: () => const <Alarm>[]);
        final stillEnabled = current.any(
          (item) => item.id == alarm.id && item.enabled,
        );
        if (mounted && stillEnabled) {
          prompting.add(alarm.id);
          _ring(alarm);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'بیدار شو!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'آلارم همراه با چالش ریاضی.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _add(context),
            icon: const Icon(Icons.add),
            label: const Text('آلارم جدید'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: const Color(0xFF041B12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ref
            .watch(alarmsProvider)
            .when(
              data: (items) => Column(
                children: items
                    .map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsetsDirectional.only(
                          start: 13,
                          end: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _showChallenge(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.alarm_rounded,
                                        color: AppColors.amber,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${faDigits(item.hour.toString().padLeft(2, '0'))}:${faDigits(item.minute.toString().padLeft(2, '0'))} · ${item.label}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'چالش آسان · ${faDigits(item.wrongAttempts)} خطای قبلی · لمس برای حل',
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: item.enabled,
                              onChanged: (enabled) =>
                                  (ref
                                          .read(databaseProvider)
                                          .update(
                                            ref.read(databaseProvider).alarms,
                                          )
                                        ..where(
                                          (row) => row.id.equals(item.id),
                                        ))
                                      .write(
                                        AlarmsCompanion(
                                          enabled: Value(enabled),
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              error: (error, _) => Text('$error'),
              loading: () =>
                  const CircularProgressIndicator(color: AppColors.emerald),
            ),
        const SizedBox(height: 10),
        const InfoTile(
          icon: Icons.calculate_outlined,
          title: 'سطح آسان',
          subtitle: 'ضرب و تقسیم ساده همراه با راهنما',
          color: AppColors.emerald,
        ),
      ],
    ),
  );
  Future<void> _add(BuildContext context) async {
    if (ref
        .read(alarmsProvider)
        .maybeWhen(data: (items) => items.length >= 5, orElse: () => false)) {
      return;
    }
    final label = TextEditingController(text: 'آلارم صبحگاهی');
    var selected = const TimeOfDay(hour: 7, minute: 0);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('آلارم جدید'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                decoration: const InputDecoration(labelText: 'عنوان'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selected,
                  );
                  if (picked != null) setDialogState(() => selected = picked);
                },
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  '${faDigits(selected.hour.toString().padLeft(2, '0'))}:${faDigits(selected.minute.toString().padLeft(2, '0'))}',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'برای خاموش شدن، چالش ریاضی را حل کن.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('بی‌خیال'),
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
      final db = ref.read(databaseProvider);
      await db
          .into(db.alarms)
          .insert(
            AlarmsCompanion.insert(
              id: const Uuid().v4(),
              label: label.text.trim(),
              hour: selected.hour,
              minute: selected.minute,
            ),
          );
    }
  }

  Future<bool> _showChallenge(Alarm alarm) async {
    final a = 3 + (alarm.id.codeUnitAt(0) % 7),
        b = 2 + (alarm.id.codeUnitAt(alarm.id.length - 1) % 6),
        answer = a * b;
    final input = TextEditingController();
    final solved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('چالش بیداری'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('برای خاموش کردن آلارم پاسخ بده:'),
            const SizedBox(height: 9),
            Text(
              '$a × $b = ؟',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: input,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'پاسخ'),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              int.tryParse(input.text.trim()) == answer,
            ),
            child: const Text('بررسی'),
          ),
        ],
      ),
    );
    final db = ref.read(databaseProvider);
    if (solved == true) {
      await (db.update(
        db.alarms,
      )..where((row) => row.id.equals(alarm.id))).write(
        const AlarmsCompanion(enabled: Value(false), wrongAttempts: Value(0)),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('آفرین! آلارم خاموش شد.')));
      }
      return true;
    } else {
      final failedAttempts = alarm.wrongAttempts + 1;
      await (db.update(
        db.alarms,
      )..where((row) => row.id.equals(alarm.id))).write(
        AlarmsCompanion(
          wrongAttempts: Value(failedAttempts),
          enabled: Value(failedAttempts < 6),
        ),
      );
      if (failedAttempts >= 6 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('آلارم پس از شش پاسخ نادرست قفل شد.')),
        );
      }
      return false;
    }
  }
}
