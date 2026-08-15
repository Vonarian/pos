package com.pos.pos_frontend

import androidx.annotation.NonNull
import androidx.lifecycle.lifecycleScope
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.pos.pos_frontend.health.HealthConnectManager
import com.pos.pos_frontend.health.HealthSyncWorker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.pos.app/health"
    private lateinit var healthConnectManager: HealthConnectManager

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        healthConnectManager = HealthConnectManager(this)

        // Schedule periodic background sync (15 min)
        schedulePeriodicSync()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailability" -> {
                    result.success(healthConnectManager.isAvailable())
                }
                "hasPermissions" -> {
                    lifecycleScope.launch {
                        val has = healthConnectManager.hasAllPermissions()
                        result.success(has)
                    }
                }
                "getTodayAggregates" -> {
                    lifecycleScope.launch {
                        try {
                            val steps = healthConnectManager.readTodaySteps()
                            val calories = healthConnectManager.readTodayCalories()
                            result.success(mapOf(
                                "steps" to steps,
                                "calories" to calories
                            ))
                        } catch (e: Exception) {
                            result.error("HEALTH_READ_ERROR", e.message, null)
                        }
                    }
                }
                "scheduleBackgroundSync" -> {
                    schedulePeriodicSync()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
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
