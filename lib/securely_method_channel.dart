import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'securely_platform_interface.dart';

/// An implementation of [SecurelyPlatform] that uses method channels.
class MethodChannelSecurely extends SecurelyPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('securely');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
