

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads an image as Base64 string and saves metadata in Firestore
  Future<bool> uploadResult({
    required String imagePath,
    required String label,
  }) async {
    try {
      // 1️⃣ Read image file
      File file = File(imagePath);
      if (!file.existsSync()) {
        print("File does not exist: $imagePath");
        return false;
      }

      // 2️⃣ Convert to Base64
      List<int> imageBytes = await file.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 3️⃣ Save document in Firestore
      await _firestore.collection('img1').add({
        'diagnosisResult': label,
        'imageBase64': base64Image, // store image as Base64
        'labelValidatedByAgronomist': "not_checked",
        'timestamp': Timestamp.now(),
      });

      print("Upload successful (Base64 saved)!");
      return true;
    } catch (e) {
      print("Upload failed: $e");
      return false;
    }
  }
}