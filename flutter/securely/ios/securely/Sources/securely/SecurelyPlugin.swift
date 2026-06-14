import Flutter
import UIKit
import Darwin
import MachO
import CFNetwork


public class SecurelyPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "securely",
      binaryMessenger: registrar.messenger()
    )
    let instance = SecurelyPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.startListening()
  }

  private func startListening() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenshotTaken),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func screenshotTaken() {
    channel?.invokeMethod("onScreenshotTaken", arguments: nil)
  }

  @objc private func screenCaptureChanged() {
    channel?.invokeMethod("onScreenRecordingChanged", arguments: isScreenRecording())
  }

  private func isScreenRecording() -> Bool {
    for screen in UIScreen.screens {
      if screen.isCaptured {
        return true
      }
    }
    return false
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

    case "isVpnDetected":
      result(isVpnActive())

    case "isScreenRecordingDetected":
      result(isScreenRecording())

    case "isDeveloperModeDetected":
      result(isDeveloperModeEnabled())

    case "isUsbDebuggingDetected":
      result(false)

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
    return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil ||
           ProcessInfo.processInfo.environment["SIMULATOR_UDID"] != nil
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

  // ================= VPN DETECTION =================

  private func isVpnActive() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #endif

    let vpnProtocolsKeys = ["tap", "tun", "ppp", "ipsec", "utun", "wg"]
    
    if let cfDict = CFNetworkCopySystemProxySettings() {
      let nsDict = cfDict.takeRetainedValue() as NSDictionary
      if let keys = nsDict["__SCOPED__"] as? NSDictionary {
        for key in keys.allKeys {
          if let keyString = key as? String {
            for protocolKey in vpnProtocolsKeys {
              if keyString.lowercased().contains(protocolKey) {
                return true
              }
            }
          }
        }
      }
    }
    return checkNetworkInterfacesForVpn()
  }

  private func checkNetworkInterfacesForVpn() -> Bool {
    var addrList: UnsafeMutablePointer<ifaddrs>? = nil
    guard getifaddrs(&addrList) == 0, let firstAddr = addrList else {
      return false
    }
    
    defer {
      freeifaddrs(addrList)
    }
    
    var vpnDetected = false
    let vpnKeywords = ["tun", "tap", "ppp", "ipsec", "utun", "wg"]
    
    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
      let flags = Int32(ptr.pointee.ifa_flags)
      if (flags & IFF_UP) == 0 {
        continue
      }
      
      let name = String(cString: ptr.pointee.ifa_name)
      let nameLower = name.lowercased()
      for keyword in vpnKeywords {
        if nameLower.contains(keyword) {
          vpnDetected = true
          break
        }
      }
      if vpnDetected {
        break
      }
    }
    return vpnDetected
  }

  private func isDeveloperModeEnabled() -> Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    var value = Int32(0)
    var size = MemoryLayout<Int32>.size
    let result = sysctlbyname("security.mac.amfi.developer_mode_status", &value, &size, nil, 0)
    return result == 0 && value == 1
    #endif
  }
}
