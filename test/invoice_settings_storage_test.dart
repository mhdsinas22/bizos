import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/features/invoice_settings/data/models/invoice_settings_model.dart';

void main() {
  group('InvoiceSettingsModel and Logo URL Tests', () {
    test('Correctly maps legacy invoice_business_logos URL to invoice_business_logs', () {
      final json = {
        'id': 'settings-123',
        'business_id': 'biz-456',
        'business_name': 'Test Business',
        'logo_url': 'https://example.supabase.co/storage/v1/object/public/invoice_business_logos/biz-456/logo.png',
      };

      final model = InvoiceSettingsModel.fromJson(json);

      expect(model.logoUrl, contains('invoice_business_logs'));
      expect(model.logoUrl, isNot(contains('invoice_business_logos')));
      expect(
        model.logoUrl,
        equals('https://example.supabase.co/storage/v1/object/public/invoice_business_logs/biz-456/logo.png'),
      );
    });

    test('Leaves already-correct invoice_business_logs URL intact', () {
      const url = 'https://example.supabase.co/storage/v1/object/public/invoice_business_logs/biz-456/logo.png';
      final json = {
        'id': 'settings-123',
        'business_id': 'biz-456',
        'logo_url': url,
      };

      final model = InvoiceSettingsModel.fromJson(json);

      expect(model.logoUrl, equals(url));
    });

    test('toJson saves logo_url correctly', () {
      const url = 'https://example.supabase.co/storage/v1/object/public/invoice_business_logs/biz-456/logo.png';
      final model = InvoiceSettingsModel(
        id: 'settings-123',
        businessId: 'biz-456',
        logoUrl: url,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = model.toJson();

      expect(json['logo_url'], equals(url));
      expect(json['business_id'], equals('biz-456'));
    });
  });
}
