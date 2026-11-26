import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class OnlineConfig {
  const OnlineConfig({
    this.endpoint = const String.fromEnvironment('APPWRITE_ENDPOINT'),
    this.projectId = const String.fromEnvironment('APPWRITE_PROJECT_ID'),
    this.databaseId = const String.fromEnvironment(
      'APPWRITE_DATABASE_ID',
      defaultValue: 'rahyar',
    ),
  });
  final String endpoint, projectId, databaseId;
  bool get enabled {
    final uri = Uri.tryParse(endpoint);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.path == '/v1' &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        projectId.isNotEmpty &&
        databaseId.isNotEmpty;
  }
}

class CloudUser {
  const CloudUser({required this.id, required this.email, required this.name});
  final String id, email, name;
  String get displayName => name.trim().isEmpty ? 'همراه راهیار' : name.trim();
}

class EmailChallenge {
  const EmailChallenge(this.userId, this.phrase);
  final String userId, phrase;
}

class CloudEntry {
  const CloudEntry({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.body,
    required this.parentId,
    required this.createdAt,
  });
  final String id, ownerId, name, body, parentId;
  final DateTime createdAt;
  factory CloudEntry.fromDocument(models.Row doc) => CloudEntry(
    id: doc.$id,
    ownerId: '${doc.data['ownerId'] ?? ''}',
    name: '${doc.data['name'] ?? 'همراه راهیار'}',
    body: '${doc.data['body'] ?? ''}',
    parentId: '${doc.data['parentId'] ?? ''}',
    createdAt:
        DateTime.tryParse(doc.$createdAt) ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

abstract class OnlineBackend {
  Future<CloudUser?> currentUser();
  Future<EmailChallenge> sendCode(String email);
  Future<CloudUser> verifyCode(String userId, String code);
  Future<CloudUser> updateName(String name);
  Future<void> signOut();
  Stream<List<CloudEntry>> watch(String collection, {String? parentId});
  Future<void> write(
    String collection,
    CloudUser user,
    String body, {
    String parentId = '',
    String? id,
  });
  Future<void> remove(String collection, String id);
}

final onlineConfigProvider = Provider<OnlineConfig>(
  (ref) => const OnlineConfig(),
);
final onlineBackendProvider = Provider<OnlineBackend?>((ref) {
  final config = ref.watch(onlineConfigProvider);
  if (!config.enabled) return null;
  return AppwriteBackend(config);
});
final cloudUserProvider = FutureProvider<CloudUser?>(
  (ref) => ref.watch(onlineBackendProvider)?.currentUser(),
);
typedef CloudFeed = ({String collection, String? parentId});
final cloudFeedProvider = StreamProvider.autoDispose
    .family<List<CloudEntry>, CloudFeed>((ref, feed) {
      final backend = ref.watch(onlineBackendProvider);
      final user = ref.watch(cloudUserProvider).asData?.value;
      if (backend == null || user == null) return Stream.value([]);
      return backend.watch(feed.collection, parentId: feed.parentId);
    });

String normalizeEmail(String value) => value.trim().toLowerCase();
bool validEmail(String value) =>
    value.length <= 254 &&
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
String normalizeEmailCode(String value) {
  const fa = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
  }
  return value.replaceAll(RegExp(r'\s'), '');
}

String onlineError(Object error) {
  if (error is AppwriteException) {
    if (error.code == 429) {
      return 'درخواست‌ها زیاد شده؛ کمی صبر کن و دوباره تلاش کن.';
    }
    if (error.code == 401) {
      return 'کد نامعتبر یا منقضی است، یا باید دوباره وارد حساب شوی.';
    }
    if (error.code == 403) {
      return 'دسترسی کافی نیست؛ ورود و مجوزهای پروژه را بررسی کن.';
    }
    if (error.code == 404) {
      return 'سرویس آنلاین آماده نیست؛ تنظیمات پروژه و پایگاه‌داده را بررسی کن.';
    }
    if (error.code == 409) return 'این مورد قبلاً ثبت شده است.';
    if (error.type == 'user_email_not_whitelisted') {
      return 'ارسال ایمیل پروژه هنوز برای این نشانی فعال نیست.';
    }
  }
  return 'ارتباط برقرار نشد. اینترنت و تنظیمات سرویس را بررسی و دوباره تلاش کن.';
}

class AppwriteBackend implements OnlineBackend {
  AppwriteBackend(this.config) {
    final client = Client()
        .setEndpoint(config.endpoint)
        .setProject(config.projectId);
    account = Account(client);
    database = TablesDB(client);
    realtime = Realtime(client);
  }
  final OnlineConfig config;
  late final Account account;
  late final TablesDB database;
  late final Realtime realtime;
  final _subscriptions = <RealtimeSubscription>{};
  static const collections = {
    'posts',
    'comments',
    'likes',
    'messages',
    'rooms',
    'members',
    'scores',
  };
  CloudUser _user(models.User user) =>
      CloudUser(id: user.$id, email: user.email, name: user.name);
  void _checkCollection(String collection) {
    if (!collections.contains(collection)) {
      throw ArgumentError('Unknown collection');
    }
  }

