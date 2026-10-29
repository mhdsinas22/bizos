import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/config/auth_config.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/auth_onboarding_screen.dart';
import 'package:bizos/features/auth/presentation/screens/create_account_screen.dart';
import 'package:bizos/features/auth/presentation/screens/google_registration_screen.dart';
import 'package:bizos/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:bizos/features/auth/presentation/widgets/auth_background_scaffold.dart';
import 'package:bizos/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:bizos/features/auth/presentation/widgets/auth_divider.dart';
import 'package:bizos/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/bizos_app.dart';
import 'package:bizos/features/dashboard/presentation/screens/main_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? sessionExpiredMessage;
  final bool showDirectSignIn;

  const LoginScreen({
    super.key,
    this.sessionExpiredMessage,
    this.showDirectSignIn = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hasNavigatedToDashboard = false;
  bool _isNavigatingToGoogleRegistration = false;

  @override
  void initState() {
    super.initState();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (context.read<AuthBloc>().state.status == AuthStatus.loading) return;
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) =>
              const AuthOnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 280),
        ),
      );
    }
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            ResetPasswordScreen(initialEmail: _emailController.text.trim()),
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

  Future<void> _showContactOwnerDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Need Access?'),
        content: const Text(
          'This software is licensed for authorized businesses only.\n\n'
          'If you need access or would like to purchase this software, please contact the product developer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final Uri url = Uri.parse('tel:+919048551457');
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                AppLogger.error('Error: $e');
              }
            },
            icon: const Icon(Icons.call),
            label: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          previous.status != current.status ||
          previous.user != current.user,
      listener: (context, state) {
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
        if (!isCurrentRoute) return;

        AppLogger.info('Current Status: ${state.status}');
        if (state.errorMessage != null) {
          AppLogger.error('Error Message: ${state.errorMessage}');
        }

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
          AppLogger.info('NAVIGATING TO MAIN DASHBOARD');
          final navigator =
              appNavigatorKey.currentState ??
              Navigator.of(context, rootNavigator: true);
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
            (route) => false,
          );
        }

        if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Authentication failed'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );

          if (state is AuthError && state.isContactOwnerRequired) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _showContactOwnerDialog();
            });
          }
        }
      },
      builder: (context, state) {
        return AuthBackgroundScaffold(
          showBackButton: true,
          onBackPressed: _handleBack,
          topWaveOnLeft: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 8.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandHeader(
                logoSize: 70,
                brandFontSize: 27,
                subtitle: 'Professional Enterprise Management Console',
              ),
              const SizedBox(height: 22),

              // Sign In Card Container matching mockup
              Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurface.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorder
                        : Colors.white.withValues(alpha: 0.95),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Access your workspace using your credentials.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Builder(
                        builder: (context) {
                          final isSupabaseAuth = AuthConfig.useSupabaseAuth;
                          return CustomTextField(
                            controller: _emailController,
                            label: isSupabaseAuth ? 'Email' : 'User ID',
                            hint: isSupabaseAuth
                                ? 'Enter your email'
                                : 'Enter your User ID',
                            prefixIcon: isSupabaseAuth
                                ? Icons.mail_outline_rounded
                                : Icons.person_outline_rounded,
                            keyboardType: isSupabaseAuth
                                ? TextInputType.emailAddress
                                : TextInputType.text,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return isSupabaseAuth
                                    ? 'Please enter your email'
                                    : 'Please enter your User ID';
                              }
                              if (isSupabaseAuth) {
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(val.trim())) {
                                  return 'Please enter a valid email address';
                                }
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        validator: (val) => val == null || val.isEmpty
                            ? 'Please enter your password'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _navigateToForgotPassword,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5A9416),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomButton(
                        text: 'Sign In',
                        height: 52,
                        borderRadius: 28,
                        useGradient: false,
                        onPressed: _submit,
                        isLoading: state.status == AuthStatus.loading,
                      ),
                      const SizedBox(height: 18),
                      const AuthDivider(text: 'or continue with'),
                      const SizedBox(height: 18),
                      GoogleAuthButton(
                        variant: GoogleAuthButtonVariant.whiteElevated,
                        text: 'Continue with Google',
                        height: 50,
                        onPressed: _handleGoogleContinue,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              "Don't have an account? ",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToCreateAccount,
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5A9416),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

Future<void> makePhoneCall() async {
  final Uri phoneUri = Uri.parse('tel:+919048551457');

  try {
    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  } catch (e) {
    AppLogger.error('Error: $e');
  }
}
