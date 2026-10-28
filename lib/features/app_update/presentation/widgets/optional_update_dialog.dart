import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/firebase/analytics_service.dart';
import '../../../../core/l10n/bilingual.dart';
import '../bloc/app_update_cubit.dart';
import 'update_copy.dart';
import 'update_visuals.dart';

/// Shows the optional-update dialog if the cubit says one is due and it
/// hasn't been shown this launch. Safe to call repeatedly.
Future<void> maybeShowOptionalUpdateDialog(BuildContext context) async {
  final cubit = context.read<AppUpdateCubit>();
  final state = cubit.state;
  if (!cubit.shouldShowOptional || state is! UpdateOptional) return;
  cubit.markOptionalShown();

  _analytics
      ?.logUpdatePromptShown(state.config.latestVersion, 'optional')
      .ignore();

  final reduceMotion = MediaQuery.of(context).disableAnimations;
  final updated = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 320),
    pageBuilder: (_, _, _) =>
        OptionalUpdateDialog(state: state, openStore: cubit.openStore),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );

  if (updated != true) {
    _analytics?.logUpdateDismissed(state.config.latestVersion).ignore();
  }
}

AnalyticsService? get _analytics =>
    GetIt.instance.isRegistered<AnalyticsService>()
    ? GetIt.instance<AnalyticsService>()
    : null;

/// A newer patch is available. Dismissible — the user carries on either
/// way. Pops `true` when the store opened.
class OptionalUpdateDialog extends StatefulWidget {
  const OptionalUpdateDialog({
    required this.state,
    required this.openStore,
    super.key,
  });

  final UpdateOptional state;
  final Future<bool> Function() openStore;

  @override
  State<OptionalUpdateDialog> createState() => _OptionalUpdateDialogState();
}

class _OptionalUpdateDialogState extends State<OptionalUpdateDialog> {
  bool _launching = false;
  bool _failed = false;

  Future<void> _update() async {
    if (_launching) return;
    setState(() {
      _launching = true;
      _failed = false;
    });
    final opened = await widget.openStore();
    if (!mounted) return;
    if (opened) {
      _analytics?.logUpdateAccepted(widget.state.config.latestVersion).ignore();
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _launching = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bi = Bilingual.of(context);
    final copy = UpdateCopy(widget.state.config, bi, mandatory: false);
    final notes = copy.releaseNotes;
    final (_, subtitle) = bi.order(
      bi.si.updateOptionalTitle,
      bi.en.updateOptionalTitle,
    );

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Material(
              color: scheme.surface,
              elevation: 0,
              borderRadius: BorderRadius.circular(AppRadius.lg + 8),
              clipBehavior: Clip.antiAlias,
              shadowColor: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      AppColors.gold.withValues(alpha: 0.12),
                      scheme.surface,
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const UpdateMedallion(),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        bi.primary.updateOptionalTitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.sinhalaTitle(
                          fontSize: 21,
                          weight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      VersionChip(
                        label: bi.primary.updateVersionLabel(
                          widget.state.config.latestVersion,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        copy.message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _ReleaseNotes(
                          title: bi.primary.updateWhatsNew,
                          notes: notes,
                        ),
                      ],
                      if (_failed) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          bi.primary.updateStoreError,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: GoldActionButton(
                          label: bi.primary.updateActionNow,
                          busy: _launching,
                          onPressed: _update,
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
                          onPressed: _launching
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(bi.primary.updateActionLater),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes({required this.title, required this.notes});

  final String title;
  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Capped so a long changelog scrolls inside the box instead of
          // pushing the buttons off a small screen.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: SingleChildScrollView(
              child: Text(
                notes,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
