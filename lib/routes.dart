
import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';
import 'screens/login_selection_page.dart';
import 'screens/farmer_login_page.dart';
import 'screens/farmer_signup_page.dart';
import 'screens/farmer_home_page.dart';
import 'screens/disease_detection_page.dart';
import 'screens/other_user_login_page.dart';

import 'screens/chatbot_page.dart';
import 'screens/admin_dashboard_page.dart';
import 'screens/agronomist_dashboard_page.dart';
import 'screens/support_dashboard_page.dart';


class Routes {
  static const String welcome = '/';
  static const String loginSelection = '/login-selection';
  static const String farmerLogin = '/farmer-login';
  static const String farmerSignUp = '/farmer-signup';
  static const String farmerHome = '/farmer-home';
  static const String diseaseDetection = '/disease-detection';
  static const String otherUserLogin = '/other-user-login';

  static const String chatbot = '/chatbot';
  static const String adminDashboard = '/admin-dashboard';
  static const String agronomistDashboard = '/agronomist-dashboard';
  static const String supportDashboard = '/support-dashboard';



  static Map<String, WidgetBuilder> getRoutes() {
    return {
      welcome: (context) => WelcomePage(),
      loginSelection: (context) => LoginSelectionPage(),
      farmerLogin: (context) => FarmerLoginPage(),
      farmerSignUp: (context) => FarmerSignUpPage(),
      farmerHome: (context) => FarmerHomePage(),
      diseaseDetection: (context) => DiseaseDetectionPage(),
      otherUserLogin: (context) => OtherUserLoginPage(),


      adminDashboard: (context) => AdminDashboardPage(
        userName: 'Admin User', // you can pass dynamic info later
        onLogout: () {
          Navigator.pushReplacementNamed(context, welcome);
        },
      ),
      agronomistDashboard: (context) => AgronomistDashboardPage(
        userName: 'Agronomist User',

      ),
      supportDashboard: (context) => SupportStaffDashboardPage(
        userName: 'Support User',
        onLogout: () {
          Navigator.pushReplacementNamed(context, welcome);
        },
      ),
    };
  }
}

