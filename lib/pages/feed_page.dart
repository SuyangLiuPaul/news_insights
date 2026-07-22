import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:news_insights/models/app_settings.dart';
import 'package:news_insights/models/news_article.dart';
import 'package:news_insights/pages/article_detail_page.dart';
import 'package:news_insights/services/news_service.dart';
import 'package:news_insights/theme/ui_strings.dart';
import 'package:news_insights/utils/relative_time.dart';
import 'package:news_insights/widgets/article_card.dart';

/// Wide-layout breakpoint — mirrors the master-detail pattern the
/// original in-app News reader used (list left, detail right) rather
/// than reinventing a new one.
const double kWideBreakpoint = 880;

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  DailyNewsBundle? _bundle;
  NewsArticle? _selected;
  String _sectionFilter = 'all';
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await NewsService.load();
      if (!mounted) return;
      setState(() {
        _bundle = b;
        _error = null;
        _selected ??= b.allArticles.isNotEmpty ? b.allArticles.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _manualRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await NewsService.refresh(force: true);
      final b = await NewsService.load();
      if (!mounted) return;
      setState(() {
        _bundle = b;
        _error = null;
        final keepSelected = _selected != null &&
            b.allArticles.any((a) => a.id == _selected!.id);
        if (!keepSelected) {
          _selected = b.allArticles.isNotEmpty ? b.allArticles.first : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  List<NewsArticle> get _filtered {
    final all = _bundle?.allArticles ?? const [];
    if (_sectionFilter == 'all') return all;
    return all.where((a) => a.section == _sectionFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final locale = settings.locale;
    final wide = MediaQuery.of(context).size.width >= kWideBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(uiStrings['appName']?[locale] ?? 'News Insights'),
        actions: [
          TextButton(
            onPressed: settings.toggleLocale,
            child: Text(
              locale == 'en' ? '中文' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: uiStrings['refresh']?[locale] ?? 'Refresh',
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_outlined),
            onPressed: _refreshing ? null : _manualRefresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, locale, wide),
    );
  }

  Widget _buildBody(BuildContext context, String locale, bool wide) {
    if (_bundle == null) {
      return Center(
        child: _error != null
            ? _ErrorState(error: _error!, locale: locale, onRetry: _load)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(uiStrings['loading']?[locale] ?? 'Loading…'),
                ],
              ),
      );
    }

    final articles = _filtered;

    return Column(
      children: [
        _Masthead(bundle: _bundle!, locale: locale),
        _SectionFilterBar(
          value: _sectionFilter,
          locale: locale,
          onChanged: (v) => setState(() => _sectionFilter = v),
        ),
        const Divider(height: 1),
        Expanded(
          child: articles.isEmpty
              ? Center(
                  child: Text(uiStrings['emptyTitle']?[locale] ?? 'No stories'),
                )
              : (wide
                  ? _buildTwoColumn(context, articles, locale)
                  : _buildSingleColumn(context, articles, locale)),
        ),
      ],
    );
  }

  Widget _buildSingleColumn(
      BuildContext context, List<NewsArticle> articles, String locale) {
    return RefreshIndicator(
      onRefresh: _manualRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: articles.length,
        itemBuilder: (context, i) {
          final a = articles[i];
          return ArticleCard(
            article: a,
            locale: locale,
            selected: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ArticleDetailPage(article: a, locale: locale),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTwoColumn(
      BuildContext context, List<NewsArticle> articles, String locale) {
    final selected = _selected != null &&
            articles.any((a) => a.id == _selected!.id)
        ? _selected
        : (articles.isNotEmpty ? articles.first : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 420,
          child: RefreshIndicator(
            onRefresh: _manualRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: articles.length,
              itemBuilder: (context, i) {
                final a = articles[i];
                return ArticleCard(
                  article: a,
                  locale: locale,
                  selected: selected?.id == a.id,
                  onTap: () => setState(() => _selected = a),
                );
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? Center(
                  child: Text(
                      uiStrings['selectAStory']?[locale] ?? 'Select a story'),
                )
              : ArticleDetailPage(
                  key: ValueKey(selected.id),
                  article: selected,
                  locale: locale,
                  embedded: true,
                ),
        ),
      ],
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.bundle, required this.locale});
  final DailyNewsBundle bundle;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final updated = relativeTime(bundle.generatedAt, locale);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              uiStrings['tagline']?[locale] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (updated.isNotEmpty)
            Text(
              (uiStrings['lastUpdated']?[locale] ?? 'Updated {time}')
                  .replaceFirst('{time}', updated),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _SectionFilterBar extends StatelessWidget {
  const _SectionFilterBar({
    required this.value,
    required this.locale,
    required this.onChanged,
  });
  final String value;
  final String locale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <(String, String)>[
      ('all', uiStrings['sectionAll']?[locale] ?? 'All'),
      ('world', uiStrings['sectionWorld']?[locale] ?? 'World'),
      ('china', uiStrings['sectionChina']?[locale] ?? 'China'),
      ('australia', uiStrings['sectionAustralia']?[locale] ?? 'Australia'),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label) = options[i];
          final selected = value == id;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onChanged(id),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.locale,
    required this.onRetry,
  });
  final String error;
  final String locale;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            uiStrings['errorTitle']?[locale] ?? "Couldn't load news",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            uiStrings['errorBody']?[locale] ?? '',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(uiStrings['retry']?[locale] ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}
