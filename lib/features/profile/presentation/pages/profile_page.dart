import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/settings_section.dart';

/// Settings, grouped per the approved design. Sinhala and English are shown
/// together rather than switched between (see docs/08_ui_ux.md), so there is
/// no language control here — the Language row states what the app shows.
///
/// Google/Apple sign-in is intentionally not offered for now. The AuthBloc
/// events and repository still support it and are left intact; only the
/// entry points are hidden, so re-enabling it is a UI-only change.
///
/// Rows for features that don't exist yet (dark mode, audio quality,
/// auto-download, storage) are rendered visibly inactive rather than as
/// working controls that silently do nothing — and no placeholder figures
/// are shown for storage, which would be inventing data.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bi = Bilingual.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l10n.authErrorGeneric)));
            }
          },
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                BilingualHeader(
                  sinhala: bi.si.profileTitle,
                  english: bi.en.profileTitle,
                ),
                _AccountTile(state: state, l10n: l10n),

                SettingsSection(
                  title: bi.en.settingsAppearance,
                  children: [
                    SettingsRow(
                      icon: Icons.dark_mode_outlined,
                      english: bi.en.settingsDarkMode,
                      sinhala: bi.si.settingsDarkMode,
                      enabled: false,
                      trailing: Text(l10n.comingSoon,
                          style: Theme.of(context).textTheme.labelSmall),
                    ),
                    SettingsRow(
                      icon: Icons.language,
                      english: bi.en.profileLanguage,
                      sinhala: bi.si.profileLanguage,
                      trailing: Text(
                        '${bi.si.profileLanguageValue} · ${bi.en.profileLanguageValue}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),

                SettingsSection(
                  title: bi.en.settingsPlayback,
                  children: [
                    SettingsRow(
                      icon: Icons.play_circle_outline,
                      english: bi.en.settingsBackgroundPlayback,
                      sinhala: bi.si.settingsBackgroundPlayback,
                      // Always on — the app is built around background and
                      // lock-screen playback, so this states a fact rather
                      // than offering a switch that could break it.
                      trailing: const Icon(Icons.check, size: 20),
                    ),
                    SettingsRow(
                      icon: Icons.graphic_eq,
                      english: bi.en.settingsAudioQuality,
                      sinhala: bi.si.settingsAudioQuality,
                      enabled: false,
                      trailing: Text(l10n.comingSoon,
                          style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ],
                ),

                SettingsSection(
                  title: bi.en.settingsStorage,
                  children: [
                    SettingsRow(
                      icon: Icons.wifi,
                      english: bi.en.settingsAutoDownloadWifi,
                      sinhala: bi.si.settingsAutoDownloadWifi,
                      enabled: false,
                      trailing: Text(l10n.comingSoon,
                          style: Theme.of(context).textTheme.labelSmall),
                    ),
                    SettingsRow(
                      icon: Icons.sd_storage_outlined,
                      english: bi.en.settingsStorageUsed,
                      sinhala: bi.si.settingsStorageUsed,
                      enabled: false,
                      trailing: Text(l10n.comingSoon,
                          style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ],
                ),

                SettingsSection(
                  title: bi.en.settingsAbout,
                  children: [
                    SettingsRow(
                      icon: Icons.workspace_premium_outlined,
                      english: bi.en.profilePremium,
                      sinhala: bi.si.profilePremium,
                      enabled: false,
                      trailing: Text(l10n.comingSoon,
                          style: Theme.of(context).textTheme.labelSmall),
                    ),
                    SettingsRow(
                      icon: Icons.info_outline,
                      english: bi.en.profileAbout,
                      sinhala: bi.si.profileAbout,
                      enabled: false,
                    ),
                    SettingsRow(
                      icon: Icons.privacy_tip_outlined,
                      english: bi.en.profilePrivacyPolicy,
                      sinhala: bi.si.profilePrivacyPolicy,
                      enabled: false,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.state, required this.l10n});

  final AuthState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bi = Bilingual.of(context);

    if (state is AuthLoading) {
      return ListTile(
        leading: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(l10n.authSigningIn),
      );
    }

    final user = state is Authenticated ? (state as Authenticated).user : null;
    final isGuest = user == null || user.isAnonymous;

    if (isGuest) {
      return SettingsRow(
        icon: Icons.person_outline,
        english: bi.en.profileGuest,
        sinhala: bi.si.profileGuest,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: user.photoUrl != null
              ? CircleAvatar(backgroundImage: NetworkImage(user.photoUrl!))
              : const Icon(Icons.person),
          title: Text(user.displayName ?? user.email ?? user.uid),
        ),
        // Its own row rather than a subtitle under the name, so the
        // destructive action isn't disguised as account status.
        SettingsRow(
          icon: Icons.logout,
          english: bi.en.profileSignOut,
          sinhala: bi.si.profileSignOut,
          destructive: true,
          onTap: () =>
              context.read<AuthBloc>().add(const AuthSignOutRequested()),
        ),
      ],
    );
  }
}
