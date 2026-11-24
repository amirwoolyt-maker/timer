import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final tasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(databaseProvider).watchActiveTasks(),
);
final notesProvider = StreamProvider<List<Note>>(
  (ref) => ref.watch(databaseProvider).watchActiveNotes(),
);
final trashedTasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(databaseProvider).watchTrashTasks(),
);
final trashedNotesProvider = StreamProvider<List<Note>>(
  (ref) => ref.watch(databaseProvider).watchTrashNotes(),
);
final projectsProvider = StreamProvider<List<Project>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.projects,
  )..where((row) => row.deletedAt.isNull())).watch();
});
final trashedProjectsProvider = StreamProvider<List<Project>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.projects,
  )..where((row) => row.deletedAt.isNotNull())).watch();
});
final booksProvider = StreamProvider<List<Book>>(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).books)
      .watch(),
);
final alarmsProvider = StreamProvider<List<Alarm>>(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).alarms)
      .watch(),
);
final postsProvider = StreamProvider<List<SocialPost>>(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).socialPosts)
      .watch(),
);
final preferencesProvider = StreamProvider<List<AppPreference>>(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).appPreferences)
      .watch(),
);
