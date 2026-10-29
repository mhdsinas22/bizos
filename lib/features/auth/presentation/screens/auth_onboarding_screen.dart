import 'package:bizos/bizos_app.dart';
import 'package:bizos/core/constants/app_images.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';
import 'package:bizos/features/auth/domain/entities/onboarding_slide_entity.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/create_account_screen.dart';
import 'package:bizos/features/auth/presentation/screens/google_registration_screen.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/auth/presentation/widgets/auth_background_scaffold.dart';
import 'package:bizos/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:bizos/features/auth/presentation/widgets/auth_divider.dart';
import 'package:bizos/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:bizos/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthOnboardingScreen extends StatefulWidget {
  final String? sessionExpiredMessage;

  const AuthOnboardingScreen({super.key, this.sessionExpiredMessage});

  @override
  State<AuthOnboardingScreen> createState() => _AuthOnboardingScreenState();
}

class _AuthOnboardingScreenState extends State<AuthOnboardingScreen> {
  late final PageController _pageController;
  final int _currentPage = 0;
  bool _hasNavigatedToDashboard = false;
  bool _isNavigatingToGoogleRegistration = false;

  final List<OnboardingSlideEntity> _slides =
      OnboardingSlideEntity.defaultSlides;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    if (widget.sessionExpiredMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.sessionExpiredMessage!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToSignIn() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            const LoginScreen(showDirectSignIn: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _navigateToCreateAccount() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            const CreateAccountScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _handleGoogleContinue() {
    if (context.read<AuthBloc>().state.status == AuthStatus.loading) {
      return;
    }
    context.read<AuthBloc>().add(GoogleSignInRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSlide = _slides[_currentPage];

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          previous.status != current.status ||
          previous.user != current.user,
      listener: (context, state) {
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
        if (!isCurrentRoute) return;

        if (state is GoogleRegistrationRequired &&
            !_isNavigatingToGoogleRegistration) {
          _isNavigatingToGoogleRegistration = true;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.of(context)
              .push(
                PageRouteBuilder(
                  pageBuilder: (_, animation, secondaryAnimation) =>
                      GoogleRegistrationScreen(
                        registrationInfo: GoogleRegistrationInfo(
                          authUserId: state.authUserId,
                          email: state.email,
                          suggestedName: state.suggestedName,
                        ),
                      ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 280),
                ),
              )
              .whenComplete(() {
                if (mounted) {
                  _isNavigatingToGoogleRegistration = false;
                }
              });
          return;
        }

        if (state.status == AuthStatus.authenticated &&
            state.user != null &&
            !_hasNavigatedToDashboard) {
          _hasNavigatedToDashboard = true;
          final navigator =
              appNavigatorKey.currentState ??
              Navigator.of(context, rootNavigator: true);
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
            (route) => false,
          );
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Authentication failed'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: AuthBackgroundScaffold(
        topWaveOnLeft: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 8.0,
        ),
        topRightAction: TextButton(
          onPressed: _navigateToSignIn,
          style: TextButton.styleFrom(
            foregroundColor: isDark
                ? AppTheme.darkTextSecondary
                : const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: const Text(
            'Skip',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBrandHeader(logoSize: 68, brandFontSize: 27),
            const SizedBox(height: 12),

            // Dynamic Headline
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey<int>(_currentPage),
                children: [
                  Text(
                    currentSlide.titlePrimary,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      height: 1.18,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    currentSlide.titleAccent,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      height: 1.18,
                      color: Color(0xFF639E1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSlide.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Hero Illustration Carousel (Floating Green Business Dashboard UI)
            SizedBox(
              height: 245,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient soft green glow behind illustration
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Image.asset(
                      AppImages.onboardingDashboardUi,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Continue with Google (Green Filled Pill)
            GoogleAuthButton(
              variant: GoogleAuthButtonVariant.greenFilled,
              text: 'Continue with Google',
              height: 52,
              onPressed: _handleGoogleContinue,
            ),
            const SizedBox(height: 12),

            // Sign in with Email (Soft Grey Pill)
            _OnboardingSecondaryPillButton(
              text: 'Sign in with Email',
              leadingIcon: Icons.mail_outline_rounded,
              showTrailingChevron: true,
              onPressed: _navigateToSignIn,
            ),
            const SizedBox(height: 14),

            // "or" Divider
            const AuthDivider(text: 'or'),
            const SizedBox(height: 14),

            // Create an Account (Soft Grey Pill)
            _OnboardingSecondaryPillButton(
              text: 'Create an Account',
              showTrailingChevron: false,
              onPressed: _navigateToCreateAccount,
            ),
            const SizedBox(height: 18),

            // Terms & Privacy Footer
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : const Color(0xFF64748B),
                ),
                children: [
                  const TextSpan(text: 'By continuing, you agree to our\n'),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: Color(0xFF5A9416),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF5A9416),
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () {},
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: Color(0xFF5A9416),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF5A9416),
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSecondaryPillButton extends StatelessWidget {
  final String text;
  final IconData? leadingIcon;
  final bool showTrailingChevron;
  final VoidCallback onPressed;

  const _OnboardingSecondaryPillButton({
    required this.text,
    required this.onPressed,
    this.leadingIcon,
    this.showTrailingChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkSurface : const Color(0xFFEEF2F6);
    final textColor = isDark
        ? AppTheme.darkTextPrimary
        : const Color(0xFF0F172A);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (leadingIcon != null)
                  SizedBox(
                    width: 28,
                    child: Icon(
                      leadingIcon,
                      size: 20,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : const Color(0xFF334155),
                    ),
                  )
                else if (showTrailingChevron)
                  const SizedBox(width: 28),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (showTrailingChevron)
                  SizedBox(
                    width: 28,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : const Color(0xFF475569),
                    ),
                  )
                else if (leadingIcon != null)
                  const SizedBox(width: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
