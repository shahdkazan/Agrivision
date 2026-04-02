import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';


class WeatherRiskService {

  Future<Position> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    const apiKey = '120924b4ae3a7f1eb71378673c4ff7ec';

    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather');
    }
  }

  Future<Map<String, dynamic>> getWeatherFromCurrentLocation() async {
    final position = await getLocation();
    return await fetchWeather(position.latitude, position.longitude);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return (value is int) ? value.toDouble() : value.toDouble();
  }
  /// =========================
  /// 🌱 Risk Analysis (Arabic)
  /// =========================
  Map<String, dynamic> analyzeRisk(Map<String, dynamic> data) {
    final temp = _toDouble(data['main']['temp']);
    final humidity = _toDouble(data['main']['humidity']);
    final windSpeed = _toDouble(data['wind']?['speed']);
    final rain = _toDouble(data['rain']?['1h']);

    double fungal = _fungalRisk(temp, humidity, rain);
    double bacterial = _bacterialRisk(temp, humidity, rain);
    double pest = _pestRisk(temp, humidity, windSpeed);

    return {
      "الفطريات": _formatRiskArabic("الفطريات", fungal),
      "البكتيريا": _formatRiskArabic("البكتيريا", bacterial),
      "الآفات": _formatRiskArabic("الآفات", pest),
      "الخلاصة": _overallRiskArabic(fungal, bacterial, pest),
    };
  }

  /// =========================
  /// 🔬 Risk Calculations
  /// =========================

  double _fungalRisk(double temp, double humidity, double rain) {
    double score = 0;

    if (humidity > 85)
      score += 40;
    else if (humidity > 70) score += 25;

    if (temp >= 18 && temp <= 30) score += 30;

    if (rain > 0) score += 30;

    return score.clamp(0, 100);
  }

  double _bacterialRisk(double temp, double humidity, double rain) {
    double score = 0;

    if (humidity > 80) score += 35;
    if (temp > 20 && temp < 35) score += 30;
    if (rain > 0) score += 35;

    return score.clamp(0, 100);
  }

  double _pestRisk(double temp, double humidity, double windSpeed) {
    double score = 0;

    if (temp > 25) score += 30;
    if (humidity > 60) score += 20;
    if (windSpeed < 3) score += 30;

    return score.clamp(0, 100);
  }

  /// =========================
  /// 📊 Arabic Formatting
  /// =========================

  String _formatRiskArabic(String type, double score) {
    if (score >= 70) {
      return "$type: خطر مرتفع ⚠️ ($score%)\nيوصى باتخاذ إجراءات عاجلة.";
    } else if (score >= 40) {
      return "$type: خطر متوسط ⚠️ ($score%)\nيُنصح بالمراقبة.";
    } else {
      return "$type: خطر منخفض ✅ ($score%)\nالوضع مستقر.";
    }
  }

  String _overallRiskArabic(double f, double b, double p) {
    double avg = (f + b + p) / 3;

    if (avg >= 70) {
      return " خطر مرتفع ⚠️\nيُنصح بالتدخل السريع (رش مبيدات / فحص المحصول).";
    } else if (avg >= 40) {
      return " خطر متوسط ⚠️\nيُنصح بالمراقبة اليومية.";
    } else {
      return "لا توجد تهديدات حالية.";
    }
  }
}