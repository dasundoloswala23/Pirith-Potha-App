import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/firebase/analytics_service.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../bloc/app_update_cubit.dart';
import 'mandatory_update_screen.dart';

/// Sits in `MaterialApp.router`'s `builder`, above the whole router. While
/// an update is mandatory it renders [MandatoryUpdateScreen] *instead of*
/// [child] — the navigator leaves the tree entirely, so splash, every tab
/// and every pushed route (`/player`, `/video/...`) are unreachable without
/// each needing its own guard, and back can only leave the app.
class UpdateGate extends StatelessWidget {
  const UpdateGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppUpdateCubit, AppUpdateState>(
      listenWhen: (previous, current) =>
          previous is! UpdateMandatory && current is UpdateMandatory,
      listener: (context, state) {
        // A chant shouldn't keep playing behind a screen the user can't
        // leave.
        context.read<PlayerBloc>().add(const PlayerPauseRequested());
        if (GetIt.instance.isRegistered<AnalyticsService>()) {
          GetIt.instance<AnalyticsService>()
              .logUpdatePromptShown(
                (state as UpdateMandatory).config.latestVersion,
                'mandatory',
              )
              .ignore();
        }
      },
      builder: (context, state) {
        if (state is! UpdateMandatory) return child;
        return PopScope(
          canPop: false,
          child: MandatoryUpdateScreen(
            state: state,
            openStore: context.read<AppUpdateCubit>().openStore,
          ),
        );
      },
    );
  }
}
