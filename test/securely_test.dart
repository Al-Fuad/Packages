import 'package:flutter_test/flutter_test.dart';
import 'package:securely/securely.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Securely', () {
    test('isDebuggerDetected returns a boolean', () async {
      final bool result = await Securely.isDebuggerDetected();
      expect(result, isA<bool>());
    });
  });
}
