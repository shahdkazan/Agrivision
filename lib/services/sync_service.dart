import 'offline_cache_service.dart';
import 'connectivity_service.dart';
import 'firebase_sync_service.dart';

class SyncService {
  final OfflineCacheService _cache = OfflineCacheService();
  final ConnectivityService _connectivity = ConnectivityService();
  final FirebaseSyncService _firebase = FirebaseSyncService();

  bool _isSyncing = false;

  Future<void> trySync() async {
    if (_isSyncing) return;

    final hasInternet = await _connectivity.hasInternet();
    if (!hasInternet) return;

    _isSyncing = true;

    final pending = await _cache.getPending();

    for (final item in pending) {
      final success = await _firebase.uploadResult(
        imagePath: item["imagePath"],
        label: item["label"],
      );

      if (success) {
        await _cache.markSynced(item["id"]);
      }
    }

    _isSyncing = false;
  }
}