import 'package:bizos/features/attachments/domain/entities/attachment_entity.dart';
import 'package:bizos/features/attachments/domain/repositories/attachment_repository.dart';

class DeleteAttachmentUseCase {
  final AttachmentRepository repository;

  DeleteAttachmentUseCase(this.repository);

  Future<void> call(AttachmentEntity attachment) async {
    await repository.deleteAttachment(attachment);
  }
}
