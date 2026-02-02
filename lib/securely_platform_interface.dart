import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'securely_method_channel.dart';

abstract class SecurelyPlatform extends PlatformInterface {
  /// Constructs a SecurelyPlatform.
  SecurelyPlatform() : super(token: _token);

  static final Object _token = Object();

  static SecurelyPlatform _instance = MethodChannelSecurely();

  /// The default instance of [SecurelyPlatform] to use.
  ///
  /// Defaults to [MethodChannelSecurely].
  static SecurelyPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SecurelyPlatform] when
  /// they register themselves.
  static set instance(SecurelyPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
