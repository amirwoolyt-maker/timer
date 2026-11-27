// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_scenes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';

/// Can be pushed as a normal route from settings or the More page.
class AppearancePage extends ConsumerStatefulWidget {
  const AppearancePage({super.key});
  @override
  ConsumerState<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends ConsumerState<AppearancePage> {
  AppScene? _saving;
  Future<void> _select(AppScene scene) async {
    if (_saving != null) return;
    setState(() => _saving = scene);
    try {
      await ref
          .read(databaseProvider)
          .savePreference('appearance.scene', scene.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            ref.read(languageProvider)
                ? '${scene.titleEn} applied'
                : 'تم ${scene.title} فعال شد',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(languageProvider)
                  ? 'Could not save the theme. Try again.'
                  : 'ذخیرهٔ تم انجام نشد؛ دوباره امتحان کن.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(appSceneProvider);
    final dark = ref.watch(darkModeProvider);
    final english = ref.watch(languageProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(english ? 'Your atmosphere' : 'حال‌وهوای برنامه'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 730
              ? 3
              : (constraints.maxWidth >= 340 ? 2 : 1);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        english
                            ? 'A small world for your focus'
                            : 'یک دنیای کوچک برای تمرکز تو',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        english
                            ? 'Each scene has its own illustrations. Your choice stays on this device. Light and dark modes work with every scene.'
                            : 'هر تم تصویرسازی مخصوص خودش را دارد. انتخابت روی این دستگاه ذخیره می‌شود و با حالت روشن و تیره کار می‌کند.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(english ? 'Dark mode' : 'حالت تیره'),
                        secondary: Icon(
                          dark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                        ),
                        value: dark,
                        onChanged: (value) async {
                          try {
                            await ref
                                .read(databaseProvider)
                                .savePreference('darkMode', '$value');
                            ref.read(darkModeProvider.notifier).state = value;
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    english
                                        ? 'Could not save this setting.'
                                        : 'تنظیم ذخیره نشد.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                sliver: SliverLayoutBuilder(
                  builder: (context, sliverConstraints) => SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent:
                          264 +
                          (MediaQuery.textScalerOf(context).scale(13) - 13)
                                  .clamp(0, 22) *
                              3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: AppScene.values.length,
                    itemBuilder: (context, index) {
                      final item = AppScene.values[index];
                      return SceneChoiceCard(
                        scene: item,
                        selected: scene == item,
                        dark: dark,
                        english: english,
                        busy: _saving == item,
                        onTap: _saving != null ? null : () => _select(item),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SceneChoiceCard extends StatelessWidget {
  const SceneChoiceCard({
    required this.scene,
    required this.selected,
    required this.dark,
    this.english = false,
    this.busy = false,
    this.onTap,
    super.key,
  });
  final AppScene scene;
  final bool selected, dark, english, busy;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final accent = dark ? scene.accent : scene.lightAccent;
    return Semantics(
      button: true,
      selected: selected,
      label: english ? scene.titleEn : scene.title,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? accent : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('scene-${scene.name}'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Theme(
                  data: buildAppTheme(dark: dark, scene: scene),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SceneBackground(
                          scene: scene,
                          dark: dark,
                          preview: true,
                          progress: .2,
                        ),
                      ),
                      PositionedDirectional(
                        top: 9,
                        end: 9,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: scene.surface(dark),
                            shape: BoxShape.circle,
                          ),
                          child: busy
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accent,
                                  ),
                                )
                              : Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : scene.icon,
                                  color: accent,
                                  size: 19,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      english ? scene.titleEn : scene.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: accent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      english ? scene.descriptionEn : scene.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
