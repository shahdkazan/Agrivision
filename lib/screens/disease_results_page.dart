//
//
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import '../routes.dart';
// import '../services/ai_diagnosis_service_old.dart';
//
// class DiseaseResultsPage extends StatelessWidget {
//   final SegmentationResult result;
//   final File imageFile;
//   final Map<String, String>? user;
//   final VoidCallback? onLogout;
//
//   const DiseaseResultsPage({
//     super.key,
//     required this.result,
//     required this.imageFile,
//     this.user,
//     this.onLogout,
//   });
//
//   // ── Helpers ───────────────────────────────
//
//   Color _flutterColor(int classIndex) {
//     const colors = [
//       Color(0xFFE53935),
//       Color(0xFF43A047),
//       Color(0xFFFB8C00),
//       Color(0xFF00ACC1),
//       Color(0xFF8E24AA),
//       Color(0xFFFFB300),
//       Color(0xFFD81B60),
//       Color(0xFF1E88E5),
//       Color(0xFF6D4C41),
//     ];
//     return colors[classIndex.clamp(0, colors.length - 1)];
//   }
//
//   String _arabic(String label) =>
//       ModelService.diseaseInfo[label]?['arabic'] ?? label;
//
//   /// ✅ Get ONE final detection (most frequent + best confidence)
//   DetectedObject? _getFinalDetection(List<DetectedObject> detections) {
//     if (detections.isEmpty) return null;
//
//     final Map<String, int> count = {};
//     final Map<String, DetectedObject> best = {};
//
//     for (final d in detections) {
//       count[d.label] = (count[d.label] ?? 0) + 1;
//
//       if (!best.containsKey(d.label) ||
//           d.confidence > best[d.label]!.confidence) {
//         best[d.label] = d;
//       }
//     }
//
//     String finalLabel =
//         count.entries.reduce((a, b) => a.value > b.value ? a : b).key;
//
//     return best[finalLabel];
//   }
//
//   // ── Build ─────────────────────────────────
//
//   @override
//   Widget build(BuildContext context) {
//     final detections = result.detections;
//     final hasDetections = detections.isNotEmpty;
//     final finalDet = _getFinalDetection(detections);
//
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFE6F4EA), Color(0xFFD1FAE5), Color(0xFFCCFBF1)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//
//                   // ── Header ───────────────────
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon: const Icon(Icons.arrow_back, color: Color(0xFF166534)),
//                       ),
//                       const Text(
//                         'نتيجة التشخيص',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF14532D),
//                           fontFamily: 'NotoSansArabic',
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: onLogout,
//                         icon: const Icon(Icons.logout, color: Colors.red),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // ── Annotated image ───────────
//                   Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16)),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(16),
//                       child: Stack(
//                         children: [
//                           Image.memory(
//                             result.annotatedImageBytes,
//                             width: double.infinity,
//                             height: 300,
//                             fit: BoxFit.cover,
//                           ),
//                           Positioned(
//                             top: 8,
//                             left: 8,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 10, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: Colors.black54,
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Text(
//                                 hasDetections
//                                     ? '${detections.length} منطقة مكتشفة'
//                                     : 'لا توجد كشوفات',
//                                 style: const TextStyle(
//                                     color: Colors.white, fontSize: 12),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//
//                   // ── No detection ──────────────
//                   if (!hasDetections)
//                     Card(
//                       color: Colors.green.shade50,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16)),
//                       child: const Padding(
//                         padding: EdgeInsets.all(20),
//                         child: Column(
//                           children: [
//                             Icon(Icons.check_circle,
//                                 color: Colors.green, size: 48),
//                             SizedBox(height: 8),
//                             Text(
//                               'لم يتم اكتشاف أي إصابة',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF14532D),
//                                 fontFamily: 'NotoSansArabic',
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                   // ── ONE FINAL LABEL ───────────
//                   if (finalDet != null)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 12),
//                       child: Card(
//                         elevation: 3,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                           side: BorderSide(
//                             color: _flutterColor(
//                               ModelService.labels.indexOf(finalDet.label),
//                             ).withValues(alpha: 0.4),
//                           ),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.label,
//                                 color: _flutterColor(
//                                   ModelService.labels.indexOf(finalDet.label),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment:
//                                   CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       _arabic(finalDet.label),
//                                       style: TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                         color: _flutterColor(
//                                           ModelService.labels.indexOf(finalDet.label),
//                                         ),
//                                         fontFamily: 'NotoSansArabic',
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       finalDet.label,
//                                       style: TextStyle(
//                                         fontSize: 13,
//                                         color: Colors.grey.shade600,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 6),
//                                     LinearProgressIndicator(
//                                       value: finalDet.confidence,
//                                       minHeight: 6,
//                                       backgroundColor: Colors.grey.shade300,
//                                       valueColor: AlwaysStoppedAnimation(
//                                         _flutterColor(
//                                           ModelService.labels.indexOf(finalDet.label),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//
//                   const SizedBox(height: 12),
//
//                                     // ── Ask specialist ────────────
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       Navigator.pushNamed(
//                         context,
//                         Routes.chatbot,
//                         arguments: {'diseaseName': finalDet!.label}, // send the disease name
//                       );
//                     },
//                     icon: const Icon(Icons.message),
//                     label: const Text('اسأل مختص', style: TextStyle(fontSize: 16)),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(double.infinity, 56),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   // ── Home ──────────────────────
//                   OutlinedButton.icon(
//                     onPressed: () => Navigator.popUntil(
//                         context, ModalRoute.withName(Routes.farmerHome)),
//                     icon: const Icon(Icons.home),
//                     label: const Text('العودة إلى الصفحة الرئيسية',
//                         style: TextStyle(fontSize: 16)),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 56),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16)),
//                       side: const BorderSide(color: Color(0xFF22C55E)),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';

import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/ai_diagnosis_service.dart'; // updated service

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

  // ── Colour palette (matches ModelService._classRgb) ──────────────────

  static const List<Color> _classColors = [
    Color(0xFFE53935), // 0  maize fall armyworm
    Color(0xFF43A047), // 1  maize leaf
    Color(0xFFFB8C00), // 2  maize leaf blight
    Color(0xFF00ACC1), // 3  potato late blight
    Color(0xFF8E24AA), // 4  potato leaf
    Color(0xFFFFB300), // 5  potato pest damage
    Color(0xFFD81B60), // 6  tomato early blight
    Color(0xFF1E88E5), // 7  tomato leaf
    Color(0xFF6D4C41), // 8  tomato leaf miner
  ];

  Color _colorForLabel(String label) {
    final idx = ModelService.labels.indexOf(label);
    if (idx < 0) return Colors.grey;
    return _classColors[idx.clamp(0, _classColors.length - 1)];
  }

  String _arabicLabel(String label) =>
      ModelService.labelArabic[label] ?? label;

  // ── Severity level → UI properties ───────────────────────────────────

  _SeverityStyle _severityStyle(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.healthy:
        return _SeverityStyle(
          color: const Color(0xFF22C55E),
          icon: Icons.check_circle_rounded,
          arabic: 'سليم',
        );
      case SeverityLevel.mild:
        return _SeverityStyle(
          color: const Color(0xFF84CC16),
          icon: Icons.info_rounded,
          arabic: 'خفيف',
        );
      case SeverityLevel.moderate:
        return _SeverityStyle(
          color: const Color(0xFFF59E0B),
          icon: Icons.warning_amber_rounded,
          arabic: 'متوسط',
        );
      case SeverityLevel.severe:
        return _SeverityStyle(
          color: const Color(0xFFF97316),
          icon: Icons.warning_rounded,
          arabic: 'شديد',
        );
      case SeverityLevel.critical:
        return _SeverityStyle(
          color: const Color(0xFFEF4444),
          icon: Icons.dangerous_rounded,
          arabic: 'حرج',
        );
    }
  }

  // ── Most severe disease for the chatbot button ────────────────────────

  /// Returns the disease label with the highest severity ratio across all
  /// leaves. Falls back to null when fully healthy.
  String? _mostSevereDisease() {
    LeafSeverity? worst;
    for (final sev in result.leafSeverities) {
      if (sev.level == SeverityLevel.healthy) continue;
      if (worst == null || sev.severityRatio > worst.severityRatio) {
        worst = sev;
      }
    }
    if (worst == null || worst.diseaseLabels.isEmpty) return null;
    return worst.diseaseLabels.first;
  }

  // ── Detected regions count (disease detections only) ─────────────────

  int get _diseaseDetectionCount =>
      result.detections.where((d) => !d.isLeaf).length;

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isHealthy      = result.isFullyHealthy;
    final worstDisease   = _mostSevereDisease();
    final severities     = result.leafSeverities;

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

                  // ── Header ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: Color(0xFF166534)),
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

                  // ── Annotated image ────────────────────────────────
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
                          // badge — disease region count
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
                                isHealthy
                                    ? 'لا توجد إصابات'
                                    : '$_diseaseDetectionCount منطقة مصابة',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                          // badge — leaf count
                          if (severities.isNotEmpty)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${severities.length} ورقة',
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

                  // ── Fully healthy banner ───────────────────────────
                  if (isHealthy)
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
                              'النبات سليم',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF14532D),
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'لم يتم اكتشاف أي إصابة على الأوراق',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF166534),
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Per-leaf severity cards ────────────────────────
                  if (severities.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'تفاصيل الأوراق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14532D),
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ),
                    ...severities.asMap().entries.map(
                          (entry) => _LeafSeverityCard(
                        index: entry.key,
                        severity: entry.value,
                        severityStyle: _severityStyle(entry.value.level),
                        colorForLabel: _colorForLabel,
                        arabicLabel: _arabicLabel,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── Ask specialist (only when disease found) ───────
                  if (!isHealthy && worstDisease != null)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        Routes.chatbot,
                        arguments: {'diseaseName': worstDisease},
                      ),
                      icon: const Icon(Icons.message),
                      label: const Text(
                        'اسأل مختص',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),

                  if (!isHealthy && worstDisease != null)
                    const SizedBox(height: 12),

                  // ── Home ──────────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () => Navigator.popUntil(
                        context, ModalRoute.withName(Routes.farmerHome)),
                    icon: const Icon(Icons.home),
                    label: const Text(
                      'العودة إلى الصفحة الرئيسية',
                      style: TextStyle(fontSize: 16),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Per-leaf severity card widget
// ─────────────────────────────────────────────────────────────────────────────

class _LeafSeverityCard extends StatelessWidget {
  final int index;
  final LeafSeverity severity;
  final _SeverityStyle severityStyle;
  final Color Function(String) colorForLabel;
  final String Function(String) arabicLabel;

  const _LeafSeverityCard({
    required this.index,
    required this.severity,
    required this.severityStyle,
    required this.colorForLabel,
    required this.arabicLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pct        = (severity.severityRatio * 100);
    final pctDisplay = pct.toStringAsFixed(1);
    final isHealthy  = severity.level == SeverityLevel.healthy;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: severityStyle.color.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Card header: leaf number + crop + severity badge ──
              Row(
                children: [
                  Icon(Icons.eco_rounded,
                      color: severityStyle.color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ورقة ${index + 1}  •  ${_arabicCrop(severity.cropType)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14532D),
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  ),
                  // severity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityStyle.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: severityStyle.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(severityStyle.icon,
                            color: severityStyle.color, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          severityStyle.arabic,
                          style: TextStyle(
                            color: severityStyle.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Severity progress bar ─────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'نسبة الإصابة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                      Text(
                        isHealthy ? '٠٪' : '$pctDisplay٪',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: severityStyle.color,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: severity.severityRatio.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(severityStyle.color),
                    ),
                  ),
                ],
              ),

              // ── Disease labels found on this leaf ─────────────────
              if (!isHealthy && severity.diseaseLabels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: severity.diseaseLabels.map((label) {
                    final col = colorForLabel(label);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: col.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        arabicLabel(label),
                        style: TextStyle(
                          fontSize: 12,
                          color: col,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // ── Healthy sub-label ─────────────────────────────────
              if (isHealthy) ...[
                const SizedBox(height: 8),
                Text(
                  'لا توجد إصابة على هذه الورقة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _arabicCrop(String crop) {
    switch (crop) {
      case 'maize':  return 'ذرة';
      case 'potato': return 'بطاطس';
      case 'tomato': return 'طماطم';
      default:       return crop;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tiny style carrier
// ─────────────────────────────────────────────────────────────────────────────

class _SeverityStyle {
  final Color  color;
  final IconData icon;
  final String arabic;
  const _SeverityStyle({
    required this.color,
    required this.icon,
    required this.arabic,
  });
}