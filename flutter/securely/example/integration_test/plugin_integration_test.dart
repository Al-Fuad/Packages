// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:securely/securely.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('isDebuggerDetected test', (WidgetTester tester) async {
      final bool result = await Securely.isDebuggerDetected();
      expect(result, isA<bool>());
    });

    testWidgets('isDebuggerDetected returns boolean', (WidgetTester tester) async {
      final result = await Securely.isDebuggerDetected();
      expect(result, isNotNull);
      expect(result, isA<bool>());
    });

    testWidgets('multiple isDebuggerDetected calls', (WidgetTester tester) async {
      final result1 = await Securely.isDebuggerDetected();
      final result2 = await Securely.isDebuggerDetected();
      expect(result1, isA<bool>());
      expect(result2, isA<bool>());
      expect(result1, equals(result2));
    });
  });
}