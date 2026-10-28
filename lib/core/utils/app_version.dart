/// How urgently the installed build needs replacing.
enum UpdateType { none, optional, mandatory }

/// Classifies [latest] against [installed] as `MAJOR.MINOR.PATCH`:
/// a newer patch is [UpdateType.optional], a newer minor or major is
/// [UpdateType.mandatory].
///
/// Components compare as integers, never strings — `"1.9"` vs `"1.10"` would
/// sort backwards as strings, and this app's own zero-padded `1.00.03`
/// parses fine segment by segment. Missing segments count as zero, and
/// anything after `+` (the build number) is ignored.
///
/// Fails open: a segment that isn't a plain non-negative integer on either
/// side means [UpdateType.none]. A typo in the remote config must never lock
/// every user out behind a mandatory-update screen.
UpdateType classifyUpdate({required String installed, required String latest}) {
  final a = _parse(installed);
  final b = _parse(latest);
  if (a == null || b == null) return UpdateType.none;

  for (var i = 0; i < 3; i++) {
    if (a[i] == b[i]) continue;
    if (a[i] > b[i]) return UpdateType.none;
    return i < 2 ? UpdateType.mandatory : UpdateType.optional;
  }
  return UpdateType.none;
}

/// Whether any newer version exists, optional or mandatory.
bool isOutdated({required String installed, required String latest}) =>
    classifyUpdate(installed: installed, latest: latest) != UpdateType.none;

/// `[major, minor, patch]`, or null when any segment isn't an integer.
/// Segments past the third are ignored.
List<int>? _parse(String version) {
  final core = version.trim().split('+').first.trim();
  if (core.isEmpty) return null;
  final parts = core.split('.');
  final result = <int>[];
  for (var i = 0; i < 3; i++) {
    if (i >= parts.length) {
      result.add(0);
      continue;
    }
    final value = int.tryParse(parts[i]);
    if (value == null || value < 0) return null;
    result.add(value);
  }
  return result;
}
