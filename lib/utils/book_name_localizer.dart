// yswords-data's verse.reference is always an English book name
// ("Matthew 5:9", "1 Corinthians 13:4-7") regardless of locale — there
// is no referenceZh field in the pipeline output. This app only ever
// shows one Chinese rendering (Simplified; see AppSettings — no
// Traditional/version selection here), so it needs just the forward
// English->Chinese book-name table, ported from yswords'
// lib/constants/book_name_mapping.dart (englishToChinese), rather than
// pulling in that file's fuller alias/Traditional/version-detection
// machinery which this app has no use for.
const Map<String, String> _englishToChinese = {
  'Genesis': '创世纪',
  'Exodus': '出埃及记',
  'Leviticus': '利未记',
  'Numbers': '民数记',
  'Deuteronomy': '申命记',
  'Joshua': '约书亚记',
  'Judges': '士师记',
  'Ruth': '路得记',
  '1 Samuel': '撒母耳记上',
  '2 Samuel': '撒母耳记下',
  '1 Kings': '列王纪上',
  '2 Kings': '列王纪下',
  '1 Chronicles': '历代志上',
  '2 Chronicles': '历代志下',
  'Ezra': '以斯拉记',
  'Nehemiah': '尼希米记',
  'Esther': '以斯帖记',
  'Job': '约伯记',
  'Psalms': '诗篇',
  'Psalm': '诗篇', // yswords-data's corpus uses the singular form.
  'Proverbs': '箴言',
  'Ecclesiastes': '传道书',
  'Song of Solomon': '雅歌',
  'Song of Songs': '雅歌',
  'Isaiah': '以赛亚书',
  'Jeremiah': '耶利米书',
  'Lamentations': '耶利米哀歌',
  'Ezekiel': '以西结书',
  'Daniel': '但以理书',
  'Hosea': '何西阿书',
  'Joel': '约珥书',
  'Amos': '阿摩司书',
  'Obadiah': '俄巴底亚书',
  'Jonah': '约拿书',
  'Micah': '弥迦书',
  'Nahum': '那鸿书',
  'Habakkuk': '哈巴谷书',
  'Zephaniah': '西番雅书',
  'Haggai': '哈该书',
  'Zechariah': '撒迦利亚书',
  'Malachi': '玛拉基书',
  'Matthew': '马太福音',
  'Mark': '马可福音',
  'Luke': '路加福音',
  'John': '约翰福音',
  'Acts': '使徒行传',
  'Romans': '罗马书',
  '1 Corinthians': '哥林多前书',
  '2 Corinthians': '哥林多后书',
  'Galatians': '加拉太书',
  'Ephesians': '以弗所书',
  'Philippians': '腓立比书',
  'Colossians': '歌罗西书',
  '1 Thessalonians': '帖撒罗尼迦前书',
  '2 Thessalonians': '帖撒罗尼迦后书',
  '1 Timothy': '提摩太前书',
  '2 Timothy': '提摩太后书',
  'Titus': '提多书',
  'Philemon': '腓利门书',
  'Hebrews': '希伯来书',
  'James': '雅各书',
  '1 Peter': '彼得前书',
  '2 Peter': '彼得后书',
  '1 John': '约翰一书',
  '2 John': '约翰二书',
  '3 John': '约翰三书',
  'Jude': '犹大书',
  'Revelation': '启示录',
};

/// Splits "1 Corinthians 13:4-7" into book name ("1 Corinthians") and
/// the chapter/verse remainder ("13:4-7"). The optional numeral
/// prefix ([1-3]) has to be matched separately from the lazy
/// letters-and-spaces group, since a bare `[A-Za-z\s]+?` can't consume
/// a leading digit itself — without it "1 Kings 2:1" would only ever
/// split as book="1" (the whole `[1-3]` alternative failing to attach
/// to the rest of the name).
final RegExp _refPattern = RegExp(r'^((?:[1-3]\s)?[A-Za-z][A-Za-z\s]*?)\s+(\d.*)$');

/// Renders a yswords-data verse reference in the reader's locale.
/// Non-Chinese locales (and any reference this app doesn't recognize
/// the book name for) pass through unchanged.
String localizeVerseReference(String reference, String locale) {
  if (!locale.startsWith('zh') || reference.isEmpty) return reference;
  final match = _refPattern.firstMatch(reference);
  if (match == null) return reference;
  final book = match.group(1)!;
  final rest = match.group(2)!;
  final zhBook = _englishToChinese[book];
  if (zhBook == null) return reference;
  return '$zhBook $rest';
}
