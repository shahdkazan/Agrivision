
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OfflineCacheService {
  static const String _folderName = "cached_images";
  static const String _metaFile = "cache_meta.json";

  Future<Directory> _getCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory("${dir.path}/$_folderName");

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<File> _getMetaFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$_metaFile");
  }

  Future<List<Map<String, dynamic>>> _readMeta() async {
    final file = await _getMetaFile();
    if (!await file.exists()) return [];
    return List<Map<String, dynamic>>.from(
      jsonDecode(await file.readAsString()),
    );
  }

  Future<void> _writeMeta(List data) async {
    final file = await _getMetaFile();
    await file.writeAsString(jsonEncode(data));
  }

  /// ALWAYS save (queue)
  Future<void> addToQueue({
    required File imageFile,
    required String label,
  }) async {
    final cacheDir = await _getCacheDir();

    final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    final savedImage = await imageFile.copy("${cacheDir.path}/$fileName");

    final data = await _readMeta();

    data.add({
      "id": fileName,
      "imagePath": savedImage.path,
      "label": label,
      "synced": false,
    });

    await _writeMeta(data);
  }

  /// Get unsynced only
  Future<List<Map<String, dynamic>>> getPending() async {
    final data = await _readMeta();
    return data.where((e) => e["synced"] == false).toList();
  }

  /// Mark synced + delete image
  Future<void> markSynced(String id) async {
    final data = await _readMeta();

    for (var item in data) {
      if (item["id"] == id) {
        item["synced"] = true;

        // delete image file
        final file = File(item["imagePath"]);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    // remove synced items completely (clean queue)
    data.removeWhere((e) => e["synced"] == true);

    await _writeMeta(data);
  }
}