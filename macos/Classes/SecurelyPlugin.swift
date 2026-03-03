import Cocoa
import FlutterMacOS

public class SecurelyPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "securely", binaryMessenger: registrar.messenger)
    let instance = SecurelyPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isDebuggerDetected":
      result(isDebuggerDetected())

    case "isRootDetected":
      result(isRootDetected())

    case "isEmulatorDetected":
      result(isEmulatorDetected())

    case "isFridaDetected":
      result(isFridaDetected())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Debugger
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

  // MARK: - Root / Privilege
  private func isRootDetected() -> Bool {
    return geteuid() == 0
  }

  // MARK: - Emulator
  private func isEmulatorDetected() -> Bool {
    // macOS itself isn't an emulator environment. We can detect virtualization via
    // the hypervisor bit in cpuid, but that's beyond the scope here, so return
    // false.
    return false
  }

  // MARK: - Frida
  private func isFridaDetected() -> Bool {
    return checkFridaEnvironmentVars() || checkFridaLibraries()
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
