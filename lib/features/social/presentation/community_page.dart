part of '../../feature_pages.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});
  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (controller.text.trim().isEmpty) return;
    final db = ref.read(databaseProvider);
    await db
        .into(db.socialPosts)
        .insert(
          SocialPostsCompanion.insert(
            id: const Uuid().v4(),
            author: 'شما',
            body: controller.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
    controller.clear();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'امروز چه چیزی پیش بردی؟',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'یک تجربه کوتاه با همراهانت به اشتراک بگذار...',
                ),
              ),
              const SizedBox(height: 9),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _publish,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('انتشار'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: const Color(0xFF061B13),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('گفت‌وگوی امروز'),
        ref
            .watch(postsProvider)
            .when(
              data: (posts) => posts.isEmpty
                  ? const EmptyState(
                      icon: Icons.groups_2_outlined,
                      title: 'هنوز پستی نیست',
                      subtitle: 'اولین قدم را تو بردار.',
                      action: 'نوشتن پست',
                      onTap: _noop,
                    )
                  : Column(
                      children: posts
                          .map(
                            (post) => InfoTile(
                              icon: Icons.person_outline_rounded,
                              title: post.author,
                              subtitle: post.body,
                              color: AppColors.emerald,
                            ),
                          )
                          .toList(),
                    ),
              error: (error, _) => Text('$error'),
              loading: () =>
                  const LinearProgressIndicator(color: AppColors.emerald),
            ),
      ],
    ),
  );
  static void _noop() {}
}
