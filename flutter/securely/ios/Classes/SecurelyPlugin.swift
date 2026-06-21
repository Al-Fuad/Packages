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

    case "secureStorageWrite":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? String,
            let algo = args["algorithm"] as? String,
            let size = args["keySize"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Key or value is missing", details: nil))
        return
      }
      result(KeychainHelper.write(key: key, value: value, algorithm: algo, size: size))

    case "secureStorageRead":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let algo = args["algorithm"] as? String,
            let size = args["keySize"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Key is missing", details: nil))
        return
      }
      result(KeychainHelper.read(key: key, algorithm: algo, size: size))

    case "secureStorageDelete":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let algo = args["algorithm"] as? String,
            let size = args["keySize"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Key is missing", details: nil))
        return
      }
      result(KeychainHelper.delete(key: key, algorithm: algo, size: size))

    case "secureStorageContainsKey":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let algo = args["algorithm"] as? String,
            let size = args["keySize"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Key is missing", details: nil))
        return
      }
      result(KeychainHelper.contains(key: key, algorithm: algo, size: size))

    case "secureStorageClear":
      result(KeychainHelper.clear())

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

import CryptoKit
import CommonCrypto

class AESHelper {
    static func generateKey(size: String) -> Data {
        let length = (size == "bits128") ? 16 : 32
        var key = Data(count: length)
        let result = key.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return key
        }
        return Data((0..<length).map { _ in UInt8.random(in: 0...255) })
    }

    static func encrypt(plainText: String, key: Data, algorithm: String) -> (encrypted: Data, iv: Data)? {
        guard let data = plainText.data(using: .utf8) else { return nil }

        if algorithm == "aesGcm" {
            if #available(iOS 13.0, macOS 10.15, *) {
                do {
                    let symmetricKey = SymmetricKey(data: key)
                    let nonce = AES.GCM.Nonce()
                    let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
                    // combined ciphertext + tag
                    return (sealedBox.ciphertext + sealedBox.tag, Data(nonce))
                } catch {
                    return nil
                }
            }
        }

        // AES-CBC
        let ivLength = kCCBlockSizeAES128
        var iv = Data(count: ivLength)
        let ivResult = iv.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, ivLength, $0.baseAddress!)
        }
        if ivResult != errSecSuccess {
            iv = Data((0..<ivLength).map { _ in UInt8.random(in: 0...255) })
        }

        var numBytesEncrypted: size_t = 0
        let dataOutLength = data.count + kCCBlockSizeAES128
        var dataOut = Data(count: dataOutLength)

        let status = dataOut.withUnsafeMutableBytes { dataOutBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, data.count,
                            dataOutBytes.baseAddress, dataOutLength,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }

        if status == kCCSuccess {
            dataOut.removeSubrange(numBytesEncrypted..<dataOutLength)
            return (dataOut, iv)
        }
        return nil
    }

    static func decrypt(encryptedData: Data, iv: Data, key: Data, algorithm: String) -> String? {
        if algorithm == "aesGcm" {
            if #available(iOS 13.0, macOS 10.15, *) {
                do {
                    let symmetricKey = SymmetricKey(data: key)
                    let nonce = try AES.GCM.Nonce(data: iv)
                    let tagLength = 16
                    guard encryptedData.count > tagLength else { return nil }
                    let ciphertext = encryptedData.subdata(in: 0..<(encryptedData.count - tagLength))
                    let tag = encryptedData.subdata(in: (encryptedData.count - tagLength)..<encryptedData.count)
                    
                    let box = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
                    let decrypted = try AES.GCM.open(box, using: symmetricKey)
                    return String(data: decrypted, encoding: .utf8)
                } catch {
                    return nil
                }
            }
        }

        // AES-CBC
        var numBytesDecrypted: size_t = 0
        let dataOutLength = encryptedData.count + kCCBlockSizeAES128
        var dataOut = Data(count: dataOutLength)

        let status = dataOut.withUnsafeMutableBytes { dataOutBytes in
            encryptedData.withUnsafeBytes { encryptedBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            ivBytes.baseAddress,
                            encryptedBytes.baseAddress, encryptedData.count,
                            dataOutBytes.baseAddress, dataOutLength,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }

        if status == kCCSuccess {
            dataOut.removeSubrange(numBytesDecrypted..<dataOutLength)
            return String(data: dataOut, encoding: .utf8)
        }
        return nil
    }
}

class KeychainHelper {
    static let service = Bundle.main.bundleIdentifier ?? "me.alfuad.securely"

    static func getOrCreateKey(algorithm: String, size: String) -> Data? {
        let keyAlias = "key_\(algorithm)_\(size)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyAlias,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return data
        }
        
        let newKey = AESHelper.generateKey(size: size)
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyAlias,
            kSecValueData as String: newKey,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemAdd(addQuery as CFDictionary, nil)
        return newKey
    }

    static func write(key: String, value: String, algorithm: String, size: String) -> Bool {
        guard let encryptionKey = getOrCreateKey(algorithm: algorithm, size: size) else { return false }
        guard let result = AESHelper.encrypt(plainText: value, key: encryptionKey, algorithm: algorithm) else { return false }
        
        let defaults = UserDefaults.standard
        let valKey = "securely_\(key)_\(algorithm)_\(size)_val"
        let ivKey = "securely_\(key)_\(algorithm)_\(size)_iv"
        
        defaults.set(result.encrypted.base64EncodedString(), forKey: valKey)
        defaults.set(result.iv.base64EncodedString(), forKey: ivKey)
        return defaults.synchronize()
    }

    static func read(key: String, algorithm: String, size: String) -> String? {
        let valKey = "securely_\(key)_\(algorithm)_\(size)_val"
        let ivKey = "securely_\(key)_\(algorithm)_\(size)_iv"
        
        guard let valBase64 = UserDefaults.standard.string(forKey: valKey),
              let ivBase64 = UserDefaults.standard.string(forKey: ivKey),
              let encryptedData = Data(base64Encoded: valBase64),
              let iv = Data(base64Encoded: ivBase64) else {
            return nil
        }
        
        guard let encryptionKey = getOrCreateKey(algorithm: algorithm, size: size) else { return nil }
        return AESHelper.decrypt(encryptedData: encryptedData, iv: iv, key: encryptionKey, algorithm: algorithm)
    }

    static func delete(key: String, algorithm: String, size: String) -> Bool {
        let valKey = "securely_\(key)_\(algorithm)_\(size)_val"
        let ivKey = "securely_\(key)_\(algorithm)_\(size)_iv"
        UserDefaults.standard.removeObject(forKey: valKey)
        UserDefaults.standard.removeObject(forKey: ivKey)
        return UserDefaults.standard.synchronize()
    }

    static func contains(key: String, algorithm: String, size: String) -> Bool {
        let valKey = "securely_\(key)_\(algorithm)_\(size)_val"
        let ivKey = "securely_\(key)_\(algorithm)_\(size)_iv"
        return UserDefaults.standard.object(forKey: valKey) != nil && UserDefaults.standard.object(forKey: ivKey) != nil
    }

    static func clear() -> Bool {
        let defaults = UserDefaults.standard
        for (k, _) in defaults.dictionaryRepresentation() {
            if k.hasPrefix("securely_") {
                defaults.removeObject(forKey: k)
            }
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
        
        return defaults.synchronize()
    }
}
