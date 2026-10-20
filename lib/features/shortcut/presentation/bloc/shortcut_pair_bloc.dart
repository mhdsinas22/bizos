import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/shortcut/domain/usecases/pair_shortcut.dart';
import 'package:bizos/features/shortcut/domain/usecases/verify_shortcut_pairing_code.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_pair_event.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_pair_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShortcutPairBloc extends Bloc<ShortcutPairEvent, ShortcutPairState> {
  final PairShortcut pairShortcut;
  final VerifyShortcutPairingCode verifyShortcutPairingCode;

  ShortcutPairBloc({
    required this.pairShortcut,
    required this.verifyShortcutPairingCode,
  }) : super(const ShortcutPairState()) {
    on<ShortcutPairRequested>(_onShortcutPair);
    on<ShortcutPairVerificationRequested>(_onVerifyShortcutPairingCode);
  }

  Future<void> _onShortcutPair(
    ShortcutPairRequested event,
    Emitter<ShortcutPairState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ShortcutPairStatus.loading,
        clearErrorMessage: true,
        clearPairingCode: true,
      ),
    );

    try {
      final result = await pairShortcut.pair(deviceName: event.deviceName);
      AppLogger.debug("result--$result");
      final pairingCode = result['pairing_code'];

      emit(
        state.copyWith(
          status: ShortcutPairStatus.success,
          pairingCode: pairingCode as String,
          clearErrorMessage: true,
          clearPairingCode: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ShortcutPairStatus.failure,
          errorMessage: e.toString(),
          clearPairingCode: true,
        ),
      );
    }
  }

  Future<void> _onVerifyShortcutPairingCode(
    ShortcutPairVerificationRequested event,
    Emitter<ShortcutPairState> emit,
  ) async {
    emit(state.copyWith(status: ShortcutPairStatus.loading));
    try {
      await verifyShortcutPairingCode.verify(code: event.code);
      emit(
        state.copyWith(
          status: ShortcutPairStatus.success,
          clearPairingCode: true,
        ),
      );
    } catch (e) {
      AppLogger.error("Error verifying shortcut pairing code: $e");
      emit(
        state.copyWith(
          status: ShortcutPairStatus.failure,
          errorMessage: e.toString(),
          clearPairingCode: true,
        ),
      );
    }
  }
}
