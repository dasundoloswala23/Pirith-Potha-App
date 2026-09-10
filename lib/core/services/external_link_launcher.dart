import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the native app if one is installed for it, otherwise the
/// external browser — never an in-app WebView (see docs/08_ui_ux.md).
/// Returns whether the launch succeeded, e.g. so the caller can show a
/// fallback message.
Future<bool> launchExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
