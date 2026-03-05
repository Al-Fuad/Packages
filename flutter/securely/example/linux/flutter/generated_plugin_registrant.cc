//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <securely/securely_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) securely_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SecurelyPlugin");
  securely_plugin_register_with_registrar(securely_registrar);
}
