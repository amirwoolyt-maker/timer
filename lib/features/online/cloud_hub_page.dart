// ignore_for_file: deprecated_member_use
import 'package:drift/drift.dart' hide Column;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/online/online_backend.dart';
import '../../data/repositories/providers.dart';
import 'account_page.dart';

/// Shared, authenticated spaces. Personal SQLite data is never uploaded silently.
class CloudHubPage extends ConsumerStatefulWidget {
  const CloudHubPage({this.mode = 'posts', this.parentId, super.key});
  final String mode;
  final String? parentId;
  @override
  ConsumerState<CloudHubPage> createState() => _CloudHubPageState();
}

class _CloudHubPageState extends ConsumerState<CloudHubPage> {
  final _body = TextEditingController();
  bool _busy = false;
  String? _error;
  String _group = 'general';
  String? get _parent =>
      widget.parentId ?? (widget.mode == 'messages' ? _group : '');
  CloudFeed get _feed => (collection: widget.mode, parentId: _parent);
  String get _title => switch (widget.mode) {
    'messages' => 'گفت‌وگوی آنلاین',
    'rooms' => 'اتاق‌های مشترک',
    'scores' => 'مطالعهٔ همراهان',
    'comments' => 'پاسخ‌ها و پسندها',
    _ => 'همراهان آنلاین',
  };
  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _act(
    Future<void> Function(OnlineBackend, CloudUser) action,
  ) async {
    if (_busy) return;
    final backend = ref.read(onlineBackendProvider),
        user = ref.read(cloudUserProvider).asData?.value;
    if (backend == null || user == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(backend, user);
    } catch (error) {
      if (mounted) setState(() => _error = onlineError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final text = _body.text.trim();
    if (text.isEmpty) return;
    await _act((backend, user) async {
      await backend.write(widget.mode, user, text, parentId: _parent ?? '');
      if (mounted) _body.clear();
    });
  }

  Future<void> _shareScore() => _act((backend, user) async {
    final db = ref.read(databaseProvider);
    final start = DateTime.now().subtract(const Duration(days: 7));
    final sessions = await (db.select(
      db.studySessions,
    )..where((s) => s.startedAt.isBiggerOrEqualValue(start))).get();
    final minutes = sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    await backend.write('scores', user, '$minutes', id: user.id);
  });
  void _open(String mode, {String? parentId, String? title}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title ?? _title)),
            body: CloudHubPage(mode: mode, parentId: parentId),
          ),
        ),
      );
  Widget _accountButton() => OutlinedButton.icon(
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('حساب کاربری')),
          body: const AccountPage(),
        ),
      ),
    ),
    icon: const Icon(Icons.person_outline),
    label: const Text('حساب و ورود ایمیلی'),
  );
  @override
  Widget build(BuildContext context) {
    if (ref.watch(onlineBackendProvider) == null) {
      return const OnlineSetupNotice();
    }
    return ref
        .watch(cloudUserProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(onlineError(error)),
                  TextButton(
                    onPressed: () => ref.invalidate(cloudUserProvider),
                    child: const Text('تلاش دوباره'),
                  ),
                  _accountButton(),
                ],
              ),
            ),
          ),
          data: (user) {
            if (user == null) return const AccountPage();
            final rows = ref.watch(cloudFeedProvider(_feed));
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(cloudFeedProvider(_feed));
                try {
                  await ref.read(cloudFeedProvider(_feed).future);
                } catch (error) {
                  if (mounted) setState(() => _error = onlineError(error));
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF103B32), Color(0xFF1E2449)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.hub_outlined,
                          size: 30,
                          color: Color(0xFF8EECC7),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 23,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'فضای مشترک کاربران واردشده • تازه‌ترین ۵۰ مورد',
                          style: TextStyle(
                            color: Color(0xFFCCDDD9),
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.mode == 'posts')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('گفت‌وگو'),
                          avatar: const Icon(Icons.forum_outlined, size: 18),
                          onPressed: () => _open('messages', title: 'گفت‌وگو'),
                        ),
                        ActionChip(
                          label: const Text('اتاق‌ها'),
                          avatar: const Icon(Icons.groups_outlined, size: 18),
                          onPressed: () =>
                              _open('rooms', title: 'اتاق‌های مطالعه'),
                        ),
                        ActionChip(
                          label: const Text('مطالعهٔ همراهان'),
                          avatar: const Icon(
                            Icons.emoji_events_outlined,
                            size: 18,
                          ),
                          onPressed: () =>
                              _open('scores', title: 'مطالعهٔ همراهان'),
                        ),
                      ],
                    ),
                  if (widget.mode == 'messages' && widget.parentId == null)
                    DropdownButtonFormField<String>(
                      initialValue: _group,
                      decoration: const InputDecoration(
                        labelText: 'گروه مشترک',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'general',
                          child: Text('عمومی'),
                        ),
                        DropdownMenuItem(value: 'math', child: Text('ریاضی')),
                        DropdownMenuItem(
                          value: 'science',
                          child: Text('تجربی'),
                        ),
                        DropdownMenuItem(
                          value: 'humanities',
                          child: Text('انسانی'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _group = value;
                            _error = null;
                          });
                        }
                      },
                    ),
                  if (widget.mode == 'comments' && widget.parentId != null)
                    _likes(user),
                  if (widget.mode == 'messages' && widget.parentId != null)
                    _members(user),
                  const SizedBox(height: 12),
                  if (widget.mode == 'scores') ...[
                    const Text(
                      'اشتراک‌گذاری اختیاری مجموع دقیقه‌های هفت روز اخیر. این اعداد خوداظهاری‌اند و رتبه‌بندی رسمی یا ضدتقلب نیستند.',
                      style: TextStyle(height: 1.9),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _shareScore,
                      icon: const Icon(Icons.publish),
                      label: const Text('انتشار / به‌روزرسانی زمان مطالعهٔ من'),
                    ),
                  ] else ...[
                    TextField(
                      key: const Key('cloud-compose'),
                      controller: _body,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: widget.mode == 'rooms' ? 200 : 2000,
                      decoration: InputDecoration(
                        labelText: widget.mode == 'rooms'
                            ? 'نام و موضوع اتاق'
                            : widget.mode == 'posts'
                            ? 'تجربهٔ مطالعه‌ات را به اشتراک بگذار'
                            : 'پیام تو',
                        alignLabelWithHint: true,
                      ),
                    ),
                    FilledButton.icon(
                      key: const Key('cloud-send'),
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        widget.mode == 'rooms'
                            ? 'ساخت اتاق مشترک'
                            : 'ارسال آنلاین',
                      ),
                    ),
                  ],
                  if (_busy) const LinearProgressIndicator(),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  const SizedBox(height: 18),
                  rows.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Column(
                      children: [
                        Text(onlineError(error)),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(cloudFeedProvider(_feed)),
                          child: const Text('بارگذاری دوباره'),
                        ),
                      ],
                    ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(26),
                          child: Text(
                            'هنوز چیزی منتشر نشده؛ اولین نفر باش.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      final sorted = [...entries];
                      if (widget.mode == 'scores') {
                        sorted.sort(
                          (a, b) => (int.tryParse(b.body) ?? 0).compareTo(
                            int.tryParse(a.body) ?? 0,
                          ),
                        );
                      }
                      return Column(
                        children: sorted
                            .map((entry) => _entry(entry, user))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _accountButton(),
                ],
              ),
            );
          },
        );
  }

  Widget _entry(CloudEntry entry, CloudUser user) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.emerald.withValues(alpha: .15),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (entry.ownerId == user.id)
                IconButton(
                  tooltip: 'حذف مورد من',
                  onPressed: _busy
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('این مورد حذف شود؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('انصراف'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            await _act(
                              (backend, _) =>
                                  backend.remove(widget.mode, entry.id),
                            );
                          }
                        },
                  icon: const Icon(Icons.delete_outline, size: 19),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            widget.mode == 'scores'
                ? '${entry.body} دقیقه مطالعه در هفت روز اخیر'
                : entry.body,
            style: const TextStyle(height: 1.9),
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.createdAt.toLocal().year}/${entry.createdAt.toLocal().month}/${entry.createdAt.toLocal().day}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          if (widget.mode == 'posts')
            TextButton.icon(
              onPressed: () =>
                  _open('comments', parentId: entry.id, title: 'گفت‌وگوی پست'),
              icon: const Icon(Icons.chat_bubble_outline, size: 17),
              label: const Text('پاسخ و پسندها'),
            ),
          if (widget.mode == 'rooms')
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      await _act(
                        (backend, user) => backend.write(
                          'members',
                          user,
                          '',
                          parentId: entry.id,
                          id: const Uuid().v5(
                            Namespace.oid.value,
                            '${user.id}:${entry.id}',
                          ),
                        ),
                      );
                      if (mounted && _error == null) {
                        _open(
                          'messages',
                          parentId: entry.id,
                          title: entry.body,
                        );
                      }
                    },
              icon: const Icon(Icons.login),
              label: const Text('عضویت و ورود به گفت‌وگوی اتاق'),
            ),
        ],
      ),
    ),
  );
  Widget _likes(CloudUser user) {
    final feed = (collection: 'likes', parentId: widget.parentId);
    final likes = ref.watch(cloudFeedProvider(feed)).asData?.value ?? [];
    final mine = likes.where((entry) => entry.ownerId == user.id).firstOrNull;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _act(
                  (backend, user) => mine != null
                      ? backend.remove('likes', mine.id)
                      : backend.write(
                          'likes',
                          user,
                          '',
                          parentId: widget.parentId!,
                          id: const Uuid().v5(
                            Namespace.oid.value,
                            '${user.id}:${widget.parentId}',
                          ),
                        ),
                ),
          icon: Icon(
            mine == null ? Icons.favorite_border : Icons.favorite,
            color: AppColors.red,
          ),
          label: Text(mine == null ? 'پسندیدن' : 'لغو پسند'),
        ),
        Text('${likes.length} پسند در موارد بارگذاری‌شده'),
      ],
    );
  }

  Widget _members(CloudUser user) {
    final feed = (collection: 'members', parentId: widget.parentId);
    return ref
        .watch(cloudFeedProvider(feed))
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(onlineError(error)),
          data: (members) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اعضای ثبت‌شده: ${members.map((m) => m.name).join('، ')}',
                style: const TextStyle(fontSize: 12, height: 1.8),
              ),
              const Text(
                'عضویت به معنی حضور آنلاین در همین لحظه نیست.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        await _act(
                          (backend, user) => backend.remove(
                            'members',
                            const Uuid().v5(
                              Namespace.oid.value,
                              '${user.id}:${widget.parentId}',
                            ),
                          ),
                        );
                        if (mounted && _error == null) Navigator.pop(context);
                      },
                child: const Text('لغو عضویت و خروج از اتاق'),
              ),
            ],
          ),
        );
  }
}
