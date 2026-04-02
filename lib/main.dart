
import 'package:flutter/material.dart';
import 'routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <- needed
import 'screens/chatbot_page.dart';


import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ⚠️ ONLY for emulator / test numbers
  FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  runApp(AgriVisionApp());
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Initializing…')),
      ),
    );
  }
}
class AgriVisionApp extends StatelessWidget {
  const AgriVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriVision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green.shade700,
          secondary: Colors.green.shade300,
        ),
        fontFamily: 'NotoSansArabic',
        scaffoldBackgroundColor: Colors.grey.shade50,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: Routes.welcome,
      routes: Routes.getRoutes(),
      onGenerateRoute: (settings) {
        if (settings.name == Routes.chatbot) {
          final args = settings.arguments as Map<String, dynamic>?;

          return MaterialPageRoute(
            builder: (context) => ChatbotPage(
              diseaseName: args?['diseaseName'] ?? '',
            ),
          );
        }
        return null;
      },
      // ---- Arabic / Localization Support ----
      locale: const Locale('ar'), // set Arabic
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Optional: Force RTL for Arabic
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}