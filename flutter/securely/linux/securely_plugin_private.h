#include <flutter_linux/flutter_linux.h>

#include "include/securely/securely_plugin.h"

// This file exposes some plugin internals for unit testing. See
// https://github.com/flutter/flutter/issues/88724 for current limitations
// in the unit-testable API.

// Security helper functions (unit tests may call these directly).
bool is_debugger_detected();
bool is_root_detected();
bool is_emulator_detected();
bool is_frida_detected();
