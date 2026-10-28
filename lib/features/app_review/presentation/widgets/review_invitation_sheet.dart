import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../app_update/presentation/widgets/update_visuals.dart';
import '../review_prompt_coordinator.dart';

/// Shows the Android review invitation. Swiping it away or tapping outside
/// counts as "Maybe Later", so it can't simply reappear next launch.
Future<ReviewSheetOutcome> showReviewInvitationSheet(
  BuildContext context, {
  required Future<bool> Function() openStore,
}) async {
  final reduceMotion = MediaQuery.of(context).disableAnimations;
  final outcome = await showModalBottomSheet<ReviewSheetOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    sheetAnimationStyle: reduceMotion
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
          ),
    builder: (_) => ReviewInvitationSheet(openStore: openStore),
  );
  return outcome ?? ReviewSheetOutcome.later;
}

/// The custom invitation. It only *invites* — the rating itself happens on
/// Google Play, where the user picks any score they like. Nothing here
/// collects stars, nudges towards five, or claims a review was posted.
class ReviewInvitationSheet extends StatefulWidget {
  const ReviewInvitationSheet({required this.openStore, super.key});

  final Future<bool> Function() openStore;

  @override
  State<ReviewInvitationSheet> createState() => _ReviewInvitationSheetState();
}

class _ReviewInvitationSheetState extends State<ReviewInvitationSheet>
    with SingleTickerProviderStateMixin {
  late final _stars = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool _opening = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _stars.value = 1;
    } else if (!_stars.isAnimating && !_stars.isCompleted) {
      _stars.forward();
    }
  }

  @override
  void dispose() {
    _stars.dispose();
    super.dispose();
  }

  Future<void> _rate() async {
    if (_opening) return;
    HapticFeedback.lightImpact();
    setState(() {
      _opening = true;
      _failed = false;
    });
    final opened = await widget.openStore();
    if (!mounted) return;
    if (opened) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final thanks = Bilingual.read(context).primary.reviewThanks;
      Navigator.of(context).pop(ReviewSheetOutcome.storeOpened);
      messenger?.showSnackBar(SnackBar(content: Text(thanks)));
    } else {
      setState(() {
        _opening = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bi = Bilingual.of(context);
    final (_, subtitle) = bi.order(bi.si.reviewTitle, bi.en.reviewTitle);
    const radius = Radius.circular(24);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, -0.2),
            colors: [AppColors.gold.withValues(alpha: 0.14), scheme.surface],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ExcludeSemantics(child: _Stars(animation: _stars)),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  header: true,
                  child: Text(
                    bi.primary.reviewTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.sinhalaTitle(
                      fontSize: 22,
                      weight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  bi.primary.reviewBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                if (_failed) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    bi.primary.reviewStoreError,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: GoldActionButton(
                    label: bi.primary.reviewActionRate,
                    busy: _opening,
                    onPressed: _rate,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                    onPressed: _opening
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop(ReviewSheetOutcome.later);
                          },
                    child: Text(bi.primary.reviewActionLater),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three gold stars popping in one after another — decoration only.
class _Stars extends StatelessWidget {
  const _Stars({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == 1 ? 10 : 0),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.elasticOut),
              ),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.gold2, AppColors.gold],
                ).createShader(bounds),
                child: Icon(Icons.star_rounded, size: i == 1 ? 60 : 44),
              ),
            ),
          ),
      ],
    );
  }
}
