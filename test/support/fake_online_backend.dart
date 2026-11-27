import 'dart:async';
import 'package:rahyar/data/online/online_backend.dart';

class FakeOnlineBackend implements OnlineBackend {
  CloudUser? user;
  String? sentEmail, verifiedCode;
  int sendCount = 0;
  bool rejectCode = false;
  bool offline = false;
  UserProfile? verifiedProfile;
  final entries = <String, List<CloudEntry>>{};
  final events = StreamController<void>.broadcast();
  @override
  Future<CloudUser?> currentUser() async {
    if (offline) throw StateError('Offline');
    return user;
  }

  @override
  Future<EmailChallenge> sendCode(String email) async {
    sentEmail = normalizeEmail(email);
    sendCount++;
    return const EmailChallenge('user-one', 'silver meadow');
  }

  @override
  Future<CloudUser> verifyCode(String userId, String code) async {
    verifiedCode = code;
    if (rejectCode) throw StateError('Rejected by fake server');
    return user = CloudUser(
      id: userId,
      email: sentEmail!,
      name: verifiedProfile?.name ?? '',
      profile: verifiedProfile ?? const UserProfile(),
    );
  }

  @override
  Future<CloudUser> updateName(String name) async => user = CloudUser(
    id: user!.id,
    email: user!.email,
    name: name.trim(),
    profile: user!.profile,
  );
  @override
  Future<CloudUser> updateProfile(UserProfile profile) async {
    if (offline) throw StateError('Offline');
    return user = CloudUser(
      id: user!.id,
      email: user!.email,
      name: profile.name,
      profile: profile,
    );
  }

  @override
  Future<void> signOut() async {
    user = null;
  }

  @override
  Stream<List<CloudEntry>> watch(String collection, {String? parentId}) async* {
    List<CloudEntry> read() => (entries[collection] ?? [])
        .where((entry) => parentId == null || entry.parentId == parentId)
        .toList();
    yield read();
    await for (final _ in events.stream) {
      yield read();
    }
  }

  @override
  Future<void> write(
    String collection,
    CloudUser user,
    String body, {
    String parentId = '',
    String? id,
  }) async {
    final rows = entries.putIfAbsent(collection, () => []);
    rows.add(
      CloudEntry(
        id: id ?? 'entry-${rows.length}',
        ownerId: user.id,
        name: user.displayName,
        body: body,
        parentId: parentId,
        createdAt: DateTime(2026, 11, 26),
      ),
    );
    events.add(null);
  }

  @override
  Future<void> remove(String collection, String id) async {
    entries[collection]?.removeWhere((entry) => entry.id == id);
    events.add(null);
  }
}
