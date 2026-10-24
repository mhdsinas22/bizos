import 'dart:async';
import 'package:bizos/core/constants/app_images.dart';
import 'package:bizos/core/di/injection.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/core/theme/app_colors.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
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
  bool _started = false;
  bool _navigationTriggered = false;
  String? _sessionExpiredMessage;
  Future<UserModel?>? _sessionValidationFuture;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_started) return;
    _started = true;

    // Concurrently validate session during splash animation
    _sessionValidationFuture = _checkSession();

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations || widget.isWaitingForAuth) {
      _controller.value = 1.0;
      _onAnimationCompleted();
    } else {
      _controller.forward();
    }
  }

  Future<UserModel?> _checkSession() async {
    try {
      AuthRepository? authRepo;
      try {
        authRepo = context.read<AuthRepository>();
      } catch (_) {
        if (getIt.isRegistered<AuthRepository>()) {
          authRepo = getIt<AuthRepository>();
        }
      }

      if (authRepo != null) {
        try {
          final user = await authRepo.checkAuthStatus().timeout(
            const Duration(seconds: 8),
          );
          if (user != null) {
            return user;
          }
        } on SessionExpiredException catch (e) {
          AppLogger.warning('SplashScreen: Session expired: ${e.message}');
          _sessionExpiredMessage = e.message;
          return null;
        } on TimeoutException {
          AppLogger.warning(
            'SplashScreen: Session check timed out, attempting fallbacks.',
          );
        } catch (e) {
          AppLogger.warning('SplashScreen: authRepo.checkAuthStatus error: $e');
        }
      }

      // Safe check for Supabase client directly
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          if (session.isExpired) {
            try {
              final res = await Supabase.instance.client.auth
                  .refreshSession()
                  .timeout(const Duration(seconds: 5));
              if (!mounted) return null;
              if (res.session != null) {
                final authState = context.read<AuthBloc>().state;
                return authState.user;
              }
            } catch (_) {}
          } else {
            if (!mounted) return null;
            final authState = context.read<AuthBloc>().state;
            return authState.user;
          }
        }
      } catch (_) {}

      if (!mounted) return null;

      // Test environment fallback: check AuthBloc state
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState.status == AuthStatus.authenticated &&
            authState.user != null) {
          return authState.user;
        }
      } catch (_) {}

      return null;
    } on SessionExpiredException catch (e) {
      _sessionExpiredMessage = e.message;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onAnimationCompleted() async {
    if (!mounted) return;

    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
      return;
    }
    if (widget.isWaitingForAuth) {
      return;
    }

    if (_navigationTriggered) return;

    UserModel? user;
    if (_sessionValidationFuture != null) {
      try {
        user = await _sessionValidationFuture!.timeout(
          const Duration(seconds: 8),
        );
      } on SessionExpiredException catch (e) {
        _sessionExpiredMessage = e.message;
      } catch (_) {}
    } else {
      user = await _checkSession();
    }

    // Secondary test fallback
    if (user == null && _sessionExpiredMessage == null && mounted) {
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState.status == AuthStatus.authenticated &&
            authState.user != null) {
          user = authState.user;
        }
      } catch (_) {}
    }

    if (!mounted || _navigationTriggered) return;
    _navigationTriggered = true;

    if (user != null) {
      try {
        context.read<AuthBloc>().add(RestoreUserSessionEvent(user));
      } catch (_) {}

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) =>
              const MainDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) =>
              LoginScreen(sessionExpiredMessage: _sessionExpiredMessage),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBg
          : AppColors.splashScreenLightBackground,
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
    );
  }
}
