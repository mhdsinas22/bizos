import 'package:bizos/core/constants/app_images.dart';
import 'package:bizos/core/theme/app_colors.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Premium Voryn Launch Splash Screen.
///
/// Features a coordinated 1.4s animation with the official Voryn gradient V logo
/// across three distinct phases:
/// - Phase A (0.0 - 0.55): Clean themed background reveal with easeOutCubic opacity & subtle scale
/// - Phase B (0.05 - 0.85): Signature motion with smooth vertical translation settling to resting center
/// - Phase C (Completion): Seamless destination routing to Dashboard (authenticated) or Login (unauthenticated)
class SplashScreen extends StatefulWidget {
  /// Optional callback invoked when the splash animation completes.
  /// When hosted in [AppStartupFlow], this notifies the host to resolve navigation.
  final VoidCallback? onAnimationComplete;

  /// Holds the splash in its completed resting state if authentication
  /// verification requires additional network time.
  final bool isWaitingForAuth;

  const SplashScreen({
    super.key,
    this.onAnimationComplete,
    this.isWaitingForAuth = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _animationFinished = false;
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Phase A: Opacity reveal (0.0 to 0.55)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Phase A & B: Subtle scale expansion (0.88 to 1.0)
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Phase B: Signature vertical settling translation (~10-12px lift into resting center)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onAnimationCompleted();
      }
    });
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final bool disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;

      if (disableAnimations || widget.isWaitingForAuth) {
        _controller.value = 1.0;
        _onAnimationCompleted();
      } else {
        _controller.forward();
      }
    }
  }

  void _onAnimationCompleted() {
    if (!mounted) return;
    _animationFinished = true;
    _resolveNavigation();
  }

  void _resolveNavigation() {
    if (!_animationFinished || _navigationTriggered || !mounted) return;

    // 1. If embedded inside AppStartupFlow with a callback, notify coordinator
    if (widget.onAnimationComplete != null) {
      _navigationTriggered = true;
      widget.onAnimationComplete!();
      return;
    }

    // 2. If held in resting state by a parent coordinator, do not push routes
    if (widget.isWaitingForAuth) {
      return;
    }

    // 3. Standalone navigation fallback: check AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.loading) {
      // Hold until AuthBloc completes
      return;
    }

    _navigationTriggered = true;
    _navigateToDestination(authState);
  }

  void _navigateToDestination(AuthState authState) {
    if (!mounted) return;

    final Widget destination =
        (authState.user != null || authState.status == AuthStatus.authenticated)
            ? const MainDashboardScreen()
            : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppTheme.darkBg : AppColors.splashScreenLightBackground;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status != AuthStatus.loading,
      listener: (context, state) {
        if (_animationFinished && !_navigationTriggered) {
          _resolveNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: Image.asset(
                    AppImages.vorynGradientLogo,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        AppImages.vorynGradientLogoOriginal,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
