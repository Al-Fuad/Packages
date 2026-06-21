#include "include/securely/securely_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <ifaddrs.h>
#include <net/if.h>
#include <string>
#include <algorithm>
#include <fstream>
#include <filesystem>
#include <vector>
#include <unistd.h>
#include <limits.h>

#include "securely_plugin_private.h"

#define SECURELY_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), securely_plugin_get_type(), \
                              SecurelyPlugin))

struct _SecurelyPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(SecurelyPlugin, securely_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void securely_plugin_handle_method_call(
    SecurelyPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "isDebuggerDetected") == 0) {
    bool detected = is_debugger_detected();
    g_autoptr(FlValue) val = fl_value_new_bool(detected);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
  } else if (strcmp(method, "isRootDetected") == 0) {
    bool detected = is_root_detected();
    g_autoptr(FlValue) val = fl_value_new_bool(detected);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
  } else if (strcmp(method, "isEmulatorDetected") == 0) {
    bool detected = is_emulator_detected();
    g_autoptr(FlValue) val = fl_value_new_bool(detected);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
  } else if (strcmp(method, "isFridaDetected") == 0) {
    bool detected = is_frida_detected();
    g_autoptr(FlValue) val = fl_value_new_bool(detected);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
  } else if (strcmp(method, "isVpnDetected") == 0) {
    bool detected = is_vpn_active();
    g_autoptr(FlValue) val = fl_value_new_bool(detected);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
  } else if (strcmp(method, "isScreenRecordingDetected") == 0) {
    g_autoptr(FlValue) val = fl_value_new_bool(false);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
  } else if (strcmp(method, "isDeveloperModeDetected") == 0) {
    g_autoptr(FlValue) val = fl_value_new_bool(false);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
  } else if (strcmp(method, "isUsbDebuggingDetected") == 0) {
    g_autoptr(FlValue) val = fl_value_new_bool(false);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
  } else if (strcmp(method, "secureStorageWrite") == 0) {
    FlValue* args = fl_method_call_get_arguments(method_call);
    if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* key_val = fl_value_lookup_string(args, "key");
      FlValue* value_val = fl_value_lookup_string(args, "value");
      FlValue* algo_val = fl_value_lookup_string(args, "algorithm");
      FlValue* size_val = fl_value_lookup_string(args, "keySize");

      if (key_val && value_val) {
        std::string key = fl_value_get_string(key_val);
        std::string value = fl_value_get_string(value_val);
        std::string algo = (algo_val) ? fl_value_get_string(algo_val) : "aesGcm";
        std::string size = (size_val) ? fl_value_get_string(size_val) : "bits256";

        bool success = LinuxSecureStorage::Write(key, value, algo, size);
        g_autoptr(FlValue) val = fl_value_new_bool(success);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENTS", "Key or value is missing", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENTS", "Arguments map is missing", nullptr));
    }
  } else if (strcmp(method, "secureStorageRead") == 0) {
    FlValue* args = fl_method_call_get_arguments(method_call);
    if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* key_val = fl_value_lookup_string(args, "key");
      FlValue* algo_val = fl_value_lookup_string(args, "algorithm");
      FlValue* size_val = fl_value_lookup_string(args, "keySize");

      if (key_val) {
        std::string key = fl_value_get_string(key_val);
        std::string algo = (algo_val) ? fl_value_get_string(algo_val) : "aesGcm";
        std::string size = (size_val) ? fl_value_get_string(size_val) : "bits256";

        bool exists = false;
        std::string value = LinuxSecureStorage::Read(key, algo, size, exists);
        if (exists) {
          g_autoptr(FlValue) val = fl_value_new_string(value.c_str());
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
        } else {
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        }
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENTS", "Key is missing", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENTS", "Arguments map is missing", nullptr));
    }
  } else if (strcmp(method, "secureStorageDelete") == 0) {
    FlValue* args = fl_method_call_get_arguments(method_call);
    if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* key_val = fl_value_lookup_string(args, "key");
      FlValue* algo_val = fl_value_lookup_string(args, "algorithm");
      FlValue* size_val = fl_value_lookup_string(args, "keySize");

      if (key_val) {
        std::string key = fl_value_get_string(key_val);
        std::string algo = (algo_val) ? fl_value_get_string(algo_val) : "aesGcm";
        std::string size = (size_val) ? fl_value_get_string(size_val) : "bits256";

        bool success = LinuxSecureStorage::Delete(key, algo, size);
        g_autoptr(FlValue) val = fl_value_new_bool(success);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENTS", "Key is missing", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENTS", "Arguments map is missing", nullptr));
    }
  } else if (strcmp(method, "secureStorageContainsKey") == 0) {
    FlValue* args = fl_method_call_get_arguments(method_call);
    if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* key_val = fl_value_lookup_string(args, "key");
      FlValue* algo_val = fl_value_lookup_string(args, "algorithm");
      FlValue* size_val = fl_value_lookup_string(args, "keySize");

      if (key_val) {
        std::string key = fl_value_get_string(key_val);
        std::string algo = (algo_val) ? fl_value_get_string(algo_val) : "aesGcm";
        std::string size = (size_val) ? fl_value_get_string(size_val) : "bits256";

        bool exists = LinuxSecureStorage::Contains(key, algo, size);
        g_autoptr(FlValue) val = fl_value_new_bool(exists);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENTS", "Key is missing", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID_ARGUMENTS", "Arguments map is missing", nullptr));
    }
  } else if (strcmp(method, "secureStorageClear") == 0) {
    bool success = LinuxSecureStorage::Clear();
    g_autoptr(FlValue) val = fl_value_new_bool(success);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(val));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

