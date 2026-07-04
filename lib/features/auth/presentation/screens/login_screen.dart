import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          userId: _userIdController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  Future<void> _showContactOwnerDialog(BuildContext context) async {
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
                print('Error: $e');
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
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          print('Current Status: ${state.status}');
          print('Error Message: ${state.errorMessage}');

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
                if (mounted) _showContactOwnerDialog(context);
              });
            }
          }
        },
        builder: (context, state) {
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
                        // App Logo/Branding
                        Center(
                          child: Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryLightColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.business_center,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Voryn ERP',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Professional Enterprise Management Console',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Login Card
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Sign In',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Access your workspace using secure credentials',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 24),
                                CustomTextField(
                                  controller: _userIdController,
                                  label: 'User ID',
                                  hint: 'Enter your User ID',
                                  prefixIcon: Icons.person_outline,
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty
                                      ? 'Please enter your User ID'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: (val) => val == null || val.isEmpty
                                      ? 'Please enter your password'
                                      : null,
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'Sign In',
                                  onPressed: _submit,
                                  isLoading: state.status == AuthStatus.loading,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    "Need Access for Voryn ERP software ? Contact ",
                              ),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: makePhoneCall,
                                  child: Text(
                                    "9048551457",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

Future<void> makePhoneCall() async {
  final Uri phoneUri = Uri.parse('tel:+919048551457');

  try {
    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  } catch (e) {
    print('Error: $e');
  }
}
