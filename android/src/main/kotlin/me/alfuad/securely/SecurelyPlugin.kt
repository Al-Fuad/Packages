package me.alfuad.securely

import android.os.Debug
import java.io.File
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class SecurelyPlugin : FlutterPlugin {

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        val channel = MethodChannel(
            binding.binaryMessenger,
            "securely"
        )

        channel.setMethodCallHandler { call, result ->
            when (call.method) {

                "isDebuggerDetected" -> {
                    result.success(Debug.isDebuggerConnected())
                }

                "isRootDetected" -> {
                    result.success(isDeviceRooted())
                }

                "isEmulatorDetected" -> {
                    result.success(isEmulator())
                }

                "isFridaDetected" -> {
                    result.success(isFridaDetected())
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    // ================= FRIDA DETECTION =================

    private fun isFridaDetected(): Boolean {
        return checkFridaServerProcess() ||
            checkFridaLibraries() ||
            checkProcMapsForFrida()
    }

    private fun checkFridaServerProcess(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("ps")
            val reader = process.inputStream.bufferedReader()
            reader.readLines().any { it.contains("frida", ignoreCase = true) }
        } catch (e: Exception) {
            false
        }
    }

    private fun checkFridaLibraries(): Boolean {
        val suspiciousLibs = listOf(
            "frida",
            "gum-js-loop",
            "gadget"
        )

        return try {
            val process = Runtime.getRuntime().exec("cat /proc/self/maps")
            val reader = process.inputStream.bufferedReader()
            reader.readLines().any { line ->
                suspiciousLibs.any { lib ->
                    line.contains(lib, ignoreCase = true)
                }
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun checkProcMapsForFrida(): Boolean {
        return try {
            val maps = File("/proc/self/maps")
            if (!maps.exists()) return false

            maps.readLines().any {
                it.contains("frida", ignoreCase = true)
            }
        } catch (e: Exception) {
            false
        }
    }

    
    // ================= EMULATOR DETECTION =================

    private fun isEmulator(): Boolean {
        return (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
                || Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.PRODUCT.contains("sdk_google")
                || Build.PRODUCT.contains("google_sdk")
                || Build.PRODUCT.contains("sdk")
                || Build.PRODUCT.contains("sdk_x86")
                || Build.PRODUCT.contains("vbox86p")
                || Build.PRODUCT.contains("emulator")
                || Build.PRODUCT.contains("simulator")
    }

    // ================= ROOT DETECTION =================

    private fun isDeviceRooted(): Boolean {
        return checkSuBinary() ||
               checkRootPaths() ||
               checkDangerousProps()
    }

    private fun checkSuBinary(): Boolean {
        val paths = arrayOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/system/app/Superuser.apk"
        )
        return paths.any { File(it).exists() }
    }

    private fun checkRootPaths(): Boolean {
        val paths = arrayOf(
            "/data/local/bin/su",
            "/data/local/xbin/su",
            "/system/bin/failsafe/su"
        )
        return paths.any { File(it).exists() }
    }

    private fun checkDangerousProps(): Boolean {
        val props = mapOf(
            "ro.debuggable" to "1",
            "ro.secure" to "0"
        )

        for ((key, badValue) in props) {
            val value = getSystemProperty(key)
            if (value == badValue) return true
        }
        return false
    }

    private fun getSystemProperty(name: String): String {
        return try {
            val process = Runtime.getRuntime().exec("getprop $name")
            process.inputStream.bufferedReader().readLine() ?: ""
        } catch (e: Exception) {
            ""
        }
    }
}
