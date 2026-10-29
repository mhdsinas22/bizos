import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bizos/core/constants/app_spacing.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A production-quality Quick Add Setup screen for configuring
/// the Apple Shortcuts integration for Personal Expenses.
class QuickAddSetupPage extends StatefulWidget {
  const QuickAddSetupPage({super.key});

  @override
  State<QuickAddSetupPage> createState() => _QuickAddSetupPageState();
}

class _QuickAddSetupPageState extends State<QuickAddSetupPage> {
  final TextEditingController _deviceNameController = TextEditingController(
    text: 'iPhone',
  );

  bool _isLoading = false;
  bool _isPaired = false;
  // One-time pairing token kept strictly in memory for the next setup step.
  // Never logged, stored in SharedPreferences, or exposed in analytics.
  // ignore: unused_field
  String? _pairingToken;
  String? _errorMessage;

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSetupPairing() async {
    if (_isLoading) return;

    final rawDeviceName = _deviceNameController.text.trim();
    final deviceName = rawDeviceName.isEmpty ? 'iPhone' : rawDeviceName;

    // Do not generate additional pairing tokens unnecessarily
    if (_isPaired && _pairingToken != null && _pairingToken!.isNotEmpty) {
      _showPairingSuccessDialog(context, deviceName, _pairingToken!);
      return;
    }

    final client = _supabaseClient;
    final session = client?.auth.currentSession;
    if (client == null || session == null || session.accessToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please sign in to your Haptic account to pair your device.',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await client.functions.invoke(
        'shortcut-pair',
        body: {'device_name': deviceName},
      );

      if (response.status >= 200 && response.status < 300) {
        String? token;
        if (response.data is Map) {
          final data = response.data as Map;
          token =
              data['pairing_token']?.toString() ??
              data['token']?.toString() ??
              data['one_time_token']?.toString() ??
              data['data']?['pairing_token']?.toString();
        } else if (response.data is String &&
            response.data.toString().isNotEmpty) {
          token = response.data.toString();
        }

        if (token == null || token.trim().isEmpty) {
          throw Exception(
            'The pairing function succeeded, but no pairing token was returned by the server.',
          );
        }

        // Keep pairing token strictly in memory only
        _pairingToken = token;

        if (mounted) {
          setState(() {
            _isPaired = true;
            _errorMessage = null;
          });
          _showPairingSuccessDialog(context, deviceName, token);
        }
      } else {
        final errorDetail = _extractErrorMessage(response.data);
        throw Exception(
          errorDetail ?? 'Pairing failed with status code ${response.status}',
        );
      }
    } on FunctionException catch (e) {
      final errorDetail = _extractErrorMessage(e.details) ?? e.reasonPhrase;
      final message = errorDetail ?? 'Pairing error (Status: ${e.status})';
      _onPairingError(message);
    } catch (e) {
      _onPairingError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPairingError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pairing Error: $message'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          data['details']?.toString();
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return null;
  }

