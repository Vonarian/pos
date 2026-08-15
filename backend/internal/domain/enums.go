package domain

type ItemStatus string

const (
	StatusPending   ItemStatus = "PENDING"
	StatusCompleted ItemStatus = "COMPLETED"
	StatusSkipped   ItemStatus = "SKIPPED"
	StatusMissed    ItemStatus = "MISSED"
)

type TimeWindow string

const (
	WindowMorning   TimeWindow = "MORNING"   // 06:00 - 12:00
	WindowAfternoon TimeWindow = "AFTERNOON" // 12:00 - 18:00
	WindowEvening   TimeWindow = "EVENING"   // 18:00 - 21:00
	WindowNight     TimeWindow = "NIGHT"     // 21:00 - 23:59
)

type MetricType string

const (
	MetricSteps          MetricType = "STEPS"
	MetricCaloriesBurned MetricType = "CALORIES_BURNED"
	MetricSleepDuration  MetricType = "SLEEP_DURATION"
	MetricWeight         MetricType = "WEIGHT"
	MetricBodyFat        MetricType = "BODY_FAT"
	MetricWorkoutSession MetricType = "WORKOUT_SESSION"
	MetricWaterIntake    MetricType = "WATER_INTAKE"
)
