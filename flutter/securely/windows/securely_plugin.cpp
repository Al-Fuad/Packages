#include "securely_plugin.h"

#include <windows.h>
#include <iphlpapi.h>
#include <shlobj.h>
#include <wincrypt.h>
#include <algorithm>
#include <fstream>
#include <filesystem>
#include <vector>

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

class WindowsSecureStorage {
private:
    static std::string HexEncode(const std::string& input) {
        static const char hexChars[] = "0123456789abcdef";
        std::string output;
        output.reserve(input.length() * 2);
        for (unsigned char c : input) {
            output.push_back(hexChars[c >> 4]);
            output.push_back(hexChars[c & 0x0F]);
        }
        return output;
    }

    static std::filesystem::path GetStorageDirectory() {
        wchar_t localAppData[MAX_PATH];
        if (SHGetSpecialFolderPathW(NULL, localAppData, CSIDL_LOCAL_APPDATA, TRUE)) {
            wchar_t exePath[MAX_PATH];
            GetModuleFileNameW(NULL, exePath, MAX_PATH);
            std::wstring exeStr(exePath);
            size_t lastSlash = exeStr.find_last_of(L"\\/");
            std::wstring exeName = (lastSlash == std::wstring::npos) ? exeStr : exeStr.substr(lastSlash + 1);

            std::filesystem::path dir = std::filesystem::path(localAppData) / L"securely_storage" / exeName;
            std::filesystem::create_directories(dir);
            return dir;
        }
        return std::filesystem::path();
    }

public:
    static bool Write(const std::string& key, const std::string& value, const std::string& algorithm, const std::string& keySize) {
        std::filesystem::path dir = GetStorageDirectory();
        if (dir.empty()) return false;

        DATA_BLOB dataIn;
        dataIn.pbData = (BYTE*)value.c_str();
        dataIn.cbData = (DWORD)value.length();

        DATA_BLOB dataOut;
        if (CryptProtectData(&dataIn, L"securely_key", NULL, NULL, NULL, 0, &dataOut)) {
            std::string storageKey = key + "_" + algorithm + "_" + keySize;
            std::string filename = HexEncode(storageKey);
            std::filesystem::path filepath = dir / filename;

            std::ofstream out(filepath, std::ios::binary);
            if (out) {
                out.write((char*)dataOut.pbData, dataOut.cbData);
                out.close();
                LocalFree(dataOut.pbData);
                return true;
            }
            LocalFree(dataOut.pbData);
        }
        return false;
    }

    static std::string Read(const std::string& key, const std::string& algorithm, const std::string& keySize, bool& exists) {
        exists = false;
        std::filesystem::path dir = GetStorageDirectory();
        if (dir.empty()) return "";

        std::string storageKey = key + "_" + algorithm + "_" + keySize;
        std::string filename = HexEncode(storageKey);
        std::filesystem::path filepath = dir / filename;

        if (!std::filesystem::exists(filepath)) return "";
        exists = true;

        std::ifstream in(filepath, std::ios::binary | std::ios::ate);
        if (!in) return "";

        std::streamsize size = in.tellg();
        in.seekg(0, std::ios::beg);

        std::vector<BYTE> buffer(size);
        if (in.read((char*)buffer.data(), size)) {
            DATA_BLOB dataIn;
            dataIn.pbData = buffer.data();
            dataIn.cbData = (DWORD)buffer.size();

            DATA_BLOB dataOut;
            if (CryptUnprotectData(&dataIn, NULL, NULL, NULL, NULL, 0, &dataOut)) {
                std::string plainText((char*)dataOut.pbData, dataOut.cbData);
                LocalFree(dataOut.pbData);
                return plainText;
            }
        }
        return "";
    }

    static bool Delete(const std::string& key, const std::string& algorithm, const std::string& keySize) {
        std::filesystem::path dir = GetStorageDirectory();
        if (dir.empty()) return false;

        std::string storageKey = key + "_" + algorithm + "_" + keySize;
        std::string filename = HexEncode(storageKey);
        std::filesystem::path filepath = dir / filename;

        if (std::filesystem::exists(filepath)) {
            return std::filesystem::remove(filepath);
        }
        return true;
    }

    static bool Contains(const std::string& key, const std::string& algorithm, const std::string& keySize) {
        std::filesystem::path dir = GetStorageDirectory();
        if (dir.empty()) return false;

        std::string storageKey = key + "_" + algorithm + "_" + keySize;
        std::string filename = HexEncode(storageKey);
        std::filesystem::path filepath = dir / filename;

        return std::filesystem::exists(filepath);
    }

    static bool Clear() {
        std::filesystem::path dir = GetStorageDirectory();
        if (dir.empty()) return false;

        try {
            for (const auto& entry : std::filesystem::directory_iterator(dir)) {
                std::filesystem::remove(entry.path());
            }
            return true;
        } catch (...) {
            return false;
        }
    }
};

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

