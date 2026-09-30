import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:bizos/features/attachments/domain/entities/attachment_entity.dart';
import 'package:bizos/features/attachments/domain/repositories/attachment_repository.dart';

class UploadAttachmentUseCase {
  final AttachmentRepository repository;

  UploadAttachmentUseCase(this.repository);

  Future<AttachmentEntity> call({
    required String businessId,
    required String entityType,
    required String entityId,
    required File file,
    required String fileName,
    String? userId,
  }) async {
    File finalFile = file;

    // Check size. 2MB = 2 * 1024 * 1024 bytes
    final length = await file.length();
    if (length > 2 * 1024 * 1024) {
      final tempDir = Directory.systemTemp;
      final extension = p.extension(fileName);
      final targetPath = p.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}$extension',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
      );

      if (result != null) {
        finalFile = File(result.path);
      }
    }

    return await repository.uploadAttachment(
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      file: finalFile,
      fileName: fileName,
      userId: userId,
    );
  }
}
