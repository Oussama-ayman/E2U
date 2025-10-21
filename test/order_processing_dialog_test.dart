import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuodz/widgets/dialogs/order_processing.dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fuodz/services/local_storage.service.dart';

void main() {
  group('Order Processing Dialog Tests', () {
    setUp(() async {
      // Mock shared preferences for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'app_colors': '{"primaryColor": "#533b85", "accentColor": "#533b85"}',
      });

      // Initialize LocalStorageService with mock preferences
      final mockPrefs = await SharedPreferences.getInstance();
      LocalStorageService.prefs = mockPrefs;
      LocalStorageService.rxPrefs = null; // Reset rxPrefs
    });

    testWidgets(
      'should display order processing dialog with correct elements',
      (WidgetTester tester) async {
        // Build the dialog widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => OrderProcessingDialog(),
                      );
                    },
                    child: Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // Tap the button to show the dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Verify that the dialog is displayed
        expect(find.byType(OrderProcessingDialog), findsOneWidget);

        // Verify that the dialog contains the correct title
        expect(find.text('Order Under Process'), findsOneWidget);

        // Verify that the dialog contains the correct description
        expect(
          find.text(
            'We\'re processing your order. This may take a few seconds.',
          ),
          findsOneWidget,
        );

        // Verify that the dialog contains a progress indicator
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Verify that the dialog contains the status message
        expect(find.text('Please wait...'), findsOneWidget);
      },
    );

    testWidgets('should have correct styling and appearance', (
      WidgetTester tester,
    ) async {
      // Build the dialog widget
      await tester.pumpWidget(MaterialApp(home: OrderProcessingDialog()));

      // Verify that the dialog uses a Dialog widget
      expect(find.byType(Dialog), findsOneWidget);

      // Verify that the dialog has rounded corners
      final dialogFinder = find.byType(Dialog);
      final dialogWidget = tester.widget<Dialog>(dialogFinder);
      expect(dialogWidget.shape, isA<RoundedRectangleBorder>());

      // Verify that the main container has padding
      expect(find.byType(Container), findsWidgets);
    });
  });
}
