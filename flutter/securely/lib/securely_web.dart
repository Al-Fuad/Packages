// Web implementation of the Securely plugin.

// This file is only imported on web builds thanks to the entry in
// `pubspec.yaml`. It registers a MethodChannel handler that performs
// trivial checks (all `false`) since web environments are not susceptible
// to the same threats as native platforms.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A simple web-side plugin that responds to the same method names used by
/// the native implementations.
class SecurelyWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'securely',
      const StandardMethodCodec(),
      registrar,
    );
    final plugin = SecurelyWeb();
    channel.setMethodCallHandler(plugin.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'isDebuggerDetected':
        return _isDebuggerDetected();
      case 'isRootDetected':
        return _isRootDetected();
      case 'isEmulatorDetected':
        return _isEmulatorDetected();
      case 'isFridaDetected':
        return _isFridaDetected();
      default:
        throw MissingPluginException();
    }
  }

  bool _isDebuggerDetected() {
    // In a browser context there's not a reliable, portable way to detect
    // the developer tools. We simply return false. Future work could
    // examine `web.window.navigator.userAgent` or check for `console` hooks.
    return false;
  }

  bool _isRootDetected() {
    // concepts like "root" or "admin" don't apply to web clients.
    return false;
  }

  bool _isEmulatorDetected() {
    // the browser is always an emulator of sorts; we treat it as "not
    // emulated" for the purposes of these heuristics.
    return false;
  }

  bool _isFridaDetected() {
    // Frida cannot usually attach to web pages; always return false.
    return false;
  }
}
