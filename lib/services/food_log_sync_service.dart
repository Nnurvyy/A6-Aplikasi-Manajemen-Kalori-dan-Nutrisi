import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/hive_service.dart';
import '../services/food_log_firestore_service.dart';
import '../features/general/food/models/log_model.dart';

class FoodLogSyncService {
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<void> syncPendingLogs() async {
    if (!await isOnline()) return;

    final pendingLogs = HiveService.logs.values
        .where((log) => log.syncStatus == 'pending')
        .toList();

    if (pendingLogs.isEmpty) return;

    try {
      await FoodLogFirestoreService.upsertLogs(pendingLogs);

      for (final log in pendingLogs) {
        log.syncStatus = 'synced';
        await log.save();
      }

      print('[FoodLogSyncService] ${pendingLogs.length} log berhasil disinkronkan');
    } catch (e) {
      print('[FoodLogSyncService] Gagal sync: $e');
    }
  }

  static Future<void> saveLog(LogModel log) async {
    await HiveService.logs.put(log.id, log);

    if (await isOnline()) {
      try {
        await FoodLogFirestoreService.upsertLog(log);
        log.syncStatus = 'synced';
        await log.save();
      } catch (e) {
        print('[FoodLogSyncService] Upload langsung gagal, akan di-retry: $e');
      }
    }
  }
}