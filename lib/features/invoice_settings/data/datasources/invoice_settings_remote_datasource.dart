import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/invoice_settings/data/models/invoice_settings_model.dart';

abstract class InvoiceSettingsRemoteDatasource {
  Future<InvoiceSettingsModel> getSettings(String businessId);
  Future<InvoiceSettingsModel> saveSettings(InvoiceSettingsModel settings);
  Future<String> uploadLogo({required String businessId, required File file});
  Future<void> deleteLogo({required String logoUrl});
}

class InvoiceSettingsRemoteDatasourceImpl
    implements InvoiceSettingsRemoteDatasource {
  final SupabaseClient supabaseClient;
  // static const String _bucketName = 'invoice_business_logs';

  InvoiceSettingsRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<InvoiceSettingsModel> getSettings(String businessId) async {
    try {
      final response = await supabaseClient
          .from('invoice_settings')
          .select()
          .eq('business_id', businessId)
          .maybeSingle();

      if (response != null) {
        return InvoiceSettingsModel.fromJson(response);
      }

      // If no settings exist yet, pre-populate default business metadata from businesses table
      String bizName = '';
      String bizPhone = '';
      String bizAddress = '';

      try {
        final bizResponse = await supabaseClient
            .from('businesses')
            .select('name, phone, address')
            .eq('id', businessId)
            .maybeSingle();

        if (bizResponse != null) {
          bizName = bizResponse['name'] as String? ?? '';
          bizPhone = bizResponse['phone'] as String? ?? '';
          bizAddress = bizResponse['address'] as String? ?? '';
        }
      } catch (_) {
        // Fallback silently if businesses table query fails
      }

      return InvoiceSettingsModel(
        id: '',
        businessId: businessId,
        businessName: bizName,
        businessPhone: bizPhone,
        businessAddress: bizAddress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw ServerException('Failed to fetch invoice settings: $e');
    }
  }

  @override
  Future<InvoiceSettingsModel> saveSettings(
    InvoiceSettingsModel settings,
  ) async {
    try {
      final data = settings.toJson();
      final response = await supabaseClient
          .from('invoice_settings')
          .upsert(data, onConflict: 'business_id')
          .select()
          .single();

      return InvoiceSettingsModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to save invoice settings: $e');
    }
  }

  @override
  Future<String> uploadLogo({
    required String businessId,
    required File file,
  }) async {
    try {
      final fileExt = p.extension(file.path).toLowerCase();
      final validExts = ['.png', '.jpg', '.jpeg', '.webp'];
      final ext = validExts.contains(fileExt) ? fileExt : '.png';
      final cleanExt = ext.startsWith('.') ? ext.substring(1) : ext;

      // Expected storage structure: invoice_business_logs/{business_id}/logo.{extension}
      final storagePath = '$businessId/logo.$cleanExt';

      await Supabase.instance.client.storage
          .from('invoice bussiness_logs')
          .upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getMimeType(ext),
            ),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('invoice bussiness_logs')
          .getPublicUrl(storagePath);

      // Persist the uploaded logo_url into invoice_settings table
      try {
        await supabaseClient
            .from('invoice_settings')
            .update({
              'logo_url': publicUrl,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('business_id', businessId);
      } catch (_) {
        // If settings record doesn't exist yet, it will be created on save
      }

      return publicUrl;
    } on StorageException catch (e) {
      throw ServerException('Storage error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to upload logo: $e');
    }
  }

  @override
  Future<void> deleteLogo({required String logoUrl}) async {
    if (logoUrl.isEmpty) return;
    try {
      String relativePath = '';
      if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
        final uri = Uri.parse(logoUrl);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf("invoice bussiness_logs");
        if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
          relativePath = pathSegments.sublist(bucketIndex + 1).join('/');
        }
      } else {
        relativePath = logoUrl;
      }

      if (relativePath.isNotEmpty) {
        await Supabase.instance.client.storage
            .from('invoice bussiness_logs')
            .remove([relativePath]);
      }
    } catch (_) {
      // Deletion error handled silently to prevent breaking UI
    }
  }

  String _getMimeType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
