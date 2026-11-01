

import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/weather_risk_service.dart';

class FarmerHomePage extends StatefulWidget {
  final Map<String, String>? user;
  final VoidCallback? onLogout;

  const FarmerHomePage({super.key, this.user, this.onLogout});

  @override
  State<FarmerHomePage> createState() => _FarmerHomePageState();
}

class _FarmerHomePageState extends State<FarmerHomePage> {
  final WeatherRiskService _service = WeatherRiskService();

  Map<String, dynamic>? weatherData;
  String risk = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    try {
      final data = await _service.getWeatherFromCurrentLocation();
      final result = _service.analyzeRisk(data);

      setState(() {
        weatherData = data;
        risk = result["الخلاصة"] ?? ""; // ✅ FIXED
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    void handleLogout() {
      widget.onLogout?.call();
      Navigator.pushNamedAndRemoveUntil(
          context, Routes.welcome, (route) => false);
    }

    String userName = widget.user?['name'] ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFE6F4EA),
                Color(0xFFD1FAE5),
                Color(0xFFCCFBF1)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "مرحبًا ،",
                          style: TextStyle(
                              fontSize: 22,
                              color: Color(0xFF14532D),
                              fontFamily: 'NotoSansArabic'),
                        ),
                        if (userName.isNotEmpty)
                          Text(
                            userName,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF166534),
                                fontFamily: 'NotoSansArabic'),
                          ),
                      ],
                    ),
                    IconButton(
                      onPressed: handleLogout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // WEATHER CARD
                if (isLoading)
                  const CircularProgressIndicator()
                else if (weatherData != null)
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF10B981)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("حالة الطقس اليوم",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontFamily: 'NotoSansArabic')),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${weatherData!['main']['temp']}°C",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    weatherData!['weather'][0]
                                    ['description'],
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontFamily: 'NotoSansArabic'),
                                  ),
                                ],
                              ),
                              const Icon(Icons.wb_sunny,
                                  size: 64, color: Colors.white70),
                            ],
                          ),

                          const Divider(
                              color: Colors.white30, height: 32),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.air,
                                      size: 20, color: Colors.white),
                                  const SizedBox(height: 4),
                                  const Text("الرياح",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontFamily: 'NotoSansArabic')),
                                  Text(
                                    "${weatherData!['wind']['speed']} m/s",
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.opacity,
                                      size: 20, color: Colors.white),
                                  const SizedBox(height: 4),
                                  const Text("الرطوبة",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontFamily: 'NotoSansArabic')),
                                  Text(
                                    "${weatherData!['main']['humidity']}%",
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.compress,
                                      size: 20, color: Colors.white),
                                  const SizedBox(height: 4),
                                  const Text("الضغط",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontFamily: 'NotoSansArabic')),
                                  Text(
                                    "${weatherData!['main']['pressure']} hPa",
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // WEATHER ALERT
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "تنبيهات الطقس",
                      style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF14532D),
                          fontFamily: 'NotoSansArabic'),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      color: Colors.amber[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.amber[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.warning,
                                  color: Colors.amber),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                risk.isEmpty
                                    ? "جاري تحليل الطقس..."
                                    : risk,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF78350F),
                                  fontFamily: 'NotoSansArabic',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // DETECTION CARD
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                      context, Routes.diseaseDetection),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF22C55E),
                                Color(0xFF10B981)
                              ]),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          const Text("كشف الأمراض",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF14532D),
                                  fontFamily: 'NotoSansArabic')),
                          const SizedBox(height: 4),
                          const Text(
                            "قم بالتقاط صورة للنبات أو تحميلها لتحديد الأمراض",
                            style: TextStyle(
                                color: Color(0xFF166534),
                                fontFamily: 'NotoSansArabic'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}