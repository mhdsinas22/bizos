import 'package:bizos/core/constants/app_images.dart';

class OnboardingSlideEntity {
  final String titlePrimary;
  final String titleAccent;
  final String subtitle;
  final String imagePath;

  const OnboardingSlideEntity({
    required this.titlePrimary,
    required this.titleAccent,
    required this.subtitle,
    required this.imagePath,
  });

  static const List<OnboardingSlideEntity> defaultSlides = [
    OnboardingSlideEntity(
      titlePrimary: 'Your Business.',
      titleAccent: 'One Platform.',
      subtitle:
          'Manage your business, team, finance\nand more — all in one place.',
      imagePath: AppImages.onboardingDashboardUi,
    ),
    OnboardingSlideEntity(
      titlePrimary: 'Smart Analytics.',
      titleAccent: 'Real-Time Growth.',
      subtitle:
          'Track revenue, expenses, and performance\nwith clear visual insights.',
      imagePath: AppImages.greenreports3d,
    ),
    OnboardingSlideEntity(
      titlePrimary: 'Seamless Team.',
      titleAccent: 'Total Control.',
      subtitle:
          'Organize tasks, inventory, and staff\noperations effortlessly.',
      imagePath: AppImages.store3Dimage,
    ),
  ];
}
