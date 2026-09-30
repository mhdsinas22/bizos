import 'dart:io';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';

abstract class InvoiceSettingsRepository {
  Future<InvoiceSettingsEntity> getSettings(String businessId);
  Future<InvoiceSettingsEntity> saveSettings(InvoiceSettingsEntity settings);
  Future<String> uploadLogo({required String businessId, required File file});
  Future<void> deleteLogo({required String logoUrl});
}
