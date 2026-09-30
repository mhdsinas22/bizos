import 'package:bizos/features/attachments/domain/entities/attachment_entity.dart';
import 'package:bizos/features/attachments/domain/repositories/attachment_repository.dart';

class GetAttachmentsUseCase {
  final AttachmentRepository repository;

  GetAttachmentsUseCase(this.repository);

  Future<List<AttachmentEntity>> call({
    required String entityType,
    required String entityId,
  }) async {
    return await repository.getAttachments(
      entityType: entityType,
      entityId: entityId,
    );
  }
}
