part of '../../feature_pages.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});
  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  String query = '';
  bool _saving = false;
  String _tr(String fa, String en) => ref.read(languageProvider) ? en : fa;
  @override
  Widget build(BuildContext context) => PageFrame(
    child: ref
        .watch(notesProvider)
        .when(
          data: (notes) {
            final needle = normalizeTaskSearch(query);
            final visible = notes
                .where(
                  (note) =>
                      needle.isEmpty ||
                      normalizeTaskSearch(
                        '${note.title} ${note.body}',
                      ).contains(needle),
                )
                .toList();
            final pinned = visible.where((n) => n.pinned).toList();
            final other = visible.where((n) => !n.pinned).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _tr(
                    'فکرها و ایده‌هایت را اینجا نگه دار.',
                    'A place for your thoughts and ideas.',
                  ),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('note-search'),
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: _tr('جستجوی یادداشت‌ها…', 'Search notes…'),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('add-note'),
                  onPressed: notes.length >= 15 || _saving ? null : _editNote,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: Text(
                    notes.length >= 15
                        ? _tr('سقف ۱۵ یادداشت پر شده', '15-note limit reached')
                        : _tr('یادداشت جدید', 'New note'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${ref.watch(languageProvider) ? notes.length : faDigits(notes.length)} / ${_tr('۱۵ یادداشت آفلاین', '15 offline notes')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 40,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          needle.isEmpty
                              ? _tr(
                                  'اولین ایده‌ات را ثبت کن',
                                  'Save your first idea',
                                )
                              : _tr('یادداشتی پیدا نشد', 'No matching notes'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tr(
                            'یادداشت‌ها روی همین دستگاه ذخیره می‌شوند.',
                            'Notes are stored on this device.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (pinned.isNotEmpty) ...[
                  SectionTitle(_tr('سنجاق‌شده', 'Pinned')),
                  _notesGrid(pinned),
                ],
                if (other.isNotEmpty) ...[
                  if (pinned.isNotEmpty)
                    SectionTitle(_tr('سایر یادداشت‌ها', 'Other notes')),
                  _notesGrid(other),
                ],
              ],
            );
          },
          error: (_, _) => Column(
            children: [
              Text(_tr('خواندن یادداشت‌ها ممکن نشد.', 'Could not load notes.')),
              TextButton(
                onPressed: () => ref.invalidate(notesProvider),
                child: Text(_tr('تلاش دوباره', 'Retry')),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
  );

  Widget _notesGrid(List<Note> notes) => LayoutBuilder(
    builder: (context, size) {
      final columns = size.maxWidth >= 560
          ? 3
          : size.maxWidth >= 330
          ? 2
          : 1;
      final width = (size.maxWidth - 10 * (columns - 1)) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: notes
            .map(
              (note) => SizedBox(
                width: width,
                child: NoteTile(
                  note: note,
                  english: ref.watch(languageProvider),
                  onEdit: () => _editNote(note),
                  onDelete: () => _delete(note),
                  onPin: () => _pin(note),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  Future<void> _pin(Note note) async {
    try {
      final db = ref.read(databaseProvider);
      await (db.update(db.notes)..where((row) => row.id.equals(note.id))).write(
        NotesCompanion(
          pinned: Value(!note.pinned),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (_) {
      _error();
    }
  }

  Future<void> _delete(Note note) async {
    try {
      await ref.read(databaseProvider).softDeleteNote(note.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr('یادداشت به سطل زباله منتقل شد.', 'Note moved to trash.'),
          ),
          action: SnackBarAction(
            label: _tr('بازگردانی', 'Undo'),
            onPressed: () => _restoreNote(context, ref, note.id),
          ),
        ),
      );
    } catch (_) {
      _error();
    }
  }

  void _error() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'ذخیره انجام نشد؛ دوباره تلاش کن.',
              'Could not save. Please retry.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _editNote([Note? note]) async {
    if (_saving) return;
    final db = ref.read(databaseProvider);
    if (note == null &&
        (await (db.select(
              db.notes,
            )..where((n) => n.deletedAt.isNull())).get()).length >=
            15) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                'حداکثر ۱۵ یادداشت مجاز است؛ یکی را به سطل زباله منتقل کن.',
                'You can keep 15 notes. Move one to trash to add another.',
              ),
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final result = await showDialog<({String title, String body})>(
      context: context,
      builder: (context) =>
          _NoteEditor(note: note, english: ref.read(languageProvider)),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await db.transaction(() async {
        if (note == null) {
          // Check inside the transaction as another editor or trash restore can change the count.
          if ((await (db.select(
                db.notes,
              )..where((n) => n.deletedAt.isNull())).get()).length >=
              15) {
            throw StateError('note_limit');
          }
          await db
              .into(db.notes)
              .insert(
                NotesCompanion.insert(
                  id: const Uuid().v4(),
                  title: Value(result.title),
                  body: result.body,
                  updatedAt: DateTime.now(),
                ),
              );
        } else {
          await (db.update(
            db.notes,
          )..where((row) => row.id.equals(note.id))).write(
            NotesCompanion(
              title: Value(result.title),
              body: Value(result.body),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      });
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({required this.note, required this.english});
  final Note? note;
  final bool english;
  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title = TextEditingController(
    text: widget.note?.title ?? '',
  );
  late final TextEditingController body = TextEditingController(
    text: widget.note?.body ?? '',
  );
  String tr(String fa, String en) => widget.english ? en : fa;
  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.note == null
          ? tr('یادداشت جدید', 'New note')
          : tr('ویرایش یادداشت', 'Edit note'),
    ),
    content: SizedBox(
      width: 430,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('note-title'),
                controller: title,
                autofocus: true,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: tr('عنوان دلخواه', 'Title (optional)'),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('note-body'),
                controller: body,
                minLines: 5,
                maxLines: 12,
                maxLength: 12000,
                decoration: InputDecoration(
                  labelText: tr('متن یادداشت', 'Note'),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? tr('متن یادداشت را بنویس.', 'Write a note.')
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(tr('انصراف', 'Cancel')),
      ),
      FilledButton(
        key: const Key('save-note'),
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, (
              title: title.text.trim(),
              body: body.text.trim(),
            ));
          }
        },
        child: Text(tr('ذخیره', 'Save')),
      ),
    ],
  );
}

class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.note,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    this.english = false,
    super.key,
  });
  final Note note;
  final VoidCallback onEdit, onDelete, onPin;
  final bool english;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 154),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: note.pinned
                ? AppColors.amber.withValues(alpha: .4)
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
                    note.title.isEmpty
                        ? (english ? 'Untitled note' : 'یادداشت بی‌عنوان')
                        : note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (note.pinned)
                  const Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: AppColors.amber,
                  ),
                PopupMenuButton<String>(
                  tooltip: english ? 'Note actions' : 'گزینه‌های یادداشت',
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'pin') {
                      onPin();
                    } else if (value == 'edit') {
                      onEdit();
                    } else {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(english ? 'Edit' : 'ویرایش'),
                    ),
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(
                        note.pinned
                            ? (english ? 'Unpin' : 'برداشتن سنجاق')
                            : (english ? 'Pin' : 'سنجاق کردن'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'trash',
                      child: Text(
                        english ? 'Move to trash' : 'انتقال به سطل زباله',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              formatJalali(note.updatedAt),
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
