import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TechnicalDrawingsScreen extends StatefulWidget {
  const TechnicalDrawingsScreen({super.key});

  @override
  State<TechnicalDrawingsScreen> createState() => _TechnicalDrawingsScreenState();
}

class _TechnicalDrawingsScreenState extends State<TechnicalDrawingsScreen> {
  void _showDrawingDialog() {
    final drawingNoController = TextEditingController();
    final titleController = TextEditingController();
    final productController = TextEditingController();
    final revisionController = TextEditingController();
    final notesController = TextEditingController();
    String status = 'Draft';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Technical Drawing'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: drawingNoController,
                  decoration: const InputDecoration(
                    labelText: 'Drawing Number',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: productController,
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: revisionController,
                  decoration: const InputDecoration(
                    labelText: 'Revision',
                    prefixIcon: Icon(Icons.update),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: ['Draft', 'Review', 'Approved', 'Obsolete']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
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
                if (drawingNoController.text.isEmpty ||
                    titleController.text.isEmpty ||
                    productController.text.isEmpty ||
                    revisionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('technicalDrawings').add({
                    'drawingNumber': drawingNoController.text,
                    'title': titleController.text,
                    'product': productController.text,
                    'revision': revisionController.text,
                    'status': status,
                    'notes': notesController.text,
                    'createdDate': FieldValue.serverTimestamp(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Drawing added')),
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
              child: const Text('Add'),
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
        title: const Text('Technical Drawings'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('technicalDrawings')
            .orderBy('createdDate', descending: true)
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
                'No drawings',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var drawing = doc.data() as Map<String, dynamic>;
              String status = drawing['status'] ?? 'Draft';
              Color statusColor = status == 'Approved'
                  ? Colors.green
                  : status == 'Review'
                      ? Colors.orange
                      : status == 'Obsolete'
                          ? Colors.red
                          : Colors.blue;

              // Safely parse date
              DateTime? createdDate;
              if (drawing['createdDate'] != null) {
                if (drawing['createdDate'] is Timestamp) {
                  createdDate = (drawing['createdDate'] as Timestamp).toDate();
                } else if (drawing['createdDate'] is DateTime) {
                  createdDate = drawing['createdDate'] as DateTime;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF00BCD4),
                    child: Icon(Icons.architecture, color: Colors.white),
                  ),
                  title: Text(
                    drawing['drawingNumber'] ?? 'Unknown Drawing',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(drawing['title'] ?? 'No title'),
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
                          Text('Product: ${drawing['product'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('Revision: ${drawing['revision'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          if ((drawing['notes'] ?? '').toString().isNotEmpty)
                            Text('Notes: ${drawing['notes']}'),
                          if (createdDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Created: ${createdDate.day}/${createdDate.month}/${createdDate.year}',
                            ),
                          ],
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
        onPressed: _showDrawingDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Drawing'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }
}