  void _showPairingSuccessDialog(
    BuildContext context,
    String deviceName,
    String pairingToken,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => PairingSuccessDialog(
        deviceName: deviceName,
        pairingToken: pairingToken,
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.apple, size: 22),
            SizedBox(width: 8),
            Text('About Quick Add'),
          ],
        ),
        content: Text(
          'Quick Add uses Apple\'s native Shortcuts system to prompt for amount and category directly from your Lock Screen or Action Button. It requires iOS 16 or newer.',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Quick Add Setup'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Shortcuts Help',
            onPressed: () => _showHelpDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenterBody(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // Hero Illustration / Icon Badge
                _buildHeroIllustration(isDark),

                const SizedBox(height: 20),

                // Platform Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.primaryColor.withValues(alpha: 0.16)
                        : AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(
                        alpha: isDark ? 0.3 : 0.2,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.apple,
                        size: 14,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Apple Shortcuts Integration',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppTheme.primaryColor,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Title
                Text(
                  'Quick Add for iPhone',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Concise Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Record personal expenses in seconds from your Lock Screen, Action Button, or Siri without opening the app.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 28),

                // Visual Workflow Explanation Section
                _buildWorkflowSection(context, isDark),

                const SizedBox(height: 20),

                // Informational Sync Section
                _buildInfoSection(context, isDark),

                const SizedBox(height: 24),

                // Device Name Field
                CustomTextField(
                  controller: _deviceNameController,
                  label: 'Device Label',
                  hint: 'e.g. iPhone',
                  prefixIcon: Icons.phone_iphone_rounded,
                ),

                const SizedBox(height: 16),

                // Error message banner (if any)
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Paired Confirmation banner (if paired)
                if (_isPaired) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pairing succeeded! The iPhone Shortcut is not installed yet.',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                              if (_pairingToken != null &&
                                  _pairingToken!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () {
                                    final rawDeviceName = _deviceNameController
                                        .text
                                        .trim();
                                    final deviceName = rawDeviceName.isEmpty
                                        ? 'iPhone'
                                        : rawDeviceName;
                                    _showPairingSuccessDialog(
                                      context,
                                      deviceName,
                                      _pairingToken!,
                                    );
                                  },
                                  child: const Text(
                                    'View or Copy Pairing Token →',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Prominent Setup Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSetupPairing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Pairing Device...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPaired && _pairingToken != null
                                    ? Icons.copy_rounded
                                    : Icons.apple,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _isPaired && _pairingToken != null
                                      ? 'View / Copy Pairing Token'
                                      : 'Set Up iPhone Shortcut',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // Requirements / Footnote
                Text(
                  'Requires iOS 16.0+ and the Apple Shortcuts app',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIllustration(bool isDark) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryColor.withValues(alpha: 0.16)
            : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1.5,
        ),
      ),
      child: const Center(
        child: Icon(Icons.bolt_rounded, size: 40, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildWorkflowSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alt_route_rounded,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'How It Works',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _WorkflowStepItem(
            stepNumber: '1',
            icon: Icons.bolt_rounded,
            title: 'Open Shortcut',
            subtitle: 'Trigger via Action Button, Lock Screen widget, or Siri',
            isFirst: true,
            isLast: false,
          ),
          const _WorkflowStepItem(
            stepNumber: '2',
            icon: Icons.pin_rounded,
            title: 'Enter Amount',
            subtitle: 'Input your expense figure in the native iOS prompt',
            isFirst: false,
            isLast: false,
          ),
          const _WorkflowStepItem(
            stepNumber: '3',
            icon: Icons.category_rounded,
            title: 'Select Category',
            subtitle: 'Choose from your saved personal categories with one tap',
            isFirst: false,
            isLast: false,
          ),
          const _WorkflowStepItem(
            stepNumber: '4',
            icon: Icons.check_circle_rounded,
            title: 'Expense Saved',
            subtitle: 'Instantly recorded and synced to your Haptic account',
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sync_lock_rounded,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'One-Time Setup & Secure Sync',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set up once on your device. Every expense logged through the Shortcut is securely authenticated and automatically saved to your Haptic personal expense ledger in real time.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStepItem extends StatelessWidget {
  final String stepNumber;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;

  const _WorkflowStepItem({
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Node
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                  : AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Step Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog presented upon successful shortcut pairing with Copy Token action and security warning.
class PairingSuccessDialog extends StatelessWidget {
  final String deviceName;
  final String pairingToken;

  const PairingSuccessDialog({
    super.key,
    required this.deviceName,
    required this.pairingToken,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pairing Succeeded',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your device "$deviceName" was successfully paired with your Haptic account.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Pairing Token Display Box
            Text(
              'Your Pairing Token',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pairingToken,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Pairing Token',
                    color: AppTheme.primaryColor,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copyToken(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Prominent Copy Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _copyToken(context),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text(
                  'Copy Pairing Token',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security Warning Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Security Warning: This token is secret and grants direct access to record expenses on your Haptic account. Do not share it with anyone.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Installation Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please note: The iPhone Shortcut is not installed yet. You will connect and install the Shortcut in the next step.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Future<void> _copyToken(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: pairingToken));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pairing token copied to clipboard!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
