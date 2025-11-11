import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TestReportsScreen extends StatefulWidget {
  const TestReportsScreen({super.key});

  @override
  State<TestReportsScreen> createState() => _TestReportsScreenState();
}

class _TestReportsScreenState extends State<TestReportsScreen> {
  void _showTestReportDialog() {
    final productController = TextEditingController();
    final batchController = TextEditingController();
    final testTypeController = TextEditingController();
    final resultController = TextEditingController();
    String status = 'Pass';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Test Report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: productController,
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: batchController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Number',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: testTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Test Type',
                    prefixIcon: Icon(Icons.science),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: resultController,
                  decoration: const InputDecoration(
                    labelText: 'Test Results',
                    prefixIcon: Icon(Icons.assignment),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.check_circle),
                  ),
                  items: ['Pass', 'Fail', 'Pending']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate input
                if (productController.text.isEmpty ||
                    batchController.text.isEmpty ||
                    testTypeController.text.isEmpty ||
                    resultController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('testReports').add({
                    'product': productController.text,
                    'batchNumber': batchController.text,
                    'testType': testTypeController.text,
                    'results': resultController.text,
                    'status': status,
                    'testDate': FieldValue.serverTimestamp(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test report added')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Reports'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('testReports')
            .orderBy('testDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No test reports',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var report = doc.data() as Map<String, dynamic>;
              String status = report['status'] ?? 'Pending';
              Color statusColor = status == 'Pass'
                  ? Colors.green
                  : status == 'Fail'
                      ? Colors.red
                      : Colors.orange;

              // Safely parse date
              DateTime? testDate;
              if (report['testDate'] != null) {
                if (report['testDate'] is Timestamp) {
                  testDate = (report['testDate'] as Timestamp).toDate();
                } else if (report['testDate'] is DateTime) {
                  testDate = report['testDate'] as DateTime;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Icon(
                      status == 'Pass'
                          ? Icons.check
                          : status == 'Fail'
                              ? Icons.close
                              : Icons.pending,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    report['product'] ?? 'Unknown Product',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${report['testType'] ?? 'N/A'} | Batch: ${report['batchNumber'] ?? 'N/A'}',
                  ),
                  trailing: Chip(
                    label: Text(
                      status,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: statusColor.withOpacity(0.2),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Results:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(report['results'] ?? 'No results available'),
                          const SizedBox(height: 12),
                          if (testDate != null)
                            Text(
                              'Date: ${testDate.day}/${testDate.month}/${testDate.year}',
                            )
                          else
                            const Text('Date: N/A'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTestReportDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Report'),
        backgroundColor: const Color(0xFF9C27B0),
      ),
    );
  }
}