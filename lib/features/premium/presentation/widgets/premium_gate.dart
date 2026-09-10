import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/premium_feature.dart';
import '../bloc/premium_bloc.dart';

/// Single checkpoint every Play/Download call site uses before acting on a
/// possibly-premium Pirith — see docs/07_monetization.md ("checked through
/// a single feature-access abstraction, not scattered `if (isPremium)`
/// checks"). Returns true (proceed) when [isPremiumItem] is false or the
/// user already has access; otherwise shows a message and returns false.
bool ensurePremiumAccess(BuildContext context, {required bool isPremiumItem}) {
  if (!isPremiumItem) return true;

  final hasAccess = context.read<PremiumBloc>().state.hasAccess(PremiumFeature.premiumContent);
  if (hasAccess) return true;

  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.premiumRequiredMessage)));
  return false;
}
