import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app_update/presentation/bloc/app_update_cubit.dart';
import '../review_prompt_coordinator.dart';
import 'review_invitation_sheet.dart';

/// Wraps the main experience (`HomeShell`) and is the coordinator's only
/// way onto the screen. Its own route being on top is what makes a moment
/// "safe": while the player, queue, a video, a dialog or a sheet is pushed
/// over Home, nothing is shown.
///
/// No-ops when no [ReviewPromptCoordinator] is provided (widget tests).
class ReviewPromptScope extends StatefulWidget {
  const ReviewPromptScope({required this.child, super.key});

  final Widget child;

  @override
  State<ReviewPromptScope> createState() => _ReviewPromptScopeState();
}

class _ReviewPromptScopeState extends State<ReviewPromptScope>
    implements ReviewPromptHost {
  ReviewPromptCoordinator? _coordinator;

  @override
  void initState() {
    super.initState();
    try {
      _coordinator = context.read<ReviewPromptCoordinator>();
    } on ProviderNotFoundException {
      _coordinator = null;
    }
    // After the first frame, so the route is in place for isSafeMoment.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _coordinator?.attach(this);
    });
  }

  @override
  void didUpdateWidget(ReviewPromptScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuilt on tab changes — another chance at a safe moment. The
    // coordinator's own guards make repeat calls free.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _coordinator?.tryPrompt();
    });
  }

  @override
  void dispose() {
    _coordinator?.detach(this);
    super.dispose();
  }

  @override
  bool get isSafeMoment {
    if (!mounted) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    // A pending optional-update dialog takes priority; the mandatory screen
    // replaces this whole subtree, so it can't coexist with a prompt.
    final update = context.read<AppUpdateCubit>();
    return !update.shouldShowOptional && update.state is! UpdateMandatory;
  }

  @override
  Future<ReviewSheetOutcome> presentInvitation({
    required Future<bool> Function() openStore,
  }) async {
    if (!mounted) return ReviewSheetOutcome.later;
    return showReviewInvitationSheet(context, openStore: openStore);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
