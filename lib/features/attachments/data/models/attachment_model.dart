import 'package:bizos/features/attachments/domain/entities/attachment_entity.dart';

class AttachmentModel extends AttachmentEntity {
  const AttachmentModel({
    required super.id,
    required super.businessId,
    required super.entityType,
    required super.entityId,
    required super.fileUrl,
    required super.fileName,
    required super.mimeType,
    required super.fileSize,
    super.uploadedByUserId,
    super.createdAt,
    super.updatedAt,
    super.signedUrl,
  });

  factory AttachmentModel.fromMap(Map<String, dynamic> map, {String? signedUrl}) {
    return AttachmentModel(
      id: map['id'] ?? '',
      businessId: map['business_id'] ?? '',
      entityType: map['entity_type'] ?? '',
      entityId: map['entity_id'] ?? '',
      fileUrl: map['file_url'] ?? '',
      fileName: map['file_name'] ?? '',
      mimeType: map['mime_type'] ?? 'image/jpeg',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      uploadedByUserId: map['uploaded_by_user_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal()
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at']).toLocal()
          : null,
      signedUrl: signedUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'entity_type': entityType,
      'entity_id': entityId,
      'file_url': fileUrl,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
      'uploaded_by_user_id': uploadedByUserId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory AttachmentModel.fromEntity(AttachmentEntity entity) {
    return AttachmentModel(
      id: entity.id,
      businessId: entity.businessId,
      entityType: entity.entityType,
      entityId: entity.entityId,
      fileUrl: entity.fileUrl,
      fileName: entity.fileName,
      mimeType: entity.mimeType,
      fileSize: entity.fileSize,
      uploadedByUserId: entity.uploadedByUserId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      signedUrl: entity.signedUrl,
    );
  }
}
