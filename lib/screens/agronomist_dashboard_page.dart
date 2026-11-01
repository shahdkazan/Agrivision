

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/auth_service.dart';

class AgronomistDashboardPage extends StatefulWidget {
  final String userName;
  // final VoidCallback onLogout;

  const AgronomistDashboardPage({
    required this.userName,
    // required this.onLogout,
    super.key,
  });

  @override
  _AgronomistDashboardPageState createState() =>
      _AgronomistDashboardPageState();
}

class _AgronomistDashboardPageState extends State<AgronomistDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final CollectionReference imagesCollection =
  FirebaseFirestore.instance.collection('img1');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void handleLogout() async {
    AuthService authService = AuthService();
    await authService.logout(); // Firebase logout

    Navigator.pushReplacementNamed(context, Routes.loginSelection);
  }

  Future<void> handleVerifyImage(String docId, String newStatus) async {
    await imagesCollection.doc(docId).update({
      'labelValidatedByAgronomist': newStatus,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus == 'accept'
            ? 'تم التحقق من الصورة'
            : newStatus == 'reject'
            ? 'تم رفض الصورة'
            : 'قيد المراجعة'),
      ),
    );
    setState(() {}); // Refresh UI
  }

  // Convert English status to Arabic for display
  String statusArabic(String status) {
    switch (status) {
      case 'accept':
        return 'تم التحقق';
      case 'reject':
        return 'مرفوض';
      case 'not_checked':
      default:
        return 'قيد المراجعة';
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
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: handleLogout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'لوحة تحكم المهندس الزراعي',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          Text('مرحباً، ${widget.userName}',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.green[900],
                  unselectedLabelColor: Colors.green[700],
                  indicatorColor: Colors.green[700],
                  tabs: const [
                    Tab(text: 'مراجعة الصور'),
                    Tab(text: 'التوصيات'),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Image Review
                      StreamBuilder<QuerySnapshot>(
                        stream: imagesCollection
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final images = snapshot.data!.docs;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Card(
                              elevation: 8,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('المعرف')),
                                    DataColumn(label: Text('الصورة')),
                                    DataColumn(
                                        label: Text('توقع الذكاء الاصطناعي')),
                                    DataColumn(label: Text('الحالة')),
                                    DataColumn(label: Text('إجراءات')),
                                  ],
                                  rows: images.map((doc) {
                                    final data =
                                    doc.data() as Map<String, dynamic>;
                                    Uint8List imageBytes = base64Decode(
                                        data['imageBase64'] as String);
                                    String status =
                                    data['labelValidatedByAgronomist'];

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(doc.id)),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.image,
                                                color: Colors.green),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  child: Image.memory(
                                                      imageBytes),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        DataCell(
                                            Text(data['diagnosisResult'])),
                                        DataCell(Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status == 'accept'
                                                ? Colors.green[100]
                                                : status == 'reject'
                                                ? Colors.red[100]
                                                : Colors.yellow[100],
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: Text(statusArabic(status)),
                                        )),
                                        DataCell(Row(
                                          children: status == 'not_checked'
                                              ? [
                                            IconButton(
                                              onPressed: () =>
                                                  handleVerifyImage(
                                                      doc.id, 'accept'),
                                              icon: const Icon(Icons.check,
                                                  color: Colors.green),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  handleVerifyImage(
                                                      doc.id, 'reject'),
                                              icon: const Icon(Icons.close,
                                                  color: Colors.red),
                                            ),
                                          ]
                                              : [],
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Recommendations (keep hardcoded or fetch from Firestore if you have)
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Card(
                              elevation: 6,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: const [
                                    Text(
                                      'Leaf Blight',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'قم بإزالة الأوراق المصابة واستخدم مبيداً فطرياً مناسباً',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}