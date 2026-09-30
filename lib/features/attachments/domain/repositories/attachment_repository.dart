import 'dart:io';
import 'package:bizos/features/attachments/domain/entities/attachment_entity.dart';

abstract class AttachmentRepository {
  Future<AttachmentEntity> uploadAttachment({
    required String businessId,
    required String entityType,
    required String entityId,
    required File file,
    required String fileName,
    String? userId,
  });

  Future<List<AttachmentEntity>> getAttachments({
    required String entityType,
    required String entityId,
  });

  Future<void> deleteAttachment(AttachmentEntity attachment);
}
