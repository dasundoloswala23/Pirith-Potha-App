import 'package:flutter/material.dart';

import '../l10n/bilingual.dart';

/// Asks the user to confirm an irreversible action, returning `true` only
/// if they did.
///
/// Every destructive action in the app used to open its own hand-rolled
/// [AlertDialog]; they had drifted apart in wording and button order. One
/// helper keeps "cancel on the left, the destructive verb on the right,
/// tinted as destructive" true everywhere.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  // read, not of: every caller invokes this from a tap handler. Follows
  // the leading language so Cancel never sits in English beside a Sinhala
  // confirm verb.
  final l10n = Bilingual.read(context).primary;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
