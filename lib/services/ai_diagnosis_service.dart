import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// ─────────────────────────────────────────────
// Plain geometry types
// ─────────────────────────────────────────────

class NPoint {
  final double x;
  final double y;
  const NPoint(this.x, this.y);
}

class NRect {
  final double left;
  final double top;
  final double right;
  final double bottom;
  const NRect(this.left, this.top, this.right, this.bottom);
}

// ─────────────────────────────────────────────
// Severity level — based on Horsfall-Barratt
// scale adapted for digital imaging
// (Bock et al., 2010, Plant Disease)
// ─────────────────────────────────────────────

enum SeverityLevel {
  healthy,   // 0 %          — no lesions detected
  mild,      // 0–10 %       — early/localised lesions
  moderate,  // 10–25 %      — noticeable spread
  severe,    // 25–50 %      — major tissue loss
  critical,  // > 50 %       — leaf functionally destroyed
}

extension SeverityLevelExt on SeverityLevel {
  String get label {
    switch (this) {
      case SeverityLevel.healthy:  return 'Healthy';
      case SeverityLevel.mild:     return 'Mild';
      case SeverityLevel.moderate: return 'Moderate';
      case SeverityLevel.severe:   return 'Severe';
      case SeverityLevel.critical: return 'Critical';
    }
  }

  String get labelArabic {
    switch (this) {
      case SeverityLevel.healthy:  return 'سليم';
      case SeverityLevel.mild:     return 'خفيف';
      case SeverityLevel.moderate: return 'متوسط';
      case SeverityLevel.severe:   return 'شديد';
      case SeverityLevel.critical: return 'حرج';
    }
  }

  static SeverityLevel fromRatio(double ratio) {
    if (ratio <= 0.0)  return SeverityLevel.healthy;
    if (ratio < 0.10)  return SeverityLevel.mild;
    if (ratio < 0.25)  return SeverityLevel.moderate;
    if (ratio < 0.50)  return SeverityLevel.severe;
    return SeverityLevel.critical;
  }
}

// ─────────────────────────────────────────────
// Per-leaf severity result
// ─────────────────────────────────────────────

class LeafSeverity {
  /// Index of the leaf detection this result belongs to.
  final int leafIndex;

  /// Crop/plant type inferred from the leaf class (e.g. "tomato").
  final String cropType;

  /// Pixel area of the leaf mask (in model-input space).
  final int leafAreaPx;

  /// Pixel area of all disease regions overlapping this leaf.
  final int diseaseAreaPx;

  /// diseaseAreaPx / leafAreaPx  (0.0 – 1.0)
  final double severityRatio;

  /// Discrete severity level (Horsfall-Barratt adapted).
  final SeverityLevel level;

  /// Disease labels found on this leaf (may be empty).
  final List<String> diseaseLabels;

  const LeafSeverity({
    required this.leafIndex,
    required this.cropType,
    required this.leafAreaPx,
    required this.diseaseAreaPx,
    required this.severityRatio,
    required this.level,
    required this.diseaseLabels,
  });
}

// ─────────────────────────────────────────────
// Detection result classes
// ─────────────────────────────────────────────

class DetectedObject {
  final String label;
  final double confidence;
  final NRect boundingBox;
  final List<NPoint> polygon;

  /// True when this detection is a leaf class (not a disease class).
  final bool isLeaf;

  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.polygon,
    required this.isLeaf,
  });
}

class SegmentationResult {
  /// All raw detections (both leaf and disease).
  final List<DetectedObject> detections;

  /// Per-leaf severity assessments.
  final List<LeafSeverity> leafSeverities;

  /// Annotated image:
  ///   • Healthy leaf  → no polygons drawn.
  ///   • Diseased leaf → only disease-region polygons drawn (no leaf outline).
  final Uint8List annotatedImageBytes;

  const SegmentationResult({
    required this.detections,
    required this.leafSeverities,
    required this.annotatedImageBytes,
  });

  /// Convenience: true when every leaf is healthy (or no leaves detected).
  bool get isFullyHealthy =>
      leafSeverities.isEmpty ||
          leafSeverities.every((s) => s.level == SeverityLevel.healthy);
}

// ─────────────────────────────────────────────
// Internal raw detection (before NMS)
// ─────────────────────────────────────────────

