#include "include/securely/securely_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

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
