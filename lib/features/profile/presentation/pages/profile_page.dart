import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.profileGuest),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.profileLanguage),
            trailing: ValueListenableBuilder<Locale>(
              valueListenable: localeController,
              builder: (context, locale, _) => Text(
                locale == LocaleController.sinhala ? 'සිංහල' : 'English',
              ),
            ),
            onTap: localeController.toggle,
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.profilePremium),
            subtitle: Text(l10n.comingSoon),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.profileSettings),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.profileAbout),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.profilePrivacyPolicy),
          ),
        ],
      ),
    );
  }
}
