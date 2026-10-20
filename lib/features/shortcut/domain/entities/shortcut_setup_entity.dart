import 'package:equatable/equatable.dart';

class ShortcutSetupEntity extends Equatable {
  final int currentStep;
  final bool isShortcutInstalled;
  final bool isBackTapConfigured;
  final bool isCompleted;
  final DateTime? completedAt;
  final String deviceName;

  const ShortcutSetupEntity({
    this.currentStep = 1,
    this.isShortcutInstalled = false,
    this.isBackTapConfigured = false,
    this.isCompleted = false,
    this.completedAt,
    this.deviceName = 'iPhone',
  });

  ShortcutSetupEntity copyWith({
    int? currentStep,
    bool? isShortcutInstalled,
    bool? isBackTapConfigured,
    bool? isCompleted,
    DateTime? completedAt,
    String? deviceName,
  }) {
    return ShortcutSetupEntity(
      currentStep: currentStep ?? this.currentStep,
      isShortcutInstalled: isShortcutInstalled ?? this.isShortcutInstalled,
      isBackTapConfigured: isBackTapConfigured ?? this.isBackTapConfigured,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        isShortcutInstalled,
        isBackTapConfigured,
        isCompleted,
        completedAt,
        deviceName,
      ];
}
