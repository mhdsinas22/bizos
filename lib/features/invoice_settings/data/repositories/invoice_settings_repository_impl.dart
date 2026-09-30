import 'dart:io';
import 'package:bizos/features/invoice_settings/data/datasources/invoice_settings_remote_datasource.dart';
import 'package:bizos/features/invoice_settings/data/models/invoice_settings_model.dart';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';
import 'package:bizos/features/invoice_settings/domain/repositories/invoice_settings_repository.dart';

class InvoiceSettingsRepositoryImpl implements InvoiceSettingsRepository {
  final InvoiceSettingsRemoteDatasource remoteDatasource;

  InvoiceSettingsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<InvoiceSettingsEntity> getSettings(String businessId) {
    return remoteDatasource.getSettings(businessId);
  }

  @override
  Future<InvoiceSettingsEntity> saveSettings(InvoiceSettingsEntity settings) {
    final model = InvoiceSettingsModel.fromEntity(settings);
    return remoteDatasource.saveSettings(model);
  }

  @override
  Future<String> uploadLogo({required String businessId, required File file}) {
    return remoteDatasource.uploadLogo(businessId: businessId, file: file);
  }

  @override
  Future<void> deleteLogo({required String logoUrl}) {
    return remoteDatasource.deleteLogo(logoUrl: logoUrl);
  }
}
