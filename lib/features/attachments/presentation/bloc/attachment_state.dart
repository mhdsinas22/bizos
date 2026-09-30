import 'package:equatable/equatable.dart';
import 'package:bizos/features/attachments/domain/entities/attachment_entity.dart';

abstract class AttachmentState extends Equatable {
  const AttachmentState();

  @override
  List<Object?> get props => [];
}

class AttachmentInitial extends AttachmentState {
  const AttachmentInitial();
}

class AttachmentLoading extends AttachmentState {
  const AttachmentLoading();
}

class AttachmentLoaded extends AttachmentState {
  final List<AttachmentEntity> attachments;

  const AttachmentLoaded(this.attachments);

  @override
  List<Object?> get props => [attachments];
}

class AttachmentUploading extends AttachmentState {
  final double progress;

  const AttachmentUploading({this.progress = 0.0});

  @override
  List<Object?> get props => [progress];
}

class AttachmentUploadSuccess extends AttachmentState {
  final AttachmentEntity attachment;

  const AttachmentUploadSuccess(this.attachment);

  @override
  List<Object?> get props => [attachment];
}

class AttachmentDeleting extends AttachmentState {
  final String attachmentId;

  const AttachmentDeleting(this.attachmentId);

  @override
  List<Object?> get props => [attachmentId];
}

class AttachmentError extends AttachmentState {
  final String message;

  const AttachmentError(this.message);

  @override
  List<Object?> get props => [message];
}
