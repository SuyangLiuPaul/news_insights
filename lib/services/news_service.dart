import 'package:news_insights/models/news_article.dart';
import 'package:news_insights/services/remote_data_service.dart';

/// Loads the bilingual daily-news bundle that powers this whole app.
///
/// Source: the yswords-data central data repo
/// (`https://yswords-data.netlify.app/data/daily_news.json`) — a
/// CORS-enabled, hourly-refreshed feed that pairs world/china/
/// australia headlines with an AI-picked Bible verse + reflection.
/// This app is a dedicated reader for that feed; it does not run its
/// own scraping/AI pipeline.
///
/// Override at build time:
///   `--dart-define=DAILY_NEWS_URL=https://example/data/daily_news.json`
class _NewsServiceImpl extends RemoteDataService<DailyNewsBundle> {
  static const String _defaultRemote =
      'https://yswords-data.netlify.app/data/daily_news.json';

  static const String _envUrl = String.fromEnvironment(
    'DAILY_NEWS_URL',
    defaultValue: _defaultRemote,
  );

  @override
  String get bundledAssetPath => 'assets/daily_news.json';

  @override
  String get remoteUrl => _envUrl;

  @override
  String get cachePrefsKey => 'dailyNews.cachedJson.v1';

  @override
  DailyNewsBundle parse(Map<String, dynamic> json) =>
      DailyNewsBundle.fromJson(json);

  @override
  DateTime? generatedAt(DailyNewsBundle bundle) => bundle.generatedAt;
}

/// Public façade — keeps call sites (`NewsService.load()` /
/// `refresh()`) simple and independent of the underlying
/// [RemoteDataService] implementation.
class NewsService {
  static final _NewsServiceImpl _impl = _NewsServiceImpl();

  static Future<DailyNewsBundle> load() => _impl.load();
  static Future<void> refresh({bool force = false}) =>
      _impl.refresh(force: force);
  static Future<void> clearCache() => _impl.clearCache();
}
