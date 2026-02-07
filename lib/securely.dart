/// A library for performing security-related environment checks on the device.
///
/// This library provides tools to detect common security risks such as
/// rooted devices, debuggers, emulators, and instrumentation tools.
library securely;

import 'package:flutter/services.dart';

/// The [Securely] class provides a suite of static methods to detect potential
/// security risks on the host device.
///
/// It uses a [MethodChannel] to communicate with native platform code to
/// perform these checks.
///
/// Reference Members:
/// * [isDebuggerDetected]
/// * [isRootDetected]
/// * [isEmulatorDetected]
/// * [isFridaDetected]
class Securely {
  static const MethodChannel _channel =
      MethodChannel('securely');

  /// Detects whether a debugger is currently attached to the application.
  ///
  /// Returns a [Future] that completes with `true` if a debugger is detected,
  /// or `false` otherwise.
  ///
  /// Reference Members:
  /// * [isRootDetected]
  /// * [isEmulatorDetected]
  /// * [isFridaDetected]
  static Future<bool> isDebuggerDetected() async {
    final bool result =
        await _channel.invokeMethod('isDebuggerDetected');
    return result;
  }

  /// Detects whether the device has been rooted or jailbroken.
  ///
  /// Returns a [Future] that completes with `true` if root access is detected,
  /// or `false` otherwise.
  ///
  /// Reference Members:
  /// * [isDebuggerDetected]
  /// * [isEmulatorDetected]
  /// * [isFridaDetected]
  static Future<bool> isRootDetected() async {
    final bool result =
        await _channel.invokeMethod('isRootDetected');
    return result;
  }

  /// Detects whether the application is running on an emulator or simulator.
  ///
  /// Returns a [Future] that completes with `true` if an emulator environment
  /// is detected, or `false` otherwise.
  ///
  /// Reference Members:
  /// * [isDebuggerDetected]
  /// * [isRootDetected]
  /// * [isFridaDetected]
  static Future<bool> isEmulatorDetected() async {
    final bool result =
        await _channel.invokeMethod('isEmulatorDetected');
    return result;
  }

  /// Detects whether the Frida instrumentation framework is present or active.
  ///
  /// Returns a [Future] that completes with `true` if Frida is detected,
  /// or `false` otherwise.
  ///
  /// Reference Members:
  /// * [isDebuggerDetected]
  /// * [isRootDetected]
  /// * [isEmulatorDetected]
  static Future<bool> isFridaDetected() async {
    final bool result =
        await _channel.invokeMethod('isFridaDetected');
    return result;
  }
}
