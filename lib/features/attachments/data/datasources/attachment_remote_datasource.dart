import 'dart:io';
import 'package:bizos/features/attachments/data/models/attachment_model.dart';

abstract class AttachmentRemoteDataSource {
  Future<AttachmentModel> uploadAttachment({
    required String businessId,
    required String entityType,
    required String entityId,
    required File file,
    required String fileName,
    String? userId,
  });

  Future<List<AttachmentModel>> getAttachments({
    required String entityType,
    required String entityId,
  });

  Future<void> deleteAttachment(AttachmentModel attachment);
}
