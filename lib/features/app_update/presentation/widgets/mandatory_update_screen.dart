import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/firebase/analytics_service.dart';
import '../../../../core/l10n/bilingual.dart';
import '../bloc/app_update_cubit.dart';
import 'update_copy.dart';
import 'update_visuals.dart';

/// Full-screen block shown instead of the whole app while a newer minor or
/// major version exists. One action only — no close, skip or later.
///
/// Rendered by [UpdateGate] *in place of* the navigator, so there is no
/// route underneath to pop back to; it has no Navigator, Overlay or
/// Scaffold of its own and reports errors inline.
///
/// Deliberately the player's always-dark palette, so it's unmistakably a
/// different kind of screen from the light, dismissible optional dialog.
class MandatoryUpdateScreen extends StatefulWidget {
  const MandatoryUpdateScreen({
    required this.state,
    required this.openStore,
    super.key,
  });

  final UpdateMandatory state;
  final Future<bool> Function() openStore;

  @override
  State<MandatoryUpdateScreen> createState() => _MandatoryUpdateScreenState();
}

class _MandatoryUpdateScreenState extends State<MandatoryUpdateScreen>
    with TickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool _launching = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _entrance.value = 1;
      _breath.stop();
    } else {
      if (!_entrance.isCompleted) _entrance.forward();
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _breath.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_launching) return;
    setState(() {
      _launching = true;
      _failed = false;
    });
    final opened = await widget.openStore();
    if (!mounted) return;
    if (opened && GetIt.instance.isRegistered<AnalyticsService>()) {
      GetIt.instance<AnalyticsService>()
          .logUpdateAccepted(widget.state.config.latestVersion)
          .ignore();
    }
    // Opening the store isn't the update. The block lifts only when the
    // cubit's recheck on resume sees a newer *installed* version.
    setState(() {
      _launching = false;
      _failed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bi = Bilingual.of(context);
    final copy = UpdateCopy(widget.state.config, bi, mandatory: true);
    final notes = copy.releaseNotes;
    final (_, subtitle) = bi.order(
      bi.si.updateMandatoryTitle,
      bi.en.updateMandatoryTitle,
    );

    final fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    final rise = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic),
    );

    return Material(
      color: AppColors.player,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.1,
            colors: [Color(0xFF2A1708), AppColors.playerSurface, AppColors.player],
            stops: [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: rise,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: AppSpacing.xxl),
                            AnimatedBuilder(
                              animation: _breath,
                              builder: (_, _) => UpdateMedallion(
                                size: 112,
                                glow: 0.3 + 0.25 * _breath.value,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Text(
                              bi.primary.updateMandatoryTitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.sinhalaTitle(
                                fontSize: 26,
                                weight: FontWeight.w700,
                                color: AppColors.playerText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.playerTextSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            VersionChip(
                              label: bi.primary.updateVersionLabel(
                                widget.state.config.latestVersion,
                              ),
                              onDark: true,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              copy.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppColors.playerText,
                              ),
                            ),
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xl),
                              _DarkReleaseNotes(
                                title: bi.primary.updateWhatsNew,
                                notes: notes,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xxl),
                            SizedBox(
                              width: double.infinity,
                              child: GoldActionButton(
                                label: bi.primary.updateActionNow,
                                busy: _launching,
                                onPressed: _update,
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _failed
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.md,
                                      ),
                                      child: Text(
                                        bi.primary.updateStoreError,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.maroonDark,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      ),
                    ),
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

class _DarkReleaseNotes extends StatelessWidget {
  const _DarkReleaseNotes({required this.title, required this.notes});

  final String title;
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.gold2Dark,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: Text(
                notes,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: AppColors.playerTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
