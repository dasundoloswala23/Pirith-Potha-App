// Parsing for the optional per-Pirith YouTube link.
//
// Mirrored in the admin app at
// src/features/pirith/youtubeUrl.ts — the two MUST change together, because
// the admin previews the exact thumbnail this resolves to.
//
// The admin app stores this field as free text: it applies no regex, no
// trimming, and its `type="url"` input never runs a constraint check because
// the form calls `preventDefault()`. So the stored string can be a full watch
// URL, a `youtu.be` short link, a Shorts link, a bare id, or junk — and it may
// carry surrounding whitespace. Everything here parses defensively and returns
// `null` rather than guessing.

/// YouTube ids are exactly 11 characters of this alphabet. Validating the
/// shape (rather than trusting position in the path) means a malformed link
/// fails cleanly instead of producing a URL that 404s as an image.
final _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Path segments that carry the id in the *next* segment.
const _idBearingSegments = {'shorts', 'embed', 'v', 'live'};

const _youTubeHosts = {'youtube.com', 'youtu.be', 'youtube-nocookie.com'};

/// Extracts the video id from [rawUrl], or `null` when it isn't a YouTube
/// link this can resolve confidently.
///
/// Handles `watch?v=`, `youtu.be/`, `/shorts/`, `/embed/`, `/v/`, `/live/`,
/// the `www.`/`m.`/`music.` subdomains, missing schemes, and a bare id.
String? youTubeVideoId(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return null;
  // Internal whitespace means this is prose, not a URL.
  if (trimmed.contains(RegExp(r'\s'))) return null;

  if (_idPattern.hasMatch(trimmed)) return trimmed;

  // A scheme-less "youtu.be/ID" parses with an empty host and the whole
  // thing in `path`, so give Uri something it can split on.
  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return null;

  // Only the host is lowercased — lowercasing the whole string would corrupt
  // the id, which is case-sensitive.
  var host = uri.host.toLowerCase();
  for (final prefix in const ['www.', 'm.', 'music.']) {
    if (host.startsWith(prefix)) {
      host = host.substring(prefix.length);
      break;
    }
  }
  if (!_youTubeHosts.contains(host)) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  // youtu.be/<id> — the id is the whole path.
  if (host == 'youtu.be') {
    return segments.isEmpty ? null : _validId(segments.first);
  }

  // youtube.com/watch?v=<id>, whatever else is in the query string.
  if (segments.isNotEmpty && segments.first == 'watch') {
    return _validId(uri.queryParameters['v']);
  }

  if (segments.length >= 2 && _idBearingSegments.contains(segments.first)) {
    return _validId(segments[1]);
  }

  return null;
}

String? _validId(String? candidate) {
  if (candidate == null) return null;
  return _idPattern.hasMatch(candidate) ? candidate : null;
}

/// Highest-quality still YouTube publishes for [videoId].
///
/// Not every video has one — see [youTubeFallbackThumbnailUrl].
String youTubeThumbnailUrl(String videoId) =>
    'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';

/// Always-present still, used when [youTubeThumbnailUrl] 404s.
///
/// This one is 480x360 — the 16:9 frame plus letterbox bars — so it must be
/// drawn with `BoxFit.cover`, which crops the bars back off.
String youTubeFallbackThumbnailUrl(String videoId) =>
    'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

/// Canonical watch URL for [videoId].
///
/// Used for launching rather than the stored string: a stored `youtu.be/ID`
/// with no scheme parses fine for the id but fails in `launchUrl`, which is
/// a silent no-op for the user.
String youTubeWatchUrl(String videoId) =>
    'https://www.youtube.com/watch?v=$videoId';
