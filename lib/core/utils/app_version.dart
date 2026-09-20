/// Compares two dotted version strings component-wise as integers, e.g.
/// `"1.00.03"` vs `"1.00.02"`.
///
/// Deliberately not a string or double compare: `"1.9"` vs `"1.10"` would
/// sort backwards as strings, and a version with more than two dots (as this
/// app's own `1.00.02` already has) isn't a valid double at all.
///
/// Missing trailing components count as zero (`"1.1"` == `"1.1.0"`), and a
/// component that isn't a plain non-negative integer makes that component —
/// and everything after it — compare as equal rather than throwing. A
/// malformed remote value must never make the app claim it's outdated by
/// accident; the safe failure here is "no update", not a wrong banner.
bool isOutdated({required String installed, required String latest}) {
  final installedParts = _parse(installed);
  final latestParts = _parse(latest);
  final length = installedParts.length > latestParts.length
      ? installedParts.length
      : latestParts.length;

  for (var i = 0; i < length; i++) {
    final a = i < installedParts.length ? installedParts[i] : 0;
    final b = i < latestParts.length ? latestParts[i] : 0;
    if (a == null || b == null) return false;
    if (a != b) return a < b;
  }
  return false;
}

/// Parses each dot-separated segment as a non-negative integer. A segment
/// that doesn't parse becomes `null` rather than throwing — [isOutdated]
/// treats any `null` as "can't tell, so no".
List<int?> _parse(String version) =>
    version.trim().split('.').map(int.tryParse).toList();
