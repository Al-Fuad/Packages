import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securely/securely.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // on non-web platforms we mock the channel so the tests do not require
    // the native implementations. web tests will run the real plugin.
    if (!kIsWeb) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('securely'), (
            MethodCall call,
          ) async {
            switch (call.method) {
              case 'isDebuggerDetected':
              case 'isRootDetected':
              case 'isEmulatorDetected':
              case 'isFridaDetected':
                return false;
              default:
                throw MissingPluginException();
            }
          });
    }
  });

  tearDown(() {
    if (!kIsWeb) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('securely'), null);
    }
  });

  group('Securely', () {
    test('isDebuggerDetected returns a boolean', () async {
      final bool result = await Securely.isDebuggerDetected();
      expect(result, isA<bool>());
    });

    test('isRootDetected returns a boolean', () async {
      final bool result = await Securely.isRootDetected();
      expect(result, isA<bool>());
    });

    test('isEmulatorDetected returns a boolean', () async {
      final bool result = await Securely.isEmulatorDetected();
      expect(result, isA<bool>());
    });

    test('isFridaDetected returns a boolean', () async {
      final bool result = await Securely.isFridaDetected();
      expect(result, isA<bool>());
    });
  });
}
