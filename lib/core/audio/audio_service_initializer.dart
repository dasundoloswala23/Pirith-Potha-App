import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'pirith_audio_handler.dart';

/// Registers [PirithAudioHandler] with `audio_service` so background/lock-
/// screen playback, the notification, and Bluetooth/headset controls all
/// work — see docs/04_audio_architecture.md. Must run once before the
/// handler is used (this app does it in configureDependencies()).
Future<PirithAudioHandler> initializeAudioService() {
  return AudioService.init(
    builder: () => PirithAudioHandler(AudioPlayer()),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.pirith.pitithpotha.audio',
      // Shown to the user in Android's notification channel settings. Can't
      // come from AppLocalizations — this runs during DI setup, before any
      // BuildContext exists — so it follows the app's English UI language
      // (see docs/08_ui_ux.md) as a literal.
      androidNotificationChannelName: 'Pirith playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}
