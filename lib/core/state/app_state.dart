import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/providers.dart';
import '../theme/app_scenes.dart';

String? _storedPreference(Ref ref, String key) => ref
    .watch(preferencesProvider)
    .asData
    ?.value
    .where((preference) => preference.key == key)
    .firstOrNull
    ?.value;

// Keep the existing notifier interface for settings while restoring preferences
// at app scope. Authenticated AppShell is no longer needed to load appearance.
final darkModeProvider = StateProvider<bool>(
  (ref) => _storedPreference(ref, 'darkMode') != 'false',
);
final languageProvider = StateProvider<bool>(
  (ref) => _storedPreference(ref, 'languageEn') == 'true',
);

/// Stream-backed so a scene is restored for the sign-in screen as well as shell.
final appSceneProvider = Provider<AppScene>((ref) {
  return sceneFromId(_storedPreference(ref, 'appearance.scene'));
});

enum AppTab { tasks, timer, notes, social, more }