  @override
  Future<CloudUser?> currentUser() async {
    try {
      return _user(await account.get());
    } on AppwriteException catch (error) {
      if (error.code == 401) return null;
      rethrow;
    }
  }

  @override
  Future<EmailChallenge> sendCode(String email) async {
    final normalized = normalizeEmail(email);
    if (!validEmail(normalized)) throw ArgumentError('Invalid email');
    final token = await account.createEmailToken(
      userId: ID.unique(),
      email: normalized,
      phrase: true,
    );
    return EmailChallenge(token.userId, token.phrase);
  }

  @override
  Future<CloudUser> verifyCode(String userId, String code) async {
    final normalized = normalizeEmailCode(code);
    if (!RegExp(r'^\d{6}$').hasMatch(normalized)) {
      throw ArgumentError('Invalid code');
    }
    await account.createSession(userId: userId, secret: normalized);
    return _user(await account.get());
  }

  @override
  Future<CloudUser> updateName(String name) async =>
      _user(await account.updateName(name: name.trim()));
  @override
  Future<void> signOut() async {
    for (final subscription in _subscriptions.toList()) {
      _subscriptions.remove(subscription);
      await subscription.close();
    }
    await account.deleteSession(sessionId: 'current');
  }

  Future<List<CloudEntry>> _list(String collection, String? parentId) async {
    _checkCollection(collection);
    final result = await database.listRows(
      databaseId: config.databaseId,
      tableId: collection,
      queries: [
        if (parentId != null) Query.equal('parentId', parentId),
        Query.orderDesc(r'$createdAt'),
        Query.limit(50),
      ],
    );
    return result.rows.map(CloudEntry.fromDocument).toList();
  }

  @override
  Stream<List<CloudEntry>> watch(String collection, {String? parentId}) {
    _checkCollection(collection);
    late StreamController<List<CloudEntry>> controller;
    RealtimeSubscription? subscription;
    StreamSubscription<dynamic>? events;
    Timer? debounce;
    var closed = false, loading = false, again = false;
    Future<void> refresh() async {
      if (closed) return;
      if (loading) {
        again = true;
        return;
      }
      loading = true;
      try {
        final rows = await _list(collection, parentId);
        if (!closed) controller.add(rows);
      } catch (error, stack) {
        if (!closed) controller.addError(error, stack);
      } finally {
        loading = false;
        if (again && !closed) {
          again = false;
          unawaited(refresh());
        }
      }
    }

    controller = StreamController<List<CloudEntry>>(
      onListen: () {
        subscription = realtime.subscribe([
          'databases.${config.databaseId}.tables.$collection.rows',
        ]);
        _subscriptions.add(subscription!);
        events = subscription!.stream.listen(
          (_) {
            debounce?.cancel();
            debounce = Timer(const Duration(milliseconds: 350), refresh);
          },
          onError: (Object error, StackTrace stack) {
            if (!closed) controller.addError(error, stack);
          },
        );
        unawaited(refresh());
      },
      onCancel: () async {
        closed = true;
        debounce?.cancel();
        await events?.cancel();
        if (subscription != null && _subscriptions.remove(subscription)) {
          await subscription!.close();
        }
      },
    );
    return controller.stream;
  }

  @override
  Future<void> write(
    String collection,
    CloudUser user,
    String body, {
    String parentId = '',
    String? id,
  }) async {
    _checkCollection(collection);
    if (body.length > 4000 || user.displayName.length > 100) {
      throw ArgumentError('Content too long');
    }
    final data = {
      'ownerId': user.id,
      'name': user.displayName,
      'body': body.trim(),
      'parentId': parentId,
    };
    if (id != null) {
      try {
        await database.updateRow(
          databaseId: config.databaseId,
          tableId: collection,
          rowId: id,
          data: data,
        );
        return;
      } on AppwriteException catch (error) {
        if (error.code != 404) rethrow;
      }
    }
    await database.createRow(
      databaseId: config.databaseId,
      tableId: collection,
      rowId: id ?? const Uuid().v4(),
      data: data,
      permissions: [
        Permission.read(Role.users()),
        Permission.update(Role.user(user.id)),
        Permission.delete(Role.user(user.id)),
      ],
    );
  }

  @override
  Future<void> remove(String collection, String id) async {
    _checkCollection(collection);
    await database.deleteRow(
      databaseId: config.databaseId,
      tableId: collection,
      rowId: id,
    );
  }
}
