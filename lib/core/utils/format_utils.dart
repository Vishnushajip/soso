import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static String compactNumber(num value) => NumberFormat.compact().format(value);

  static String relativeTime(DateTime? when) {
    if (when == null) return '—';
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 30) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(when);
  }

  static String winRatePct(int wins, int matches) {
    if (matches <= 0) return '0%';
    return '${(wins / matches * 100).toStringAsFixed(0)}%';
  }
}
