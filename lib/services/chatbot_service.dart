

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String apiKey = "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";

  // Step 1: Get disease info from Firestore
  Future<String> getDiseaseInfo(String diseaseName, String intent) async {
    try {
      final doc =
      await _firestore.collection('diseases').doc(diseaseName).get();

      if (!doc.exists) {
        return 'عذرًا، لا توجد معلومات متاحة لهذا المرض.';
      }

      switch (intent) {
        case 'التوصيات':
          return doc.data()?['recommendation'] ?? '';
        case 'الوصف':
          return doc.data()?['description'] ?? '';
        case 'الأعراض':
          return doc.data()?['symptoms'] ?? '';
        case 'مراكز الدعم':
          return doc.data()?['support'] ?? '';
        default:
          return '';
      }
    } catch (e) {
      return 'حدث خطأ أثناء جلب المعلومات';
    }
  }

  // Step 2: Send context to LLM and get Arabic answer
  Future<String> askLLM(String context, String question) async {
    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://yourapp.com",
        "X-Title": "AgriVision"
      },
      body: jsonEncode({
        "model": "meta-llama/llama-3.3-70b-instruct",

        "messages": [
          {
            "role": "system",
            "content":
            "أنت مساعد زراعي. أجب باللغة العربية فقط. استخدم المعلومات التالية فقط للإجابة."
          },
          {
            "role": "user",
            "content":
            "المعلومات: $context \n\n السؤال: $question"
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      return "حدث خطأ في الاتصال بالنموذج";
    }
  }

  // Step 3: Full pipeline
  Future<String> getChatbotResponse(
      String diseaseName, String intent) async {
    String context = await getDiseaseInfo(diseaseName, intent);

    if (context.isEmpty) {
      return "لا توجد معلومات متاحة.";
    }

    String answer = await askLLM(context, intent);
    return answer;
  }
}