class _RawDet {
  final int cls;
  final double conf;
  final double x1, y1, x2, y2;
  final List<double> maskCoef;

  const _RawDet({
    required this.cls,
    required this.conf,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.maskCoef,
  });
}

// ─────────────────────────────────────────────
// Model Service
// ─────────────────────────────────────────────

class ModelService {
  late Interpreter _interpreter;

  // ── Model dimensions ──────────────────────
  static const int inputSize   = 640;
  static const int numAnchors  = 8400;   // 640-input YOLOv-seg anchors
  static const int numClasses  = 9;
  static const int numMaskCoef = 32;
  static const int protoSize   = 160;    // 640/4 — standard YOLOv-seg proto
  static const int rowSize     = 4 + numClasses + numMaskCoef;

  // ── Inference thresholds ─────────────────
  static const double confThreshold = 0.10;
  static const double iouThreshold  = 0.45;

  static const String modelPath = 'assets/models/model_float16.tflite';

  // ── Class labels (index = class id) ──────
  //
  // Classes at indices 1, 4, 7 are LEAF classes — they carry the leaf mask.
  // All other classes carry disease masks.
  static const List<String> labels = [
    'maize fall armyworm', // 0  disease
    'maize leaf',          // 1  leaf  ← crop: maize
    'maize leaf blight',   // 2  disease
    'potato late blight',  // 3  disease
    'potato leaf',         // 4  leaf  ← crop: potato
    'potato pest damage',  // 5  disease
    'tomato early blight', // 6  disease
    'tomato leaf',         // 7  leaf  ← crop: tomato
    'tomato leaf miner',   // 8  disease
  ];

  /// Set of class indices that represent LEAF (not disease) detections.
  static const Set<int> _leafClassIds = {1, 4, 7};

  /// Maps a leaf class id → crop name string.
  static const Map<int, String> _leafCropName = {
    1: 'maize',
    4: 'potato',
    7: 'tomato',
  };

  /// Maps a disease class id → the crop it belongs to.
  /// Used to pair disease detections with the correct leaf.
  static const Map<int, String> _diseaseCrop = {
    0: 'maize',
    2: 'maize',
    3: 'potato',
    5: 'potato',
    6: 'tomato',
    8: 'tomato',
  };

  // ── Arabic translations ───────────────────
  static const Map<String, String> labelArabic = {
    'maize fall armyworm': 'دودة الحشد الخريفية في الذرة',
    'maize leaf':          'ورقة الذرة',
    'maize leaf blight':   'لفحة أوراق الذرة',
    'potato late blight':  'اللفحة المتأخرة في البطاطس',
    'potato leaf':         'ورقة البطاطس',
    'potato pest damage':  'تلف آفات البطاطس',
    'tomato early blight': 'اللفحة المبكرة في الطماطم',
    'tomato leaf':         'ورقة الطماطم',
    'tomato leaf miner':   'حفار أوراق الطماطم',
  };

  // ── Per-class drawing colours (RGB) ──────
  static const List<List<int>> _classRgb = [
    [229,  57,  53],  // 0  maize fall armyworm  — red
    [ 67, 160,  71],  // 1  maize leaf           — green   (not drawn)
    [251, 140,   0],  // 2  maize leaf blight     — orange
    [  0, 172, 193],  // 3  potato late blight    — cyan
    [142,  36, 170],  // 4  potato leaf           — purple  (not drawn)
    [255, 179,   0],  // 5  potato pest damage    — amber
    [216,  27,  96],  // 6  tomato early blight   — pink
    [ 30, 136, 229],  // 7  tomato leaf           — blue    (not drawn)
    [109,  76,  65],  // 8  tomato leaf miner     — brown
  ];

