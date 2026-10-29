import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/shortcut/core/shortcut_constants.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_bloc.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_event.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_state.dart';
import 'package:bizos/features/shortcut/presentation/widgets/shortcut_instruction_card.dart';
import 'package:bizos/features/shortcut/presentation/widgets/shortcut_setup_checklist.dart';
import 'package:bizos/features/shortcut/presentation/widgets/shortcut_step_indicator.dart';
import 'package:bizos/features/shortcut/presentation/widgets/shortcut_visual_graphics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuickAddOnboardingPage extends StatefulWidget {
  final int initialStep;

  const QuickAddOnboardingPage({super.key, this.initialStep = 1});

  @override
  State<QuickAddOnboardingPage> createState() => _QuickAddOnboardingPageState();
}

class _QuickAddOnboardingPageState extends State<QuickAddOnboardingPage> {
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';
    context.read<ShortcutBloc>().add(
      LoadShortcutSetupStatus(
        userId: userId,
        initialStep: widget.initialStep > 1 ? widget.initialStep : null,
      ),
    );
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step.clamp(1, ShortcutConstants.totalOnboardingSteps);
    });
    context.read<ShortcutBloc>().add(ShortcutStepChanged(_currentStep));
  }

  void _nextStep(int currentStep) {
    if (currentStep < ShortcutConstants.totalOnboardingSteps) {
      _goToStep(currentStep + 1);
    } else {
      context.read<ShortcutBloc>().add(const CompleteOnboarding());
      Navigator.of(context).maybePop();
    }
  }

  void _previousStep(int currentStep) {
    if (currentStep > 1) {
      _goToStep(currentStep - 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ShortcutBloc, ShortcutState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.currentStep != _currentStep) {
          setState(() {
            _currentStep = state.currentStep;
          });
        }
      },
      builder: (context, state) {
        final currentStep = _currentStep;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0B0F17)
              : const Color(0xFFFAFBFD),
          body: SafeArea(
            child: Column(
              children: [
                // Top Step Header (Screens 1 to 12)
                ShortcutStepIndicator(
                  currentStep: currentStep,
                  totalSteps: ShortcutConstants.totalOnboardingSteps,
                  stepLabel:
                      currentStep > 1 &&
                          currentStep <= ShortcutConstants.totalOnboardingSteps
                      ? '$currentStep of ${ShortcutConstants.totalOnboardingSteps}'
                      : null,
                  onBack: () => _previousStep(currentStep),
                  onClose: () => Navigator.of(context).maybePop(),
                ),

                // Main Step Body
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: _buildStepContent(context, state, isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ShortcutState state,
    bool isDark,
  ) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Introduction(context, isDark);
      case 2:
        return _buildStep2AddShortcut(context, state, isDark);
      case 3:
        return _buildStep3InShortcutsPreview(context, isDark);
      case 4:
        return _buildStep4OpenSettings(context, isDark);
      case 5:
        return _buildStep5TapTouch(context, isDark);
      case 6:
        return _buildStep6EnableBackTap(context, isDark);
      case 7:
        return _buildStep7ChooseDoubleTap(context, isDark);
      case 8:
        return _buildStep8SelectShortcut(context, isDark);
      case 9:
        return _buildStep9SetupComplete(context, state, isDark);
      case 10:
        return _buildStep12UseWithSiri(context, isDark);
      default:
        return _buildStep12UseWithSiri(context, isDark);
    }
  }

  // ==========================================
  // STEP 1: Quick Add Introduction
  // ==========================================
  Widget _buildStep1Introduction(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Add',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppTheme.primaryColor,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add expenses in seconds without opening Haptic.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // 3D Phone Hero with Coffee, Fuel, Shopping cards
        const QuickAddPhoneHero(),

        const SizedBox(height: 24),

        // Value Proposition Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131926) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Use Back Tap, Siri or Shortcuts to quickly add expenses to Haptic.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildBullet(label: 'Super fast expense entry', isDark: isDark),
              const SizedBox(height: 8),
              _buildBullet(label: 'Works offline', isDark: isDark),
              const SizedBox(height: 8),
              _buildBullet(label: 'Secure & private', isDark: isDark),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Primary Button: "Let's Set Up →"
        _buildGradientButton(
          label: "Let's Set Up →",
          onPressed: () => _nextStep(1),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ==========================================
  // STEP 2: Add Haptic Shortcut to your library
  // ==========================================
  Widget _buildStep2AddShortcut(
    BuildContext context,
    ShortcutState state,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Add Haptic Shortcut to your library',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the button below to add the Haptic Quick Add shortcut to your Shortcuts app.',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // Centered Voryn Shortcut Card Preview
        Center(
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131926) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'V',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Haptic',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quick Add Expense',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMiniFeature(
                  icon: Icons.bolt_rounded,
                  text: 'Add expense quickly',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildMiniFeature(
                  icon: Icons.access_time_rounded,
                  text: 'Works offline',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildMiniFeature(
                  icon: Icons.lock_outline_rounded,
                  text: 'Secure & private',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 36),

        _buildGradientButton(
          icon: Icons.add_rounded,
          label: 'Add to Shortcuts',
          onPressed: () {
            context.read<ShortcutBloc>().add(const OpenShortcutsAppRequested());
            context.read<ShortcutBloc>().add(const ConfirmShortcutInstalled());
            _nextStep(2);
          },
        ),

        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "This will open the Apple Shortcuts app. After adding, you'll return to Haptic automatically.",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: In Shortcuts Preview Modal
  // ==========================================
  Widget _buildStep3InShortcutsPreview(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131926) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const Icon(Icons.ios_share_rounded, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'V',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Haptic – Quick Add Expense',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Shared 12 Sep 2026',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'H',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Haptic\nQuick Add Expense',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.more_horiz_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'About This Shortcut',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildShortcutDetailRow(
                icon: Icons.graphic_eq_rounded,
                text: 'Say "Hey Siri, add expense in Haptic" to run',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildShortcutDetailRow(
                icon: Icons.watch_rounded,
                text: 'Appears on Apple Watch',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildShortcutDetailRow(
                icon: Icons.ios_share_rounded,
                text: 'Appears in Share Sheet',
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildGradientButton(
          label: 'Add Shortcut',
          onPressed: () {
            context.read<ShortcutBloc>().add(const ConfirmShortcutInstalled());
            _nextStep(3);
          },
        ),

        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => _nextStep(3),
            child: const Text('Show Actions'),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: Open iPhone Settings
  // ==========================================
  Widget _buildStep4OpenSettings(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Open iPhone Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Now open your iPhone Settings app and tap on "Accessibility".',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),

        const ShortcutInstructionCard(type: InstructionCardType.openSettings),

        const SizedBox(height: 24),

        _buildGradientButton(
          icon: Icons.open_in_new_rounded,
          label: 'Open Settings',
          onPressed: () {
            context.read<ShortcutBloc>().add(const OpenIosSettingsRequested());
            _nextStep(4);
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap the button to open Settings app.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 5: Tap Touch
  // ==========================================
  Widget _buildStep5TapTouch(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tap Touch',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Under the Physical and Motor section, tap "Touch".',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),

        const ShortcutInstructionCard(type: InstructionCardType.tapTouch),

        const SizedBox(height: 24),

        _buildGradientButton(
          label: "I've Opened Touch",
          onPressed: () => _nextStep(5),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 6: Enable Back Tap
  // ==========================================
  Widget _buildStep6EnableBackTap(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enable Back Tap',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Scroll down and tap "Back Tap".',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),

        const ShortcutInstructionCard(type: InstructionCardType.enableBackTap),

        const SizedBox(height: 24),

        _buildGradientButton(
          label: "I've Opened Back Tap",
          onPressed: () => _nextStep(6),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 7: Choose Double Tap
  // ==========================================
  Widget _buildStep7ChooseDoubleTap(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose Double Tap',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap "Double Tap" (or "Triple Tap" if you prefer).',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),

        const ShortcutInstructionCard(
          type: InstructionCardType.chooseDoubleTap,
        ),

        const SizedBox(height: 24),

        _buildGradientButton(label: 'Continue', onPressed: () => _nextStep(7)),
      ],
    );
  }

  // ==========================================
  // STEP 8: Select Haptic Shortcut
  // ==========================================
  Widget _buildStep8SelectShortcut(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select Haptic Shortcut',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Scroll down and select "Haptic – Quick Add Expense" from the list.',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),

        const ShortcutInstructionCard(type: InstructionCardType.selectShortcut),

        const SizedBox(height: 24),

        _buildGradientButton(
          label: "I've Selected Haptic",
          onPressed: () {
            context.read<ShortcutBloc>().add(const ConfirmBackTapConfigured());
            _nextStep(8);
          },
        ),
      ],
    );
  }

  // ==========================================
  // STEP 9: You're nearly set!
  // ==========================================
  Widget _buildStep9SetupComplete(
    BuildContext context,
    ShortcutState state,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        const CelebrationCheckmarkGraphic(
          circleColor: AppTheme.primaryColor,
          icon: Icons.check_rounded,
        ),
        const SizedBox(height: 16),
        Text(
          'Back on Haptic',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "You're nearly set!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your shortcut is added and Back Tap is configured. Now test it to make sure everything works.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        ShortcutSetupChecklist(
          isShortcutAdded: state.isShortcutInstalled,
          isBackTapConfigured: state.isBackTapConfigured,
          isReady: true,
        ),

        const SizedBox(height: 28),

        // "▶ Test Quick Add"
        _buildGradientButton(label: 'Continue', onPressed: () => _goToStep(10)),
      ],
    );
  }

  // ==========================================
  // STEP 10: Use with Siri
  // ==========================================
  Widget _buildStep12UseWithSiri(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Use with Siri',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You can also add expenses using Siri. Try one of these:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 28),

        const Center(child: SiriOrbGraphic()),

        const SizedBox(height: 28),

        const SiriPhraseCard(phrase: 'Hey Siri, add expense in Haptic'),
        const SizedBox(height: 12),
        const SiriPhraseCard(phrase: 'Hey Siri, log expense in Haptic'),
        const SizedBox(height: 12),
        const SiriPhraseCard(
          phrase: 'Hey Siri, add ₹500 food expense in Haptic',
        ),

        const SizedBox(height: 32),

        _buildGradientButton(
          label: 'All Set!',
          onPressed: () {
            context.read<ShortcutBloc>().add(const CompleteOnboarding());
            Navigator.of(context).maybePop();
          },
        ),

        const SizedBox(height: 12),
        Center(
          child: Text(
            'You can always change this later in Settings.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildBullet({required String label, required bool isDark}) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniFeature({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutDetailRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    IconData? icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppTheme.primaryOnColor, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOnColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
