import Flutter
import UIKit
import Darwin
import MachO


public class SecurelyPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "securely",
      binaryMessenger: registrar.messenger()
    )
    let instance = SecurelyPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "isDebuggerDetected":
      result(isDebuggerDetected())

    case "isRootDetected":
      result(isJailbroken())

    case "isEmulatorDetected":
      result(isSimulator())

    case "isFridaDetected":
      result(isFridaDetected())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // ================= DEBUGGER DETECTION =================

  private func isDebuggerDetected() -> Bool {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var name = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

    let sysctlResult = sysctl(&name, 4, &info, &size, nil, 0)
    if sysctlResult != 0 {
      return false
    }

    return (info.kp_proc.p_flag & P_TRACED) != 0
  }

  // ================= JAILBREAK DETECTION =================

  private func isJailbroken() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #endif

    let jailbreakPaths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt/"
    ]

    for path in jailbreakPaths {
      if FileManager.default.fileExists(atPath: path) {
        return true
      }
    }

    // Write test (sandbox escape)
    let testPath = "/private/jailbreak_test.txt"
    do {
      try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
      try FileManager.default.removeItem(atPath: testPath)
      return true
    } catch {
      return false
    }
  }

  // ================= EMULATOR (SIMULATOR) DETECTION =================

  private func isSimulator() -> Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
  }

  // ================= FRIDA BASIC DETECTION =================

  private func isFridaDetected() -> Bool {
    return checkFridaEnvironmentVars() ||
           checkFridaLibraries()
  }

  private func checkFridaEnvironmentVars() -> Bool {
    let suspiciousVars = [
      "FRIDA",
      "FRIDA_SERVER",
      "DYLD_INSERT_LIBRARIES"
    ]

    for key in suspiciousVars {
      if getenv(key) != nil {
        return true
      }
    }
    return false
  }

  private func checkFridaLibraries() -> Bool {
    let suspiciousLibs = [
      "frida",
      "gum-js-loop",
      "cycript"
    ]

    for i in 0..<_dyld_image_count() {
      if let imageName = _dyld_get_image_name(i) {
        let name = String(cString: imageName).lowercased()
        if suspiciousLibs.contains(where: { name.contains($0) }) {
          return true
        }
      }
    }
    return false
  }
}
