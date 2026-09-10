import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_route_paths.dart';
import '../../core/l10n/app_localizations.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Branded splash screen shown while the initial guest/auth session is
/// being established (see docs/06_authentication.md). Timing/entrance
/// sequence follows the approved UI reference (`Buddhist Audio App UI
/// Design/src/App.tsx`): the logo fades in first, then the title/subtitle,
/// then the loading dots. Moves on to Home once [AuthBloc] reaches a
/// settled state and the entry sequence has had time to play out.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const _minimumDisplayTime = Duration(milliseconds: 2600);

  late final _entryController = AnimationController(
    vsync: this,
    duration: _minimumDisplayTime,
  )..forward();

  late final _logoOpacity = CurvedAnimation(
    parent: _entryController,
    curve: const Interval(0, 0.35, curve: Curves.easeOut),
  );
  late final _titleOpacity = CurvedAnimation(
    parent: _entryController,
    curve: const Interval(0.19, 0.58, curve: Curves.easeOut),
  );
  late final _dotsOpacity = CurvedAnimation(
    parent: _entryController,
    curve: const Interval(0.58, 0.96, curve: Curves.easeOut),
  );

  bool _minimumTimeElapsed = false;
  Timer? _minimumTimeTimer;

  @override
  void initState() {
    super.initState();
    _minimumTimeTimer = Timer(_minimumDisplayTime, () {
      if (!mounted) return;
      setState(() => _minimumTimeElapsed = true);
      _maybeContinue(context.read<AuthBloc>().state);
    });
  }

  void _maybeContinue(AuthState state) {
    final settled = state is Authenticated || state is Unauthenticated || state is AuthError;
    if (_minimumTimeElapsed && settled) {
      context.go(AppRoutePaths.home);
    }
  }

  @override
  void dispose() {
    _minimumTimeTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _maybeContinue(state),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.5, -1),
              end: Alignment(0.3, 1),
              colors: [Color(0xFF0C0700), Color(0xFF1E1005), Color(0xFF0A0600)],
              stops: [0, 0.5, 1],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: Image.asset('assets/logo.png', width: 96, height: 96),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: Column(
                        children: [
                          Text(
                            l10n.appName,
                            style: AppTypography.sinhalaTitle(
                              fontSize: 36,
                              weight: FontWeight.w700,
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pirith Potha',
                            style: AppTypography.englishSerif(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    FadeTransition(opacity: _dotsOpacity, child: const _LoadingDots()),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Center(
                  child: Text(
                    l10n.splashTagline,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: const Color(0xFF5A4020),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - i * 0.1) % 1.0;
            final wave = (math.sin(t * 2 * math.pi) + 1) / 2; // 0..1
            final opacity = 0.6 + 0.4 * wave;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: opacity.clamp(0.6, 1.0),
                child: const CircleAvatar(radius: 3, backgroundColor: Color(0xFFC09050)),
              ),
            );
          }),
        );
      },
    );
  }
}
