#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint securely.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'securely'
  s.version          = '0.2.0'
  s.summary          = 'Securely is a flutter plugin for Runtime Application Self-Protection (RASP).'
  s.description      = <<-DESC
Securely is a flutter plugin for Runtime Application Self-Protection (RASP).
                       DESC
  s.homepage         = 'https://github.com/Al-Fuad/Securely'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Al-Fuad' => 'me@alfuad.me' }
  s.source           = { :path => '.' }
  s.source_files = 'securely/Sources/securely/**/*.swift'
  s.resource_bundles = {'securely_privacy' => ['securely/Sources/securely/PrivacyInfo.xcprivacy']}
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
