import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/app_update_cubit.dart';
import 'optional_update_dialog.dart';

/// Shows the optional-update dialog over the main experience — whether the
/// check finished before Home appeared or arrives while the user is on it.
/// Never on splash: it lives in `HomeShell`.
class OptionalUpdatePrompter extends StatefulWidget {
  const OptionalUpdatePrompter({required this.child, super.key});

  final Widget child;

  @override
  State<OptionalUpdatePrompter> createState() => _OptionalUpdatePrompterState();
}

class _OptionalUpdatePrompterState extends State<OptionalUpdatePrompter> {
  @override
  void initState() {
    super.initState();
    _scheduleShow();
  }

  void _scheduleShow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowOptionalUpdateDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUpdateCubit, AppUpdateState>(
      listenWhen: (_, current) => current is UpdateOptional,
      listener: (_, _) => _scheduleShow(),
      child: widget.child,
    );
  }
}
