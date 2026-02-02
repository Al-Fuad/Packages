library;

import 'package:flutter/services.dart';

class Securely {
  static const MethodChannel _channel =
      MethodChannel('anti_reverse');

  static Future<bool> isDebuggerDetected() async {
    final bool result =
        await _channel.invokeMethod('isDebuggerDetected');
    return result;
  }

  static Future<bool> isRootDetected() async {
    final bool result =
        await _channel.invokeMethod('isRootDetected');
    return result;
  }

  static Future<bool> isEmulatorDetected() async {
    final bool result =
        await _channel.invokeMethod('isEmulatorDetected');
    return result;
  }

  static Future<bool> isFridaDetected() async {
    final bool result =
        await _channel.invokeMethod('isFridaDetected');
    return result;
  }
}
