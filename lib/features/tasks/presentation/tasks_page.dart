part of '../../feature_pages.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});
  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  String filter = 'همه', query = '';
  @override
  Widget build(BuildContext context) => PageFrame(
    child: ref
        .watch(tasksProvider)
        .when(
          data: (tasks) {
            final now = DateTime.now();
            final completed = tasks.where((task) => task.completed).length;
            final filtered = tasks.where((task) {
              final today =
                  task.dueAt != null &&
                  task.dueAt!.year == now.year &&
                  task.dueAt!.month == now.month &&
                  task.dueAt!.day == now.day;
              final matches = switch (filter) {
                'امروز' => today,
                'در پیش' => !task.completed,
                'انجام‌شده' => task.completed,
                _ => true,
              };
              return matches &&
                  (query.isEmpty ||
                      task.title.contains(query) ||
                      task.description.contains(query));
            }).toList();
            final taskWidgets = filtered.isEmpty
                ? <Widget>[
                    EmptyState(
                      icon: Icons.wb_sunny_outlined,
                      title: 'روزت هنوز پر نشده',
                      subtitle: 'یک کار کوچک اضافه کن و مسیرت را روشن کن.',
                      action: 'افزودن کار',
                      onTap: _addTask,
                    ),
                  ]
                : filtered
                      .map<Widget>(
                        (task) => TaskTile(
                          task: task,
                          onToggle: () => _toggle(task),
                          onDelete: () => ref
                              .read(databaseProvider)
                              .softDeleteTask(task.id),
                        ),
                      )
                      .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Greeting(total: tasks.length, completed: completed),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatCard(
                      label: 'در پیش',
                      value: faDigits(tasks.length - completed),
                      icon: Icons.bolt_rounded,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 8),
                    StatCard(
                      label: 'انجام‌شده',
                      value: faDigits(completed),
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 8),
                    const StatCard(
                      label: 'پیوستگی',
                      value: '۷ روز',
                      icon: Icons.local_fire_department_outlined,
                      color: AppColors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.muted,
                    ),
                    hintText: 'جستجوی کارها...',
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['همه', 'امروز', 'در پیش', 'انجام‌شده'].map((
                      value,
                    ) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 7),
                        child: ChoiceChip(
                          label: Text(value),
                          selected: filter == value,
                          onSelected: (_) => setState(() => filter = value),
                          selectedColor: AppColors.emerald.withValues(
                            alpha: .17,
                          ),
                          side: BorderSide(
                            color: filter == value
                                ? AppColors.emerald
                                : AppColors.border,
                          ),
                          labelStyle: TextStyle(
                            color: filter == value
                                ? AppColors.emerald
                                : AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SectionTitle('برنامه امروز', action: 'افزودن', onTap: _addTask),
                ...taskWidgets,
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('کار تازه'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: AppColors.emerald,
                      foregroundColor: const Color(0xFF041B12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          error: (error, _) => Text('خطا در خواندن کارها: $error'),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.emerald),
          ),
        ),
  );

  Future<void> _toggle(Task task) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.tasks)..where((row) => row.id.equals(task.id))).write(
      TasksCompanion(
        completed: Value(!task.completed),
        completedAt: Value(task.completed ? null : DateTime.now()),
      ),
    );
  }

  Future<void> _addTask() async {
    final title = TextEditingController(), detail = TextEditingController();
    var priority = 'متوسط';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('کار تازه'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'عنوان'),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: detail,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'توضیحات'),
              ),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'اولویت'),
                items: ['کم', 'متوسط', 'زیاد']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => priority = value ?? priority),
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
                  Navigator.pop(context, title.text.trim().isNotEmpty),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final now = DateTime.now(), db = ref.read(databaseProvider);
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Uuid().v4(),
            title: title.text.trim(),
            description: Value(detail.text.trim()),
            priority: Value(priority),
            dueAt: Value(DateTime(now.year, now.month, now.day, 18)),
            createdAt: now,
          ),
        );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });
  final Task task;
  final VoidCallback onToggle, onDelete;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: task.completed
              ? AppColors.emerald.withValues(alpha: .28)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.completed ? AppColors.emerald : Colors.transparent,
                border: Border.all(
                  color: task.completed ? AppColors.emerald : AppColors.muted,
                ),
              ),
              child: task.completed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xFF061B13),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 5),
                Text(
                  '${task.dueAt == null ? 'بدون زمان' : formatClock(task.dueAt!)} · ${task.category} · ${task.priority}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
            onSelected: (_) => onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('انتقال به سطل زباله')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.total, required this.completed});
  final int total, completed;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF173B31), Color(0xFF10221E)],
      ),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.emerald.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'صبح بخیر، قهرمان 🌿',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'امروز ${faDigits(total)} کار در مسیرت داری.',
                style: const TextStyle(color: Color(0xFFB7CBC4), fontSize: 12),
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : completed / total,
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text('☀️', style: TextStyle(fontSize: 40)),
      ],
    ),
  );
}
