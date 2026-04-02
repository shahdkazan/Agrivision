
import 'package:flutter/material.dart';
import '../routes.dart';

class FarmerSignUpPage extends StatefulWidget {
  const FarmerSignUpPage({super.key});

  @override
  State<FarmerSignUpPage> createState() => _FarmerSignUpPageState();
}

class _FarmerSignUpPageState extends State<FarmerSignUpPage>
    with SingleTickerProviderStateMixin {
  String step = 'details';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void handleSendOTP() {
    if (nameController.text.isEmpty || phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء جميع الحقول بشكل صحيح', style: TextStyle(fontFamily: 'NotoSansArabic'))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال رمز التحقق بنجاح!', style: TextStyle(fontFamily: 'NotoSansArabic'))),
    );

    setState(() {
      step = 'otp';
    });
  }

  void handleVerifyOTP() {
    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز التحقق كامل', style: TextStyle(fontFamily: 'NotoSansArabic'))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إنشاء الحساب بنجاح!', style: TextStyle(fontFamily: 'NotoSansArabic'))),
    );

    Navigator.pushNamed(context, Routes.farmerHome);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Force RTL for the page
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
                        setState(() => step = 'details');
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Text(
                    'تسجيل حساب المزارع',
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
                        child: step == 'details' ? _buildDetailsStep() : _buildOTPStep(),
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

  Widget _buildDetailsStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 32, color: Colors.green),
        ),
        const SizedBox(height: 16),
        const Text(
          'إنشاء حساب',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14532D),
              fontFamily: 'NotoSansArabic'),
        ),
        const SizedBox(height: 8),
        const Text(
          'أدخل بياناتك للمتابعة',
          style: TextStyle(color: Color(0xFF166534), fontFamily: 'NotoSansArabic'),
        ),
        const SizedBox(height: 24),
        // Name field adaptive LTR/RTL
        LayoutBuilder(builder: (context, constraints) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'الاسم الكامل',
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              maxLines: 1,
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
          );
        }),
        const SizedBox(height: 16),
        // Phone field LTR
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'رقم الهاتف',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: handleSendOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Center(
              child: Text('متابعة', style: TextStyle(fontSize: 18,color:Colors.white,fontFamily: 'NotoSansArabic'))),
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
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
          'تأكيد الهاتف',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14532D),
              fontFamily: 'NotoSansArabic'),
        ),
        const SizedBox(height: 8),
        Text("تم الإرسال إلى ${phoneController.text}",
            style: const TextStyle(color: Color(0xFF166534), fontFamily: 'NotoSansArabic')),
        const SizedBox(height: 24),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'أدخل رمز التحقق',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: handleVerifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Center(
              child: Text('إنشاء الحساب', style: TextStyle(fontSize: 18, fontFamily: 'NotoSansArabic', color: Colors.white))),
        ),
      ],
    );
  }
}