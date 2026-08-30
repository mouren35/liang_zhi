package com.liangzhi.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.liangzhi.app/system_settings",
        ).setMethodCallHandler { call, result ->
            if (call.method != "openAppSettings") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            )
            startActivity(intent)
            result.success(null)
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.liangzhi.app/notification_permission",
        ).setMethodCallHandler { call, result ->
            if (call.method != "getPermissionStatus") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                result.success(
                    if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
                        "granted"
                    } else {
                        "permanentlyDenied"
                    },
                )
                return@setMethodCallHandler
            }
            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
            ) {
                result.success("granted")
                return@setMethodCallHandler
            }
            val requested = call.argument<Boolean>("requested") ?: false
            val status = when {
                !requested -> "notDetermined"
                shouldShowRequestPermissionRationale(
                    Manifest.permission.POST_NOTIFICATIONS,
                ) -> "denied"
                else -> "permanentlyDenied"
            }
            result.success(status)
        }
    }
}
