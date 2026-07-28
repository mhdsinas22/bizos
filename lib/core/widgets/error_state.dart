import 'package:flutter/material.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';

/// Reusable friendly human error state widget with retry action.
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'Unable to Load Data',
    this.message = 'We encountered a temporary issue. Please try again.',
    this.onRetry,
  });

  /// Sanitizes technical error messages (e.g. PostgrestException, SocketException) into human text.
  static String sanitizeMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('postgrest') ||
        lower.contains('socketexception') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('http') ||
        lower.contains('supabase') ||
        lower.contains('exception')) {
      return "We couldn't load your data right now. Please check your connection and try again.";
    }
    return rawMessage;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final friendlyMessage = sanitizeMessage(message);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppTheme.error.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              friendlyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: 'Try Again',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                width: 140,
                height: 42,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

