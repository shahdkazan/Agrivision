
import 'package:flutter/material.dart';
import '../routes.dart';

class LoginSelectionPage extends StatefulWidget {
  const LoginSelectionPage({super.key});

  @override
  State<LoginSelectionPage> createState() => _LoginSelectionPageState();
}

class _LoginSelectionPageState extends State<LoginSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _moveAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _moveAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color borderColor,
    required VoidCallback onTap,
    required double width, // pass width to make it consistent
  }) {
    return SlideTransition(
      position: _moveAnimation,
      child: FadeTransition(
        opacity: _fadeInAnimation,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width, // consistent width
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: iconColor),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: iconColor.withOpacity(0.7),
                      fontFamily: 'NotoSansArabic',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.85; // 85% of screen width

    return Directionality(
      textDirection: TextDirection.rtl, // Force RTL
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF166534)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14532D),
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 60), // more space for visual balance
              // Selection Cards
              buildCard(
                icon: Icons.person,
                iconBg: Colors.green[100]!,
                iconColor: Colors.green[700]!,
                title: 'مزارع',
                subtitle: '',
                borderColor: Colors.green[200]!,
                width: cardWidth,
                onTap: () {
                  Navigator.pushNamed(context, Routes.farmerLogin);
                },
              ),
              const SizedBox(height: 24),
              buildCard(
                icon: Icons.group,
                iconBg: Colors.green[100]!,
                iconColor: Colors.green[700]!,
                title: 'موظف / الإدارة',
                subtitle: '',
                borderColor: Colors.green[300]!,
                width: cardWidth,
                onTap: () {
                  Navigator.pushNamed(context, Routes.otherUserLogin);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}