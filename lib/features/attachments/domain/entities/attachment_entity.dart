import 'package:equatable/equatable.dart';

class AttachmentEntity extends Equatable {
  final String id;
  final String businessId;
  final String entityType;
  final String entityId;
  final String fileUrl;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? uploadedByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? signedUrl;

  const AttachmentEntity({
    required this.id,
    required this.businessId,
    required this.entityType,
    required this.entityId,
    required this.fileUrl,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.uploadedByUserId,
    this.createdAt,
    this.updatedAt,
    this.signedUrl,
  });

  AttachmentEntity copyWith({
    String? id,
    String? businessId,
    String? entityType,
    String? entityId,
    String? fileUrl,
    String? fileName,
    String? mimeType,
    int? fileSize,
    String? uploadedByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? signedUrl,
  }) {
    return AttachmentEntity(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      signedUrl: signedUrl ?? this.signedUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessId,
        entityType,
        entityId,
        fileUrl,
        fileName,
        mimeType,
        fileSize,
        uploadedByUserId,
        createdAt,
        updatedAt,
        signedUrl,
      ];
}
