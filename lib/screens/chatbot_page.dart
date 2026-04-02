

import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/chatbot_service.dart'; // import your ChatbotService

class ChatbotPage extends StatefulWidget {
  final String diseaseName;

  const ChatbotPage({super.key, required this.diseaseName});

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late String diseaseName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    diseaseName = args?['diseaseName'] ?? widget.diseaseName;
  }

  List<Map<String, dynamic>> messages = [];
  final ChatbotService _chatbotService = ChatbotService();


  void sendUserMessage(String intent) async {
    setState(() {
      messages.add({'text': intent, 'isUser': true});
    });

    String response =
    await _chatbotService.getChatbotResponse(diseaseName, intent);

    setState(() {
      messages.add({'text': response, 'isUser': false});
    });
  }
  Widget buildOptionButton(String text) {
    return ElevatedButton(
      onPressed: () => sendUserMessage(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المساعد الزراعي'),
          backgroundColor: Colors.green[700],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ChatBubble(
                    text: messages[index]['text'],
                    isUser: messages[index]['isUser'],
                  );
                },
              ),
            ),

            // Intent / Info Buttons
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  buildOptionButton('التوصيات'),
                  buildOptionButton('الوصف'),
                  buildOptionButton('الأعراض'),
                  buildOptionButton('مراكز الدعم'),
                ],
              ),
            ),

            // Back to Home
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.farmerHome);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'العودة للرئيسية',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text),
      ),
    );
  }
}