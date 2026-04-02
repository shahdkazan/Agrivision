
import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/auth_service.dart';

class FarmerLoginPage extends StatefulWidget {
  const FarmerLoginPage({super.key});

  @override
  State<FarmerLoginPage> createState() => _FarmerLoginPageState();
}

class _FarmerLoginPageState extends State<FarmerLoginPage>
    with SingleTickerProviderStateMixin {
  String step = 'phone';
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void handleSendOTP() async {
    String rawPhone = phoneController.text.trim();

    // Egypt phone numbers should be 11 digits (e.g., 01XXXXXXXXX)
    if (rawPhone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير صحيح')),
      );
      return;
    }

    String phone = "+20${rawPhone.substring(1)}"; // Convert 01xxxxxxxxx → +201xxxxxxxxx

    setState(() => isLoading = true);

    try {
      await _authService.sendOTP(phone);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رمز التحقق')),
      );

      setState(() {
        step = 'otp';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  void handleVerifyOTP() async {
    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل الرمز كامل')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await _authService.verifyOTP(otpController.text);

      if (user != null) {
        Navigator.pushReplacementNamed(context, Routes.farmerHome);
      }
    } catch (e) {
      print("OTP ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحقق: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  void handleResendOTP() async {
    String rawPhone = phoneController.text.trim();

    if (rawPhone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير صحيح')),
      );
      return;
    }

    String phone = "+20${rawPhone.substring(1)}";

    try {
      await _authService.resendOTP(phone);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة إرسال الرمز')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE6F4EA), Color(0xFFD1FAE5), Color(0xFFCCFBF1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF166534)),
                    onPressed: () {
                      if (step == 'otp') {
                        setState(() => step = 'phone');
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Text(
                    'تسجيل دخول المزارع',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14532D),
                        fontFamily: 'NotoSansArabic'),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 5))
                          ],
                        ),
                        child: step == 'phone'
                            ? _buildPhoneStep()
                            : _buildOTPStep(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone, size: 32, color: Colors.green),
        ),
        const SizedBox(height: 16),
        const Text(
          'أدخل رقم الهاتف',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14532D),
              fontFamily: 'NotoSansArabic'),
        ),
        const SizedBox(height: 24),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '01XXXXXXXXX',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isLoading ? null : handleSendOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Center(
            child: Text('إرسال رمز التحقق',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'NotoSansArabic')),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'أدخل رمز التحقق',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14532D),
              fontFamily: 'NotoSansArabic'),
        ),
        const SizedBox(height: 24),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '******',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isLoading ? null : handleVerifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Center(
            child: Text('تأكيد وتسجيل الدخول',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'NotoSansArabic')),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: handleResendOTP,
          child: const Text(
            'إعادة إرسال رمز التحقق',
            style: TextStyle(
                color: Color(0xFF166534), fontFamily: 'NotoSansArabic'),
          ),
        ),
      ],
    );
  }
}