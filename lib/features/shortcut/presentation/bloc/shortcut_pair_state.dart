enum ShortcutPairStatus { initial, loading, success, failure }

class ShortcutPairState {
  final ShortcutPairStatus status;
  final String? pairingCode;
  final String? errorMessage;

  const ShortcutPairState({
    this.status = ShortcutPairStatus.initial,
    this.pairingCode,
    this.errorMessage,
  });

  ShortcutPairState copyWith({
    ShortcutPairStatus? status,
    String? pairingCode,
    String? errorMessage,
    bool clearPairingCode = false,
    bool clearErrorMessage = false,
  }) {
    return ShortcutPairState(
      status: status ?? this.status,
      pairingCode: clearPairingCode ? null : pairingCode ?? this.pairingCode,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
