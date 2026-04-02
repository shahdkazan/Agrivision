
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_diagnosis_service.dart';
import '../routes.dart';
import 'disease_results_page.dart';
import '../services/offline_cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/sync_service.dart';

class DiseaseDetectionPage extends StatefulWidget {
  final Map<String, String>? user;
  final VoidCallback? onLogout;

  const DiseaseDetectionPage({super.key, this.user, this.onLogout});

  @override
  State<DiseaseDetectionPage> createState() => _DiseaseDetectionPageState();
}

class _DiseaseDetectionPageState extends State<DiseaseDetectionPage> {
  final _modelService = ModelService();
  final _cacheService = OfflineCacheService();
  final _syncService = SyncService();
  File?  _imageFile;
  bool   _loading     = false;
  bool   _modelLoaded = false;

  final _picker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _loadModel();

    Future.microtask(() => _syncService.trySync());
  }
  Future<void> _loadModel() async {
    try {
      await _modelService.loadModel();
      if (!mounted) return;
      setState(() => _modelLoaded = true);
    } catch (e) {
      debugPrint('Error loading model: $e');
      if (!mounted) return;
      setState(() => _modelLoaded = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }


  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;
    setState(() => _loading = true);

    try {
      final result = await _modelService.analyzeImage(_imageFile!.path);

      final firstLabel =
      result.detections.isNotEmpty ? result.detections.first.label : "unknown";

      // ✅ ALWAYS store in queue
      await _cacheService.addToQueue(
        imageFile: _imageFile!,
        label: firstLabel,
      );

      // ✅ Try immediate sync (if online)
      await _syncService.trySync();

      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiseaseResultsPage(
            result: result,
            imageFile: _imageFile!,
            user: widget.user,
            onLogout: widget.onLogout,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحليل الصورة: $e')),
      );
    }
  }
  void _logout() {
    widget.onLogout?.call();
    Navigator.pushNamedAndRemoveUntil(context, Routes.welcome, (_) => false);
  }

  // ── Styles ────────────────────────────────

  ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
    backgroundColor: Colors.green.shade600,
    foregroundColor: Colors.white,
    minimumSize:     const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  ButtonStyle _outlineStyle({Color border = Colors.green}) =>
      ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: border,
        minimumSize:     const Size(double.infinity, 56),
        side:            BorderSide(color: border, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userName = widget.user?['name'] ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE6F4EA), Color(0xFFD1FAE5), Color(0xFFCCFBF1)],
              begin:  Alignment.topLeft,
              end:    Alignment.bottomRight,
            ),
          ),
          child: !_modelLoaded
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Header ─────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:      const Icon(Icons.arrow_back, color: Colors.green),
                      onPressed: () => Navigator.pushNamed(context, Routes.farmerHome),
                    ),
                    const Text(
                      'كشف الأمراض',
                      style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.bold,
                        color:      Color(0xFF14532D),
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                    IconButton(
                      icon:      const Icon(Icons.logout, color: Colors.red),
                      onPressed: _logout,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Welcome ────────────────
                if (userName.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'مرحبًا، $userName',
                      style: const TextStyle(
                        fontSize:   16,
                        color:      Color(0xFF166534),
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // ── Image preview ──────────
                _imageFile != null
                    ? Card(
                  elevation: 4,
                  shape:     RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _imageFile!,
                      height: 300,
                      width:  double.infinity,
                      fit:    BoxFit.cover,
                    ),
                  ),
                )
                    : Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: Colors.green.shade300,
                        width: 2,
                        style: BorderStyle.solid),
                  ),
                  child: Container(
                    height:    220,
                    alignment: Alignment.center,
                    padding:   const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:        Colors.green.shade100,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 48, color: Colors.green),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد صورة محددة',
                          style: TextStyle(
                            fontSize:   18,
                            fontWeight: FontWeight.bold,
                            color:      Color(0xFF14532D),
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'قم بالتقاط صورة أو رفعها لنباتك',
                          style: TextStyle(
                            fontSize:   14,
                            color:      Color(0xFF166534),
                            fontFamily: 'NotoSansArabic',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Buttons ────────────────
                if (_imageFile == null) ...[
                  ElevatedButton.icon(
                    icon:      const Icon(Icons.camera_alt),
                    label:     const Text('التقاط صورة',
                        style: TextStyle(fontSize: 16)),
                    onPressed: () => _pickImage(ImageSource.camera),
                    style:     _primaryStyle(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon:      const Icon(Icons.photo_library),
                    label:     const Text('رفع صورة',
                        style: TextStyle(fontSize: 16)),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style:     _outlineStyle(),
                  ),
                ],

                if (_imageFile != null) ...[
                  ElevatedButton(
                    onPressed: !_loading ? _analyzeImage : null,
                    style:     _primaryStyle(),
                    child: _loading
                        ? const SizedBox(
                      height: 24,
                      width:  24,
                      child:  CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                    )
                        : const Text('تحليل الصورة',
                        style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _imageFile = null),
                    style:     _outlineStyle(border: Colors.red),
                    child: const Text('مسح الصورة',
                        style: TextStyle(fontSize: 16, color: Colors.red)),
                  ),
                ],

                // ── Loading hint ───────────
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Card(
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: Colors.blue.shade200, width: 1),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child:   Text(
                          'يتم الآن تحليل صورة النبات... قد يستغرق الأمر بضع ثوانٍ',
                          style: TextStyle(
                            fontSize:   14,
                            color:      Color(0xFF1E3A8A),
                            fontFamily: 'NotoSansArabic',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

