abstract class ShortcutPairEvent {
  const ShortcutPairEvent();
  List<Object?> get props => [];
}

class ShortcutPairRequested extends ShortcutPairEvent {
  final String deviceName;
  const ShortcutPairRequested({required this.deviceName});
  @override
  List<Object?> get props => [deviceName];
}

class ShortcutPairVerificationRequested extends ShortcutPairEvent {
  final String code;

  const ShortcutPairVerificationRequested({required this.code});

  @override
  List<Object?> get props => [code];
}
