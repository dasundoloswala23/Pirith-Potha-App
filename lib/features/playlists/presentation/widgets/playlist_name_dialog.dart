import 'package:flutter/material.dart';

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
    final bi = widget.bi;

    return AlertDialog(
      // With the keyboard up, two fields and their counters don't fit on a
      // short screen; without this the dialog content overflows instead of
      // scrolling.
      scrollable: true,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: bi.si.playlistNameLabel,
              hintText: bi.si.playlistNameHint,
              helperText: bi.en.playlistNameLabel,
            ),
          ),
          TextField(
            controller: _descriptionController,
            textInputAction: TextInputAction.done,
            maxLength: 120,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: bi.si.playlistDescriptionLabel,
              helperText: bi.en.playlistDescriptionLabel,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l10n.actionCancel),
        ),
        TextButton(onPressed: _submit, child: Text(widget.l10n.actionSave)),
      ],
    );
  }
}
