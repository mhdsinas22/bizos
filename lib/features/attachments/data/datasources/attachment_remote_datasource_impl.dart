import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:bizos/features/attachments/data/datasources/attachment_remote_datasource.dart';
import 'package:bizos/features/attachments/data/models/attachment_model.dart';

class AttachmentRemoteDataSourceImpl implements AttachmentRemoteDataSource {
  final SupabaseClient supabaseClient;

  AttachmentRemoteDataSourceImpl({required this.supabaseClient});

  static const String _bucketName = 'attachments';
  static const String _tableName = 'attachments';

  String _getMimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  @override
  Future<AttachmentModel> uploadAttachment({
    required String businessId,
    required String entityType,
    required String entityId,
    required File file,
    required String fileName,
    String? userId,
  }) async {
    final fileExt = p.extension(fileName);
    final baseName = p.basenameWithoutExtension(fileName);
    final sanitizedBase = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final uniqueFileName = '${const Uuid().v4()}_$sanitizedBase$fileExt';
    final storagePath = '$businessId/$entityType/$entityId/$uniqueFileName';

    // 1. Upload to Supabase Storage
    await supabaseClient.storage
        .from(_bucketName)
        .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

    // 2. Determine file details
    final fileSize = await file.length();
    final mimeType = _getMimeType(fileName);

    // 3. Save database record
    final data = {
      'business_id': businessId,
      'entity_type': entityType,
      'entity_id': entityId,
      'file_url': storagePath,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
      if (userId != null && userId.isNotEmpty) 'uploaded_by_user_id': userId,
    };

    final response =
        await supabaseClient.from(_tableName).insert(data).select().single();

    // 4. Generate signed URL for immediate preview
    String? signedUrl;
    try {
      signedUrl = await supabaseClient.storage
          .from(_bucketName)
          .createSignedUrl(storagePath, 3600);
    } catch (_) {
      signedUrl = null;
    }

    return AttachmentModel.fromMap(response, signedUrl: signedUrl);
  }

  @override
  Future<List<AttachmentModel>> getAttachments({
    required String entityType,
    required String entityId,
  }) async {
    final response = await supabaseClient
        .from(_tableName)
        .select()
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .order('created_at', ascending: false);

    final List<AttachmentModel> result = [];
    for (final row in response) {
      final fileUrl = row['file_url'] as String? ?? '';
      String? signedUrl;
      if (fileUrl.isNotEmpty) {
        try {
          signedUrl = await supabaseClient.storage
              .from(_bucketName)
              .createSignedUrl(fileUrl, 3600);
        } catch (_) {
          signedUrl = null;
        }
      }
      result.add(AttachmentModel.fromMap(row, signedUrl: signedUrl));
    }
    return result;
  }

  @override
  Future<void> deleteAttachment(AttachmentModel attachment) async {
    // 1. Remove file from storage
    if (attachment.fileUrl.isNotEmpty) {
      try {
        await supabaseClient.storage
            .from(_bucketName)
            .remove([attachment.fileUrl]);
      } catch (_) {
        // Storage file deletion attempt logged/ignored if already missing
      }
    }

    // 2. Delete database record
    await supabaseClient.from(_tableName).delete().eq('id', attachment.id);
  }
}
