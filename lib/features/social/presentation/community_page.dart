part of '../../feature_pages.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});
  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final controller = TextEditingController();
  final _focus = FocusNode();
  bool _publishing = false;
  @override
  void dispose() {
    controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = controller.text.trim();
    if (text.isEmpty || _publishing) {
      _focus.requestFocus();
      return;
    }
    if (text.length > 2000) {
      _toolNotice(context, 'متن پست باید کمتر از ۲۰۰۰ نویسه باشد.');
      return;
    }
    setState(() => _publishing = true);
    try {
      final prefs = ref
          .read(preferencesProvider)
          .maybeWhen(
            data: (rows) => rows,
            orElse: () => const <AppPreference>[],
          );
      final name =
          prefs.where((p) => p.key == 'profile.name').firstOrNull?.value ??
          'شما';
      final db = ref.read(databaseProvider);
      await db
          .into(db.socialPosts)
          .insert(
            SocialPostsCompanion.insert(
              id: const Uuid().v4(),
              author: name,
              body: text,
              createdAt: DateTime.now(),
            ),
          );
      controller.clear();
      if (mounted) _toolNotice(context, 'پست روی دستگاه ذخیره شد.');
    } catch (_) {
      if (mounted) _toolNotice(context, 'ذخیره پست ممکن نشد. دوباره تلاش کن.');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _open(String feature) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(featureTitles[feature] ?? 'همراهان')),
        body: FeaturePage(feature: feature),
      ),
    ),
  );

  Future<void> _comment(SocialPost post) async {
    final result = await _toolForm(
      context,
      title: 'پاسخ به ${post.author}',
      fields: [('body', 'پاسخ تو')],
      multiline: {'body'},
    );
    if (result == null || !mounted) return;
    final rows = _toolRecords(ref, 'tools.postComments', listen: false);
    await _saveToolRecords(ref, 'tools.postComments', [
      ...rows,
      {
        'id': const Uuid().v4(),
        'postId': post.id,
        'body': result['body'],
        'createdAt': DateTime.now().toIso8601String(),
      },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(onlineConfigProvider).enabled) return const CloudHubPage();
    final english = ref.watch(languageProvider);
    final likes = _toolRecords(ref, 'tools.postLikes');
    final comments = _toolRecords(ref, 'tools.postComments');
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToolHeading(
            english ? 'Together, one step further' : 'کنار هم، یک قدم جلوتر',
            english
                ? 'Save your study experiences and organize your community spaces.'
                : 'تجربه‌های مطالعه‌ات را بنویس و مسیرت را مرور کن.',
          ),
          Row(
            children: [
              Expanded(
                child: _SocialShortcut(
                  icon: Icons.emoji_events_outlined,
                  title: english ? 'Study league' : 'لیگ مطالعه',
                  onTap: () => _open('league'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SocialShortcut(
                  icon: Icons.groups_outlined,
                  title: english ? 'Study rooms' : 'اتاق مطالعه',
                  onTap: () => _open('studyRoom'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SocialShortcut(
                  icon: Icons.forum_outlined,
                  title: english ? 'Groups' : 'گفت‌وگو',
                  onTap: () => _open('chat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ToolPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  english
                      ? 'What did you learn today?'
                      : 'امروز چه چیزی یاد گرفتی؟',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  focusNode: _focus,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: english
                        ? 'A small discovery or a useful study tip...'
                        : 'یک تجربه کوتاه یا نکتهٔ مفید برای روزهای بعد...',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.icon(
                    onPressed: _publishing ? null : _publish,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _publishing
                          ? (english ? 'Saving...' : 'در حال ذخیره...')
                          : (english ? 'Save post' : 'ثبت پست'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          InfoTile(
            icon: Icons.cloud_off_outlined,
            title: english
                ? 'Your local community notebook'
                : 'دفتر اجتماعی روی دستگاه',
            subtitle: english
                ? 'Posts, likes and comments currently stay on this device. They are not sent to other people.'
                : 'پست‌ها، پسندها و پاسخ‌ها روی همین دستگاه ذخیره می‌شوند و هنوز برای دیگران ارسال نمی‌شوند.',
            color: AppColors.blue,
          ),
          SectionTitle(english ? 'Your posts' : 'نوشته‌های تو'),
          ref
              .watch(postsProvider)
              .when(
                loading: () =>
                    const LinearProgressIndicator(color: AppColors.emerald),
                error: (_, _) => Text(
                  english
                      ? 'Posts could not be loaded.'
                      : 'خواندن نوشته‌ها ممکن نشد.',
                ),
                data: (items) {
                  final posts = [...items]
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  if (posts.isEmpty) {
                    return EmptyState(
                      icon: Icons.groups_2_outlined,
                      title: english ? 'Your first post' : 'اولین نوشته‌ات',
                      subtitle: english
                          ? 'Write one useful thing you learned today.'
                          : 'یک چیز مفید که امروز یاد گرفتی را بنویس.',
                      action: english ? 'Write a post' : 'نوشتن پست',
                      onTap: () => _focus.requestFocus(),
                    );
                  }
                  return Column(
                    children: posts.map((post) {
                      final liked = likes.any(
                        (row) => row['postId'] == post.id,
                      );
                      final replies = comments
                          .where((row) => row['postId'] == post.id)
                          .toList();
                      return _ToolPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.emerald.withValues(
                                    alpha: .14,
                                  ),
                                  child: Text(
                                    post.author.isEmpty
                                        ? '؟'
                                        : post.author.characters.first,
                                    style: const TextStyle(
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.author,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '${formatJalali(post.createdAt)} · ${formatClock(post.createdAt)}',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: english ? 'Delete post' : 'حذف پست',
                                  onPressed: () async {
                                    if (!await _toolConfirm(
                                      context,
                                      'این پست و پاسخ‌هایش حذف شوند؟',
                                    )) {
                                      return;
                                    }
                                    final db = ref.read(databaseProvider);
                                    await db.transaction(() async {
                                      await (db.delete(
                                            db.socialPosts,
                                          )..where((r) => r.id.equals(post.id)))
                                          .go();
                                      await db.savePreference(
                                        'tools.postComments',
                                        jsonEncode(
                                          comments
                                              .where(
                                                (r) => r['postId'] != post.id,
                                              )
                                              .toList(),
                                        ),
                                      );
                                      await db.savePreference(
                                        'tools.postLikes',
                                        jsonEncode(
                                          likes
                                              .where(
                                                (r) => r['postId'] != post.id,
                                              )
                                              .toList(),
                                        ),
                                      );
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SelectableText(
                              post.body,
                              style: const TextStyle(fontSize: 13, height: 1.9),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final db = ref.read(databaseProvider);
                                    await db.transaction(() async {
                                      await db.savePreference(
                                        'tools.postLikes',
                                        jsonEncode(
                                          liked
                                              ? likes
                                                    .where(
                                                      (r) =>
                                                          r['postId'] !=
                                                          post.id,
                                                    )
                                                    .toList()
                                              : [
                                                  ...likes,
                                                  {'postId': post.id},
                                                ],
                                        ),
                                      );
                                      await (db.update(
                                            db.socialPosts,
                                          )..where((r) => r.id.equals(post.id)))
                                          .write(
                                            SocialPostsCompanion(
                                              likes: Value(
                                                (post.likes + (liked ? -1 : 1))
                                                    .clamp(0, 1000000),
                                              ),
                                            ),
                                          );
                                    });
                                  },
                                  icon: Icon(
                                    liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 17,
                                    color: liked
                                        ? AppColors.red
                                        : AppColors.muted,
                                  ),
                                  label: Text(faDigits(post.likes)),
                                ),
                                TextButton.icon(
                                  onPressed: () => _comment(post),
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                  ),
                                  label: Text(
                                    english
                                        ? 'Reply (${replies.length})'
                                        : 'پاسخ ${faDigits(replies.length)}',
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: english ? 'Copy post' : 'کپی متن',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: post.body),
                                    );
                                    _toolNotice(context, 'متن کپی شد.');
                                  },
                                  icon: const Icon(Icons.copy, size: 17),
                                ),
                              ],
                            ),
                            ...replies.map(
                              (reply) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(
                                    alpha: .06,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${reply['body']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.8,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'حذف پاسخ',
                                      onPressed: () => _saveToolRecords(
                                        ref,
                                        'tools.postComments',
                                        comments
                                            .where(
                                              (r) => r['id'] != reply['id'],
                                            )
                                            .toList(),
                                      ),
                                      icon: const Icon(Icons.close, size: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
        ],
      ),
    );
  }
}

class _SocialShortcut extends StatelessWidget {
  const _SocialShortcut({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.emerald, size: 23),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}
