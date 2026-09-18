import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../../../premium/presentation/widgets/premium_gate.dart';
import '../../domain/entities/pirith_entity.dart';

/// The one place that decides what tapping a Pirith does.
///
/// Every row, card and play button routes through here. Before this existed
/// the premium check was copy-pasted at four call sites, and adding a second
/// kind of Pirith would have meant a fifth copy of the branch as well.
///
/// [onPlay] lets a playlist row start the whole playlist instead of the one
/// item — but note the ordering below: it is consulted *after* the video
/// branch, so a video-only row inside a playlist opens the video rather than
/// starting playback from a position it cannot occupy.
void openPirith(
  BuildContext context,
  PirithEntity item, {
  VoidCallback? onPlay,
}) {
  // First, so a premium video is gated exactly like premium audio.
  if (!ensurePremiumAccess(context, isPremiumItem: item.isPremium)) return;

  if (item.isVideoOnly) {
    context.push(AppRoutePaths.videoPirithFor(item.id));
    return;
  }

  // Neither audio nor video. PlayerBloc would refuse this silently, which
  // reads as a dead tap, so say something instead. Should only be reachable
  // for an unpublished draft.
  if (!item.hasAudio) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(Bilingual.read(context).primary.pirithUnavailable)),
      );
    return;
  }

  if (onPlay != null) {
    onPlay();
    return;
  }

  context.read<PlayerBloc>().add(PlayerPlayRequested(item));
  context.push(AppRoutePaths.player);
}
