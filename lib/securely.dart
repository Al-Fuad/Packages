
import 'securely_platform_interface.dart';

class Securely {
  Future<String?> getPlatformVersion() {
    return SecurelyPlatform.instance.getPlatformVersion();
  }
}
