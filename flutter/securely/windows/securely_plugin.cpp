#include "securely_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace securely {

// static
void SecurelyPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "securely",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<SecurelyPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

SecurelyPlugin::SecurelyPlugin() {}

SecurelyPlugin::~SecurelyPlugin() {}

// ---------- security helpers ----------

// https://learn.microsoft.com/windows/win32/secauthz/checking-for-administrator
static bool IsRunAsAdmin() {
  BOOL fIsRunAsAdmin = FALSE;
  PSID pAdministratorsGroup = NULL;
  SID_IDENTIFIER_AUTHORITY NtAuthority = SECURITY_NT_AUTHORITY;
  if (AllocateAndInitializeSid(&NtAuthority, 2,
      SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
      0, 0, 0, 0, 0, 0, &pAdministratorsGroup)) {
    CheckTokenMembership(NULL, pAdministratorsGroup, &fIsRunAsAdmin);
    FreeSid(pAdministratorsGroup);
  }
  return fIsRunAsAdmin == TRUE;
}

// check CPUID hypervisor bit
#include <intrin.h>
static bool check_hypervisor_bit() {
  int cpuInfo[4] = {0,0,0,0};
  __cpuid(cpuInfo, 1);
  // ECX bit 31 indicates hypervisor presence
  return (cpuInfo[2] & (1 << 31)) != 0;
}

static bool check_frida_env() {
  const char* vars[] = {"FRIDA", "FRIDA_SERVER", "DYLD_INSERT_LIBRARIES"};
  for (auto var : vars) {
    if (getenv(var) != nullptr) {
      return true;
    }
  }
  return false;
}

#include <psapi.h>
static bool check_frida_modules() {
  HMODULE modules[1024];
  DWORD cbNeeded;
  if (EnumProcessModules(GetCurrentProcess(), modules, sizeof(modules), &cbNeeded)) {
    size_t count = cbNeeded / sizeof(HMODULE);
    for (size_t i = 0; i < count; i++) {
      char name[MAX_PATH] = {0};
      if (GetModuleFileNameA(modules[i], name, MAX_PATH)) {
        std::string s(name);
        std::transform(s.begin(), s.end(), s.begin(), ::tolower);
        if (s.find("frida") != std::string::npos ||
            s.find("gum-js-loop") != std::string::npos ||
            s.find("gum") != std::string::npos) {
          return true;
        }
      }
    }
  }
  return false;
}

static bool is_frida_detected() {
  return check_frida_env() || check_frida_modules();
}

void SecurelyPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& name = method_call.method_name();
  if (name == "isDebuggerDetected") {
    bool detected = IsDebuggerPresent() != 0;
    result->Success(flutter::EncodableValue(detected));
  } else if (name == "isRootDetected") {
    result->Success(flutter::EncodableValue(IsRunAsAdmin()));
  } else if (name == "isEmulatorDetected") {
    result->Success(flutter::EncodableValue(check_hypervisor_bit()));
  } else if (name == "isFridaDetected") {
    result->Success(flutter::EncodableValue(is_frida_detected()));
  } else {
    result->NotImplemented();
  }
}

}  // namespace securely
