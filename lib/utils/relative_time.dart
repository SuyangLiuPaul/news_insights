/// Compact "time ago" formatting, bilingual. Deliberately hand-rolled
/// rather than pulling in `intl` for this one need.
String relativeTime(DateTime? at, String locale) {
  if (at == null) return '';
  final isZh = locale.startsWith('zh');
  final diff = DateTime.now().toUtc().difference(at.toUtc());

  if (diff.inSeconds < 60) return isZh ? '刚刚' : 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return isZh ? '$m分钟前' : '${m}m ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return isZh ? '$h小时前' : '${h}h ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return isZh ? '$d天前' : '${d}d ago';
  }
  // Beyond a week: show an absolute short date.
  final local = at.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return isZh ? '${local.year}年$mm月$dd日' : '$mm/$dd/${local.year}';
}
