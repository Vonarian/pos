package com.pos.pos_frontend.health

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.health.connect.client.records.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class HealthSyncWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    companion object {
        const val TAG = "HealthSyncWorker"
        const val PREFS_NAME = "pos_health_sync_prefs"
        const val KEY_CHANGES_TOKEN = "health_connect_changes_token"
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val manager = HealthConnectManager(applicationContext)
        if (!manager.isAvailable() || !manager.hasAllPermissions()) {
            Log.d(TAG, "Health Connect unavailable or missing permissions, skipping background sync")
            return@withContext Result.success()
        }

        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        var token = prefs.getString(KEY_CHANGES_TOKEN, null)

        val recordTypes = setOf(
            StepsRecord::class,
            TotalCaloriesBurnedRecord::class,
            ActiveCaloriesBurnedRecord::class,
            SleepSessionRecord::class,
            WeightRecord::class,
            ExerciseSessionRecord::class
        )

        try {
            if (token == null) {
                token = manager.getChangesToken(recordTypes)
                prefs.edit().putString(KEY_CHANGES_TOKEN, token).apply()
                return@withContext Result.success()
            }

            val changes = manager.getChanges(token)
            if (changes != null) {
                Log.d(TAG, "Fetched differential Health Connect changes: ${changes.upsertionRecords.size} upserts")
                // Persist new token
                prefs.edit().putString(KEY_CHANGES_TOKEN, changes.nextChangesToken).apply()
            }

            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error in HealthSyncWorker: ${e.message}", e)
            Result.retry()
        }
    }
}
