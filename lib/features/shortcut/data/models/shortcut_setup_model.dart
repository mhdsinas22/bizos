import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';

class ShortcutSetupModel extends ShortcutSetupEntity {
  const ShortcutSetupModel({
    super.currentStep,
    super.isShortcutInstalled,
    super.isBackTapConfigured,
    super.isCompleted,
    super.completedAt,
    super.deviceName,
  });

  factory ShortcutSetupModel.fromJson(Map<String, dynamic> json) {
    return ShortcutSetupModel(
      currentStep: (json['current_step'] as num?)?.toInt() ?? 1,
      isShortcutInstalled: json['is_shortcut_installed'] as bool? ?? false,
      isBackTapConfigured: json['is_back_tap_configured'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      deviceName: json['device_name'] as String? ?? 'iPhone',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_step': currentStep,
      'is_shortcut_installed': isShortcutInstalled,
      'is_back_tap_configured': isBackTapConfigured,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'device_name': deviceName,
    };
  }

  factory ShortcutSetupModel.fromEntity(ShortcutSetupEntity entity) {
    return ShortcutSetupModel(
      currentStep: entity.currentStep,
      isShortcutInstalled: entity.isShortcutInstalled,
      isBackTapConfigured: entity.isBackTapConfigured,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      deviceName: entity.deviceName,
    );
  }
}
