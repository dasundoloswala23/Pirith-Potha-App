import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/pirith_mark.dart';

/// Gold medallion shared by the optional dialog and the mandatory screen,
/// so the two read as one design language at different volumes.
class UpdateMedallion extends StatelessWidget {
  const UpdateMedallion({this.size = 76, this.glow = 0.35, super.key});

  final double size;

  /// Shadow strength, 0–1 — animated by the mandatory screen's breathing.
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold2, AppColors.gold],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: glow),
            blurRadius: size * 0.45,
            spreadRadius: size * 0.04,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PirithMark(
            size: size * 0.86,
            strokeWidth: 1.2,
            color: Colors.white.withValues(alpha: 0.22),
          ),
          Icon(
            Icons.system_update_alt_rounded,
            size: size * 0.42,
            color: AppColors.onAccent,
          ),
        ],
      ),
    );
  }
}

/// The filled gold call to action. Shows a spinner and ignores taps while
/// [busy], so a double tap can't launch the store twice.
class GoldActionButton extends StatelessWidget {
  const GoldActionButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final radius = BorderRadius.circular(AppRadius.md);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled || busy ? 1 : 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              colors: [AppColors.gold, AppColors.goldDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.onAccent,
                            ),
                          )
                        : Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.onAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
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

/// Small pill showing the target version.
class VersionChip extends StatelessWidget {
  const VersionChip({required this.label, this.onDark = false, super.key});

  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.gold.withValues(alpha: onDark ? 0.18 : 0.12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onDark ? AppColors.gold2Dark : AppColors.gold,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
