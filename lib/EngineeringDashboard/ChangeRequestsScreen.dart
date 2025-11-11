import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChangeRequestsScreen extends StatefulWidget {
  const ChangeRequestsScreen({super.key});

  @override
  State<ChangeRequestsScreen> createState() => _ChangeRequestsScreenState();
}

class _ChangeRequestsScreenState extends State<ChangeRequestsScreen> {
  void _showChangeRequestDialog() {
    final titleController = TextEditingController();
    final productController = TextEditingController();
    final descriptionController = TextEditingController();
    final requestedByController = TextEditingController();
    String priority = 'Medium';
    String type = 'Design Change';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Change Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    labelText: 'Product/Component',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Change Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ['Design Change', 'Process Change', 'Material Change', 'Specification Change']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => type = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: requestedByController,
                  decoration: const InputDecoration(
                    labelText: 'Requested By',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: ['Low', 'Medium', 'High', 'Critical']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => priority = value!),
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
                if (titleController.text.isEmpty ||
                    productController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    requestedByController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('changeRequests').add({
                    'title': titleController.text,
                    'product': productController.text,
                    'type': type,
                    'description': descriptionController.text,
                    'requestedBy': requestedByController.text,
                    'priority': priority,
                    'status': 'Pending',
                    'requestDate': FieldValue.serverTimestamp(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change request created')),
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
              child: const Text('Create'),
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
        title: const Text('Change Requests'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('changeRequests')
            .orderBy('requestDate', descending: true)
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
                'No change requests',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var request = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              String status = request['status'] ?? 'Pending';
              Color statusColor = status == 'Approved'
                  ? Colors.green
                  : status == 'Rejected'
                      ? Colors.red
                      : status == 'Under Review'
                          ? Colors.orange
                          : Colors.blue;

              // Safely parse date
              DateTime? requestDate;
              if (request['requestDate'] != null) {
                if (request['requestDate'] is Timestamp) {
                  requestDate = (request['requestDate'] as Timestamp).toDate();
                } else if (request['requestDate'] is DateTime) {
                  requestDate = request['requestDate'] as DateTime;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF00BCD4),
                    child: Icon(Icons.edit_note, color: Colors.white),
                  ),
                  title: Text(
                    request['title'] ?? 'Untitled Request',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${request['type'] ?? 'N/A'} | ${request['product'] ?? 'N/A'}',
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
                          Text('Description: ${request['description'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('Requested By: ${request['requestedBy'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('Priority: ${request['priority'] ?? 'N/A'}'),
                          if (requestDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Request Date: ${requestDate.day}/${requestDate.month}/${requestDate.year}',
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (status == 'Pending')
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('changeRequests')
                                            .doc(docId)
                                            .update({'status': 'Approved'});
                                        
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Request approved'),
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
                                    child: const Text('Approve'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('changeRequests')
                                            .doc(docId)
                                            .update({'status': 'Rejected'});
                                        
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Request rejected'),
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
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                              ],
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
        onPressed: _showChangeRequestDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }
}