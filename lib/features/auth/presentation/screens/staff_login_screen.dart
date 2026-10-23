import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            AppLogger.error('Staff Login Error: ${state.errorMessage}');
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ??
                      'Authentication failed. Please verify your staff credentials.',
                ),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state.status == AuthStatus.authenticated &&
              state.user != null) {
            // If pushed on top of LoginScreen, pop back to allow root navigator to display Dashboard
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: SafeArea(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Portal Badge/Icon
                        Center(
                          child: Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.accentColor,
                                  AppTheme.primaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.badge_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Staff Workspace',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in with your organization-issued staff email and password',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Login Form Card
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Staff Sign In',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enter your credentials to access assigned tasks and branches',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 24),
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Staff Email',
                                  hint: 'staff@company.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your staff email';
                                    }
                                    final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                    );
                                    if (!emailRegex.hasMatch(val.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (val.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Sign In to Staff Portal',
                                  onPressed: _submit,
                                  isLoading: isLoading,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Switch to Owner Console
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Business Owner? Sign In to Admin Console',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
