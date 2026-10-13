package com.synergiz.swr.pmis

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationsChannel = "swr_pmis_mobile/notifications"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createDefaultNotificationChannel()
    }

    private fun createDefaultNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val channel = NotificationChannel(
            "swr_pmis_default",
            "SWR PMIS Notifications",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "RFI and system notifications"
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "clearAll") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val manager =
                        getSystemService(NotificationManager::class.java)
                    manager?.cancelAll()
                    result.success(null)
                } catch (error: Throwable) {
                    result.error("CLEAR_FAILED", error.message, null)
                }
            }
    }
}
