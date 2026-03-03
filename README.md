# Securely

A runtime security framework for Flutter applications that detects common reverse engineering and tampering environments such as debuggers, rooted devices, emulators, and instrumentation tools (e.g., Frida).

This project focuses on **runtime detection**, not just static obfuscation, making it suitable for security-critical Flutter applications.

---

## 🚀 Features Overview

### ✅ Implemented (Basic Security Layer)

- **Debugger Detection**
  - Detects if the app is being debugged at runtime.
  - Uses native APIs per platform (Android, iOS, macOS, Linux, Windows).

- **Root / Privilege Detection**
  - On mobile: identifies rooted/jailbroken devices.
  - On desktop/server platforms: checks for elevated (root/administrator) privileges.

- **Emulator/VM Detection**
  - Recognizes emulator conditions on Android and virtualized environments on desktop (hypervisor bit).

- **Frida (Basic) Detection**
  - Detects common Frida indicators on all supported platforms:
    - environment variables such as `FRIDA` or `DYLD_INSERT_LIBRARIES`
    - loaded library names containing `frida`, `gum`, etc.

---

## 🧩 Planned (Next Phase)

- **Unified Security Result**
  - Single API call to check all threats at once.
  - Example result:
    ```json
    {
      "debugger": false,
      "rooted": false,
      "emulator": true,
      "frida": false
    }
    ```

- **Simple Response Engine**
  - Basic reactions when a threat is detected:
    - App termination
    - Disable sensitive features
    - Log security events

---

## 🏗 Architecture

```
Flutter App (Dart)
│
├── Security API Layer
│
├── MethodChannel
│
└── Android Native Layer (Kotlin)
├── Debug Detection
├── Root Detection
├── Emulator Detection
└── Frida Detection
```

---

## 📦 Project Structure

```
flutter_anti_reverse/
│
├── lib/
│ └── flutter_anti_reverse.dart
│
├── android/
│ └── src/main/kotlin/com/example/flutter_anti_reverse/
│ └── FlutterAntiReversePlugin.kt
│
├── example/
│ └── lib/main.dart
│
└── README.md
```

---

## 🔧 Usage

### Check individual threats

```dart
bool isRooted = await AntiReverse.isRootDetected();
bool isEmulator = await AntiReverse.isEmulatorDetected();
bool isFrida = await AntiReverse.isFridaDetected();
bool isDebugged = await AntiReverse.isDebuggerDetected();
```
## 🎯 Project Goals
Provide runtime protection for Flutter apps

Make reverse engineering and dynamic analysis harder

Serve as a final-year project / project-based thesis in Cyber Security, Mobile Application Security, Software Engineering

## ⚠️ Limitations
Root and Frida detection are not 100% foolproof

Advanced attackers may bypass checks

This framework focuses on raising the attack cost, not absolute prevention

## 🔮 Future Improvements
Native C/C++ (NDK) based detection

Risk scoring system

Policy-based responses

iOS support

Obfuscation-aware runtime checks