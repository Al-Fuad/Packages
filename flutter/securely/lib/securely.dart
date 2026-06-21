/// A library for performing security-related environment checks on the
/// host platform.
///
/// The APIs are available on Android, iOS, macOS, Linux, and Windows and
/// dispatch to native code via a [MethodChannel].
///
/// Detection methods include:
///  * Debugger attachment
///  * Root/administrator privileges (or jailbroken devices on mobile)
///  * Emulator or virtualized environments
///  * Presence of instrumentation frameworks like Frida
///
/// Keep in mind that these checks raise the bar for attackers but are not
/// foolproof; advanced adversaries may bypass them.
library;

import 'dart:async';
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
  static const MethodChannel _channel = MethodChannel('securely');

  static final StreamController<void> _screenshotController =
      StreamController<void>.broadcast();
  static final StreamController<bool> _screenRecordingController =
      StreamController<bool>.broadcast();
  static bool _initialized = false;

  static void _initialize() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onScreenshotTaken':
          _screenshotController.add(null);
          break;
        case 'onScreenRecordingChanged':
          final bool isRecording = call.arguments as bool;
          _screenRecordingController.add(isRecording);
          break;
      }
    });
  }

  /// A stream of screenshot detection events.
  static Stream<void> get onScreenshot {
    _initialize();
    return _screenshotController.stream;
  }

  /// A stream that emits whether screen recording is active whenever the state changes.
  static Stream<bool> get onScreenRecordingChanged {
    _initialize();
    return _screenRecordingController.stream;
  }

  /// Detects whether screen recording is currently active.
  ///
  /// Returns a [Future] that completes with `true` if screen recording/capture
  /// is detected, or `false` otherwise.
  static Future<bool> isScreenRecordingDetected() async {
    final bool result = await _channel.invokeMethod(
      'isScreenRecordingDetected',
    );
    return result;
  }

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
    final bool result = await _channel.invokeMethod('isDebuggerDetected');
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
    final bool result = await _channel.invokeMethod('isRootDetected');
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
    final bool result = await _channel.invokeMethod('isEmulatorDetected');
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
  ///
  static Future<bool> isFridaDetected() async {
    final bool result = await _channel.invokeMethod('isFridaDetected');
    return result;
  }

  /// Detects whether the device is connected to a VPN.
  ///
  /// Returns a [Future] that completes with `true` if a VPN is detected,
  /// or `false` otherwise.
  ///
  /// Reference Members:
  /// * [isDebuggerDetected]
  /// * [isRootDetected]
  /// * [isEmulatorDetected]
  /// * [isFridaDetected]
  static Future<bool> isVpnDetected() async {
    final bool result = await _channel.invokeMethod('isVpnDetected');
    return result;
  }

  /// Detects whether developer mode is enabled on the device.
  ///
  /// Returns a [Future] that completes with `true` if developer mode is enabled,
  /// or `false` otherwise.
  static Future<bool> isDeveloperModeDetected() async {
    final bool result = await _channel.invokeMethod('isDeveloperModeDetected');
    return result;
  }

  /// Detects whether USB debugging (ADB) is enabled on the device.
  ///
  /// Returns a [Future] that completes with `true` if USB debugging is enabled,
  /// or `false` otherwise.
  static Future<bool> isUsbDebuggingDetected() async {
    final bool result = await _channel.invokeMethod('isUsbDebuggingDetected');
    return result;
  }
}

/// The encryption algorithms supported by [StoreSecurely].
enum SecurelyAlgorithm {
  /// Advanced Encryption Standard in Galois/Counter Mode.
  aesGcm,

  /// Advanced Encryption Standard in Cipher Block Chaining Mode.
  aesCbc,
}

/// The encryption key sizes supported by [StoreSecurely].
enum SecurelyKeySize {
  /// 128-bit key size.
  bits128,

  /// 256-bit key size.
  bits256,
}

/// A class providing secure key-value storage capabilities using hardware-backed
/// keystores or native platforms' security frameworks.
class StoreSecurely {
  static const MethodChannel _channel = MethodChannel('securely');

  SecurelyAlgorithm _algorithm = SecurelyAlgorithm.aesGcm;
  SecurelyKeySize _keySize = SecurelyKeySize.bits256;

  /// Creates a new instance of [StoreSecurely].
  StoreSecurely();

  /// Configures the encryption algorithm for this storage instance.
  void setAlgorithm(SecurelyAlgorithm algorithm) {
    _algorithm = algorithm;
  }

  /// Configures the key size for this storage instance.
  void setKeySize(SecurelyKeySize keySize) {
    _keySize = keySize;
  }

  /// The current encryption algorithm configured for this instance.
  SecurelyAlgorithm get algorithm => _algorithm;

  /// The current key size configured for this instance.
  SecurelyKeySize get keySize => _keySize;

  /// Writes a secure string [value] associated with [key].
  Future<void> write({required String key, required String value}) async {
    await _channel.invokeMethod('secureStorageWrite', {
      'key': key,
      'value': value,
      'algorithm': _algorithm.name,
      'keySize': _keySize.name,
    });
  }

  /// Reads a secure string associated with [key].
  ///
  /// Returns `null` if the key does not exist.
  Future<String?> read({required String key}) async {
    return await _channel.invokeMethod<String>('secureStorageRead', {
      'key': key,
      'algorithm': _algorithm.name,
      'keySize': _keySize.name,
    });
  }

  /// Deletes the secure key-value pair associated with [key].
  Future<void> delete({required String key}) async {
    await _channel.invokeMethod('secureStorageDelete', {
      'key': key,
      'algorithm': _algorithm.name,
      'keySize': _keySize.name,
    });
  }

  /// Checks if secure storage contains a value for the specified [key].
  Future<bool> containsKey({required String key}) async {
    final bool? result = await _channel.invokeMethod<bool>(
      'secureStorageContainsKey',
      {'key': key, 'algorithm': _algorithm.name, 'keySize': _keySize.name},
    );
    return result ?? false;
  }

  /// Clears all secure storage entries saved by this application.
  Future<void> clear() async {
    await _channel.invokeMethod('secureStorageClear');
  }
}
