package com.pos.pos_frontend.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.ChangesTokenRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.response.ChangesResponse
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.*
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
        HealthPermission.getReadPermission(NutritionRecord::class),
        HealthPermission.getReadPermission(SleepSessionRecord::class),
        HealthPermission.getReadPermission(WeightRecord::class),
        HealthPermission.getReadPermission(ExerciseSessionRecord::class)
    )

    fun isAvailable(): Boolean =
        HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE

    suspend fun hasAllPermissions(): Boolean {
        val client = healthConnectClient ?: return false
        val granted = client.permissionController.getGrantedPermissions()
        return granted.containsAll(permissions)
    }

    suspend fun getChangesToken(recordTypes: Set<KClass<out Record>>): String? {
        val client = healthConnectClient ?: return null
        return client.getChangesToken(ChangesTokenRequest(recordTypes = recordTypes))
    }

    suspend fun getChanges(token: String): ChangesResponse? {
        val client = healthConnectClient ?: return null
        return client.getChanges(token)
    }

    private fun getDayRange(daysAgo: Long): Pair<Instant, Instant> {
        val zone = ZoneId.systemDefault()
        val targetDate = LocalDate.now(zone).minusDays(daysAgo)
        val start = targetDate.atStartOfDay(zone).toInstant()
        val end = if (daysAgo == 0L) Instant.now() else targetDate.plusDays(1).atStartOfDay(zone).toInstant()
        return Pair(start, end)
    }

    suspend fun readStepsForRange(start: Instant, end: Instant): Long {
        val client = healthConnectClient ?: return 0L
        val res = client.readRecords(ReadRecordsRequest(StepsRecord::class, TimeRangeFilter.between(start, end)))
        return res.records.sumOf { it.count }
    }

    suspend fun readNutritionForRange(start: Instant, end: Instant): Double {
        val client = healthConnectClient ?: return 0.0
        val res = client.readRecords(ReadRecordsRequest(NutritionRecord::class, TimeRangeFilter.between(start, end)))
        return res.records.sumOf { r ->
            val kcal = r.energy?.inKilocalories ?: 0.0
            if (kcal > 0.0) kcal else {
                val p = r.protein?.inGrams ?: 0.0
                val c = r.totalCarbohydrate?.inGrams ?: 0.0
                val f = r.totalFat?.inGrams ?: 0.0
                (p * 4.0) + (c * 4.0) + (f * 9.0)
            }
        }
    }

    suspend fun readCaloriesForRange(start: Instant, end: Instant): Double {
        val client = healthConnectClient ?: return 0.0
        val total = client.readRecords(ReadRecordsRequest(TotalCaloriesBurnedRecord::class, TimeRangeFilter.between(start, end))).records.sumOf { it.energy.inKilocalories }
        if (total > 0.0) return total
        return client.readRecords(ReadRecordsRequest(ActiveCaloriesBurnedRecord::class, TimeRangeFilter.between(start, end))).records.sumOf { it.energy.inKilocalories }
    }

    private fun mergeIntervals(raw: List<Pair<Instant, Instant>>): Double {
        if (raw.isEmpty()) return 0.0
        val sorted = raw.sortedBy { it.first }
        var total = 0.0
        var s = sorted[0].first
        var e = sorted[0].second
        for (i in 1 until sorted.size) {
            if (!sorted[i].first.isAfter(e)) {
                if (sorted[i].second.isAfter(e)) e = sorted[i].second
            } else {
                total += Duration.between(s, e).toMinutes().toDouble()
                s = sorted[i].first
                e = sorted[i].second
            }
        }
        total += Duration.between(s, e).toMinutes().toDouble()
        return total.coerceIn(0.0, 1440.0)
    }

    suspend fun readSleepForRange(start: Instant, end: Instant): Double {
        val client = healthConnectClient ?: return 0.0
        val queryStart = start.minus(14, ChronoUnit.HOURS)
        val res = client.readRecords(ReadRecordsRequest(SleepSessionRecord::class, TimeRangeFilter.between(queryStart, end)))
        val list = mutableListOf<Pair<Instant, Instant>>()
        for (r in res.records) {
            if (r.endTime.isAfter(start) && !r.endTime.isAfter(end)) {
                list.add(Pair(r.startTime, r.endTime))
            }
        }
        return mergeIntervals(list)
    }

    suspend fun readWeightLatest(end: Instant): Double {
        val client = healthConnectClient ?: return 0.0
        val start = end.minus(30, ChronoUnit.DAYS)
        val res = client.readRecords(ReadRecordsRequest(WeightRecord::class, TimeRangeFilter.between(start, end)))
        return res.records.lastOrNull()?.weight?.inKilograms ?: 0.0
    }

    suspend fun readTodayMetrics(): Map<String, Any> {
        val (start, end) = getDayRange(0L)
        val nutrition = readNutritionForRange(start, end)
        val burned = readCaloriesForRange(start, end)
        val calories = if (nutrition > 0.0) nutrition else burned
        return mapOf(
            "steps" to readStepsForRange(start, end),
            "calories" to calories,
            "nutritionCalories" to nutrition,
            "burnedCalories" to burned,
            "sleepMinutes" to readSleepForRange(start, end),
            "weightKg" to readWeightLatest(end),
            "date" to LocalDate.now(ZoneId.systemDefault()).toString()
        )
    }

    suspend fun readHealthHistory(days: Int): List<Map<String, Any>> {
        val zone = ZoneId.systemDefault()
        val history = mutableListOf<Map<String, Any>>()
        for (i in (days - 1) downTo 0) {
            val (start, end) = getDayRange(i.toLong())
            val dateStr = LocalDate.now(zone).minusDays(i.toLong()).toString()
            val nutrition = readNutritionForRange(start, end)
            val burned = readCaloriesForRange(start, end)
            val calories = if (nutrition > 0.0) nutrition else burned
            history.add(
                mapOf(
                    "date" to dateStr,
                    "steps" to readStepsForRange(start, end),
                    "calories" to calories,
                    "nutritionCalories" to nutrition,
                    "burnedCalories" to burned,
                    "sleepMinutes" to readSleepForRange(start, end),
                    "weightKg" to readWeightLatest(end)
                )
            )
        }
        return history
    }

    suspend fun getRawHealthData(days: Int): Map<String, Any> {
        val client = healthConnectClient ?: return emptyMap()
        val end = Instant.now()
        val start = end.minus(days.toLong(), ChronoUnit.DAYS)
        val tf = TimeRangeFilter.between(start, end)

        val steps = client.readRecords(ReadRecordsRequest(StepsRecord::class, tf)).records.map {
            mapOf("start" to it.startTime.toString(), "end" to it.endTime.toString(), "count" to it.count, "pkg" to it.metadata.dataOrigin.packageName)
        }
        val totalCal = client.readRecords(ReadRecordsRequest(TotalCaloriesBurnedRecord::class, tf)).records.map {
            mapOf("start" to it.startTime.toString(), "end" to it.endTime.toString(), "kcal" to it.energy.inKilocalories, "pkg" to it.metadata.dataOrigin.packageName)
        }
        val activeCal = client.readRecords(ReadRecordsRequest(ActiveCaloriesBurnedRecord::class, tf)).records.map {
            mapOf("start" to it.startTime.toString(), "end" to it.endTime.toString(), "kcal" to it.energy.inKilocalories, "pkg" to it.metadata.dataOrigin.packageName)
        }
        val nutrition = client.readRecords(ReadRecordsRequest(NutritionRecord::class, tf)).records.map {
            val kcal = it.energy?.inKilocalories ?: 0.0
            mapOf("start" to it.startTime.toString(), "name" to (it.name ?: ""), "kcal" to kcal, "pkg" to it.metadata.dataOrigin.packageName)
        }
        val sleep = client.readRecords(ReadRecordsRequest(SleepSessionRecord::class, tf)).records.map {
            val durMin = Duration.between(it.startTime, it.endTime).toMinutes()
            mapOf("start" to it.startTime.toString(), "end" to it.endTime.toString(), "minutes" to durMin, "title" to (it.title ?: ""), "pkg" to it.metadata.dataOrigin.packageName)
        }
        val weight = client.readRecords(ReadRecordsRequest(WeightRecord::class, tf)).records.map {
            mapOf("time" to it.time.toString(), "kg" to it.weight.inKilograms, "pkg" to it.metadata.dataOrigin.packageName)
        }

        return mapOf("steps" to steps, "totalCalories" to totalCal, "activeCalories" to activeCal, "nutrition" to nutrition, "sleep" to sleep, "weight" to weight)
    }
}
