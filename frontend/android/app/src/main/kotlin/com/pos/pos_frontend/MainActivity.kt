package com.pos.pos_frontend

import androidx.annotation.NonNull
import androidx.health.connect.client.PermissionController
import androidx.lifecycle.lifecycleScope
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.pos.pos_frontend.health.HealthConnectManager
import com.pos.pos_frontend.health.HealthSyncWorker
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.pos.app/health"
    private lateinit var healthConnectManager: HealthConnectManager
    private var pendingPermissionResult: MethodChannel.Result? = null

    private val requestPermissionsLauncher =
        registerForActivityResult(PermissionController.createRequestPermissionResultContract()) { granted: Set<String> ->
            val allGranted = granted.containsAll(healthConnectManager.permissions)
            pendingPermissionResult?.success(allGranted)
            pendingPermissionResult = null
        }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        healthConnectManager = HealthConnectManager(this)
        schedulePeriodicSync()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkAvailability" -> result.success(healthConnectManager.isAvailable())
            "hasPermissions" -> lifecycleScope.launch {
                result.success(healthConnectManager.hasAllPermissions())
            }
            "requestPermissions" -> {
                if (!healthConnectManager.isAvailable()) {
                    result.success(false)
                    return
                }
                pendingPermissionResult = result
                requestPermissionsLauncher.launch(healthConnectManager.permissions)
            }
            "getTodayAggregates", "getTodayMetrics" -> lifecycleScope.launch {
                try {
                    result.success(healthConnectManager.readTodayMetrics())
                } catch (e: Exception) {
                    result.error("HEALTH_READ_ERROR", e.message, null)
                }
            }
            "getHealthHistory" -> lifecycleScope.launch {
                try {
                    val days = call.argument<Int>("days") ?: 30
                    result.success(healthConnectManager.readHealthHistory(days))
                } catch (e: Exception) {
                    result.error("HEALTH_HISTORY_ERROR", e.message, null)
                }
            }
            "getRawHealthData" -> lifecycleScope.launch {
                try {
                    val days = call.argument<Int>("days") ?: 30
                    result.success(healthConnectManager.getRawHealthData(days))
                } catch (e: Exception) {
                    result.error("HEALTH_RAW_ERROR", e.message, null)
                }
            }
            "scheduleBackgroundSync" -> {
                schedulePeriodicSync()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun schedulePeriodicSync() {
        val workRequest = PeriodicWorkRequestBuilder<HealthSyncWorker>(
            15, TimeUnit.MINUTES,
            5, TimeUnit.MINUTES
        ).build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "POSHealthSyncWorker",
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )
    }
}
