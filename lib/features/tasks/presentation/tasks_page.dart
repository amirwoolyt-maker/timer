part of '../../feature_pages.dart';

String normalizeTaskSearch(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ي', 'ی')
    .replaceAll('ك', 'ک')
    .replaceAll('‌', ' ');

DateTime nextTaskOccurrence(DateTime date, String repeat) {
  if (repeat == 'daily') {
    return DateTime(
      date.year,
      date.month,
      date.day + 1,
      date.hour,
      date.minute,
    );
  }
  if (repeat == 'weekly') {
    return DateTime(
      date.year,
      date.month,
      date.day + 7,
      date.hour,
      date.minute,
    );
  }
  final lastDay = DateTime(date.year, date.month + 2, 0).day;
  return DateTime(
    date.year,
    date.month + 1,
    date.day.clamp(1, lastDay),
    date.hour,
    date.minute,
  );
}

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});
  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  String filter = 'all', query = '';
  String? category;
  bool _saving = false;
  String _tr(String fa, String en) => ref.read(languageProvider) ? en : fa;
  String _digits(Object value) =>
      ref.read(languageProvider) ? '$value' : faDigits(value);
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      PageFrame(
        child: ref
            .watch(tasksProvider)
            .when(
              data: (tasks) {
                final now = DateTime.now(), today = DateTime.now();
                final midnight = DateTime(today.year, today.month, today.day);
                final completed = tasks.where((t) => t.completed).length;
                final dates = tasks
                    .where((t) => t.completedAt != null)
                    .map(
                      (t) => DateTime(
                        t.completedAt!.year,
                        t.completedAt!.month,
                        t.completedAt!.day,
                      ),
                    )
                    .toSet();
                var day = dates.contains(midnight)
                    ? midnight
                    : midnight.subtract(const Duration(days: 1));
                var streak = 0;
                while (dates.contains(day)) {
                  streak++;
                  day = day.subtract(const Duration(days: 1));
                }
                final categories = tasks.map((t) => t.category).toSet().toList()
                  ..sort();
                final search = normalizeTaskSearch(query);
                final filtered = tasks.where((task) {
                  final due = task.dueAt;
                  final isToday =
                      due != null &&
                      due.year == now.year &&
                      due.month == now.month &&
                      due.day == now.day;
                  final matches = switch (filter) {
                    'today' => isToday,
                    'upcoming' =>
                      !task.completed &&
                          (due == null || !due.isBefore(midnight)),
                    'overdue' =>
                      !task.completed && due != null && due.isBefore(now),
                    'done' => task.completed,
                    _ => true,
                  };
                  return matches &&
                      (category == null || task.category == category) &&
                      (search.isEmpty ||
                          normalizeTaskSearch(
                            '${task.title} ${task.description} ${task.category}',
                          ).contains(search));
                }).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Greeting(
                      total: tasks.where((t) => !t.completed).length,
                      completed: completed,
                      all: tasks.length,
                      english: ref.watch(languageProvider),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StatCard(
                          label: _tr('در پیش', 'Remaining'),
                          value: _digits(tasks.length - completed),
                          icon: Icons.bolt_rounded,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(width: 8),
                        StatCard(
                          label: _tr('انجام‌شده', 'Completed'),
                          value: _digits(completed),
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.blue,
                        ),
                        const SizedBox(width: 8),
                        StatCard(
                          label: _tr('پیوستگی', 'Day streak'),
                          value: _digits(streak),
                          icon: Icons.local_fire_department_outlined,
                          color: AppColors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('task-search'),
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: _tr(
                          'جستجوی عنوان، توضیح یا دسته…',
                          'Search tasks…',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final entry in <String, String>{
                            'all': _tr('همه', 'All'),
                            'today': _tr('امروز', 'Today'),
                            'upcoming': _tr('در پیش', 'Upcoming'),
                            'overdue': _tr('عقب‌افتاده', 'Overdue'),
                            'done': _tr('انجام‌شده', 'Completed'),
                          }.entries)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 6),
                              child: ChoiceChip(
                                label: Text(entry.value),
                                selected: filter == entry.key,
                                onSelected: (_) =>
                                    setState(() => filter = entry.key),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (categories.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(category),
                          initialValue: categories.contains(category)
                              ? category
                              : null,
                          decoration: InputDecoration(
                            labelText: _tr('دسته‌بندی', 'Category'),
                            suffixIcon: category == null
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close, size: 17),
                                    onPressed: () =>
                                        setState(() => category = null),
                                  ),
                          ),
                          hint: Text(_tr('همهٔ دسته‌ها', 'All categories')),
                          items: categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => category = v),
                        ),
                      ),
                    SectionTitle(
                      '${_tr('کارهای من', 'My tasks')} · ${_digits(filtered.length)}',
                      action: _tr('افزودن', 'Add'),
                      onTap: _editTask,
                    ),
                    if (filtered.isEmpty)
                      EmptyState(
                        icon: Icons.checklist_rounded,
                        title: search.isEmpty && filter == 'all'
                            ? _tr(
                                'برای یک شروع کوچک آماده‌ای؟',
                                'Ready for a fresh start?',
                              )
                            : _tr(
                                'کاری با این فیلتر پیدا نشد',
                                'No tasks match this filter',
                              ),
                        subtitle: _tr(
                          'عنوان، زمان و اولویت کار را انتخاب کن.',
                          'Add a title, due date and priority.',
                        ),
                        action: _tr('تسک جدید', 'New task'),
                        onTap: _editTask,
                      )
                    else
                      ...filtered.map(
                        (task) => TaskTile(
                          task: task,
                          onToggle: () => _toggle(task),
                          onDelete: () => _delete(task),
                          onEdit: () => _editTask(task),
                          english: ref.watch(languageProvider),
                        ),
                      ),
                    const SizedBox(height: 22),
                  ],
                );
              },
              error: (_, _) => Column(
                children: [
                  Text(_tr('خواندن کارها ممکن نشد.', 'Could not load tasks.')),
                  TextButton(
                    onPressed: () => ref.invalidate(tasksProvider),
                    child: Text(_tr('تلاش دوباره', 'Retry')),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
      ),
      Positioned(
        bottom: 14,
        left: 0,
        right: 0,
        child: Center(
          child: FilledButton.icon(
            key: const Key('add-task'),
            onPressed: _saving ? null : _editTask,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: Text(_tr('تسک جدید', 'New task')),
            style: FilledButton.styleFrom(
              minimumSize: const Size(146, 44),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Future<void> _delete(Task task) async {
    try {
      await ref.read(databaseProvider).softDeleteTask(task.id);
      await PlatformServices.cancelTask(task.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('به سطل زباله منتقل شد.', 'Moved to trash.')),
          action: SnackBarAction(
            label: _tr('بازگردانی', 'Undo'),
            onPressed: () async {
              await ref.read(databaseProvider).restoreTask(task.id);
              await _schedule(task);
            },
          ),
        ),
      );
    } catch (_) {
      _error();
    }
  }

  Future<void> _toggle(Task task) async {
    final db = ref.read(databaseProvider);
    try {
      await db.transaction(() async {
        await (db.update(
          db.tasks,
        )..where((row) => row.id.equals(task.id))).write(
          TasksCompanion(
            completed: Value(!task.completed),
            completedAt: Value(task.completed ? null : DateTime.now()),
          ),
        );
        if (task.completed) return;
        final preference =
            await (db.select(db.appPreferences)
                  ..where((p) => p.key.equals('taskConfig:${task.id}')))
                .getSingleOrNull();
        if (preference == null) return;
        final config = jsonDecode(preference.value) as Map<String, dynamic>;
        final repeat = config['repeat'] as String? ?? 'none';
        if (repeat == 'none') return;
        final nextId = 'repeat-${task.id}';
        if (await (db.select(
              db.tasks,
            )..where((t) => t.id.equals(nextId))).getSingleOrNull() !=
            null) {
          return;
        }
        final due = nextTaskOccurrence(task.dueAt ?? DateTime.now(), repeat);
        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                id: nextId,
                title: task.title,
                description: Value(task.description),
                category: Value(task.category),
                priority: Value(task.priority),
                dueAt: Value(due),
                createdAt: DateTime.now(),
              ),
            );
        await db.savePreference('taskConfig:$nextId', preference.value);
      });
      if (task.completed) {
        await _schedule(task);
      } else {
        await PlatformServices.cancelTask(task.id);
        final next = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals('repeat-${task.id}'))).getSingleOrNull();
        if (next != null) await _schedule(next);
      }
    } catch (_) {
      _error();
    }
  }

  Future<void> _schedule(Task task) async {
    if (task.dueAt != null && task.dueAt!.isAfter(DateTime.now())) {
      await PlatformServices.scheduleTask(
        task.id,
        task.title,
        task.dueAt!,
        body: task.description,
      );
    }
  }

  void _error() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'ذخیرهٔ تغییر انجام نشد؛ دوباره تلاش کن.',
              'Could not save. Please retry.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _editTask([Task? task]) async {
    if (_saving) return;
    final db = ref.read(databaseProvider);
    final title = TextEditingController(text: task?.title ?? ''),
        detail = TextEditingController(text: task?.description ?? ''),
        categoryText = TextEditingController(
          text: task?.category ?? _tr('درسی', 'Study'),
        ),
        tags = TextEditingController();
    var priority = task?.priority ?? 'متوسط', repeat = 'none';
    DateTime? due = task?.dueAt;
    if (task != null) {
      final p = await (db.select(
        db.appPreferences,
      )..where((p) => p.key.equals('taskConfig:${task.id}'))).getSingleOrNull();
      if (p != null) {
        try {
          final data = jsonDecode(p.value) as Map<String, dynamic>;
          repeat = data['repeat'] as String? ?? 'none';
          tags.text = data['tags'] as String? ?? '';
        } catch (_) {
          /* Older tasks have no optional repeat metadata. */
        }
      }
    }
    if (!mounted) {
      title.dispose();
      detail.dispose();
      categoryText.dispose();
      tags.dispose();
      return;
    }
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogControllers(
        controllers: [title, detail, categoryText, tags],
        child: StatefulBuilder(
          builder: (context, setDialog) => AlertDialog(
            title: Text(
              task == null
                  ? _tr('تسک جدید', 'New task')
                  : _tr('ویرایش تسک', 'Edit task'),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        key: const Key('task-title'),
                        controller: title,
                        autofocus: true,
                        maxLength: 120,
                        decoration: InputDecoration(
                          labelText: _tr('عنوان', 'Title'),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? _tr('عنوان را وارد کن.', 'Enter a title.')
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: detail,
                        maxLines: 3,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: _tr('توضیحات', 'Description'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: categoryText,
                        maxLength: 50,
                        decoration: InputDecoration(
                          labelText: _tr('دسته‌بندی', 'Category'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: ['کم', 'متوسط', 'زیاد'].contains(priority)
                            ? priority
                            : 'متوسط',
                        decoration: InputDecoration(
                          labelText: _tr('اولویت', 'Priority'),
                        ),
                        items: ['کم', 'متوسط', 'زیاد']
                            .asMap()
                            .entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.value,
                                child: Text(
                                  ref.read(languageProvider)
                                      ? ['Low', 'Medium', 'High'][entry.key]
                                      : entry.value,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialog(() => priority = v ?? priority),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                        ),
                        label: Text(
                          due == null
                              ? _tr('انتخاب تاریخ شمسی', 'Choose a date')
                              : formatJalali(due!),
                        ),
                        onPressed: () async {
                          final picked = await pickJalaliTaskDate(
                            context,
                            initial: due,
                          );
                          if (picked != null) {
                            setDialog(
                              () => due = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                due?.hour ?? 9,
                                due?.minute ?? 0,
                              ),
                            );
                          }
                        },
                      ),
                      if (due != null)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                ),
                                label: Text(formatClock(due!)),
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(due!),
                                  );
                                  if (picked != null) {
                                    setDialog(
                                      () => due = DateTime(
                                        due!.year,
                                        due!.month,
                                        due!.day,
                                        picked.hour,
                                        picked.minute,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: _tr('حذف زمان', 'Remove due date'),
                              onPressed: () => setDialog(() => due = null),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: repeat,
                        decoration: InputDecoration(
                          labelText: _tr('تکرار', 'Repeat'),
                        ),
                        items:
                            <String, String>{
                                  'none': _tr('بدون تکرار', 'Never'),
                                  'daily': _tr('هر روز', 'Daily'),
                                  'weekly': _tr('هر هفته', 'Weekly'),
                                  'monthly': _tr('هر ماه', 'Monthly'),
                                }.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setDialog(() => repeat = v ?? 'none'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: tags,
                        decoration: InputDecoration(
                          labelText: _tr('برچسب‌ها', 'Tags'),
                          hintText: _tr(
                            'با ویرگول جدا کن',
                            'Separate with commas',
                          ),
                        ),
                      ),
                      if (repeat != 'none')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _tr(
                              'پس از انجام، کار بعدی با همین تنظیمات ساخته می‌شود.',
                              'Completing this task creates its next occurrence.',
                            ),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_tr('انصراف', 'Cancel')),
              ),
              FilledButton(
                key: const Key('save-task'),
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                child: Text(_tr('ذخیره', 'Save')),
              ),
            ],
          ),
        ),
      ),
    );
    final titleValue = title.text.trim(),
        detailValue = detail.text.trim(),
        categoryValue = categoryText.text.trim(),
        tagsValue = tags.text.trim();
    if (saved != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final id = task?.id ?? const Uuid().v4();
      await db.transaction(() async {
        if (task == null) {
          await db
              .into(db.tasks)
              .insert(
                TasksCompanion.insert(
                  id: id,
                  title: titleValue,
                  description: Value(detailValue),
                  category: Value(
                    categoryValue.isEmpty
                        ? _tr('درسی', 'Study')
                        : categoryValue,
                  ),
                  priority: Value(priority),
                  dueAt: Value(due),
                  createdAt: DateTime.now(),
                ),
              );
        } else {
          await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
            TasksCompanion(
              title: Value(titleValue),
              description: Value(detailValue),
              category: Value(
                categoryValue.isEmpty ? task.category : categoryValue,
              ),
              priority: Value(priority),
              dueAt: Value(due),
            ),
          );
        }
        await db.savePreference(
          'taskConfig:$id',
          jsonEncode({'repeat': repeat, 'tags': tagsValue}),
        );
      });
      await PlatformServices.cancelTask(id);
      final savedTask = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(id))).getSingle();
      if (!savedTask.completed && due != null && due!.isAfter(DateTime.now())) {
        if (PlatformServices.supportsBackgroundAlarms) {
          await PlatformServices.requestAlarmPermissions();
        }
        await _schedule(savedTask);
      }
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<DateTime?> pickJalaliTaskDate(
  BuildContext context, {
  DateTime? initial,
}) async {
  var date = Jalali.fromDateTime(initial ?? DateTime.now());
  var year = date.year, month = date.month, day = date.day;
  return showDialog<DateTime>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialog) {
        final maxDay = Jalali(year, month, 1).monthLength;
        if (day > maxDay) day = maxDay;
        return AlertDialog(
          title: const Text('انتخاب تاریخ شمسی'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${faDigits(day)} ${jalaliMonths[month - 1]} ${faDigits(year)}',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('d:$maxDay:$day'),
                        initialValue: day,
                        decoration: const InputDecoration(labelText: 'روز'),
                        items: List.generate(
                          maxDay,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(faDigits(i + 1)),
                          ),
                        ),
                        onChanged: (v) => setDialog(() => day = v ?? day),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        initialValue: month,
                        decoration: const InputDecoration(labelText: 'ماه'),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(jalaliMonths[i]),
                          ),
                        ),
                        onChanged: (v) => setDialog(() => month = v ?? month),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: year,
                  decoration: const InputDecoration(labelText: 'سال'),
                  items: List.generate(31, (i) => Jalali.now().year - 10 + i)
                      .toSet()
                      .union({year})
                      .toList()
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(faDigits(y)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => year = v ?? year),
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
              onPressed: () =>
                  Navigator.pop(context, Jalali(year, month, day).toDateTime()),
              child: const Text('انتخاب'),
            ),
          ],
        );
      },
    ),
  );
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.english = false,
    super.key,
  });
  final Task task;
  final VoidCallback onToggle, onDelete, onEdit;
  final bool english;
  @override
  Widget build(BuildContext context) {
    final overdue =
        !task.completed &&
        task.dueAt != null &&
        task.dueAt!.isBefore(DateTime.now());
    final color = task.priority == 'زیاد'
        ? AppColors.red
        : task.priority == 'کم'
        ? AppColors.blue
        : AppColors.amber;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.completed
              ? AppColors.emerald.withValues(alpha: .28)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: task.completed,
                onChanged: (_) => onToggle(),
                semanticLabel: english ? 'Complete task' : 'انجام کار',
                activeColor: AppColors.emerald,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          task.category,
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          english
                              ? {
                                      'کم': 'Low',
                                      'متوسط': 'Medium',
                                      'زیاد': 'High',
                                    }[task.priority] ??
                                    task.priority
                              : task.priority,
                          style: TextStyle(color: color, fontSize: 10),
                        ),
                        if (task.dueAt != null)
                          Text(
                            '${formatJalali(task.dueAt!, withYear: false)} · ${formatClock(task.dueAt!)}',
                            style: TextStyle(
                              color: overdue ? AppColors.red : AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: english ? 'Task actions' : 'گزینه‌های کار',
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(english ? 'Edit' : 'ویرایش'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      english ? 'Move to trash' : 'انتقال به سطل زباله',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.total,
    required this.completed,
    required this.all,
    required this.english,
  });
  final int total, completed, all;
  final bool english;
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = english
        ? (hour < 12
              ? 'Good morning'
              : hour < 18
              ? 'Good afternoon'
              : 'Good evening')
        : (hour < 12
              ? 'صبح بخیر'
              : hour < 18
              ? 'روزت بخیر'
              : 'عصرت بخیر');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173B31), Color(0xFF10221E)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.emerald.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$greeting 🌿',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const Icon(Icons.auto_awesome, color: AppColors.emerald),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            english
                ? '$total tasks ahead. One step at a time.'
                : '${faDigits(total)} کار در مسیرت داری؛ قدم‌به‌قدم جلو برو.',
            style: const TextStyle(color: Color(0xFFB7CBC4), fontSize: 12),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: all == 0 ? 0 : completed / all,
              minHeight: 5,
              color: AppColors.emerald,
              backgroundColor: Colors.white10,
            ),
          ),
        ],
      ),
    );
  }
}
