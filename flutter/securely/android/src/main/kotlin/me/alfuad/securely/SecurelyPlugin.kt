package me.alfuad.securely

import android.app.Activity
import android.content.Context
import android.database.ContentObserver
import android.hardware.display.DisplayManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Debug
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.view.Display
import android.view.WindowManager
import androidx.annotation.RequiresApi
import java.io.File
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

class SecurelyPlugin : FlutterPlugin, ActivityAware {

    private var context: Context? = null
    private var channel: MethodChannel? = null
    private var activity: Activity? = null

    // For pre-Android 14 screenshot content observer
    private var contentObserver: ContentObserver? = null

    // Callbacks for Android 14+ and Android 15+
    private var screenCaptureCallback: Any? = null
    private var screenRecordingCallback: Any? = null

    // Display listener for pre-Android 15 screen recording
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {
            notifyScreenRecordingState()
        }
        override fun onDisplayRemoved(displayId: Int) {
            notifyScreenRecordingState()
        }
        override fun onDisplayChanged(displayId: Int) {
            notifyScreenRecordingState()
        }
    }

    private fun notifyScreenRecordingState() {
        val isRecording = isScreenRecording()
        channel?.invokeMethod("onScreenRecordingChanged", isRecording)
    }

    private fun isScreenRecording(): Boolean {
        val ctx = context ?: return false
        val displayManager = ctx.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager ?: return false
        val displays = displayManager.displays
        for (display in displays) {
            if (display.displayId != Display.DEFAULT_DISPLAY) {
                val flags = display.flags
                if ((flags and Display.FLAG_PRESENTATION) != 0 || (flags and Display.FLAG_SECURE) == 0) {
                    return true
                }
            }
        }
        return false
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(
            binding.binaryMessenger,
            "securely"
        )

        channel?.setMethodCallHandler { call, result ->
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

                "isVpnDetected" -> {
                    result.success(isVpnActive())
                }

                "isScreenRecordingDetected" -> {
                    result.success(isScreenRecording())
                }

                "isDeveloperModeDetected" -> {
                    result.success(isDeveloperModeEnabled())
                }

                "isUsbDebuggingDetected" -> {
                    result.success(isUsbDebuggingEnabled())
                }

                else -> result.notImplemented()
            }
        }

        // Register display listener
        val displayManager = context?.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
        displayManager?.registerDisplayListener(displayListener, Handler(Looper.getMainLooper()))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val displayManager = context?.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
        displayManager?.unregisterDisplayListener(displayListener)

        context = null
        channel?.setMethodCallHandler(null)
        channel = null
    }

    // ================= ACTIVITY AWARE =================

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        registerActivityListeners(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity?.let { unregisterActivityListeners(it) }
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        registerActivityListeners(binding.activity)
    }

    override fun onDetachedFromActivity() {
        activity?.let { unregisterActivityListeners(it) }
        activity = null
    }

    private fun registerActivityListeners(act: Activity) {
        // Register Android 14+ screenshot callback
        if (Build.VERSION.SDK_INT >= 34) {
            val callback = Activity.ScreenCaptureCallback {
                channel?.invokeMethod("onScreenshotTaken", null)
            }
            screenCaptureCallback = callback
            act.registerScreenCaptureCallback(act.mainExecutor, callback)
        } else {
            // Register ContentObserver for pre-Android 14 screenshot detection
            registerContentObserver(act)
        }

        // Register Android 15+ screen recording callback
        if (Build.VERSION.SDK_INT >= 35) {
            val callback = java.util.function.Consumer<Int> { state ->
                val isRecording = state == WindowManager.SCREEN_RECORDING_STATE_VISIBLE
                channel?.invokeMethod("onScreenRecordingChanged", isRecording)
            }
            screenRecordingCallback = callback
            act.windowManager.addScreenRecordingCallback(act.mainExecutor, callback)
        }
    }

    private fun unregisterActivityListeners(act: Activity) {
        if (Build.VERSION.SDK_INT >= 34 && screenCaptureCallback != null) {
            val callback = screenCaptureCallback as? Activity.ScreenCaptureCallback
            if (callback != null) {
                act.unregisterScreenCaptureCallback(callback)
            }
            screenCaptureCallback = null
        } else {
            unregisterContentObserver(act)
        }

        if (Build.VERSION.SDK_INT >= 35 && screenRecordingCallback != null) {
            val callback = screenRecordingCallback as? java.util.function.Consumer<Int>
            if (callback != null) {
                act.windowManager.removeScreenRecordingCallback(callback)
            }
            screenRecordingCallback = null
        }
    }

    private fun registerContentObserver(ctx: Context) {
        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                if (uri == null) return
                try {
                    val projection = arrayOf(MediaStore.Images.Media.DISPLAY_NAME, MediaStore.Images.Media.DATA)
                    ctx.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                        if (cursor.moveToFirst()) {
                            val nameIndex = cursor.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                            val pathIndex = cursor.getColumnIndex(MediaStore.Images.Media.DATA)
                            val name = if (nameIndex != -1) cursor.getString(nameIndex) else ""
                            val path = if (pathIndex != -1) cursor.getString(pathIndex) else ""
                            if (name.lowercase().contains("screenshot") || path.lowercase().contains("screenshot")) {
                                channel?.invokeMethod("onScreenshotTaken", null)
                            }
                        }
                    }
                } catch (e: SecurityException) {
                    // ignore permission issues
                } catch (e: Exception) {
                    // ignore other issues
                }
            }
        }
        contentObserver = observer
        ctx.contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            observer
        )
    }

    private fun unregisterContentObserver(ctx: Context) {
        contentObserver?.let {
            ctx.contentResolver.unregisterContentObserver(it)
            contentObserver = null
        }
    }

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
        val brand = Build.BRAND.lowercase()
        val device = Build.DEVICE.lowercase()
        val fingerprint = Build.FINGERPRINT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        val model = Build.MODEL.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        val product = Build.PRODUCT.lowercase()
        val board = Build.BOARD.lowercase()
        val bootloader = Build.BOOTLOADER.lowercase()

        return (brand.startsWith("generic") && device.startsWith("generic"))
                || fingerprint.startsWith("generic")
                || hardware.contains("goldfish")
                || hardware.contains("ranchu")
                || model.contains("google_sdk")
                || model.contains("emulator")
                || model.contains("android sdk built for x86")
                || manufacturer.contains("genymotion")
                || product.contains("sdk_google")
                || product.contains("google_sdk")
                || product.startsWith("sdk")
                || product.contains("sdk_x86")
                || product.contains("vbox86p")
                || product.contains("emulator")
                || product.contains("simulator")
                || product.contains("gphone")
                || model.contains("gphone")
                || device.contains("gphone")
                || (brand.contains("google") && device.contains("google_sdk"))
                || board.contains("nox")
                || hardware.contains("nox")
                || product.contains("nox")
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

    // ================= VPN DETECTION =================

    private fun isVpnActive(): Boolean {
        val ctx = context ?: return false
        val connectivityManager = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return false
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val activeNetwork = connectivityManager.activeNetwork ?: return false
                val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork) ?: return false
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                    return true
                }
            }
        } catch (e: SecurityException) {
            // Fallback if permission ACCESS_NETWORK_STATE is missing or denied
        } catch (e: Exception) {
            // Fallback for any other unexpected issues
        }
        return checkNetworkInterfacesForVpn()
    }

    private fun checkNetworkInterfacesForVpn(): Boolean {
        try {
            val interfaces = java.net.NetworkInterface.getNetworkInterfaces()
            if (interfaces != null) {
                for (networkInterface in interfaces) {
                    if (networkInterface.isUp) {
                        val name = networkInterface.name.lowercase()
                        if (name.contains("tun") || name.contains("tap") || name.contains("ppp") || name.contains("wg")) {
                            return true
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // ignore
        }
        return false
    }

    private fun isDeveloperModeEnabled(): Boolean {
        val ctx = context ?: return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                android.provider.Settings.Global.getInt(
                    ctx.contentResolver,
                    android.provider.Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                    0
                ) != 0
            } else {
                @Suppress("DEPRECATION")
                android.provider.Settings.Secure.getInt(
                    ctx.contentResolver,
                    android.provider.Settings.Secure.DEVELOPMENT_SETTINGS_ENABLED,
                    0
                ) != 0
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun isUsbDebuggingEnabled(): Boolean {
        val ctx = context ?: return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                android.provider.Settings.Global.getInt(
                    ctx.contentResolver,
                    android.provider.Settings.Global.ADB_ENABLED,
                    0
                ) != 0
            } else {
                @Suppress("DEPRECATION")
                android.provider.Settings.Secure.getInt(
                    ctx.contentResolver,
                    android.provider.Settings.Secure.ADB_ENABLED,
                    0
                ) != 0
            }
        } catch (e: Exception) {
            false
        }
    }
}
