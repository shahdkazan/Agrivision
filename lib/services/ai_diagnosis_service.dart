
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
// Result classes
// ─────────────────────────────────────────────

class DetectedObject {
  final String label;
  final double confidence;
  final NRect boundingBox;
  final List<NPoint> polygon;

  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.polygon,
  });
}

class SegmentationResult {
  final List<DetectedObject> detections;
  final Uint8List annotatedImageBytes;

  const SegmentationResult({
    required this.detections,
    required this.annotatedImageBytes,
  });
}

// ─────────────────────────────────────────────
// Model Service
// ─────────────────────────────────────────────

class ModelService {
  late Interpreter _interpreter;

  static const int inputSize = 320;
  static const int numAnchors = 2100;
  static const int numClasses = 9;
  static const int numMaskCoef = 32;
  static const int protoSize = 80;
  static const int rowSize = 4 + numClasses + numMaskCoef;

  static const double confThreshold = 0.10;
  static const double iouThreshold = 0.45;

  static const String modelPath = 'assets/models/best_float16.tflite';

  static const List<String> labels = [
    'maize fall armyworm',
    'maize healthy',
    'maize leaf blight',
    'potato healthy',
    'potato late blight',
    'potato pest damage',
    'tomato early blight',
    'tomato healthy',
    'tomato leaf miner',
  ];
  // ── Disease info ──
  static const Map<String, Map<String, String>> diseaseInfo = {
    'maize fall armyworm': {
      'arabic':    'دودة الحشد الخريفية في الذرة',
    },
    'maize healthy': {
      'arabic':    'ذرة سليمة',

    },
    'maize leaf blight': {
      'arabic':    'لفحة أوراق الذرة',

    },
    'potato healthy': {
      'arabic':    'بطاطس سليمة',

    },
    'potato late blight': {
      'arabic':    'اللفحة المتأخرة في البطاطس',

    },
    'potato pest damage': {
      'arabic':    'تلف آفات البطاطس',

    },
    'tomato early blight': {
      'arabic':    'اللفحة المبكرة في الطماطم',

    },
    'tomato healthy': {
      'arabic':    'طماطم سليمة',

    },
    'tomato leaf miner': {
      'arabic':    'حفار أوراق الطماطم',

    },
  };

