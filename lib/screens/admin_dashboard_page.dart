
import 'package:flutter/material.dart';
import '../routes.dart';

class AdminDashboardPage extends StatefulWidget {
  final String userName;
  final VoidCallback onLogout;

  const AdminDashboardPage({required this.userName, required this.onLogout, super.key});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with TickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, String>> users = [
    {'id': '1', 'name': 'John Agronomist', 'email': 'john@agri.com', 'role': 'agronomist'},
    {'id': '2', 'name': 'Sarah Support', 'email': 'sarah@agri.com', 'role': 'support'},
    {'id': '3', 'name': 'Mike Admin', 'email': 'mike@agri.com', 'role': 'admin'},
  ];

  List<Map<String, String>> pendingImages = [
    {'id': '1', 'userId': 'farmer_123', 'disease': 'Leaf Blight', 'uploadDate': '2024-12-19', 'status': 'pending'},
    {'id': '2', 'userId': 'farmer_456', 'disease': 'Rust', 'uploadDate': '2024-12-18', 'status': 'pending'},
    {'id': '3', 'userId': 'farmer_789', 'disease': 'Powdery Mildew', 'uploadDate': '2024-12-17', 'status': 'pending'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void handleDeleteUser(String id) {
    setState(() {
      users.removeWhere((u) => u['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User deleted successfully')),
    );
  }

  void handleApproveImage(String id) {
    setState(() {
      pendingImages.removeWhere((img) => img['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image approved and added to dataset')),
    );
  }

  void handleRejectImage(String id) {
    setState(() {
      pendingImages.removeWhere((img) => img['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image rejected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        Text('Welcome, ${widget.userName}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        widget.onLogout();
                        Navigator.pushReplacementNamed(context, Routes.loginSelection);
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
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
                  Tab(text: 'Manage Users'),
                  Tab(text: 'Approve Images'),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Users Management
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                          child: Card(
                            elevation: 8,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Role')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: users.map((u) {
                                return DataRow(cells: [
                                  DataCell(Text(u['name']!)),
                                  DataCell(Text(u['email']!)),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.green),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(u['role']!, style: const TextStyle(color: Colors.green)),
                                  )),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Edit user feature')),
                                        ),
                                        icon: const Icon(Icons.edit),
                                      ),
                                      IconButton(
                                        onPressed: () => handleDeleteUser(u['id']!),
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Pending Images
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                          child: Card(
                            elevation: 8,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('User ID')),
                                DataColumn(label: Text('Disease')),
                                DataColumn(label: Text('Upload Date')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: pendingImages.map((img) {
                                return DataRow(cells: [
                                  DataCell(Text(img['userId']!)),
                                  DataCell(Text(img['disease']!)),
                                  DataCell(Text(img['uploadDate']!)),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(img['status']!, style: const TextStyle(color: Colors.orange)),
                                  )),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => handleApproveImage(img['id']!),
                                        icon: const Icon(Icons.check, color: Colors.green),
                                      ),
                                      IconButton(
                                        onPressed: () => handleRejectImage(img['id']!),
                                        icon: const Icon(Icons.close, color: Colors.red),
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}