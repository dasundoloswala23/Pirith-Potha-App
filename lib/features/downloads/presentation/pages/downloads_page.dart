import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsTitle)),
      body: Center(child: Text(l10n.downloadsEmpty)),
    );
  }
}
