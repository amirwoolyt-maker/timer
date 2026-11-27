import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahyar/data/local/app_database.dart';
import 'package:rahyar/data/online/online_backend.dart';
import 'package:rahyar/data/repositories/providers.dart';
import 'support/fake_online_backend.dart';

void main() {
  const profile = UserProfile(
    name: 'سارا',
    age: 17,
    grade: '11',
    gender: 'female',
    avatar: 'fox',
    subject: 'تجربی',
  );
  test('profile requires valid identity and an explicit avatar choice', () {
    expect(profile.complete, isTrue);
    expect(
      const UserProfile(
        name: 'سارا',
        age: 17,
        grade: '11',
        gender: 'female',
      ).complete,
      isFalse,
    );
    expect(
      UserProfile.fromMap({...profile.toMap(), 'age': 5}).complete,
      isFalse,
    );
    expect(
      UserProfile.fromMap({...profile.toMap(), 'age': 101}).complete,
      isFalse,
    );
    expect(
      UserProfile.fromMap({...profile.toMap(), 'grade': 'bogus'}).complete,
      isFalse,
    );
    expect(UserProfile.fromMap(profile.toMap()).toMap(), profile.toMap());
  });

  test(
    'authenticated profile cache survives offline reopen but not sign-out',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final backend = FakeOnlineBackend()
        ..user = const CloudUser(
          id: 'one',
          email: 'one@example.com',
          name: 'سارا',
          profile: profile,
        );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          onlineBackendProvider.overrideWithValue(backend),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
        await backend.events.close();
      });
      expect((await container.read(cloudUserProvider.future))!.profile.age, 17);
      backend.offline = true;
      container.invalidate(cloudUserProvider);
      final offline = await container.read(cloudUserProvider.future);
      expect(offline!.isOffline, isTrue);
      expect(offline.profile.toMap(), profile.toMap());
      backend.offline = false;
      await backend.signOut();
      container.invalidate(cloudUserProvider);
      expect(await container.read(cloudUserProvider.future), isNull);
      backend.offline = true;
      container.invalidate(cloudUserProvider);
      await expectLater(
        container.read(cloudUserProvider.future),
        throwsStateError,
      );
    },
  );

  test(
    'private profile values are separated when another account signs in',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final backend = FakeOnlineBackend()
        ..user = const CloudUser(
          id: 'one',
          email: 'one@example.com',
          name: 'سارا',
          profile: profile,
        );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          onlineBackendProvider.overrideWithValue(backend),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
        await backend.events.close();
      });
      await container.read(cloudUserProvider.future);
      backend.user = const CloudUser(
        id: 'two',
        email: 'two@example.com',
        name: '',
      );
      container.invalidate(cloudUserProvider);
      final second = await container.read(cloudUserProvider.future);
      expect(second!.profile.age, isNull);
      final rows = await db.select(db.appPreferences).get();
      expect(rows.any((row) => row.key == 'profile.age:two'), isFalse);
      expect(
        rows.singleWhere((row) => row.key == 'profile.age:one').value,
        '17',
      );
    },
  );
}
