import 'package:bizos/features/notifications/domain/usecases/save_fcm_token.dart';
import 'package:bizos/features/notifications/presentation/bloc/notification_event.dart';
import 'package:bizos/features/notifications/presentation/bloc/notification_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final SaveFcmToken saveFcmTokenUsecase;
  NotificationBloc({required this.saveFcmTokenUsecase})
    : super(NotificationState()) {
    on<InitAndSaveFCMTokenEvent>(_initAndSaveFCMTokenEvent);
  }
  Future<void> _initAndSaveFCMTokenEvent(
    NotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // await saveFcmTokenUsecase();
      emit(state.copyWith(notificationStatus: NotificationStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          notificationStatus: NotificationStatus.error,
          message: "Failed to save FCM token: $e",
        ),
      );
    }
  }
}
