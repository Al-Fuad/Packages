import 'package:flutter_test/flutter_test.dart';
import 'package:securely/securely.dart';
import 'package:securely/securely_platform_interface.dart';
import 'package:securely/securely_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSecurelyPlatform
    with MockPlatformInterfaceMixin
    implements SecurelyPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SecurelyPlatform initialPlatform = SecurelyPlatform.instance;

  test('$MethodChannelSecurely is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSecurely>());
  });

  test('getPlatformVersion', () async {
    Securely securelyPlugin = Securely();
    MockSecurelyPlatform fakePlatform = MockSecurelyPlatform();
    SecurelyPlatform.instance = fakePlatform;

    expect(await securelyPlugin.getPlatformVersion(), '42');
  });
}
