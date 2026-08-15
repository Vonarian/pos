package com.pos.pos_frontend.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.ChangesTokenRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.response.ChangesResponse
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Duration
import java.time.Instant
import java.time.temporal.ChronoUnit
import kotlin.reflect.KClass

class HealthConnectManager(private val context: Context) {

    val healthConnectClient: HealthConnectClient? by lazy {
        if (HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE) {
            HealthConnectClient.getOrCreate(context)
        } else {
            null
        }
    }

    val permissions = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class),
        HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
        HealthPermission.getReadPermission(SleepSessionRecord::class),
        HealthPermission.getReadPermission(WeightRecord::class),
        HealthPermission.getReadPermission(ExerciseSessionRecord::class)
    )

    fun isAvailable(): Boolean {
        return HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE
    }

    suspend fun hasAllPermissions(): Boolean {
        val client = healthConnectClient ?: return false
        val granted = client.permissionController.getGrantedPermissions()
        return granted.containsAll(permissions)
    }

    suspend fun getChangesToken(recordTypes: Set<KClass<out Record>>): String? {
        val client = healthConnectClient ?: return null
        return client.getChangesToken(
            ChangesTokenRequest(recordTypes = recordTypes)
        )
    }

    suspend fun getChanges(token: String): ChangesResponse? {
        val client = healthConnectClient ?: return null
        return client.getChanges(token)
    }

    suspend fun readTodaySteps(): Long {
        val client = healthConnectClient ?: return 0L
        val startTime = Instant.now().truncatedTo(ChronoUnit.DAYS)
        val endTime = Instant.now()

        val response = client.readRecords(
            ReadRecordsRequest(
                recordType = StepsRecord::class,
                timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
            )
        )
        return response.records.sumOf { it.count }
    }

    suspend fun readTodayCalories(): Double {
        val client = healthConnectClient ?: return 0.0
        val startTime = Instant.now().truncatedTo(ChronoUnit.DAYS)
        val endTime = Instant.now()

        val response = client.readRecords(
            ReadRecordsRequest(
                recordType = TotalCaloriesBurnedRecord::class,
                timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
            )
        )
        return response.records.sumOf { it.energy.inKilocalories }
    }

    suspend fun readTodaySleep(): Double {
        val client = healthConnectClient ?: return 0.0
        val startTime = Instant.now().minus(24, ChronoUnit.HOURS)
        val endTime = Instant.now()

        val response = client.readRecords(
            ReadRecordsRequest(
                recordType = SleepSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
            )
        )
        var totalMinutes = 0.0
        for (record in response.records) {
            val duration = Duration.between(record.startTime, record.endTime)
            totalMinutes += duration.toMinutes().toDouble()
        }
        return totalMinutes
    }

    suspend fun readTodayWeight(): Double {
        val client = healthConnectClient ?: return 0.0
        val startTime = Instant.now().minus(30, ChronoUnit.DAYS)
        val endTime = Instant.now()

        val response = client.readRecords(
            ReadRecordsRequest(
                recordType = WeightRecord::class,
                timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
            )
        )
        return response.records.lastOrNull()?.weight?.inKilograms ?: 0.0
    }
}
