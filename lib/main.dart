// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/providers.dart';
import 'features/feature_pages.dart';

void main() => runApp(const ProviderScope(child: RahyarApp()));

class RahyarApp extends ConsumerWidget {
  const RahyarApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'راهیار',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(dark: ref.watch(darkModeProvider)),
    home: const AppShell(),
    builder: (context, child) => Directionality(
      textDirection: ref.watch(languageProvider)
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin {
  AppTab selected = AppTab.tasks;
  String? feature;
  late final AnimationController glow;

  @override
  void initState() {
    super.initState();
    glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final db = ref.read(databaseProvider);
    final saved = await db.select(db.appPreferences).get();
    if (!mounted) return;
    for (final preference in saved) {
      if (preference.key == 'darkMode') {
        ref.read(darkModeProvider.notifier).state = preference.value == 'true';
      } else if (preference.key == 'languageEn') {
        ref.read(languageProvider.notifier).state = preference.value == 'true';
      }
    }
  }

  @override
  void dispose() {
    glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = feature != null
        ? FeaturePage(feature: feature!)
        : switch (selected) {
            AppTab.tasks => const TasksPage(),
            AppTab.timer => const StudyTimerPage(),
            AppTab.notes => const NotesPage(),
            AppTab.social => const CommunityPage(),
            AppTab.more => MoreGrid(
              onSelect: (value) => setState(() => feature = value),
            ),
          };
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: glow,
              builder: (context, _) => CosmicGlow(glow.value),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: Row(
                        children: [
                          if (feature == null)
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.emerald,
                              ),
                            )
                          else
                            IconButton(
                              onPressed: () => setState(() => feature = null),
                              icon: const Icon(Icons.arrow_forward_rounded),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature == null
                                  ? (ref.watch(languageProvider)
                                        ? 'Rahyar'
                                        : 'راهیار')
                                  : (ref.watch(languageProvider)
                                            ? featureTitlesEn[feature]
                                            : featureTitles[feature]) ??
                                        'بیشتر',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _settings(context),
                            icon: const Icon(Icons.tune_rounded, size: 21),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: page),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AppNavigation(
              selected: selected,
              onSelect: (value) => setState(() {
                selected = value;
                feature = null;
              }),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _settings(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تنظیمات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SwitchListTile.adaptive(
              value: ref.watch(darkModeProvider),
              onChanged: (value) async {
                await ref
                    .read(databaseProvider)
                    .savePreference('darkMode', '$value');
                ref.read(darkModeProvider.notifier).state = value;
              },
              title: const Text('تم تیره کهکشانی'),
              secondary: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.emerald,
              ),
            ),
            SwitchListTile.adaptive(
              value: ref.watch(languageProvider),
              onChanged: (value) async {
                await ref
                    .read(databaseProvider)
                    .savePreference('languageEn', '$value');
                ref.read(languageProvider.notifier).state = value;
              },
              title: const Text('رابط انگلیسی'),
              secondary: const Icon(
                Icons.translate_rounded,
                color: AppColors.emerald,
              ),
            ),
            const ListTile(
              leading: Icon(Icons.storage_rounded, color: AppColors.emerald),
              title: Text('ذخیره‌سازی آفلاین'),
              subtitle: Text('پایگاه داده SQLite محلی'),
            ),
          ],
        ),
      ),
    ),
  );
}

class CosmicGlow extends StatelessWidget {
  const CosmicGlow(this.progress, {super.key});
  final double progress;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GlowPainter(progress));
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    final center = Offset(size.width * .8, size.height * .1);
    canvas.drawCircle(
      center,
      size.width * .75,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppColors.emerald.withValues(alpha: .06 + progress * .04),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * .75),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
