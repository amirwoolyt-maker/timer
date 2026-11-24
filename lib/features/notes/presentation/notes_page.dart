part of '../../feature_pages.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});
  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  String query = '';
  @override
  Widget build(BuildContext context) => PageFrame(
    child: ref
        .watch(notesProvider)
        .when(
          data: (notes) {
            final visible = notes
                .where(
                  (note) =>
                      query.isEmpty ||
                      note.title.contains(query) ||
                      note.body.contains(query),
                )
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'فکرها و ایده‌هایت را اینجا نگه دار.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 13),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.muted,
                    ),
                    hintText: 'جستجوی یادداشت‌ها...',
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: notes.length >= 15 ? null : _editNote,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      notes.length >= 15
                          ? 'سقف ۱۵ یادداشت پر شده'
                          : 'یادداشت تازه',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      backgroundColor: AppColors.emerald,
                      foregroundColor: const Color(0xFF041B12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                if (visible.isEmpty)
                  EmptyState(
                    icon: Icons.sticky_note_2_outlined,
                    title: 'اینجا هنوز چیزی نیست',
                    subtitle: 'یک یادداشت کوتاه برای خودت ثبت کن.',
                    action: 'یادداشت تازه',
                    onTap: _editNote,
                  )
                else
                  ...visible.map(
                    (note) => NoteTile(
                      note: note,
                      onEdit: () => _editNote(note),
                      onDelete: () =>
                          ref.read(databaseProvider).softDeleteNote(note.id),
                      onPin: () => _pin(note),
                    ),
                  ),
                const Text(
                  'حداکثر ۱۵ یادداشت آفلاین',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
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
  Future<void> _pin(Note note) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.notes)..where((row) => row.id.equals(note.id))).write(
      NotesCompanion(pinned: Value(!note.pinned)),
    );
  }

  Future<void> _editNote([Note? note]) async {
    final title = TextEditingController(text: note?.title ?? ''),
        body = TextEditingController(text: note?.body ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'یادداشت تازه' : 'ویرایش یادداشت'),
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
              controller: body,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'متن یادداشت'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بی‌خیال'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              title.text.trim().isNotEmpty && body.text.trim().isNotEmpty,
            ),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final db = ref.read(databaseProvider);
    if (note == null) {
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              id: const Uuid().v4(),
              title: Value(title.text.trim()),
              body: body.text.trim(),
              updatedAt: DateTime.now(),
            ),
          );
    } else {
      await (db.update(db.notes)..where((row) => row.id.equals(note.id))).write(
        NotesCompanion(
          title: Value(title.text.trim()),
          body: Value(body.text.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
}

class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.note,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    super.key,
  });
  final Note note;
  final VoidCallback onEdit, onDelete, onPin;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onEdit,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: note.pinned
              ? AppColors.amber.withValues(alpha: .35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (note.pinned)
                const Icon(
                  Icons.push_pin_rounded,
                  size: 15,
                  color: AppColors.amber,
                ),
              PopupMenuButton<int>(
                onSelected: (value) => value == 1 ? onPin() : onDelete(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 1,
                    child: Text(note.pinned ? 'برداشتن سنجاق' : 'سنجاق کردن'),
                  ),
                  const PopupMenuItem(
                    value: 2,
                    child: Text('انتقال به سطل زباله'),
                  ),
                ],
              ),
            ],
          ),
          Text(
            note.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFC8CCD2),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            formatJalali(note.updatedAt),
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}
