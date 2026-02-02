package com.example.securely

import android.os.Debug
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

                else -> result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
