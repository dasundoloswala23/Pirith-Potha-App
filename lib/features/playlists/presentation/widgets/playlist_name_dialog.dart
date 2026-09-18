import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';

/// Result of [showPlaylistNameDialog].
class PlaylistNameResult {
  const PlaylistNameResult({required this.name, required this.description});

  final String name;
  final String description;
}

/// Name/description prompt shared by "new playlist" and "rename", since the
/// two differ only in their title and starting values.
///
/// Returns `null` if the user cancelled or left the name blank — a nameless
/// playlist is unfindable, so an empty name is a cancel rather than an error
/// to scold the user with.
Future<PlaylistNameResult?> showPlaylistNameDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  String initialDescription = '',
}) {
  final l10n = AppLocalizations.of(context);
  // [Bilingual.read], not [Bilingual.of]: this runs from a tap handler,
  // where watching a provider asserts. Resolved here and passed in, so the
  // dialog — which builds under the root navigator — never has to look up
  // a provider from this subtree.
  final bi = Bilingual.read(context);

  return showDialog<PlaylistNameResult>(
    context: context,
    builder: (dialogContext) => _PlaylistNameDialog(
      title: title,
      initialName: initialName,
      initialDescription: initialDescription,
      l10n: l10n,
      bi: bi,
    ),
  );
}

/// A [StatefulWidget] rather than controllers owned by the function above,
/// because the dialog outlives its own result: disposing the controllers
/// when the future completes tears them down while the exit transition is
/// still rebuilding the live [TextField]s, which throws "A
/// TextEditingController was used after being disposed". Owning them here
/// ties their lifetime to the widget that actually uses them.
class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({
    required this.title,
    required this.initialName,
    required this.initialDescription,
    required this.l10n,
    required this.bi,
  });

  final String title;
  final String initialName;
  final String initialDescription;
  final AppLocalizations l10n;
  final Bilingual bi;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _descriptionController = TextEditingController(
    text: widget.initialDescription,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      PlaylistNameResult(
        name: name,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bi = widget.bi;
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg + 8),
      ),
      child: SingleChildScrollView(
        // The keyboard takes roughly half a short screen; scrolling here
        // beats an overflowing dialog.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A tinted badge rather than a bare title: it gives the
              // dialog a centre of gravity and ties it to the gold used
              // across the player and cards.
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  ),
                  child: Icon(Icons.queue_music, size: 28, color: accent),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTypography.sinhalaTitle(
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Field(
                controller: _nameController,
                label: bi.primary.playlistNameLabel,
                hint: bi.si.playlistNameHint,
                autofocus: true,
                textInputAction: TextInputAction.next,
                maxLength: 60,
              ),
              const SizedBox(height: AppSpacing.md),
              _Field(
                controller: _descriptionController,
                label: bi.primary.playlistDescriptionLabel,
                textInputAction: TextInputAction.done,
                maxLength: 120,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                      child: Text(widget.l10n.actionCancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(widget.l10n.actionSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded, filled text field matching the search bar and cards rather than
/// Material's default underlined input. The character counter is hidden —
/// [maxLength] still caps the text, but a live "0/60" under an empty field
/// is clutter in a two-field dialog.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.hint,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final int maxLength;
  final String? hint;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // dividerColor is near-black in this theme and made the resting field
    // heavier than the gold focus state; a light tint of the text colour
    // keeps the field quiet until it is focused.
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
      ),
    );

    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: textInputAction,
      maxLength: maxLength,
      onSubmitted: onSubmitted,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        filled: true,
        // A warm tint of the accent, so the field reads as an input on the
        // cream dialog instead of disappearing into it.
        fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
        ),
      ),
    );
  }
}
