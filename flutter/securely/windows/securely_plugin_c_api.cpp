#include "include/securely/securely_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "securely_plugin.h"

void SecurelyPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  securely::SecurelyPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
