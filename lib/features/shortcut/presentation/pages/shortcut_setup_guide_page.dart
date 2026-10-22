import 'package:bizos/features/shortcut/presentation/pages/quick_add_onboarding_page.dart';
import 'package:flutter/material.dart';

class ShortcutSetupGuidePage extends StatelessWidget {
  final int guideStep;

  const ShortcutSetupGuidePage({super.key, this.guideStep = 4});

  @override
  Widget build(BuildContext context) {
    return QuickAddOnboardingPage(initialStep: guideStep);
  }
}
