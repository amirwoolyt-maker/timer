import 'package:flutter_riverpod/legacy.dart';

final darkModeProvider = StateProvider<bool>((ref) => true);
final languageProvider = StateProvider<bool>((ref) => false);

enum AppTab { tasks, timer, notes, social, more }