// ------------------- SECURITY DETECTION HELPERS -------------------

static bool is_debugger_detected() {
  FILE* f = fopen("/proc/self/status", "r");
  if (!f) return false;
  char line[256];
  while (fgets(line, sizeof(line), f)) {
    if (strncmp(line, "TracerPid:", 10) == 0) {
      int tracer = atoi(line + 10);
      fclose(f);
      return tracer != 0;
    }
  }
  fclose(f);
  return false;
}

static bool is_root_detected() {
  return geteuid() == 0;
}

static bool is_emulator_detected() {
  // look for hypervisor bit in cpuinfo
  FILE* f = fopen("/proc/cpuinfo", "r");
  if (!f) return false;
  char buf[1024];
  bool found = false;
  while (fgets(buf, sizeof(buf), f)) {
    if (strstr(buf, "hypervisor") != NULL) {
      found = true;
      break;
    }
  }
  fclose(f);
  return found;
}

static bool check_frida_env() {
  const char* vars[] = {"FRIDA", "FRIDA_SERVER", "DYLD_INSERT_LIBRARIES"};
  for (size_t i = 0; i < sizeof(vars)/sizeof(vars[0]); i++) {
    if (getenv(vars[i]) != NULL) {
      return true;
    }
  }
  return false;
}

static bool check_frida_maps() {
  bool found = false;
  FILE* f = fopen("/proc/self/maps", "r");
  if (!f) return false;
  char line[1024];
  while (fgets(line, sizeof(line), f)) {
    if (strstr(line, "frida") != NULL) {
      found = true;
      break;
    }
  }
  fclose(f);
  return found;
}

static bool is_frida_detected() {
  return check_frida_env() || check_frida_maps();
}

static bool is_vpn_active() {
  struct ifaddrs* ifaddr = nullptr;
  if (getifaddrs(&ifaddr) == -1) {
    return false;
  }

  bool vpnDetected = false;
  for (struct ifaddrs* ifa = ifaddr; ifa != nullptr; ifa = ifa->ifa_next) {
    if (ifa->ifa_addr == nullptr) continue;

    // Check if interface is up
    if ((ifa->ifa_flags & IFF_UP) == 0) continue;

    std::string name(ifa->ifa_name);
    std::transform(name.begin(), name.end(), name.begin(), ::tolower);

    if (name.find("tun") != std::string::npos ||
        name.find("tap") != std::string::npos ||
        name.find("ppp") != std::string::npos ||
        name.find("wg") != std::string::npos) {
      vpnDetected = true;
      break;
    }
  }

  freeifaddrs(ifaddr);
  return vpnDetected;
}


#define MX (((z>>5^y<<2) + (y>>3^z<<4)) ^ ((sum^y) + (key[(p&3)^e] ^ z)))

static void xxtea_encrypt(uint32_t* v, int n, uint32_t const key[4]) {
    uint32_t y, z, sum;
    unsigned p, rounds, e;
    if (n > 1) {
        rounds = 6 + 52/n;
        sum = 0;
        z = v[n-1];
        do {
            sum += 0x9e3779b9;
            e = (sum >> 2) & 3;
            for (p=0; p<n-1; p++) {
                y = v[p+1];
                z = v[p] += MX;
            }
            y = v[0];
            z = v[n-1] += MX;
        } while (--rounds);
    }
}

static void xxtea_decrypt(uint32_t* v, int n, uint32_t const key[4]) {
    uint32_t y, z, sum;
    unsigned p, rounds, e;
    if (n > 1) {
        rounds = 6 + 52/n;
        sum = rounds*0x9e3779b9;
        y = v[0];
        do {
            e = (sum >> 2) & 3;
            for (p=n-1; p>0; p--) {
                z = v[p-1];
                y = v[p] -= MX;
            }
            z = v[n-1];
            y = v[0] -= MX;
            sum -= 0x9e3779b9;
        } while (sum != 0);
    }
}

