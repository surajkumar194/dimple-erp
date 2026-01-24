import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QualityInspectionScreen extends StatefulWidget {
  const QualityInspectionScreen({super.key});

  @override
  State<QualityInspectionScreen> createState() => _QualityInspectionScreenState();
}

class _QualityInspectionScreenState extends State<QualityInspectionScreen> {
  Future<void> _showAddInspectionDialog() async {
    final productController = TextEditingController();
    final batchController = TextEditingController();
    final inspectorController = TextEditingController();
    final remarksController = TextEditingController();
    String result = 'Pass';

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Quality Inspection'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: productController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: batchController,
                      decoration: const InputDecoration(
                        labelText: 'Batch Number',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: inspectorController,
                      decoration: const InputDecoration(
                        labelText: 'Inspector Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: result,
                      decoration: const InputDecoration(
                        labelText: 'Inspection Result',
                        prefixIcon: Icon(Icons.check_circle),
                      ),
                      items: const ['Pass', 'Fail', 'Conditional Pass']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => result = value ?? 'Pass'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await FirebaseFirestore.instance
                        .collection('qualityInspections')
                        .add({
                      'product': productController.text.trim(),
                      'batchNumber': batchController.text.trim(),
                      'inspector': inspectorController.text.trim(),
                      'result': result,
                      'remarks': remarksController.text.trim(),
                      'inspectionDate': FieldValue.serverTimestamp(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inspection recorded')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Inspection'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('qualityInspections')
            .orderBy('inspectionDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No inspections', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>? ?? {};
              final product = (data['product'] as String?)?.trim();
              final batchNumber = (data['batchNumber'] as String?)?.trim();
              final inspector = (data['inspector'] as String?)?.trim();
              final remarks = (data['remarks'] as String?)?.trim();
              final result = (data['result'] as String?)?.trim() ?? 'Pass';
              final ts = data['inspectionDate'] is Timestamp ? data['inspectionDate'] as Timestamp? : null;

              final Color resultColor = switch (result) {
                'Pass' => Colors.green,
                'Fail' => Colors.red,
                'Conditional Pass' => Colors.orange,
                _ => Colors.blueGrey,
              };

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: resultColor,
                    child: Icon(
                      result == 'Pass' ? Icons.check : Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    product?.isNotEmpty == true ? product! : 'Unnamed Product',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Batch: ${batchNumber?.isNotEmpty == true ? batchNumber : '-'}'),
                  trailing: Chip(
                    label: Text(result, style: const TextStyle(fontSize: 10)),
                    backgroundColor: resultColor.withOpacity(0.2),
                    labelStyle: TextStyle(color: resultColor, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Inspector', inspector?.isNotEmpty == true ? inspector! : '-'),
                          _buildDetailRow('Date', _formatTimestamp(ts)),
                          if (remarks != null && remarks.isNotEmpty)
                            _buildDetailRow('Remarks', remarks),
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
        onPressed: _showAddInspectionDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
        backgroundColor: const Color(0xFF9C27B0),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
