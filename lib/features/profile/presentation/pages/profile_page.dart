import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// There is no in-app language switcher (see docs/08_ui_ux.md) — the
/// language row below is informational, not a control.
///
/// Google/Apple sign-in is intentionally not offered here for now. The
/// AuthBloc events and repository support it and are left intact; only the
/// entry points are hidden, so re-enabling it is a UI-only change.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
                trailing: Text(l10n.profileLanguageValue),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(l10n.profilePremium),
                subtitle: Text(l10n.comingSoon),
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
      return ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(l10n.profileGuest),
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
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.profileSignOut),
          onTap: () =>
              context.read<AuthBloc>().add(const AuthSignOutRequested()),
        ),
      ],
    );
  }
}