class LinuxSecureStorage {
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

    static std::string GetExecutableName() {
        char result[PATH_MAX];
        ssize_t count = readlink("/proc/self/exe", result, PATH_MAX);
        if (count != -1) {
            std::string path(result, count);
            size_t lastSlash = path.find_last_of('/');
            return (lastSlash == std::string::npos) ? path : path.substr(lastSlash + 1);
        }
        return "default_app";
    }

    static std::string GetMachineKey() {
        std::string key = "securely_fallback_key";
        FILE* f = fopen("/etc/machine-id", "r");
        if (!f) {
            f = fopen("/var/lib/dbus/machine-id", "r");
        }
        if (f) {
            char buf[256];
            if (fgets(buf, sizeof(buf), f)) {
                key = buf;
                key.erase(std::remove(key.begin(), key.end(), '\n'), key.end());
                key.erase(std::remove(key.begin(), key.end(), '\r'), key.end());
                key.erase(std::remove(key.begin(), key.end(), ' '), key.end());
            }
            fclose(f);
        }
        return key;
    }

    static std::filesystem::path GetStorageDirectory() {
        const char* configDir = g_get_user_config_dir();
        if (configDir) {
            std::filesystem::path dir = std::filesystem::path(configDir) / "securely_storage" / GetExecutableName();
            std::filesystem::create_directories(dir);
            return dir;
        }
        return std::filesystem::path();
    }

    static std::vector<uint8_t> EncryptXXTEA(const std::string& plainText, const std::string& keyStr) {
        size_t len = plainText.length();
        size_t numWords = (len + 3) / 4;
        if (numWords < 2) numWords = 2;

        size_t totalWords = numWords + 1;
        std::vector<uint32_t> formattedData(totalWords, 0);
        formattedData[0] = (uint32_t)len;
        memcpy(formattedData.data() + 1, plainText.data(), len);

        uint32_t key[4] = {0};
        std::string paddedKey = keyStr;
        paddedKey.resize(16, '0');
        memcpy(key, paddedKey.data(), 16);

        xxtea_encrypt(formattedData.data(), totalWords, key);

        std::vector<uint8_t> result(totalWords * 4);
        memcpy(result.data(), formattedData.data(), totalWords * 4);
        return result;
    }

    static std::string DecryptXXTEA(const std::vector<uint8_t>& encryptedBytes, const std::string& keyStr) {
        if (encryptedBytes.size() % 4 != 0 || encryptedBytes.size() < 8) return "";

        size_t totalWords = encryptedBytes.size() / 4;
        std::vector<uint32_t> data(totalWords);
        memcpy(data.data(), encryptedBytes.data(), encryptedBytes.size());

        uint32_t key[4] = {0};
        std::string paddedKey = keyStr;
        paddedKey.resize(16, '0');
        memcpy(key, paddedKey.data(), 16);

        xxtea_decrypt(data.data(), totalWords, key);

        uint32_t len = data[0];
        if (len > (totalWords - 1) * 4) {
            return "";
        }

        std::string plainText((char*)(data.data() + 1), len);
        return plainText;
    }

public:
    static bool Write(const std::string& key, const std::string& value, const std::string& algorithm, const std::string& keySize) {
        std::filesystem::path dir = GetStorageDirectory();
        if (dir.empty()) return false;

        std::string machineKey = GetMachineKey();
        std::string derivedKey = machineKey + "_" + algorithm + "_" + keySize;
        std::vector<uint8_t> encryptedBytes = EncryptXXTEA(value, derivedKey);

        std::string storageKey = key + "_" + algorithm + "_" + keySize;
        std::string filename = HexEncode(storageKey);
        std::filesystem::path filepath = dir / filename;

        std::ofstream out(filepath, std::ios::binary);
        if (out) {
            out.write((char*)encryptedBytes.data(), encryptedBytes.size());
            out.close();
            return true;
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

        std::vector<uint8_t> buffer(size);
        if (in.read((char*)buffer.data(), size)) {
            std::string machineKey = GetMachineKey();
            std::string derivedKey = machineKey + "_" + algorithm + "_" + keySize;
            return DecryptXXTEA(buffer, derivedKey);
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

static void securely_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(securely_plugin_parent_class)->dispose(object);
}

static void securely_plugin_class_init(SecurelyPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = securely_plugin_dispose;
}

static void securely_plugin_init(SecurelyPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  SecurelyPlugin* plugin = SECURELY_PLUGIN(user_data);
  securely_plugin_handle_method_call(plugin, method_call);
}

void securely_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  SecurelyPlugin* plugin = SECURELY_PLUGIN(
      g_object_new(securely_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "securely",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
