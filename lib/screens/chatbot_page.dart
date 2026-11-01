

// import 'package:flutter/material.dart';
// import '../routes.dart';
// import '../services/chatbot_service.dart'; // import your ChatbotService
//
// class ChatbotPage extends StatefulWidget {
//   final String diseaseName;
//
//   const ChatbotPage({super.key, required this.diseaseName});
//
//   @override
//   _ChatbotPageState createState() => _ChatbotPageState();
// }
//
// class _ChatbotPageState extends State<ChatbotPage> {
//   late String diseaseName;
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
//     diseaseName = args?['diseaseName'] ?? widget.diseaseName;
//   }
//
//   List<Map<String, dynamic>> messages = [];
//   final ChatbotService _chatbotService = ChatbotService();
//
//
//   void sendUserMessage(String intent) async {
//     setState(() {
//       messages.add({'text': intent, 'isUser': true});
//     });
//
//     String response =
//     await _chatbotService.getChatbotResponse(diseaseName, intent);
//
//     setState(() {
//       messages.add({'text': response, 'isUser': false});
//     });
//   }
//   Widget buildOptionButton(String text) {
//     return ElevatedButton(
//       onPressed: () => sendUserMessage(text),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green[700],
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//       ),
//       child: Text(text, style: const TextStyle(color: Colors.white)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('المساعد الزراعي'),
//           backgroundColor: Colors.green[700],
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: messages.length,
//                 itemBuilder: (context, index) {
//                   return ChatBubble(
//                     text: messages[index]['text'],
//                     isUser: messages[index]['isUser'],
//                   );
//                 },
//               ),
//             ),
//
//             // Intent / Info Buttons
//             Padding(
//               padding: const EdgeInsets.all(8),
//               child: Wrap(
//                 spacing: 8,
//                 children: [
//                   buildOptionButton('التوصيات'),
//                   buildOptionButton('الوصف'),
//                   buildOptionButton('الأعراض'),
//                   buildOptionButton('مراكز الدعم'),
//                 ],
//               ),
//             ),
//
//             // Back to Home
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, Routes.farmerHome);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green[700],
//                   minimumSize: const Size(double.infinity, 56),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: const Text(
//                   'العودة للرئيسية',
//                   style: TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ChatBubble extends StatelessWidget {
//   final String text;
//   final bool isUser;
//
//   const ChatBubble({required this.text, required this.isUser});
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isUser ? Colors.green[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Text(text),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import '../routes.dart';
// import '../services/chatbot_service.dart';
// import '../services/tts_service.dart';
//
// class ChatbotPage extends StatefulWidget {
//   final String diseaseName;
//
//   const ChatbotPage({super.key, required this.diseaseName});
//
//   @override
//   State<ChatbotPage> createState() => _ChatbotPageState();
// }
//
// class _ChatbotPageState extends State<ChatbotPage> {
//   late String diseaseName;
//
//   final ChatbotService _chatbotService = ChatbotService();
//   final TtsService _ttsService = TtsService();
//
//   List<Map<String, dynamic>> messages = [];
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//
//     diseaseName = args?['diseaseName'] ?? widget.diseaseName;
//   }
//
//   void sendUserMessage(String intent) async {
//     setState(() {
//       messages.add({
//         'text': intent,
//         'isUser': true,
//       });
//     });
//
//     final response =
//     await _chatbotService.getChatbotResponse(diseaseName, intent);
//
//     setState(() {
//       messages.add({
//         'text': response,
//         'isUser': false,
//       });
//     });
//   }
//
//   Widget buildOptionButton(String text) {
//     return ElevatedButton(
//       onPressed: () => sendUserMessage(text),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green[700],
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//       ),
//       child: Text(text, style: const TextStyle(color: Colors.white)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('المساعد الزراعي'),
//           backgroundColor: Colors.green,
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: messages.length,
//                 itemBuilder: (context, index) {
//                   final msg = messages[index];
//
//                   return ChatBubble(
//                     text: msg['text'],
//                     isUser: msg['isUser'],
//                     onSpeak: msg['isUser']
//                         ? null
//                         : () => _ttsService.speak(msg['text']),
//                   );
//                 },
//               ),
//             ),
//
//             // Options
//             Padding(
//               padding: const EdgeInsets.all(8),
//               child: Wrap(
//                 spacing: 8,
//                 children: [
//                   buildOptionButton('التوصيات'),
//                   buildOptionButton('الوصف'),
//                   buildOptionButton('الأعراض'),
//                   buildOptionButton('مراكز الدعم'),
//                 ],
//               ),
//             ),
//
//             // Home button
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, Routes.farmerHome);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   minimumSize: const Size(double.infinity, 56),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: const Text(
//                   'العودة للرئيسية',
//                   style: TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ChatBubble extends StatelessWidget {
//   final String text;
//   final bool isUser;
//   final VoidCallback? onSpeak;
//
//   const ChatBubble({
//     super.key,
//     required this.text,
//     required this.isUser,
//     this.onSpeak,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isUser ? Colors.green[100] : Colors.grey[200],
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: isUser
//             ? Text(text)
//             : Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(child: Text(text)),
//             IconButton(
//               icon: const Icon(Icons.volume_up, size: 20),
//               onPressed: onSpeak,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/chatbot_service.dart';
import '../services/tts_service.dart';

class ChatbotPage extends StatefulWidget {
  final String diseaseName;

  const ChatbotPage({super.key, required this.diseaseName});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late String diseaseName;

  final ChatbotService _chatbotService = ChatbotService();

  // IMPORTANT FIX: declare only
  late final TtsService _ttsService;

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();

    // IMPORTANT FIX: initialize once
    _ttsService = TtsService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments
    as Map<String, dynamic>?;

    diseaseName = args?['diseaseName'] ?? widget.diseaseName;
  }

  void sendUserMessage(String intent) async {
    setState(() {
      messages.add({
        'text': intent,
        'isUser': true,
      });
    });

    final response =
    await _chatbotService.getChatbotResponse(diseaseName, intent);

    setState(() {
      messages.add({
        'text': response,
        'isUser': false,
      });
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
          backgroundColor: Colors.green,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];

                  return ChatBubble(
                    text: msg['text'],
                    isUser: msg['isUser'],
                    onSpeak: msg['isUser']
                        ? null
                        : () async {
                      await _ttsService.speak(msg['text']);
                    },
                  );
                },
              ),
            ),

            // Options
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

            // Home button
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.farmerHome);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
  final VoidCallback? onSpeak;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.onSpeak,
  });

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
        child: isUser
            ? Text(text)
            : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(text)),
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20),
              onPressed: onSpeak,
            ),
          ],
        ),
      ),
    );
  }
}