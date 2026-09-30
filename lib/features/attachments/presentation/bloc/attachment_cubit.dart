import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/attachments/domain/entities/attachment_entity.dart';
import 'package:bizos/features/attachments/domain/usecases/delete_attachment_usecase.dart';
import 'package:bizos/features/attachments/domain/usecases/get_attachments_usecase.dart';
import 'package:bizos/features/attachments/domain/usecases/upload_attachment_usecase.dart';
import 'package:bizos/features/attachments/presentation/bloc/attachment_state.dart';

class AttachmentCubit extends Cubit<AttachmentState> {
  final UploadAttachmentUseCase uploadAttachmentUseCase;
  final GetAttachmentsUseCase getAttachmentsUseCase;
  final DeleteAttachmentUseCase deleteAttachmentUseCase;

  AttachmentCubit({
    required this.uploadAttachmentUseCase,
    required this.getAttachmentsUseCase,
    required this.deleteAttachmentUseCase,
  }) : super(const AttachmentInitial());

  Future<void> loadAttachments({
    required String entityType,
    required String entityId,
  }) async {
    emit(const AttachmentLoading());
    try {
      final attachments = await getAttachmentsUseCase(
        entityType: entityType,
        entityId: entityId,
      );
      emit(AttachmentLoaded(attachments));
    } catch (e) {
      emit(AttachmentError('Failed to load attachments: ${e.toString()}'));
    }
  }

  Future<AttachmentEntity?> uploadAttachment({
    required String businessId,
    required String entityType,
    required String entityId,
    required File file,
    required String fileName,
    String? userId,
  }) async {
    emit(const AttachmentUploading());
    try {
      final attachment = await uploadAttachmentUseCase(
        businessId: businessId,
        entityType: entityType,
        entityId: entityId,
        file: file,
        fileName: fileName,
        userId: userId,
      );
      emit(AttachmentUploadSuccess(attachment));
      return attachment;
    } catch (e) {
      emit(AttachmentError('Failed to upload attachment: ${e.toString()}'));
      return null;
    }
  }

  Future<void> deleteAttachment(AttachmentEntity attachment) async {
    final currentState = state;
    List<AttachmentEntity> currentList = [];
    if (currentState is AttachmentLoaded) {
      currentList = List.from(currentState.attachments);
    }

    emit(AttachmentDeleting(attachment.id));
    try {
      await deleteAttachmentUseCase(attachment);
      final updatedList = currentList.where((a) => a.id != attachment.id).toList();
      emit(AttachmentLoaded(updatedList));
    } catch (e) {
      emit(AttachmentError('Failed to delete attachment: ${e.toString()}'));
      if (currentList.isNotEmpty) {
        emit(AttachmentLoaded(currentList));
      }
    }
  }
}
