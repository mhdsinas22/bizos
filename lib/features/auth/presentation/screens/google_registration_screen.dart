import 'package:bizos/bizos_app.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/auth/presentation/widgets/auth_background_scaffold.dart';
import 'package:bizos/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:bizos/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:bizos/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoogleRegistrationScreen extends StatefulWidget {
  final GoogleRegistrationInfo? registrationInfo;
  final String? authUserId;
  final String? email;
  final String? suggestedName;

  const GoogleRegistrationScreen({
    super.key,
    this.registrationInfo,
    this.authUserId,
    this.email,
    this.suggestedName,
  });

  @override
  State<GoogleRegistrationScreen> createState() =>
      _GoogleRegistrationScreenState();
}

class _GoogleRegistrationScreenState extends State<GoogleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  final _phoneController = TextEditingController();

  bool _hasNavigatedToDashboard = false;
  bool _isBackingOut = false;

  @override
  void initState() {
    super.initState();

    String resolvedEmail = widget.registrationInfo?.email ?? widget.email ?? '';
    String resolvedName =
        widget.registrationInfo?.suggestedName ?? widget.suggestedName ?? '';

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is GoogleRegistrationRequired) {
        if (resolvedEmail.isEmpty) {
          resolvedEmail = authState.email;
        }
        if (resolvedName.isEmpty) {
          resolvedName = authState.suggestedName;
        }
      }
    } catch (_) {}

    _fullNameController = TextEditingController(text: resolvedName.trim());
    _emailController = TextEditingController(text: resolvedEmail.trim());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (val.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Google account email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(val.trim())) {
      return 'Invalid Google account email address';
    }
    return null;
  }

  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final trimmed = val.trim();
    final formatRegex = RegExp(r'^\+?[\d\s\-()]+$');
    if (!formatRegex.hasMatch(trimmed)) {
      return 'Please enter a valid phone number';
    }
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Phone number must be between 7 and 15 digits';
    }
    return null;
  }

  void _submit() {
    if (context.read<AuthBloc>().state.status == AuthStatus.loading) {
      return;
    }
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
        CompleteGoogleRegistrationRequested(
          name: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
        ),
      );
    }
  }

  void _handleBack() {
    if (_isBackingOut) return;
    if (context.read<AuthBloc>().state.status == AuthStatus.loading) {
      return;
    }
    _isBackingOut = true;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(LogoutRequested());

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType ||
            previous.status != current.status ||
            previous.user != current.user,
        listener: (context, state) {
          if (_isBackingOut) return;

          if (state.status == AuthStatus.authenticated &&
              state.user != null &&
              !_hasNavigatedToDashboard) {
            _hasNavigatedToDashboard = true;
            AppLogger.info(
              'Google registration completed; navigating to MainDashboardScreen.',
            );
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration complete! Welcome to Haptic.'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
            final navigator =
                appNavigatorKey.currentState ??
                Navigator.of(context, rootNavigator: true);
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
              (route) => false,
            );
          } else if (state.status == AuthStatus.error) {
            final errorMessage =
                state.errorMessage ?? 'Registration failed. Please try again.';
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );

            final lowerError = errorMessage.toLowerCase();
            if (lowerError.contains('session') &&
                lowerError.contains('expired')) {
              _isBackingOut = true;
              context.read<AuthBloc>().add(LogoutRequested());
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(showDirectSignIn: true),
                  ),
                );
              }
            }
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;

          return AuthBackgroundScaffold(
            showBackButton: true,
            onBackPressed: isLoading ? () {} : _handleBack,
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
                  logoSize: 68,
                  brandFontSize: 27,
                  subtitle: 'Complete your profile to get started',
                ),
                const SizedBox(height: 22),
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
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkBg
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkBorder
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const GoogleLogoIcon(size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Complete Registration',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Confirm your details to set up your owner workspace.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        CustomTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          prefixIcon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.name,
                          readOnly: isLoading,
                          validator: _validateFullName,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Google account email',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                          suffixIcon: Tooltip(
                            message: 'Verified via Google',
                            child: Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: isDark
                                  ? AppTheme.primaryLightColor
                                  : const Color(0xFF5A9416),
                            ),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'Enter your phone number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          readOnly: isLoading,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Complete Registration',
                          height: 52,
                          borderRadius: 28,
                          useGradient: false,
                          onPressed: _submit,
                          isLoading: isLoading,
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
      ),
    );
  }
}