static bool is_vpn_active() {
  ULONG outBufLen = 15000;
  PIP_ADAPTER_ADDRESSES pAddresses = (PIP_ADAPTER_ADDRESSES*)malloc(outBufLen);
  if (pAddresses == NULL) return false;

  ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_DNS_SERVER;
  DWORD dwRetVal = GetAdaptersAddresses(AF_UNSPEC, flags, NULL, pAddresses, &outBufLen);
  
  if (dwRetVal == ERROR_BUFFER_OVERFLOW) {
    free(pAddresses);
    pAddresses = (PIP_ADAPTER_ADDRESSES*)malloc(outBufLen);
    if (pAddresses == NULL) return false;
    dwRetVal = GetAdaptersAddresses(AF_UNSPEC, flags, NULL, pAddresses, &outBufLen);
  }

  bool vpnDetected = false;
  if (dwRetVal == NO_ERROR) {
    PIP_ADAPTER_ADDRESSES pCurrAddresses = pAddresses;
    while (pCurrAddresses) {
      if (pCurrAddresses->OperStatus == IfOperStatusUp) {
        if (pCurrAddresses->IfType == 23) { // IF_TYPE_PPP
          vpnDetected = true;
          break;
        }
        
        std::wstring friendlyName(pCurrAddresses->FriendlyName ? pCurrAddresses->FriendlyName : L"");
        std::wstring description(pCurrAddresses->Description ? pCurrAddresses->Description : L"");
        
        std::string name(friendlyName.begin(), friendlyName.end());
        std::string desc(description.begin(), description.end());
        
        std::transform(name.begin(), name.end(), name.begin(), ::tolower);
        std::transform(desc.begin(), desc.end(), desc.begin(), ::tolower);
        
        if (name.find("vpn") != std::string::npos ||
            name.find("tap") != std::string::npos ||
            name.find("tun") != std::string::npos ||
            name.find("wg") != std::string::npos ||
            desc.find("vpn") != std::string::npos ||
            desc.find("tap") != std::string::npos ||
            desc.find("tun") != std::string::npos ||
            desc.find("wg") != std::string::npos ||
            desc.find("virtual private network") != std::string::npos) {
          vpnDetected = true;
          break;
        }
      }
      pCurrAddresses = pCurrAddresses->Next;
    }
  }
  
  free(pAddresses);
  return vpnDetected;
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
  } else if (name == "isVpnDetected") {
    result->Success(flutter::EncodableValue(is_vpn_active()));
  } else if (name == "isScreenRecordingDetected") {
    result->Success(flutter::EncodableValue(false));
  } else if (name == "isDeveloperModeDetected") {
    result->Success(flutter::EncodableValue(false));
  } else if (name == "isUsbDebuggingDetected") {
    result->Success(flutter::EncodableValue(false));
  } else if (name == "secureStorageWrite") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Arguments map is missing");
      return;
    }
    auto key_it = arguments->find(flutter::EncodableValue("key"));
    auto val_it = arguments->find(flutter::EncodableValue("value"));
    auto algo_it = arguments->find(flutter::EncodableValue("algorithm"));
    auto size_it = arguments->find(flutter::EncodableValue("keySize"));

    if (key_it != arguments->end() && val_it != arguments->end()) {
      std::string key = std::get<std::string>(key_it->second);
      std::string value = std::get<std::string>(val_it->second);
      std::string algo = (algo_it != arguments->end()) ? std::get<std::string>(algo_it->second) : "aesGcm";
      std::string size = (size_it != arguments->end()) ? std::get<std::string>(size_it->second) : "bits256";

      bool success = WindowsSecureStorage::Write(key, value, algo, size);
      result->Success(flutter::EncodableValue(success));
    } else {
      result->Error("INVALID_ARGUMENTS", "Key or value is missing");
    }
  } else if (name == "secureStorageRead") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Arguments map is missing");
      return;
    }
    auto key_it = arguments->find(flutter::EncodableValue("key"));
    auto algo_it = arguments->find(flutter::EncodableValue("algorithm"));
    auto size_it = arguments->find(flutter::EncodableValue("keySize"));

    if (key_it != arguments->end()) {
      std::string key = std::get<std::string>(key_it->second);
      std::string algo = (algo_it != arguments->end()) ? std::get<std::string>(algo_it->second) : "aesGcm";
      std::string size = (size_it != arguments->end()) ? std::get<std::string>(size_it->second) : "bits256";

      bool exists = false;
      std::string value = WindowsSecureStorage::Read(key, algo, size, exists);
      if (exists) {
        result->Success(flutter::EncodableValue(value));
      } else {
        result->Success(flutter::EncodableValue());
      }
    } else {
      result->Error("INVALID_ARGUMENTS", "Key is missing");
    }
  } else if (name == "secureStorageDelete") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Arguments map is missing");
      return;
    }
    auto key_it = arguments->find(flutter::EncodableValue("key"));
    auto algo_it = arguments->find(flutter::EncodableValue("algorithm"));
    auto size_it = arguments->find(flutter::EncodableValue("keySize"));

    if (key_it != arguments->end()) {
      std::string key = std::get<std::string>(key_it->second);
      std::string algo = (algo_it != arguments->end()) ? std::get<std::string>(algo_it->second) : "aesGcm";
      std::string size = (size_it != arguments->end()) ? std::get<std::string>(size_it->second) : "bits256";

      bool success = WindowsSecureStorage::Delete(key, algo, size);
      result->Success(flutter::EncodableValue(success));
    } else {
      result->Error("INVALID_ARGUMENTS", "Key is missing");
    }
  } else if (name == "secureStorageContainsKey") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Arguments map is missing");
      return;
    }
    auto key_it = arguments->find(flutter::EncodableValue("key"));
    auto algo_it = arguments->find(flutter::EncodableValue("algorithm"));
    auto size_it = arguments->find(flutter::EncodableValue("keySize"));

    if (key_it != arguments->end()) {
      std::string key = std::get<std::string>(key_it->second);
      std::string algo = (algo_it != arguments->end()) ? std::get<std::string>(algo_it->second) : "aesGcm";
      std::string size = (size_it != arguments->end()) ? std::get<std::string>(size_it->second) : "bits256";

      bool exists = WindowsSecureStorage::Contains(key, algo, size);
      result->Success(flutter::EncodableValue(exists));
    } else {
      result->Error("INVALID_ARGUMENTS", "Key is missing");
    }
  } else if (name == "secureStorageClear") {
    bool success = WindowsSecureStorage::Clear();
    result->Success(flutter::EncodableValue(success));
  } else {
    result->NotImplemented();
  }
}

}  // namespace securely
