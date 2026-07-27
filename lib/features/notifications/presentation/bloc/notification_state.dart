enum NotificationStatus { initial, loading, loaded, error }

class NotificationState {
  final NotificationStatus notificationStatus;
  final String message;

  const NotificationState({
    this.notificationStatus = NotificationStatus.loading,
    this.message = "",
  });

  NotificationState copyWith({
    NotificationStatus? notificationStatus,
    String? message,
  }) {
    return NotificationState(
      notificationStatus: notificationStatus ?? this.notificationStatus,
      message: message ?? this.message,
    );
  }
}
