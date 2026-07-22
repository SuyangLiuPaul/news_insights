import 'package:flutter/material.dart';

/// [Image.network] wrapper that automatically retries a couple of times
/// on failure. Bulk-loading many thumbnails at once (e.g. paging in a
/// whole archived day of headlines during infinite scroll) can trip
/// transient failures — browser per-host connection limits, a dropped
/// connection — that a plain [Image.network] never recovers from: once
/// its errorBuilder fires, that widget instance shows the placeholder
/// forever. Evicting the URL from the image cache before each retry
/// ensures a genuinely fresh fetch rather than replaying the same
/// failed attempt.
class RetryNetworkImage extends StatefulWidget {
  const RetryNetworkImage({
    super.key,
    required this.url,
    required this.fit,
    required this.placeholderBuilder,
    this.maxRetries = 2,
  });

  final String url;
  final BoxFit fit;
  final WidgetBuilder placeholderBuilder;
  final int maxRetries;

  @override
  State<RetryNetworkImage> createState() => _RetryNetworkImageState();
}

class _RetryNetworkImageState extends State<RetryNetworkImage> {
  int _attempt = 0;
  bool _retryScheduled = false;

  void _scheduleRetry() {
    if (_retryScheduled || _attempt >= widget.maxRetries) return;
    _retryScheduled = true;
    Future.delayed(Duration(milliseconds: 600 * (_attempt + 1)), () {
      if (!mounted) return;
      PaintingBinding.instance.imageCache.evict(NetworkImage(widget.url));
      setState(() {
        _attempt++;
        _retryScheduled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.url,
      key: ValueKey('${widget.url}#$_attempt'),
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        _scheduleRetry();
        return widget.placeholderBuilder(context);
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return widget.placeholderBuilder(context);
      },
    );
  }
}
