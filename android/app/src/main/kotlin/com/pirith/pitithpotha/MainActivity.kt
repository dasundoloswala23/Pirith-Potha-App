package com.pirith.pitithpotha

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Extends [AudioServiceActivity] so `audio_service` can host background
 * playback — do not change the superclass.
 *
 * Adds a small channel for the Android 13+ notification permission. Without
 * it the media notification and lock-screen controls never appear, because
 * POST_NOTIFICATIONS is declared in the manifest but must also be granted at
 * runtime on API 33+. A whole permissions plugin would be a lot of surface
 * for one boolean, so this is done by hand.
 */
class MainActivity : AudioServiceActivity() {

    private companion object {
        const val CHANNEL = "com.pirith.pitithpotha/notification_permission"
        const val REQUEST_CODE = 1001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isGranted" -> result.success(isGranted())
                    "request" -> {
                        // Below API 33 the permission does not exist and
                        // notifications are on by default, so report granted
                        // rather than making the Dart side branch on version.
                        if (isGranted()) {
                            result.success(true)
                        } else {
                            requestPermissions(
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                REQUEST_CODE,
                            )
                            // The system dialog is asynchronous; the Dart
                            // caller only uses this to decide whether to stop
                            // asking, so answering with the pre-prompt state
                            // is enough and avoids holding the result open
                            // across a configuration change.
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isGranted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }
}