  static const List<List<int>> _classRgb = [
    [229, 57, 53],
    [67, 160, 71],
    [251, 140, 0],
    [0, 172, 193],
    [142, 36, 170],
    [255, 179, 0],
    [216, 27, 96],
    [30, 136, 229],
    [109, 76, 65],
  ];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(modelPath);
  }

  Future<SegmentationResult> analyzeImage(String imagePath) async {
    final rawBytes = File(imagePath).readAsBytesSync();
    final original = img.decodeImage(rawBytes)!;

    final origW = original.width;
    final origH = original.height;

    final resized = img.copyResize(original, width: inputSize, height: inputSize);

    final flat = Float32List(inputSize * inputSize * 3);
    int i = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        flat[i++] = img.getRed(p) / 255.0;
        flat[i++] = img.getGreen(p) / 255.0;
        flat[i++] = img.getBlue(p) / 255.0;
      }
    }

    final input = _reshape4D(flat, 1, inputSize, inputSize, 3);

    final out0 = List.generate(
        1, (_) => List.generate(rowSize, (_) => List<double>.filled(numAnchors, 0.0)));

    final out1 = List.generate(
        1,
        (_) => List.generate(
            protoSize,
            (_) => List.generate(
                protoSize, (_) => List<double>.filled(numMaskCoef, 0.0))));

    _interpreter.runForMultipleInputs([input], {0: out0, 1: out1});

    final detections = _decode(out0[0], out1[0]);

    final annotated = _drawPolygons(original, detections);

    return SegmentationResult(
      detections: detections,
      annotatedImageBytes: Uint8List.fromList(img.encodePng(annotated)),
    );
  }

  List<DetectedObject> _decode(
      List<List<double>> pred,
      List<List<List<double>>> proto) {

    final dets = <_RawDet>[];

    for (int a = 0; a < numAnchors; a++) {
      double best = 0;
      int cls = 0;

      for (int c = 0; c < numClasses; c++) {
        final s = pred[4 + c][a];
        if (s > best) {
          best = s;
          cls = c;
        }
      }

      if (best < confThreshold) continue;

      final cx = pred[0][a] / inputSize;
      final cy = pred[1][a] / inputSize;
      final bw = pred[2][a] / inputSize;
      final bh = pred[3][a] / inputSize;

      dets.add(_RawDet(
        cls: cls,
        conf: best,
        x1: (cx - bw / 2).clamp(0.0, 1.0),
        y1: (cy - bh / 2).clamp(0.0, 1.0),
        x2: (cx + bw / 2).clamp(0.0, 1.0),
        y2: (cy + bh / 2).clamp(0.0, 1.0),
        maskCoef: List.generate(numMaskCoef,
            (i) => pred[4 + numClasses + i][a]),
      ));
    }

    final kept = _nms(dets);

    return kept.map((d) {
      return DetectedObject(
        label: labels[d.cls],
        confidence: d.conf,
        boundingBox: NRect(d.x1, d.y1, d.x2, d.y2),
        polygon: _buildPolygon(d, proto),
      );
    }).toList();
  }

  List<_RawDet> _nms(List<_RawDet> dets) {
    dets.sort((a, b) => b.conf.compareTo(a.conf));
    final kept = <_RawDet>[];

    for (int i = 0; i < dets.length; i++) {
      bool ok = true;
      for (final k in kept) {
        if (_iou(k, dets[i]) > iouThreshold) {
          ok = false;
          break;
        }
      }
      if (ok) kept.add(dets[i]);
    }
    return kept;
  }

  double _iou(_RawDet a, _RawDet b) {
    final ix1 = max(a.x1, b.x1);
    final iy1 = max(a.y1, b.y1);
    final ix2 = min(a.x2, b.x2);
    final iy2 = min(a.y2, b.y2);

    final inter = max(0.0, ix2 - ix1) * max(0.0, iy2 - iy1);
    if (inter == 0) return 0;

    final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);

    return inter / (areaA + areaB - inter);
  }


  bool _isEdge(List<List<int>> grid, int x, int y) {
    final h = grid.length;
    final w = grid[0].length;

    if (grid[y][x] == 0) return false;

    // Check bounds BEFORE accessing neighbors
    if (y > 0 && grid[y - 1][x] == 0) return true;
    if (y < h - 1 && grid[y + 1][x] == 0) return true;
    if (x > 0 && grid[y][x - 1] == 0) return true;
    if (x < w - 1 && grid[y][x + 1] == 0) return true;

    return false;
  }
  List<List<NPoint>> _marchingSquares(List<List<int>> grid) {
    final h = grid.length;
    final w = grid[0].length;

    final visited = List.generate(h, (_) => List.filled(w, false));
    final contours = <List<NPoint>>[];

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (grid[y][x] == 0 || visited[y][x]) continue;

        // Only start from EDGE pixels
        if (!_isEdge(grid, x, y)) continue;

        final contour = <NPoint>[];

        int cx = x;
        int cy = y;

        int startX = x;
        int startY = y;

        int steps = 0;
        const maxSteps = 10000;

        do {
          visited[cy][cx] = true;

          contour.add(NPoint(
            (cx + 0.5) / w,
            (cy + 0.5) / h,
          ));

          bool moved = false;

          // 8-direction search (clockwise)
          for (final d in [
            [1, 0],
            [1, 1],
            [0, 1],
            [-1, 1],
            [-1, 0],
            [-1, -1],
            [0, -1],
            [1, -1],
          ]) {
            final nx = cx + d[0];
            final ny = cy + d[1];

            if (nx >= 0 &&
                ny >= 0 &&
                nx < w &&
                ny < h &&
                grid[ny][nx] == 1 &&
                _isEdge(grid, nx, ny) &&
                !visited[ny][nx]) {
              cx = nx;
              cy = ny;
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
  // ─────────────────────────────────────────────
  // Polygon builder (UPDATED)
  // ─────────────────────────────────────────────

  List<NPoint> _buildPolygon(
      _RawDet det,
      List<List<List<double>>> proto) {

    final size = inputSize;

    final mask = List.generate(protoSize, (y) =>
        List.generate(protoSize, (x) {
          double v = 0;
          for (int k = 0; k < numMaskCoef; k++) {
            v += proto[y][x][k] * det.maskCoef[k];
          }
          return 1 / (1 + exp(-v));
        }));

    final upscaled = _resizeMask(mask, size);
    //
    // final binary = List.generate(size,
    //     (y) => List.generate(size, (x) => upscaled[y][x] > 0.05 ? 1 : 0));
    final binary = List.generate(size,
            (y) => List.generate(size, (x) => upscaled[y][x] > 0.1 ? 1 : 0));
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

  List<List<double>> _resizeMask(
      List<List<double>> src, int newSize) {

    final oldSize = src.length;

    return List.generate(newSize, (y) {
      return List.generate(newSize, (x) {
        final gx = x * (oldSize - 1) / (newSize - 1);
        final gy = y * (oldSize - 1) / (newSize - 1);

        final x0 = gx.floor();
        final y0 = gy.floor();
        final x1 = (x0 + 1).clamp(0, oldSize - 1);
        final y1 = (y0 + 1).clamp(0, oldSize - 1);

        final dx = gx - x0;
        final dy = gy - y0;

        return src[y0][x0] * (1 - dx) * (1 - dy) +
            src[y0][x1] * dx * (1 - dy) +
            src[y1][x0] * (1 - dx) * dy +
            src[y1][x1] * dx * dy;
      });
    });
  }

  List<NPoint> _simplify(List<NPoint> pts, double eps) {
    if (pts.length < 3) return pts;

    final res = <NPoint>[pts.first];

    for (int i = 1; i < pts.length - 1; i++) {
      final p = pts[i];
      if ((p.x - res.last.x).abs() + (p.y - res.last.y).abs() > eps) {
        res.add(p);
      }
    }

    res.add(pts.last);
    return res;
  }

  img.Image _drawPolygons(img.Image src, List<DetectedObject> dets) {
    final out = img.Image.from(src);

    for (final d in dets) {
      final c = _classRgb[labels.indexOf(d.label)];
      final color = img.getColor(c[0], c[1], c[2]);

      for (int i = 0; i < d.polygon.length; i++) {
        final a = d.polygon[i];
        final b = d.polygon[(i + 1) % d.polygon.length];

        img.drawLine(
            out,
            (a.x * src.width).round(),
            (a.y * src.height).round(),
            (b.x * src.width).round(),
            (b.y * src.height).round(),
            color);
      }
    }

    return out;
  }

  double _sigmoid(double x) => 1 / (1 + exp(-x));

  List<List<List<List<double>>>> _reshape4D(
      Float32List flat, int n, int h, int w, int c) {
    int i = 0;
    return List.generate(
        n,
        (_) => List.generate(
            h,
            (_) => List.generate(
                w,
                (_) => List.generate(c, (_) => flat[i++].toDouble()))));
  }
}

class _RawDet {
  final int cls;
  final double conf;
  final double x1, y1, x2, y2;
  final List<double> maskCoef;

  _RawDet({
    required this.cls,
    required this.conf,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.maskCoef,
  });
}
