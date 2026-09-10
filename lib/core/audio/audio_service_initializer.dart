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
      androidNotificationChannelName: 'Pirith Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}
