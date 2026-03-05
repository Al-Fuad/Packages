#ifndef FLUTTER_PLUGIN_SECURELY_PLUGIN_H_
#define FLUTTER_PLUGIN_SECURELY_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace securely {

class SecurelyPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SecurelyPlugin();

  virtual ~SecurelyPlugin();

  // Disallow copy and assign.
  SecurelyPlugin(const SecurelyPlugin&) = delete;
  SecurelyPlugin& operator=(const SecurelyPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace securely

#endif  // FLUTTER_PLUGIN_SECURELY_PLUGIN_H_
