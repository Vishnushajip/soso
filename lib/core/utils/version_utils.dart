/// Semantic-version comparison helpers used by the app-update system.
///
/// Tolerant of real-world version strings: ignores any build metadata after
/// `+` (e.g. `1.2.0+34`) and pre-release suffixes after `-` (e.g. `1.2.0-beta`),
/// and treats missing segments as `0` (so `1.2` == `1.2.0`).
class VersionUtils {
  VersionUtils._();

  /// Returns a negative number if [a] < [b], `0` if equal, positive if [a] > [b].
  static int compare(String a, String b) {
    final pa = _parse(a);
    final pb = _parse(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    return 0;
  }

  /// True when [a] is strictly older than [b].
  static bool isLower(String a, String b) => compare(a, b) < 0;

  /// True when [a] is strictly newer than [b].
  static bool isHigher(String a, String b) => compare(a, b) > 0;

  static List<int> _parse(String version) {
    var s = version.trim();
    if (s.isEmpty) return const [0];
    final plus = s.indexOf('+');
    if (plus != -1) s = s.substring(0, plus);
    final dash = s.indexOf('-');
    if (dash != -1) s = s.substring(0, dash);
    return s
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList(growable: false);
  }
}
