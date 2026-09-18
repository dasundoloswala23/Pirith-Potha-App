import '../../pirith/domain/entities/pirith_entity.dart';

/// Drops the items that can't be played and remaps the start index onto what
/// survives.
///
/// This exists because filtering used to happen *after* the indices were
/// computed. `PirithAudioHandler.setQueue` skipped items with no audio when
/// building its sources, while the repository and `PlayerActive.queueIndex`
/// still counted the unfiltered list — so `currentIndexStream` reported
/// positions into one array that were then used to index another, and every
/// track after a skipped item showed the wrong title and artwork in the
/// player, the mini player and the lock-screen notification.
///
/// Filtering in one place, before anything counts, is what makes that class
/// of bug unrepresentable. Pure and synchronous so it can be tested without
/// an audio session.
({List<PirithEntity> items, int index}) playableQueue(
  List<PirithEntity> items, {
  int startIndex = 0,
}) {
  final playable = items.where((item) => item.hasAudio).toList();
  if (playable.isEmpty) return (items: const <PirithEntity>[], index: 0);

  // Follow the item the caller actually asked for, wherever it landed. If it
  // was one of the filtered-out ones, start from the top rather than at some
  // arbitrary neighbour.
  final requested = startIndex >= 0 && startIndex < items.length
      ? items[startIndex]
      : null;
  final index = requested == null
      ? 0
      : playable.indexWhere((item) => item.id == requested.id);

  return (items: playable, index: index < 0 ? 0 : index);
}
