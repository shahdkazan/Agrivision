

import 'dart:io';

import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/ai_diagnosis_service.dart';

class DiseaseResultsPage extends StatelessWidget {
  final SegmentationResult result;
  final File imageFile;
  final Map<String, String>? user;
  final VoidCallback? onLogout;

  const DiseaseResultsPage({
    super.key,
    required this.result,
    required this.imageFile,
    this.user,
    this.onLogout,
  });

  // ── Helpers ───────────────────────────────

  Color _flutterColor(int classIndex) {
    const colors = [
      Color(0xFFE53935),
      Color(0xFF43A047),
      Color(0xFFFB8C00),
      Color(0xFF00ACC1),
      Color(0xFF8E24AA),
      Color(0xFFFFB300),
      Color(0xFFD81B60),
      Color(0xFF1E88E5),
      Color(0xFF6D4C41),
    ];
    return colors[classIndex.clamp(0, colors.length - 1)];
  }

  String _arabic(String label) =>
      ModelService.diseaseInfo[label]?['arabic'] ?? label;

  /// ✅ Get ONE final detection (most frequent + best confidence)
  DetectedObject? _getFinalDetection(List<DetectedObject> detections) {
    if (detections.isEmpty) return null;

    final Map<String, int> count = {};
    final Map<String, DetectedObject> best = {};

    for (final d in detections) {
      count[d.label] = (count[d.label] ?? 0) + 1;

      if (!best.containsKey(d.label) ||
          d.confidence > best[d.label]!.confidence) {
        best[d.label] = d;
      }
    }

    String finalLabel =
        count.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return best[finalLabel];
  }

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final detections = result.detections;
    final hasDetections = detections.isNotEmpty;
    final finalDet = _getFinalDetection(detections);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE6F4EA), Color(0xFFD1FAE5), Color(0xFFCCFBF1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Header ───────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF166534)),
                      ),
                      const Text(
                        'نتيجة التشخيص',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14532D),
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                      IconButton(
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Annotated image ───────────
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.memory(
                            result.annotatedImageBytes,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                hasDetections
                                    ? '${detections.length} منطقة مكتشفة'
                                    : 'لا توجد كشوفات',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── No detection ──────────────
                  if (!hasDetections)
                    Card(
                      color: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'لم يتم اكتشاف أي إصابة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF14532D),
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── ONE FINAL LABEL ───────────
                  if (finalDet != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _flutterColor(
                              ModelService.labels.indexOf(finalDet.label),
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.label,
                                color: _flutterColor(
                                  ModelService.labels.indexOf(finalDet.label),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _arabic(finalDet.label),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _flutterColor(
                                          ModelService.labels.indexOf(finalDet.label),
                                        ),
                                        fontFamily: 'NotoSansArabic',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      finalDet.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: finalDet.confidence,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation(
                                        _flutterColor(
                                          ModelService.labels.indexOf(finalDet.label),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                                    // ── Ask specialist ────────────
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Routes.chatbot,
                        arguments: {'diseaseName': finalDet!.label}, // send the disease name
                      );
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('اسأل مختص', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Home ──────────────────────
                  OutlinedButton.icon(
                    onPressed: () => Navigator.popUntil(
                        context, ModalRoute.withName(Routes.farmerHome)),
                    icon: const Icon(Icons.home),
                    label: const Text('العودة إلى الصفحة الرئيسية',
                        style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Color(0xFF22C55E)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}