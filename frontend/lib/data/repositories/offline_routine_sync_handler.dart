import '../local/database.dart';
import '../remote/api_client.dart';
import '../../domain/models/routine_item.dart';
import 'offline_routine_mapper.dart';

class OfflineRoutineSyncHandler {
  static Future<void> syncWithServer(AppDatabase db, ApiClient? apiClient) async {
    if (apiClient == null) return;
    try {
      final unsynced = await db.routineDao.getUnsyncedRoutines();
      if (unsynced.isNotEmpty) {
        final domainItems =
            unsynced.map(OfflineRoutineMapper.mapRowToDomain).toList();
        await apiClient.pushSync(routines: domainItems, metrics: []);
        await db.routineDao.markAsSynced(
          domainItems.map((e) => e.id).toList(),
        );
      }

      final pullData = await apiClient.pullSync();
      if (pullData['routines'] != null) {
        final remoteRoutines =
            (pullData['routines'] as List)
                .map((e) => RoutineItem.fromJson(e as Map<String, dynamic>))
                .toList();

        final companions =
            remoteRoutines
                .map(
                  (e) => OfflineRoutineMapper.mapDomainToCompanion(
                    e,
                    isSynced: true,
                  ),
                )
                .toList();

        await db.routineDao.batchUpsertRoutines(companions);
      }
    } catch (_) {}
  }
}
