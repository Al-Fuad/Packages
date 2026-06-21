import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securely/securely.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> mockSecureDb = {};

  setUp(() {
    mockSecureDb.clear();
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
              case 'isVpnDetected':
              case 'isScreenRecordingDetected':
              case 'isDeveloperModeDetected':
              case 'isUsbDebuggingDetected':
                return false;
              case 'secureStorageWrite':
                final key = call.arguments['key'] as String;
                final value = call.arguments['value'] as String;
                final algo = call.arguments['algorithm'] as String;
                final size = call.arguments['keySize'] as String;
                mockSecureDb['${key}_${algo}_$size'] = value;
                return true;
              case 'secureStorageRead':
                final key = call.arguments['key'] as String;
                final algo = call.arguments['algorithm'] as String;
                final size = call.arguments['keySize'] as String;
                return mockSecureDb['${key}_${algo}_$size'];
              case 'secureStorageDelete':
                final key = call.arguments['key'] as String;
                final algo = call.arguments['algorithm'] as String;
                final size = call.arguments['keySize'] as String;
                mockSecureDb.remove('${key}_${algo}_$size');
                return true;
              case 'secureStorageContainsKey':
                final key = call.arguments['key'] as String;
                final algo = call.arguments['algorithm'] as String;
                final size = call.arguments['keySize'] as String;
                return mockSecureDb.containsKey('${key}_${algo}_$size');
              case 'secureStorageClear':
                mockSecureDb.clear();
                return true;
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

    test('isVpnDetected returns a boolean', () async {
      final bool result = await Securely.isVpnDetected();
      expect(result, isA<bool>());
    });

    test('isScreenRecordingDetected returns a boolean', () async {
      final bool result = await Securely.isScreenRecordingDetected();
      expect(result, isA<bool>());
    });

    test('isDeveloperModeDetected returns a boolean', () async {
      final bool result = await Securely.isDeveloperModeDetected();
      expect(result, isA<bool>());
    });

    test('isUsbDebuggingDetected returns a boolean', () async {
      final bool result = await Securely.isUsbDebuggingDetected();
      expect(result, isA<bool>());
    });

    test('onScreenshot is a Stream', () {
      expect(Securely.onScreenshot, isA<Stream<void>>());
    });

    test('onScreenRecordingChanged is a Stream', () {
      expect(Securely.onScreenRecordingChanged, isA<Stream<bool>>());
    });
  });

  group('StoreSecurely', () {
    test(
      'write, read, containsKey, delete, and clear work correctly',
      () async {
        final storage = StoreSecurely();

        // Default GCM/256 configuration
        await storage.write(key: 'test_key', value: 'hello_world');
        expect(await storage.containsKey(key: 'test_key'), isTrue);
        expect(await storage.read(key: 'test_key'), equals('hello_world'));

        // Modify configuration
        storage.setAlgorithm(SecurelyAlgorithm.aesCbc);
        storage.setKeySize(SecurelyKeySize.bits128);

        // Verify separation/isolation of storage keys
        expect(await storage.containsKey(key: 'test_key'), isFalse);
        expect(await storage.read(key: 'test_key'), isNull);

        // Write with custom settings
        await storage.write(key: 'test_key', value: 'hello_cbc_128');
        expect(await storage.containsKey(key: 'test_key'), isTrue);
        expect(await storage.read(key: 'test_key'), equals('hello_cbc_128'));

        // Switch back and verify
        storage.setAlgorithm(SecurelyAlgorithm.aesGcm);
        storage.setKeySize(SecurelyKeySize.bits256);
        expect(await storage.read(key: 'test_key'), equals('hello_world'));

        // Delete default
        await storage.delete(key: 'test_key');
        expect(await storage.containsKey(key: 'test_key'), isFalse);
        expect(await storage.read(key: 'test_key'), isNull);

        // Custom CBC one should still exist
        storage.setAlgorithm(SecurelyAlgorithm.aesCbc);
        storage.setKeySize(SecurelyKeySize.bits128);
        expect(await storage.read(key: 'test_key'), equals('hello_cbc_128'));

        // Clear all
        await storage.clear();
        expect(await storage.containsKey(key: 'test_key'), isFalse);
      },
    );
  });
}
