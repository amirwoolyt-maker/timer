part of '../../feature_pages.dart';

class UniversityDirectoryPage extends ConsumerStatefulWidget {
  const UniversityDirectoryPage({super.key});
  @override
  ConsumerState<UniversityDirectoryPage> createState() =>
      _UniversityDirectoryPageState();
}

class _UniversityDirectoryPageState
    extends ConsumerState<UniversityDirectoryPage> {
  String _query = '';
  bool _favoritesOnly = false;
  int _visibleCount = 20;

  Set<String> _favoriteIds(List<Map<String, dynamic>> favorites) => {
    for (final favorite in favorites)
      if (favorite['id'] is String)
        favorite['id'] as String
      else if (legacyUniversityFavorites[favorite['rank']] != null)
        legacyUniversityFavorites[favorite['rank']]!,
  };

  @override
  Widget build(BuildContext context) {
    final english = ref.watch(languageProvider);
    final favoriteIds = _favoriteIds(_toolRecords(ref, 'tools.universities'));
    final rows = iranUniversities
        .where(
          (university) =>
              university.matches(_query) &&
              (!_favoritesOnly || favoriteIds.contains(university.id)),
        )
        .toList();
    final primary = Theme.of(context).colorScheme.primary;
    return _ToolLoading(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToolHeading(
              english ? '100 universities in Iran' : '۱۰۰ دانشگاه ایران',
              english
                  ? 'EduRank 2026 overall ranking • updated March 15, 2026. Based on research, non-academic prominence and alumni influence. This is not an official admissions or subject ranking.'
                  : 'رتبه‌بندی کلی EduRank سال ۲۰۲۶؛ به‌روزرسانی ۱۵ مارس ۲۰۲۶. بر پایهٔ پژوهش، شناخته‌شدن خارج از دانشگاه و اثرگذاری دانش‌آموختگان؛ این ترتیب، رتبه‌بندی رسمی پذیرش یا رشتهٔ خاص نیست.',
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      _toolOpenUrl(context, universityRankingSource),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(english ? 'Ranking source' : 'منبع رتبه‌بندی'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _toolOpenUrl(context, universityRankingMethodology),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(english ? 'Methodology' : 'معیار رتبه‌بندی'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('university-search'),
              onChanged: (value) => setState(() {
                _query = value;
                _visibleCount = 20;
              }),
              decoration: InputDecoration(
                hintText: english
                    ? 'University, city or field'
                    : 'نام فارسی یا انگلیسی، شهر یا حوزه',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  key: const Key('university-favorites'),
                  avatar: const Icon(Icons.favorite_outline, size: 17),
                  label: Text(english ? 'Favorites' : 'علاقه‌مندی‌ها'),
                  selected: _favoritesOnly,
                  onSelected: (value) => setState(() {
                    _favoritesOnly = value;
                    _visibleCount = 20;
                  }),
                ),
                Text(
                  english
                      ? '${rows.length} of 100 universities'
                      : '${faDigits(rows.length)} دانشگاه از ۱۰۰',
                  key: const Key('university-count'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...rows.take(_visibleCount).map((university) {
              final selected = favoriteIds.contains(university.id);
              return _ToolPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primary.withValues(alpha: .12),
                          foregroundColor: primary,
                          child: Text(
                            english
                                ? '${university.rank}'
                                : faDigits(university.rank),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            english ? university.englishName : university.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          key: ValueKey('university-favorite-${university.id}'),
                          tooltip: english ? 'Favorite' : 'علاقه‌مندی',
                          onPressed: () async {
                            final next = {...favoriteIds};
                            selected
                                ? next.remove(university.id)
                                : next.add(university.id);
                            await _saveToolRecords(ref, 'tools.universities', [
                              for (final id in next) {'id': id},
                            ]);
                          },
                          icon: Icon(
                            selected ? Icons.favorite : Icons.favorite_border,
                            color: AppColors.red,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '${university.city} · ${university.category}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      english
                          ? 'Iran rank #${university.rank} · EduRank 2026'
                          : 'رتبهٔ ${faDigits(university.rank)} ایران در EduRank ۲۰۲۶',
                      style: const TextStyle(fontSize: 12, height: 1.8),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: () =>
                            _toolOpenUrl(context, university.sourceUrl),
                        icon: const Icon(Icons.open_in_new, size: 15),
                        label: Text(
                          english ? 'Details in source' : 'جزئیات در منبع',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (rows.length > _visibleCount)
              Center(
                child: OutlinedButton.icon(
                  key: const Key('university-load-more'),
                  onPressed: () => setState(() => _visibleCount += 20),
                  icon: const Icon(Icons.expand_more),
                  label: Text(
                    english ? 'Show next 20' : 'نمایش ۲۰ دانشگاه بعدی',
                  ),
                ),
              ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  english
                      ? (_favoritesOnly
                            ? 'No favorites match this search.'
                            : 'No university found.')
                      : (_favoritesOnly
                            ? 'علاقه‌مندی مطابق جست‌وجو پیدا نشد.'
                            : 'دانشگاهی پیدا نشد.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