  // ─────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(modelPath);
  }

  Future<SegmentationResult> analyzeImage(String imagePath) async {
    // ── 1. Load & resize image ───────────────
    final rawBytes = File(imagePath).readAsBytesSync();
    final original = img.decodeImage(rawBytes)!;
    final resized  = img.copyResize(original, width: inputSize, height: inputSize);

    // ── 2. Build input tensor [1, 640, 640, 3] ─
    final flat = Float32List(inputSize * inputSize * 3);
    int i = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        flat[i++] = img.getRed(p)   / 255.0;
        flat[i++] = img.getGreen(p) / 255.0;
        flat[i++] = img.getBlue(p)  / 255.0;
      }
    }
    final input = _reshape4D(flat, 1, inputSize, inputSize, 3);

    // ── 3. Allocate output tensors ────────────
    // out0: [1, rowSize, numAnchors]  — boxes + class scores + mask coefficients
    // out1: [1, protoSize, protoSize, numMaskCoef]  — prototype masks
    final out0 = List.generate(
        1, (_) => List.generate(rowSize,
            (_) => List<double>.filled(numAnchors, 0.0)));

    final out1 = List.generate(
        1, (_) => List.generate(protoSize,
            (_) => List.generate(protoSize,
                (_) => List<double>.filled(numMaskCoef, 0.0))));

    // ── 4. Run inference ─────────────────────
    _interpreter.runForMultipleInputs([input], {0: out0, 1: out1});

    // ── 5. Decode detections ─────────────────
    final detections = _decode(out0[0], out1[0]);

    // ── 6. Compute per-leaf severity ─────────
    final leafSeverities = _computeLeafSeverities(detections, out1[0]);

    // ── 7. Render annotated image ────────────
    final annotated = _drawAnnotations(original, detections, leafSeverities);

    return SegmentationResult(
      detections: detections,
      leafSeverities: leafSeverities,
      annotatedImageBytes: Uint8List.fromList(img.encodePng(annotated)),
    );
  }

  // ─────────────────────────────────────────
  // Decode + NMS
  // ─────────────────────────────────────────

  List<DetectedObject> _decode(
      List<List<double>> pred,
      List<List<List<double>>> proto) {

    final rawDets = <_RawDet>[];

    for (int a = 0; a < numAnchors; a++) {
      double best = 0;
      int    cls  = 0;

      for (int c = 0; c < numClasses; c++) {
        final s = pred[4 + c][a];
        if (s > best) { best = s; cls = c; }
      }

      if (best < confThreshold) continue;

      final cx = pred[0][a] / inputSize;
      final cy = pred[1][a] / inputSize;
      final bw = pred[2][a] / inputSize;
      final bh = pred[3][a] / inputSize;

      rawDets.add(_RawDet(
        cls:      cls,
        conf:     best,
        x1:       (cx - bw / 2).clamp(0.0, 1.0),
        y1:       (cy - bh / 2).clamp(0.0, 1.0),
        x2:       (cx + bw / 2).clamp(0.0, 1.0),
        y2:       (cy + bh / 2).clamp(0.0, 1.0),
        maskCoef: List.generate(numMaskCoef, (i) => pred[4 + numClasses + i][a]),
      ));
    }

    final kept = _nms(rawDets);

    return kept.map((d) => DetectedObject(
      label:       labels[d.cls],
      confidence:  d.conf,
      boundingBox: NRect(d.x1, d.y1, d.x2, d.y2),
      polygon:     _buildPolygon(d, proto),
      isLeaf:      _leafClassIds.contains(d.cls),
    )).toList();
  }

  List<_RawDet> _nms(List<_RawDet> dets) {
    dets.sort((a, b) => b.conf.compareTo(a.conf));
    final kept = <_RawDet>[];
    for (final d in dets) {
      bool ok = true;
      for (final k in kept) {
        if (_iou(k, d) > iouThreshold) { ok = false; break; }
      }
      if (ok) kept.add(d);
    }
    return kept;
  }

  double _iou(_RawDet a, _RawDet b) {
    final ix1  = max(a.x1, b.x1);
    final iy1  = max(a.y1, b.y1);
    final ix2  = min(a.x2, b.x2);
    final iy2  = min(a.y2, b.y2);
    final inter = max(0.0, ix2 - ix1) * max(0.0, iy2 - iy1);
    if (inter == 0) return 0;
    final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
    return inter / (areaA + areaB - inter);
  }

  // ─────────────────────────────────────────
  // Per-leaf severity calculation
  //
  // Approach (Horsfall-Barratt / Bock et al.):
  //   severity_ratio = Σ disease_px_on_leaf / leaf_px
  //
  // Disease regions are matched to a leaf by:
  //   (a) same crop type, AND
  //   (b) bounding-box IoU > 0.10  (disease is on / inside that leaf)
  //
  // Pixel areas are computed on binary masks projected to
  // inputSize × inputSize space for speed.
  // ─────────────────────────────────────────

  List<LeafSeverity> _computeLeafSeverities(
      List<DetectedObject> detections,
      List<List<List<double>>> proto) {

    // Separate leaves and diseases
    final leafDets    = detections.where((d) =>  d.isLeaf).toList();
    final diseaseDets = detections.where((d) => !d.isLeaf).toList();

    if (leafDets.isEmpty) return [];

    // Build pixel-space binary masks for every detection (at inputSize)
    final List<List<List<int>>> leafBinaries    = leafDets   .map((d) => _polygonToBinaryMask(d.polygon, inputSize)).toList();
    final List<List<List<int>>> diseaseBinaries = diseaseDets.map((d) => _polygonToBinaryMask(d.polygon, inputSize)).toList();

    final results = <LeafSeverity>[];

    for (int li = 0; li < leafDets.length; li++) {
      final leaf     = leafDets[li];
      final leafMask = leafBinaries[li];
      final leafPx   = _countPixels(leafMask);

      if (leafPx == 0) continue;

      final cropType = _getCropFromLabel(leaf.label);

      // Find all disease detections that belong to this crop and overlap leaf
      final matchedDiseases = <String>[];
      int totalDiseasePx = 0;

      for (int di = 0; di < diseaseDets.length; di++) {
        final disease     = diseaseDets[di];
        final diseaseCrop = _getCropFromLabel(disease.label);

        if (diseaseCrop != cropType) continue;

        // Bounding-box IoU as a fast overlap pre-filter
        final bbIou = _bboxIouFromNRect(leaf.boundingBox, disease.boundingBox);
        if (bbIou < 0.05) continue;

        // Count pixels where BOTH leaf mask and disease mask are active
        final overlap = _maskIntersectionCount(leafMask, diseaseBinaries[di]);
        if (overlap == 0) continue;

        totalDiseasePx += overlap;
        if (!matchedDiseases.contains(disease.label)) {
          matchedDiseases.add(disease.label);
        }
      }

      final ratio = (totalDiseasePx / leafPx).clamp(0.0, 1.0);
      final level = matchedDiseases.isEmpty
          ? SeverityLevel.healthy
          : SeverityLevelExt.fromRatio(ratio);

      results.add(LeafSeverity(
        leafIndex:    li,
        cropType:     cropType,
        leafAreaPx:   leafPx,
        diseaseAreaPx: totalDiseasePx,
        severityRatio: ratio,
        level:         level,
        diseaseLabels: matchedDiseases,
      ));
    }

    return results;
  }

  // ─────────────────────────────────────────
  // Annotation drawing
  //
  // Rules:
  //  • Healthy leaf (level == healthy, or isLeaf && no disease) → no polygon
  //  • Diseased leaf → draw disease region polygons only (not the leaf outline)
  //  • Bounding box label with severity is drawn for every leaf
  // ─────────────────────────────────────────

  img.Image _drawAnnotations(
      img.Image original,
      List<DetectedObject> detections,
      List<LeafSeverity> leafSeverities) {

    final canvas = img.copyResize(original,
        width: original.width, height: original.height);

    final origW = original.width.toDouble();
    final origH = original.height.toDouble();

    // Build a set of disease labels for leaves that ARE diseased
    // so we know which disease polygons to render.
    final diseasedCrops = <String>{};
    for (final sev in leafSeverities) {
      if (sev.level != SeverityLevel.healthy) {
        diseasedCrops.add(sev.cropType);
      }
    }

    // ── Draw disease polygons (only for diseased crops) ──────────────
    for (final det in detections) {
      if (det.isLeaf) continue; // never draw leaf outlines

      final crop = _getCropFromLabel(det.label);
      if (!diseasedCrops.contains(crop)) continue; // healthy crop — skip

      final clsIdx = labels.indexOf(det.label);
      final rgb    = clsIdx >= 0 ? _classRgb[clsIdx] : [255, 0, 0];
      final color  = img.getColor(rgb[0], rgb[1], rgb[2]);

      _drawFilledPolygon(canvas, det.polygon, origW, origH, color, alpha: 80);
      _drawPolygonOutline(canvas, det.polygon, origW, origH, color, thickness: 2);
    }

    // ── Draw severity label per leaf ─────────────────────────────────
    final leafDets = detections.where((d) => d.isLeaf).toList();

    for (int li = 0; li < leafSeverities.length; li++) {
      final sev = leafSeverities[li];
      if (li >= leafDets.length) continue;

      final leaf = leafDets[sev.leafIndex < leafDets.length ? sev.leafIndex : li];
      final bb   = leaf.boundingBox;

      final lx = (bb.left  * origW).round();
      final ty = (bb.top   * origH).round();

      final clsIdx    = labels.indexOf(leaf.label);
      final rgb       = clsIdx >= 0 ? _classRgb[clsIdx] : [100, 200, 100];
      final textColor = img.getColor(rgb[0], rgb[1], rgb[2]);

      final sevPct = (sev.severityRatio * 100).toStringAsFixed(1);
      final tag    = '${sev.level.label} $sevPct%';

      img.drawString(canvas, img.arial_14, lx.clamp(0, canvas.width - 80), ty.clamp(0, canvas.height - 20), tag, color: textColor);
    }

    return canvas;
  }

  // ─────────────────────────────────────────
  // Mask utilities
  // ─────────────────────────────────────────

  /// Rasterise a normalised polygon into a binary mask of [size × size].
  List<List<int>> _polygonToBinaryMask(List<NPoint> polygon, int size) {
    final mask = List.generate(size, (_) => List<int>.filled(size, 0));
    if (polygon.length < 3) return mask;

    final pts = polygon.map((p) => [
      (p.x * size).round().clamp(0, size - 1),
      (p.y * size).round().clamp(0, size - 1),
    ]).toList();

    // Scanline fill
    for (int y = 0; y < size; y++) {
      final intersections = <int>[];
      final n = pts.length;
      for (int i = 0; i < n; i++) {
        final p1 = pts[i];
        final p2 = pts[(i + 1) % n];
        final y1 = p1[1]; final y2 = p2[1];
        if ((y1 <= y && y < y2) || (y2 <= y && y < y1)) {
          final x = (p1[0] + (y - y1) / (y2 - y1) * (p2[0] - p1[0])).round();
          intersections.add(x);
        }
      }
      intersections.sort();
      for (int k = 0; k + 1 < intersections.length; k += 2) {
        final x0 = intersections[k].clamp(0, size - 1);
        final x1 = intersections[k + 1].clamp(0, size - 1);
        for (int x = x0; x <= x1; x++) {
          mask[y][x] = 1;
        }
      }
    }
    return mask;
  }

  int _countPixels(List<List<int>> mask) {
    int count = 0;
    for (final row in mask) {
      for (final px in row) {
        if (px == 1) count++;
      }
    }
    return count;
  }

  int _maskIntersectionCount(List<List<int>> a, List<List<int>> b) {
    int count = 0;
    final h = min(a.length, b.length);
    for (int y = 0; y < h; y++) {
      final w = min(a[y].length, b[y].length);
      for (int x = 0; x < w; x++) {
        if (a[y][x] == 1 && b[y][x] == 1) count++;
      }
    }
    return count;
  }

  double _bboxIouFromNRect(NRect a, NRect b) {
    final ix1  = max(a.left,   b.left);
    final iy1  = max(a.top,    b.top);
    final ix2  = min(a.right,  b.right);
    final iy2  = min(a.bottom, b.bottom);
    final inter = max(0.0, ix2 - ix1) * max(0.0, iy2 - iy1);
    if (inter == 0) return 0;
    final areaA = (a.right - a.left) * (a.bottom - a.top);
    final areaB = (b.right - b.left) * (b.bottom - b.top);
    return inter / (areaA + areaB - inter);
  }

  // ─────────────────────────────────────────
  // Polygon builder (mask → contour)
  // ─────────────────────────────────────────

  List<NPoint> _buildPolygon(
      _RawDet det,
      List<List<List<double>>> proto) {

    // 1. Compute soft mask at proto resolution (protoSize × protoSize)
    final mask = List.generate(protoSize, (y) =>
        List.generate(protoSize, (x) {
          double v = 0;
          for (int k = 0; k < numMaskCoef; k++) {
            v += proto[y][x][k] * det.maskCoef[k];
          }
          return 1.0 / (1.0 + exp(-v));
        }));

    // 2. Crop to bounding box in proto space, then upscale to inputSize
    final upscaled = _resizeMask(mask, inputSize);

    // 3. Binarise
    final binary = List.generate(inputSize,
            (y) => List.generate(inputSize,
                (x) => upscaled[y][x] > 0.10 ? 1 : 0));

    // 4. Extract contour
    final contours = _marchingSquares(binary);

    if (contours.isEmpty) {
      return [
        NPoint(det.x1, det.y1),
        NPoint(det.x2, det.y1),
        NPoint(det.x2, det.y2),
        NPoint(det.x1, det.y2),
      ];
    }

    contours.sort((a, b) => b.length.compareTo(a.length));
    return contours.first;
  }

  // ─────────────────────────────────────────
  // Marching squares contour tracer
  // ─────────────────────────────────────────

  bool _isEdge(List<List<int>> grid, int x, int y) {
    final h = grid.length;
    final w = grid[0].length;
    if (grid[y][x] == 0) return false;
    if (y > 0     && grid[y - 1][x] == 0) return true;
    if (y < h - 1 && grid[y + 1][x] == 0) return true;
    if (x > 0     && grid[y][x - 1] == 0) return true;
    if (x < w - 1 && grid[y][x + 1] == 0) return true;
    return false;
  }

  List<List<NPoint>> _marchingSquares(List<List<int>> grid) {
    final h       = grid.length;
    final w       = grid[0].length;
    final visited = List.generate(h, (_) => List.filled(w, false));
    final contours = <List<NPoint>>[];

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (grid[y][x] == 0 || visited[y][x]) continue;
        if (!_isEdge(grid, x, y)) continue;

        final contour = <NPoint>[];
        int cx = x, cy = y;
        final startX = x, startY = y;
        int steps = 0;
        const maxSteps = 10000;

        do {
          visited[cy][cx] = true;
          contour.add(NPoint((cx + 0.5) / w, (cy + 0.5) / h));

          bool moved = false;
          for (final d in [
            [1, 0], [1, 1], [0, 1], [-1, 1],
            [-1, 0], [-1, -1], [0, -1], [1, -1],
          ]) {
            final nx = cx + d[0];
            final ny = cy + d[1];
            if (nx >= 0 && ny >= 0 && nx < w && ny < h &&
                grid[ny][nx] == 1 &&
                _isEdge(grid, nx, ny) &&
                !visited[ny][nx]) {
              cx = nx; cy = ny;
              moved = true;
              break;
            }
          }
          steps++;
          if (!moved || steps > maxSteps) break;
        } while (!(cx == startX && cy == startY && contour.length > 10));

        if (contour.length > 20) {
          contours.add(_simplify(contour, 0.002));
        }
      }
    }
    return contours;
  }

  // ─────────────────────────────────────────
  // Ramer-Douglas-Peucker simplification
  // ─────────────────────────────────────────

  List<NPoint> _simplify(List<NPoint> pts, double eps) {
    if (pts.length < 3) return pts;

    double maxDist = 0;
    int    maxIdx  = 0;

    final first = pts.first;
    final last  = pts.last;

    for (int i = 1; i < pts.length - 1; i++) {
      final d = _perpendicularDistance(pts[i], first, last);
      if (d > maxDist) { maxDist = d; maxIdx = i; }
    }

    if (maxDist > eps) {
      final left  = _simplify(pts.sublist(0, maxIdx + 1), eps);
      final right = _simplify(pts.sublist(maxIdx), eps);
      return [...left.sublist(0, left.length - 1), ...right];
    }
    return [first, last];
  }

  double _perpendicularDistance(NPoint p, NPoint a, NPoint b) {
    final dx  = b.x - a.x;
    final dy  = b.y - a.y;
    final mag = sqrt(dx * dx + dy * dy);
    if (mag == 0) return sqrt(pow(p.x - a.x, 2) + pow(p.y - a.y, 2));
    return ((dy * p.x - dx * p.y + b.x * a.y - b.y * a.x) / mag).abs();
  }

  // ─────────────────────────────────────────
  // Mask resize (bilinear)
  // ─────────────────────────────────────────

  List<List<double>> _resizeMask(List<List<double>> src, int newSize) {
    final oldSize = src.length;
    return List.generate(newSize, (y) {
      return List.generate(newSize, (x) {
        final gx = x * (oldSize - 1) / (newSize - 1);
        final gy = y * (oldSize - 1) / (newSize - 1);
        final x0 = gx.floor(), y0 = gy.floor();
        final x1 = (x0 + 1).clamp(0, oldSize - 1);
        final y1 = (y0 + 1).clamp(0, oldSize - 1);
        final dx = gx - x0, dy = gy - y0;
        return src[y0][x0] * (1 - dx) * (1 - dy)
            + src[y0][x1] * dx       * (1 - dy)
            + src[y1][x0] * (1 - dx) * dy
            + src[y1][x1] * dx       * dy;
      });
    });
  }

  // ─────────────────────────────────────────
  // Drawing helpers
  // ─────────────────────────────────────────

  void _drawFilledPolygon(
      img.Image canvas,
      List<NPoint> polygon,
      double w, double h,
      int color,
      {int alpha = 80}) {

    if (polygon.length < 3) return;

    final pts = polygon.map((p) =>
    [  (p.x * w).round().clamp(0, canvas.width  - 1),
      (p.y * h).round().clamp(0, canvas.height - 1),
    ]).toList();

    final r = img.getRed(color);
    final g = img.getGreen(color);
    final b = img.getBlue(color);

    // Bounding box of polygon
    int minY = pts.map((p) => p[1]).reduce(min);
    int maxY = pts.map((p) => p[1]).reduce(max);

    for (int y = minY; y <= maxY; y++) {
      final xs = <int>[];
      final n  = pts.length;
      for (int i = 0; i < n; i++) {
        final p1 = pts[i];
        final p2 = pts[(i + 1) % n];
        if ((p1[1] <= y && y < p2[1]) || (p2[1] <= y && y < p1[1])) {
          final x = (p1[0] + (y - p1[1]) / (p2[1] - p1[1]) * (p2[0] - p1[0])).round();
          xs.add(x);
        }
      }
      xs.sort();
      for (int k = 0; k + 1 < xs.length; k += 2) {
        for (int x = xs[k]; x <= xs[k + 1]; x++) {
          if (x < 0 || x >= canvas.width) continue;
          final orig = canvas.getPixel(x, y);
          final br = img.getRed(orig);
          final bg = img.getGreen(orig);
          final bb = img.getBlue(orig);
          final a  = alpha / 255.0;
          canvas.setPixel(x, y,
              img.getColor(
                (r * a + br * (1 - a)).round(),
                (g * a + bg * (1 - a)).round(),
                (b * a + bb * (1 - a)).round(),
              ));
        }
      }
    }
  }

  void _drawPolygonOutline(
      img.Image canvas,
      List<NPoint> polygon,
      double w, double h,
      int color,
      {int thickness = 2}) {

    if (polygon.length < 2) return;

    final pts = polygon.map((p) =>
    [  (p.x * w).round().clamp(0, canvas.width  - 1),
      (p.y * h).round().clamp(0, canvas.height - 1),
    ]).toList();

    final n = pts.length;
    for (int i = 0; i < n; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      img.drawLine(canvas, p1[0], p1[1], p2[0], p2[1], color, thickness: thickness);
    }
  }

  // ─────────────────────────────────────────
  // Tensor reshape helper
  // ─────────────────────────────────────────

  List _reshape4D(Float32List flat, int d0, int d1, int d2, int d3) {
    int idx = 0;
    return List.generate(d0, (_) =>
        List.generate(d1, (_) =>
            List.generate(d2, (_) =>
                List.generate(d3, (_) => flat[idx++]))));
  }

  // ─────────────────────────────────────────
  // Label → crop-type string
  // ─────────────────────────────────────────

  String _getCropFromLabel(String label) {
    if (label.startsWith('maize'))   return 'maize';
    if (label.startsWith('potato'))  return 'potato';
    if (label.startsWith('tomato'))  return 'tomato';
    return 'unknown';
  }
}

