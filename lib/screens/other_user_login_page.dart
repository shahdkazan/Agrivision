
import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/auth_service.dart';

class OtherUserLoginPage extends StatefulWidget {
  @override
  _OtherUserLoginPageState createState() => _OtherUserLoginPageState();
}

class _OtherUserLoginPageState extends State<OtherUserLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'Admin';

  final roles = ['Admin', 'Agronomist', 'Support Staff'];

  String getRoleArabic(String role) {
    switch (role) {
      case 'Admin':
        return 'مدير النظام';
      case 'Agronomist':
        return 'مهندس زراعي';
      case 'Support Staff':
        return 'موظف دعم';
      default:
        return role;
    }
  }

  void handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    AuthService authService = AuthService();

    String? userRole = await authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (userRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في تسجيل الدخول')),
      );
      return;
    }

    // Check if selected role matches Firestore role
    if (userRole != role) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الدور غير صحيح')),
      );
      return;
    }

    // Navigate based on role
    switch (userRole) {
      case 'Admin':
        Navigator.pushReplacementNamed(context, Routes.adminDashboard);
        break;
      case 'Agronomist':
        Navigator.pushReplacementNamed(context, Routes.agronomistDashboard);
        break;
      case 'Support Staff':
        Navigator.pushReplacementNamed(context, Routes.supportDashboard);
        break;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE6F4EA), Color(0xFFB7E4C7), Color(0xFF8ED0B1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'مرحبًا بعودتك',
                      style: TextStyle(
                          fontSize: 22,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansArabic'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'سجل الدخول للوصول إلى لوحة التحكم',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontFamily: 'NotoSansArabic'),
                    ),
                    const SizedBox(height: 24),

                    // Role Dropdown
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: _inputDecoration('الدور'),
                      items: roles.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(
                            getRoleArabic(r),
                            style:
                            const TextStyle(fontFamily: 'NotoSansArabic'),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          role = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextField(
                      controller: emailController,
                      decoration:
                      _inputDecoration('البريد الإلكتروني', icon: Icons.mail),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration:
                      _inputDecoration('كلمة المرور', icon: Icons.lock),
                    ),
                    const SizedBox(height: 32),

                    // Login button
                    ElevatedButton(
                      onPressed: handleLogin,
                      style: _primaryButtonStyle(),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'NotoSansArabic'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'NotoSansArabic'),
      prefixIcon:
      icon != null ? Icon(icon, color: Colors.green[700]) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.green[700],
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}