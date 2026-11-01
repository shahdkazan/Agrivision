import 'package:flutter/material.dart';
import '../routes.dart';

class SupportStaffDashboardPage extends StatefulWidget {
  final String userName;
  final VoidCallback onLogout;

  const SupportStaffDashboardPage({
    required this.userName,
    required this.onLogout,
    super.key,
  });

  @override
  _SupportStaffDashboardPageState createState() =>
      _SupportStaffDashboardPageState();
}

class _SupportStaffDashboardPageState
    extends State<SupportStaffDashboardPage> {
  // Typed initialization to avoid dynamic
  List<Map<String, String>> supports = <Map<String, String>>[
    <String, String>{
      'id': '1',
      'name': 'Green Valley Suppliers',
      'type': 'supplier',
      'phone': '+1234567890',
      'location': 'Downtown',
      'address': '123 Main St',
    },
    <String, String>{
      'id': '2',
      'name': 'AgriCare Support Center',
      'type': 'support-center',
      'phone': '+0987654321',
      'location': 'North District',
      'address': '456 Farm Road',
    },
  ];

  Map<String, String> formData = {
    'name': '',
    'type': 'supplier',
    'phone': '',
    'location': '',
    'address': ''
  };

  String? editingId;

  void handleLogout() {
    widget.onLogout();
    Navigator.pushReplacementNamed(context, Routes.loginSelection);
  }

  void openAddEditDialog({Map<String, String>? support}) {
    if (support != null) {
      formData = Map<String, String>.from(support);
      editingId = support['id'];
    } else {
      formData = {
        'name': '',
        'type': 'supplier',
        'phone': '',
        'location': '',
        'address': ''
      };
      editingId = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
        Text(editingId != null ? 'Edit Support Entry' : 'Add New Support Entry'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                controller: TextEditingController(text: formData['name']),
                onChanged: (val) => formData['name'] = val,
              ),
              DropdownButtonFormField<String>(
                initialValue: formData['type'], // <-- use this instead of `value`
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
                  DropdownMenuItem(value: 'support-center', child: Text('Support Center')),
                ],
                onChanged: (val) => formData['type'] = val!,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Phone'),
                controller: TextEditingController(text: formData['phone']),
                onChanged: (val) => formData['phone'] = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Location'),
                controller: TextEditingController(text: formData['location']),
                onChanged: (val) => formData['location'] = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Address'),
                controller: TextEditingController(text: formData['address']),
                onChanged: (val) => formData['address'] = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formData.values.any((v) => v.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')));
                return;
              }

              if (editingId != null) {
                setState(() {
                  supports = supports.map((s) {
                    if (s['id'] == editingId) {
                      return Map<String, String>.from(formData)
                        ..['id'] = editingId!;
                    }
                    return s;
                  }).toList();
                });
              } else {
                setState(() {
                  supports.add(Map<String, String>.from(formData)
                    ..['id'] = DateTime.now().millisecondsSinceEpoch.toString());
                });
              }

              Navigator.pop(context);
            },
            child: Text(editingId != null ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void handleDelete(String id) {
    setState(() => supports.removeWhere((s) => s['id'] == id));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Support entry deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F4EA), Color(0xFFB7E4C7), Color(0xFF8ED0B1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support Staff Dashboard',
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text('Welcome, ${widget.userName}',
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
                IconButton(
                  onPressed: handleLogout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Add button
            //make buttnntext white
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => openAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add New', style: TextStyle(fontSize: 18, color: Colors.white)),

                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              ),
            ),

            const SizedBox(height: 16),

            // Data table
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Location')),
                      DataColumn(label: Text('Address')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: supports.map((s) {
                      return DataRow(cells: [
                        DataCell(Text(s['name']!)),
                        DataCell(Text(s['type']!.replaceAll('-', ' '))),
                        DataCell(Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(s['phone']!),
                          ],
                        )),
                        DataCell(Text(s['location']!)),
                        DataCell(Text(s['address']!)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => openAddEditDialog(support: s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => handleDelete(s['id']!),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}