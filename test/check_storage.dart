import 'package:bizos/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Verify Supabase storage connectivity and buckets', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    final url = dotenv.env['SUPABASE_URL']!;
    final anonKey = dotenv.env['PUBLISHABLE_KEY']!;

    AppLogger.info('Checking Supabase URL: $url');

    final supabase = await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
    );

    try {
      final buckets = await supabase.client.storage.listBuckets();
      AppLogger.info('Buckets count: ${buckets.length}');
      for (final b in buckets) {
        AppLogger.error(
          'Bucket: "${b.id}" (name: "${b.name}", public: ${b.public})',
        );
      }
    } catch (e) {
      AppLogger.info('listBuckets error: $e');
    }

    try {
      final files = await supabase.client.storage
          .from('invoice_business_logs')
          .list();
      AppLogger.info(
        'invoice_business_logs list successful. Items: ${files.length}',
      );
    } catch (e) {
      AppLogger.error('invoice_business_logs list error: $e');
    }

    try {
      final files = await supabase.client.storage
          .from('invoice_business_logos')
          .list();
      AppLogger.info(
        'invoice_business_logos list successful. Items: ${files.length}',
      );
    } catch (e) {
      AppLogger.error('invoice_business_logos list error: $e');
    }
  });
}
