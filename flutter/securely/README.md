# Securely

[![Pub Version](https://img.shields.io/pub/v/securely?color=cyan&style=flat-square)](https://pub.dev/packages/securely)
[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue?style=flat-square)](https://github.com/Al-Fuad/Packages/tree/main/flutter/securely/LICENSE)
[![Platform Support](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20macos%20%7C%20windows%20%7C%20linux%20%7C%20web-blueviolet?style=flat-square)](https://pub.dev/packages/securely)

**Securely** is a robust, lightweight, cross-platform Runtime Application Self-Protection (RASP) framework for Flutter. It provides hardware-backed storage, deep environment telemetry, and a custom secure in-app input suite designed to shield sensitive data from reverse engineers, debuggers, screen recorders, and physical snoopers.

All native checks execute directly on the host operating systems via lightweight channel calls, raising the bar for reverse engineering and ensuring optimal protection across **Android, iOS, macOS, Windows, Linux, and Web**.

---

## 🚀 Key Security Pillars

### 1. 🛡️ Runtime Threat Detection (RASP)
Perform live environment checks to intercept threats before they compromise your application:
*   **Debugger Detection:** Identifies attached interactive debugging tools.
*   **Root & Jailbreak Detection:** Detects compromised OS status (e.g., `su` binaries, Cydia, custom ROM indicators).
*   **Frida Instrumentation:** Intercepts active hook injections and framework artifacts.
*   **Emulator & Simulator Isolation:** Determines if execution occurs on non-physical devices.
*   **Network Safeguards:** Detects active VPN tunnels.
*   **System Integrity:** Detects developer options and USB debugging (ADB) status.
*   **Screen-Capture Shielding:** Identifies active screen recording, casting, or sharing.

### 2. 💾 Hardware-Backed Secure Storage (`StoreSecurely`)
A secure, encrypted local key-value store leveraging platform-level keystores (Keychain, Android Keystore, etc.):
*   Configurable cipher suites: **AES-GCM** or **AES-CBC**.
*   Flexible key lengths: **128-bit** or **256-bit** encryption keys.
*   Standard persistence operations: Write, Read, Delete, Check Key, and Clear.

### 3. 🔒 Custom In-App Secure Keyboard Suite
A complete in-app soft keyboard and text field implementation (`SecureKeyboard` & `SecureTextField`) that **entirely bypasses the native system soft keyboard**, mitigating keylogger exploits and clipboard snooping:
*   **Keyboard Layouts:** Numeric pinpad (`numeric`) or full QWERTY (`alphanumeric`).
*   **Key Scrambling (Shuffling):** Randomize layout positions once upon display or dynamically after every single keystroke.
*   **Screen Share Protections:** 
    *   `obscureLabels`: Replaces keyboard labels with padlocks (`🔒`) or dots when a screen recording is active.
    *   `blockKeyboard`: Renders a secure overlay shield over the keyboard, completely preventing user input.
    *   `obscureOnScreenShare`: Automatically obscures input field characters during screen capture.
*   **Premium UX & Customization:** Haptic key feedback, fully themeable container/keys/headers, and fluid slide-in bottom sheets.
*   **Clipboard & Hijack Protection:** Disables context overlay actions (copy/paste/select-all) to secure memory buffers.

---

## 📊 Platform Support Matrix

| Detection Feature | Android | iOS | macOS | Windows | Linux | Web |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Debugger Detection** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ *(returns false)* |
| **Root / Jailbreak** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ *(returns false)* |
| **Emulator / Simulator** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ *(returns false)* |
| **Frida Detection** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ *(returns false)* |
| **VPN Active** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ *(returns false)* |
| **Developer Mode** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ *(returns false)* |
| **USB Debugging / ADB** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ *(returns false)* |
| **Screen Recording** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ *(returns false)* |
| **Screenshot Events** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Secure Storage** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ *(Web LocalStorage)* |

---

## 📦 Project Structure

```
securely/
├── android/             # Android Kotlin source (Keystore, environment detectors)
├── ios/                 # iOS Swift source (Keychain, Jailbreak check, recording monitors)
├── macos/               # macOS Swift source
├── linux/               # Linux C++ source
├── windows/             # Windows C++ source
├── lib/
│   ├── securely.dart         # Main Dart API interface (RASP & Storage)
│   ├── securely_web.dart     # Web plugin fallback implementation
│   └── src/widgets/
│       ├── secure_keyboard.dart   # Interactive soft keyboard & state logic
│       └── secure_text_field.dart # Obscured TextField bypassing system keyboard
├── example/             # Premium multi-screen testbench demo application
└── test/                # Unit & Widget verification suites
```

---

## 🔧 Usage & Integration

### 1. Environment Telemetry
Query system state asynchronously from Dart:

```dart
import 'package:securely/securely.dart';

void performSecurityChecks() async {
  bool isDebugger = await Securely.isDebuggerDetected();
  bool isRooted   = await Securely.isRootDetected();
  bool isEmulator = await Securely.isEmulatorDetected();
  bool isFrida    = await Securely.isFridaDetected();
  bool isVpn      = await Securely.isVpnDetected();
  bool isDevMode  = await Securely.isDeveloperModeDetected();
  bool isUsbDebug = await Securely.isUsbDebuggingDetected();
  bool isRecording = await Securely.isScreenRecordingDetected();

  if (isDebugger || isRooted || isFrida) {
    // Take immediate defensive action (e.g., exit application, wipe cache)
  }
}
```

### 2. Real-Time Event Listening
Register global streams to react to security events immediately:

```dart
import 'dart:async';
import 'package:securely/securely.dart';

StreamSubscription<void>? screenshotSub;
StreamSubscription<bool>? recordingSub;

void initSecurityListeners() {
  // Listen for screen capture events
  screenshotSub = Securely.onScreenshot.listen((_) {
    print("📸 Security Alert: Screenshot captured!");
  });

  // Listen for real-time screen recording changes
  recordingSub = Securely.onScreenRecordingChanged.listen((isRecording) {
    if (isRecording) {
      print("🎥 Security Alert: Screen recording or casting active!");
    } else {
      print("✅ Screen recording stopped.");
    }
  });
}

void disposeSecurityListeners() {
  screenshotSub?.cancel();
  recordingSub?.cancel();
}
```

### 3. Key-Value Secure Storage
Construct a hardware-backed cipher storage engine using `StoreSecurely`:

```dart
import 'package:securely/securely.dart';

final storage = StoreSecurely();

void secureDataOperations() async {
  // Configure encryption properties (Optional: Defaults to AES-GCM / 256-bit)
  storage.setAlgorithm(SecurelyAlgorithm.aesGcm);
  storage.setKeySize(SecurelyKeySize.bits256);

  // Write sensitive key
  await storage.write(key: 'jwt_token', value: 'eyJhbGciOiJIUzI1NiIsIn...');

  // Check key existence
  bool hasKey = await storage.containsKey(key: 'jwt_token');

  if (hasKey) {
    // Read key
    String? token = await storage.read(key: 'jwt_token');
    print('Token: $token');
  }

  // Delete key
  await storage.delete(key: 'jwt_token');

  // Clear everything
  await storage.clear();
}
```

### 4. Custom Secure Input Widgets

> [!IMPORTANT]
> To prevent opening the native OS keyboard, `SecureTextField` automatically enforces `readOnly: true` and `showCursor: true`. This allows the text caret to blink naturally while blocking native keystroke interceptors.

#### Basic Usage (Modal Bottom Sheet Drawer)
By default, focusing `SecureTextField` displays the `SecureKeyboard` within a modal sheet drawer sliding up from the bottom:

```dart
import 'package:flutter/material.dart';
import 'package:securely/securely.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SecureTextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: SecureKeyboardType.numeric,
            keyboardShuffleType: SecureKeyboardShuffle.once,
            keyboardObscureMode: SecureKeyboardObscureMode.blockKeyboard,
            decoration: const InputDecoration(
              labelText: 'Transaction PIN',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.dialpad),
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Inline (Pinned) Usage
For custom security screen layouts (e.g., authentication flow PIN pads), you can pin `SecureKeyboard` inline on the page:

```dart
import 'package:flutter/material.dart';
import 'package:securely/securely.dart';

class InlineKeyboardDemo extends StatefulWidget {
  const InlineKeyboardDemo({super.key});

  @override
  State<InlineKeyboardDemo> createState() => _InlineKeyboardDemoState();
}

class _InlineKeyboardDemoState extends State<InlineKeyboardDemo> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isKeyboardVisible = _focusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SecureTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  showKeyboardBottomSheet: false, // Turn off slide-up sheet
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter Passcode',
                  ),
                ),
              ),
            ),
          ),
          // Toggle keyboard layout on focus
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _isKeyboardVisible ? 330.0 : 0.0,
            child: _isKeyboardVisible
                ? SecureKeyboard(
                    controller: _controller,
                    type: SecureKeyboardType.alphanumeric,
                    shuffleType: SecureKeyboardShuffle.always, // Scramble after each tap
                    obscureMode: SecureKeyboardObscureMode.obscureLabels,
                    onDone: () => _focusNode.unfocus(),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎨 Theme & Layout Customization

Modify keyboard visuals completely through `SecureKeyboardTheme`:

```dart
SecureTextField(
  controller: _controller,
  keyboardTheme: SecureKeyboardTheme(
    backgroundColor: const Color(0xFF10101C),
    keyBackgroundColor: const Color(0xFF1A1A2B),
    actionKeyBackgroundColor: const Color(0xFF24243D),
    textStyle: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
    actionTextStyle: const TextStyle(fontSize: 15, color: Colors.cyanAccent),
    keyBorderRadius: 10.0,
    height: 350.0,
    headerText: '🛡️ SECURE ENCRYPTED KEYBOARD',
    showHeader: true,
  ),
  // ... configuration options
)
```

### Options Breakdown

#### `SecureKeyboardShuffle`
*   `none`: Keys occupy standard QWERTY / numeric arrangements.
*   `once`: Layout is randomized when the keyboard is constructed/rendered.
*   `always`: Layout undergoes a fresh random scramble after every key press.

#### `SecureKeyboardObscureMode`
*   `none`: Keycaps remain visible during screen sharing.
*   `obscureLabels`: Native screenshot protection changes keycaps to `🔒` or dots `•` when active.
*   `blockKeyboard`: Displays a fullscreen warning layout blocker restricting user interaction until sharing halts.

---

## ⚠️ Security Warning & Design Philosophy

No RASP check is entirely bulletproof. Determined adversaries with administrative control (`root`/`jailbreak`) or specialized tool chains (Frida scripts, system Hook frameworks, custom runtime kernels) may bypass individual checks.

This plugin is designed to:
1.  **Elevate the entry barrier** for basic reverse engineering attempts.
2.  **Hinder automated scanning utilities** and basic debugging configurations.
3.  **Avert physical snooping** and screen capture attempts.

Developers should employ a **Defense-in-Depth** model: combine `securely` checks with server-side validation, secure network connections, code obfuscation, and application shielding.