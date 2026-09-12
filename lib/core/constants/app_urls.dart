/// Public web addresses the app links out to.
///
/// The privacy policy is a store requirement, not a nicety: Play Console and
/// App Store Connect both refuse a submission without a reachable URL, and
/// the same address must be entered in both listings. Its source lives in
/// `store/privacy-policy.html`.
abstract final class AppUrls {
  static const privacyPolicy = 'https://pithi-potha.web.app/privacy';

  static const youtubeChannel =
      'https://www.youtube.com/channel/UC4Ug5ybW6tJS3DKgtKJui3A';
}
