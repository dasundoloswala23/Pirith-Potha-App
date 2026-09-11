/// How the queue advances when a Pirith finishes.
///
/// Exclusive rather than a set of independent toggles, so the player only
/// ever has one mode to show and the user only has one control to reason
/// about. Each maps onto `just_audio`'s loop/shuffle settings in
/// [PirithAudioHandler] rather than being re-implemented by hand.
enum PlaybackMode {
  /// Play through the queue once, then stop.
  normal,

  /// Repeat the current Pirith indefinitely.
  repeatOne,

  /// Play through the queue, then start again from the first item.
  repeatAll,

  /// Play the queue in a randomised order, each item once.
  shuffle;

  PlaybackMode get next => switch (this) {
    PlaybackMode.normal => PlaybackMode.repeatAll,
    PlaybackMode.repeatAll => PlaybackMode.repeatOne,
    PlaybackMode.repeatOne => PlaybackMode.shuffle,
    PlaybackMode.shuffle => PlaybackMode.normal,
  };
}
