import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('درسی'))();
  TextColumn get priority => text().withDefault(const Constant('متوسط'))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get color => text().withDefault(const Constant('#10B981'))();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get grade => text()();
  TextColumn get subject => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StudySessions extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text().withDefault(const Constant('مطالعه آزاد'))();
  IntColumn get durationMinutes => integer()();
  DateTimeColumn get startedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Alarms extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get challengeLevel => text().withDefault(const Constant('آسان'))();
  IntColumn get wrongAttempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class SocialPosts extends Table {
  TextColumn get id => text()();
  TextColumn get author => text()();
  TextColumn get body => text()();
  IntColumn get likes => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Tasks,
    Notes,
    Projects,
    Books,
    StudySessions,
    Alarms,
    AppPreferences,
    SocialPosts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'rahyar_local',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(alarms, alarms.wrongAttempts);
      }
    },
  );

  Stream<List<Task>> watchActiveTasks() =>
      (select(tasks)
            ..where((row) => row.deletedAt.isNull())
            ..orderBy([
              (row) => OrderingTerm.asc(row.completed),
              (row) => OrderingTerm.asc(row.dueAt),
              (row) => OrderingTerm.desc(row.createdAt),
            ]))
          .watch();

  Stream<List<Task>> watchTrashTasks() =>
      (select(tasks)
            ..where((row) => row.deletedAt.isNotNull())
            ..orderBy([(row) => OrderingTerm.desc(row.deletedAt)]))
          .watch();

  Stream<List<Note>> watchActiveNotes() =>
      (select(notes)
            ..where((row) => row.deletedAt.isNull())
            ..orderBy([
              (row) => OrderingTerm.desc(row.pinned),
              (row) => OrderingTerm.desc(row.updatedAt),
            ]))
          .watch();

  Stream<List<Note>> watchTrashNotes() =>
      (select(notes)
            ..where((row) => row.deletedAt.isNotNull())
            ..orderBy([(row) => OrderingTerm.desc(row.deletedAt)]))
          .watch();

  Future<int> softDeleteTask(String id) =>
      (update(tasks)..where((row) => row.id.equals(id))).write(
        TasksCompanion(deletedAt: Value(DateTime.now())),
      );

  Future<int> deleteTaskPermanently(String id) =>
      (delete(tasks)..where((row) => row.id.equals(id))).go();

  Future<int> restoreTask(String id) =>
      (update(tasks)..where((row) => row.id.equals(id))).write(
        const TasksCompanion(deletedAt: Value(null)),
      );

  Future<int> softDeleteNote(String id) =>
      (update(notes)..where((row) => row.id.equals(id))).write(
        NotesCompanion(deletedAt: Value(DateTime.now())),
      );

  Future<int> deleteNotePermanently(String id) =>
      (delete(notes)..where((row) => row.id.equals(id))).go();

  Future<int> restoreNote(String id) =>
      (update(notes)..where((row) => row.id.equals(id))).write(
        const NotesCompanion(deletedAt: Value(null)),
      );

  Future<int> restoreProject(String id) =>
      (update(projects)..where((row) => row.id.equals(id))).write(
        const ProjectsCompanion(deletedAt: Value(null)),
      );

  Future<int> softDeleteProject(String id) =>
      (update(projects)..where((row) => row.id.equals(id))).write(
        ProjectsCompanion(deletedAt: Value(DateTime.now())),
      );

  Future<int> deleteProjectPermanently(String id) =>
      (delete(projects)..where((row) => row.id.equals(id))).go();

  Future<int> completedCount() async =>
      (select(tasks)..where(
            (row) => row.completed.equals(true) & row.deletedAt.isNull(),
          ))
          .get()
          .then((rows) => rows.length);

  Future<void> savePreference(String key, String value) =>
      into(appPreferences).insertOnConflictUpdate(
        AppPreferencesCompanion.insert(key: key, value: value),
      );

  Future<List<StudySession>> sessionsForToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(studySessions)
          ..where(
            (row) =>
                row.startedAt.isBiggerOrEqualValue(start) &
                row.startedAt.isSmallerThanValue(end),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]))
        .get();
  }
}
