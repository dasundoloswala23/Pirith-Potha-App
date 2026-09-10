import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.authErrorGeneric)));
          }
        },
        builder: (context, state) {
          return ListView(
            children: [
              _AccountTile(state: state, l10n: l10n),
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
          );
        },
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.profileGuest),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: Text(l10n.profileSignInWithGoogle),
            onTap: () => context
                .read<AuthBloc>()
                .add(const AuthSignInWithGoogleRequested()),
          ),
          ListTile(
            leading: const Icon(Icons.apple),
            title: Text(l10n.profileSignInWithApple),
            onTap: () => context
                .read<AuthBloc>()
                .add(const AuthSignInWithAppleRequested()),
          ),
        ],
      );
    }

    return ListTile(
      leading: user.photoUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(user.photoUrl!))
          : const Icon(Icons.person),
      title: Text(user.displayName ?? user.email ?? user.uid),
      subtitle: Text(l10n.profileSignOut),
      onTap: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
    );
  }
}
