import 'dart:io';
import 'package:bizos/features/attachments/data/datasources/attachment_remote_datasource.dart';
import 'package:bizos/features/attachments/data/models/attachment_model.dart';
import 'package:bizos/features/attachments/domain/entities/attachment_entity.dart';
import 'package:bizos/features/attachments/domain/repositories/attachment_repository.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final AttachmentRemoteDataSource remoteDataSource;

  AttachmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AttachmentEntity> uploadAttachment({
    required String businessId,
    required String entityType,
    required String entityId,
    required File file,
    required String fileName,
    String? userId,
  }) async {
    return await remoteDataSource.uploadAttachment(
      businessId: businessId,
      entityType: entityType,
      entityId: entityId,
      file: file,
      fileName: fileName,
      userId: userId,
    );
  }

  @override
  Future<List<AttachmentEntity>> getAttachments({
    required String entityType,
    required String entityId,
  }) async {
    return await remoteDataSource.getAttachments(
      entityType: entityType,
      entityId: entityId,
    );
  }

  @override
  Future<void> deleteAttachment(AttachmentEntity attachment) async {
    final model = AttachmentModel.fromEntity(attachment);
    await remoteDataSource.deleteAttachment(model);
  }
}
