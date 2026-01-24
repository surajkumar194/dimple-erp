import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DefectTrackingScreen extends StatefulWidget {
  const DefectTrackingScreen({super.key});

  @override
  State<DefectTrackingScreen> createState() => _DefectTrackingScreenState();
}

class _DefectTrackingScreenState extends State<DefectTrackingScreen> {
  void _showDefectDialog() {
    final productController = TextEditingController();
    final batchController = TextEditingController();
    final defectController = TextEditingController();
    final quantityController = TextEditingController();
    String severity = 'Medium';
    String action = 'Rework';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report Defect'),
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
                  controller: defectController,
                  decoration: const InputDecoration(
                    labelText: 'Defect Description',
                    prefixIcon: Icon(Icons.bug_report),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    prefixIcon: Icon(Icons.warning),
                  ),
                  items: ['Low', 'Medium', 'High', 'Critical']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => severity = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: action,
                  decoration: const InputDecoration(
                    labelText: 'Action Taken',
                    prefixIcon: Icon(Icons.build),
                  ),
                  items: ['Rework', 'Scrap', 'Sort', 'Hold']
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => action = value!),
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
                    defectController.text.isEmpty ||
                    quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                  return;
                }

                final quantity = int.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('defects').add({
                    'product': productController.text,
                    'batchNumber': batchController.text,
                    'defectDescription': defectController.text,
                    'quantity': quantity,
                    'severity': severity,
                    'action': action,
                    'status': 'Open',
                    'reportedDate': FieldValue.serverTimestamp(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Defect reported')),
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
              child: const Text('Report'),
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
        title: const Text('Defect Tracking'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('defects')
            .orderBy('reportedDate', descending: true)
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
                'No defects reported',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var defect = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              String severity = defect['severity'] ?? 'Medium';
              String status = defect['status'] ?? 'Open';
              
              Color severityColor = severity == 'Critical'
                  ? Colors.red
                  : severity == 'High'
                      ? Colors.orange
                      : severity == 'Medium'
                          ? Colors.yellow[700]!
                          : Colors.green;

              // Safely parse date
              DateTime? reportedDate;
              if (defect['reportedDate'] != null) {
                if (defect['reportedDate'] is Timestamp) {
                  reportedDate = (defect['reportedDate'] as Timestamp).toDate();
                } else if (defect['reportedDate'] is DateTime) {
                  reportedDate = defect['reportedDate'] as DateTime;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: severityColor,
                    child: const Icon(Icons.bug_report, color: Colors.white),
                  ),
                  title: Text(
                    defect['product'] ?? 'Unknown Product',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Batch: ${defect['batchNumber'] ?? 'N/A'}'),
                  trailing: Chip(
                    label: Text(
                      severity,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: severityColor.withOpacity(0.2),
                    labelStyle: TextStyle(color: severityColor),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Defect: ${defect['defectDescription'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('Quantity: ${defect['quantity'] ?? 0}'),
                          const SizedBox(height: 8),
                          Text('Action: ${defect['action'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('Status: $status'),
                          if (reportedDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Reported: ${reportedDate.day}/${reportedDate.month}/${reportedDate.year}',
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (status == 'Open')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('defects')
                                        .doc(docId)
                                        .update({'status': 'Resolved'});
                                    
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Defect marked as resolved'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Mark Resolved'),
                              ),
                            ),
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
        onPressed: _showDefectDialog,
        icon: const Icon(Icons.add),
        label: const Text('Report Defect'),
        backgroundColor: const Color(0xFF9C27B0),
      ),
    );
  }
}