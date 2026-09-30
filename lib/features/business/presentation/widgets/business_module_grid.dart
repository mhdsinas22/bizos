import 'package:flutter/material.dart';
import 'package:bizos/features/business/presentation/widgets/business_module_card.dart';

class BusinessModuleItemData {
  final String id;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final String? footerLeft;
  final String? footerRight;
  final Color? footerRightColor;
  final bool footerIsDivided;
  final Color? chevronColor;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isVisible;

  const BusinessModuleItemData({
    required this.id,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    this.footerLeft,
    this.footerRight,
    this.footerRightColor,
    this.footerIsDivided = false,
    this.chevronColor,
    this.onTap,
    this.isEnabled = true,
    this.isVisible = true,
  });
}

class BusinessModuleGrid extends StatelessWidget {
  final List<BusinessModuleItemData> modules;
  final BusinessModuleItemData? fullWidthModule;

  const BusinessModuleGrid({
    super.key,
    required this.modules,
    this.fullWidthModule,
  });

  @override
  Widget build(BuildContext context) {
    final visibleModules = modules.where((m) => m.isVisible).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        int crossAxisCount;
        double cardHeight;
        if (availableWidth < 600) {
          crossAxisCount = 2;
          cardHeight = 126.0;
        } else if (availableWidth < 900) {
          crossAxisCount = availableWidth < 700 ? 2 : 3;
          cardHeight = 130.0;
        } else {
          crossAxisCount = availableWidth < 1200 ? 3 : 4;
          cardHeight = 132.0;
        }

        const double spacing = 12.0;

        final cardWidth =
            (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        final childAspectRatio = cardWidth / cardHeight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleModules.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final module = visibleModules[index];
                return BusinessModuleCard(
                  key: ValueKey('module_${module.id}'),
                  icon: module.icon,
                  accentColor: module.accentColor,
                  title: module.title,
                  description: module.description,
                  footerLeft: module.footerLeft,
                  footerRight: module.footerRight,
                  footerRightColor: module.footerRightColor,
                  footerIsDivided: module.footerIsDivided,
                  chevronColor: module.chevronColor,
                  isEnabled: module.isEnabled,
                  onTap: module.onTap,
                );
              },
            ),

            if (fullWidthModule != null && fullWidthModule!.isVisible) ...[
              const SizedBox(height: spacing),
              BusinessModuleCard(
                key: ValueKey('module_${fullWidthModule!.id}'),
                icon: fullWidthModule!.icon,
                accentColor: fullWidthModule!.accentColor,
                title: fullWidthModule!.title,
                description: fullWidthModule!.description,
                isFullWidth: true,
                isEnabled: fullWidthModule!.isEnabled,
                onTap: fullWidthModule!.onTap,
              ),
            ],
          ],
        );
      },
    );
  }
}

