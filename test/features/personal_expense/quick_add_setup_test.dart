import 'package:bizos/features/personal_expense/presentation/pages/quick_add_setup_page.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/quick_add_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuickAddBanner Widget Tests', () {
    testWidgets('renders title, description and triggers onTap', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddBanner(
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Quick Add via iPhone Shortcut'), findsOneWidget);
      expect(
        find.text(
          'Log expenses in seconds directly from your Action Button or Lock Screen.',
        ),
        findsOneWidget,
      );
      expect(find.text('Set Up'), findsOneWidget);
      expect(find.text('iOS'), findsOneWidget);

      await tester.tap(find.byType(QuickAddBanner));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('QuickAddSetupPage Widget Tests', () {
    testWidgets('renders all core UI elements, device field and workflow steps', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: QuickAddSetupPage()));

      // Verify header and platform chip
      expect(find.text('Quick Add Setup'), findsOneWidget);
      expect(find.text('Apple Shortcuts Integration'), findsOneWidget);
      expect(find.text('Quick Add for iPhone'), findsOneWidget);
      expect(
        find.text(
          'Record personal expenses in seconds from your Lock Screen, Action Button, or Siri without opening the app.',
        ),
        findsOneWidget,
      );

      // Verify 4-step workflow
      expect(find.text('How It Works'), findsOneWidget);
      expect(find.text('Open Shortcut'), findsOneWidget);
      expect(find.text('Enter Amount'), findsOneWidget);
      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Expense Saved'), findsOneWidget);

      // Verify Informational section
      expect(find.text('One-Time Setup & Secure Sync'), findsOneWidget);

      // Verify Device Label field with default value
      expect(find.text('Device Label'), findsOneWidget);
      expect(find.text('iPhone'), findsOneWidget);

      // Verify Set Up button & Requirements
      expect(find.text('Set Up iPhone Shortcut'), findsOneWidget);
      expect(
        find.text('Requires iOS 16.0+ and the Apple Shortcuts app'),
        findsOneWidget,
      );
    });

    testWidgets('allows user to edit device label', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: QuickAddSetupPage()));

      final deviceFieldFinder = find.byType(TextFormField);
      expect(deviceFieldFinder, findsOneWidget);

      await tester.enterText(deviceFieldFinder, 'Work iPhone 15 Pro');
      await tester.pumpAndSettle();

      expect(find.text('Work iPhone 15 Pro'), findsOneWidget);
    });

    testWidgets(
      'tapping setup button without active session shows sign-in message',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: QuickAddSetupPage()));

        // Scroll to Set Up button
        await tester.scrollUntilVisible(
          find.text('Set Up iPhone Shortcut'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Tap Set Up button
        await tester.tap(find.text('Set Up iPhone Shortcut'));
        await tester.pumpAndSettle();

        // Verify sign-in prompt message appears
        expect(
          find.text(
            'Please sign in to your Haptic account to pair your device.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'adapts cleanly to narrow mobile (320px) and wide desktop (1200px)',
      (tester) async {
        // Test 320px width (iPhone SE narrow)
        tester.view.physicalSize = const Size(320 * 2, 600 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: QuickAddSetupPage()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Test wide desktop
        tester.view.physicalSize = const Size(1200 * 2, 800 * 2);
        await tester.pumpWidget(const MaterialApp(home: QuickAddSetupPage()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('PairingSuccessDialog Widget Tests', () {
    testWidgets(
      'renders device name, pairing token, secret warning, and copies to clipboard',
      (tester) async {
        const testToken = 'voryn_pair_test_abc123xyz789';
        const testDevice = 'Alex iPhone 16';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PairingSuccessDialog(
                deviceName: testDevice,
                pairingToken: testToken,
              ),
            ),
          ),
        );

        // Verify title & device name
        expect(find.text('Pairing Succeeded'), findsOneWidget);
        expect(
          find.text(
            'Your device "$testDevice" was successfully paired with your Haptic account.',
          ),
          findsOneWidget,
        );

        // Verify token label & monospace token
        expect(find.text('Your Pairing Token'), findsOneWidget);
        expect(find.text(testToken), findsOneWidget);

        // Verify security warning text
        expect(
          find.text(
            'Security Warning: This token is secret and grants direct access to record expenses on your Haptic account. Do not share it with anyone.',
          ),
          findsOneWidget,
        );

        // Verify shortcut not installed note
        expect(
          find.text(
            'Please note: The iPhone Shortcut is not installed yet. You will connect and install the Shortcut in the next step.',
          ),
          findsOneWidget,
        );

        // Verify Copy Pairing Token button exists
        final copyButton = find.widgetWithText(
          ElevatedButton,
          'Copy Pairing Token',
        );
        expect(copyButton, findsOneWidget);

        String? clipboardText;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              clipboardText = (methodCall.arguments as Map)['text'] as String?;
              return null;
            } else if (methodCall.method == 'Clipboard.getData') {
              return {'text': clipboardText};
            }
            return null;
          },
        );

        // Tap Copy Pairing Token
        await tester.tap(copyButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify confirmation SnackBar
        expect(find.text('Pairing token copied to clipboard!'), findsOneWidget);

        // Verify clipboard content
        expect(clipboardText, equals(testToken));
      },
    );
  });
}
