import 'package:bizos/features/shortcut/presentation/pages/quick_add_onboarding_page.dart';
import 'package:flutter/material.dart';

class ShortcutInstallationPage extends StatelessWidget {
  const ShortcutInstallationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuickAddOnboardingPage(initialStep: 2);
  }
}
