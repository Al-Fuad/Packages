package com.example.securely

import android.os.Debug
import java.io.File
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class SecurelyPlugin : FlutterPlugin {

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        val channel = MethodChannel(
            binding.binaryMessenger,
            "anti_reverse"
        )

        channel.setMethodCallHandler { call, result ->
            when (call.method) {

                "isDebuggerDetected" -> {
                    result.success(Debug.isDebuggerConnected())
                }

                "isRootDetected" -> {
                    result.success(isDeviceRooted())
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
    
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
