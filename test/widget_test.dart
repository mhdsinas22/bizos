import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/bizos_app.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class MyGotrueAsyncStorage extends GotrueAsyncStorage {
  const MyGotrueAsyncStorage();
  @override
  Future<String?> getItem({required String key}) async => null;
  @override
  Future<void> removeItem({required String key}) async {}
  @override
  Future<void> setItem({required String key, required String value}) async {}
}

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox('session_box');
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtiZmxtY2hsaW9sYXFreW91YXhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5Nzg3NDAsImV4cCI6MjA5NjU1NDc0MH0.ygdLWiKeFfj7l_8MHLiW5_m0I6wczUNoO11RlVLrXAQ',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: MyGotrueAsyncStorage(),
      ),
    );
  });

  testWidgets('Bizos app startup smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BizosApp());
    expect(find.textContaining('Bizos'), findsAny);
  });
}
