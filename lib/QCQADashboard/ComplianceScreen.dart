import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  void _showComplianceDialog() {
    final titleController = TextEditingController();
    final standardController = TextEditingController();
    final certificateController = TextEditingController();
    DateTime issueDate = DateTime.now();
    DateTime expiryDate = DateTime.now().add(const Duration(days: 365));
    String status = 'Valid';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Compliance Record'),
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
                  controller: standardController,
                  decoration: const InputDecoration(
                    labelText: 'Standard/Regulation',
                    prefixIcon: Icon(Icons.gavel),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: certificateController,
                  decoration: const InputDecoration(
                    labelText: 'Certificate Number',
                    prefixIcon: Icon(Icons.card_membership),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Issue Date'),
                  subtitle: Text('${issueDate.day}/${issueDate.month}/${issueDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: issueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => issueDate = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiry Date'),
                  subtitle: Text('${expiryDate.day}/${expiryDate.month}/${expiryDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => expiryDate = picked);
                    }
                  },
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
                    standardController.text.isEmpty ||
                    certificateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                  return;
                }

                // Validate dates
                if (expiryDate.isBefore(issueDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expiry date must be after issue date'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('compliance').add({
                    'title': titleController.text,
                    'standard': standardController.text,
                    'certificateNumber': certificateController.text,
                    'issueDate': Timestamp.fromDate(issueDate),
                    'expiryDate': Timestamp.fromDate(expiryDate),
                    'status': status,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compliance record added')),
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
        title: const Text('Compliance Records'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('compliance')
            .orderBy('expiryDate')
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
                'No compliance records',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var compliance = doc.data() as Map<String, dynamic>;
              
              // Safely parse dates
              DateTime? expiryDate;
              DateTime? issueDate;
              
              if (compliance['expiryDate'] != null) {
                if (compliance['expiryDate'] is Timestamp) {
                  expiryDate = (compliance['expiryDate'] as Timestamp).toDate();
                } else if (compliance['expiryDate'] is DateTime) {
                  expiryDate = compliance['expiryDate'] as DateTime;
                }
              }
              
              if (compliance['issueDate'] != null) {
                if (compliance['issueDate'] is Timestamp) {
                  issueDate = (compliance['issueDate'] as Timestamp).toDate();
                } else if (compliance['issueDate'] is DateTime) {
                  issueDate = compliance['issueDate'] as DateTime;
                }
              }

              bool expiringSoon = false;
              Color statusColor = Colors.green;
              
              if (expiryDate != null) {
                int daysRemaining = expiryDate.difference(DateTime.now()).inDays;
                expiringSoon = daysRemaining < 30 && daysRemaining >= 0;
                bool expired = daysRemaining < 0;
                statusColor = expired ? Colors.red : (expiringSoon ? Colors.orange : Colors.green);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Icon(
                      expiringSoon ? Icons.warning : Icons.verified,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    compliance['title'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(compliance['standard'] ?? 'N/A'),
                  trailing: expiringSoon
                      ? const Chip(
                          label: Text(
                            'Expiring Soon',
                            style: TextStyle(fontSize: 9),
                          ),
                          backgroundColor: Colors.orange,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Certificate: ${compliance['certificateNumber'] ?? 'N/A'}',
                          ),
                          const SizedBox(height: 8),
                          if (issueDate != null)
                            Text(
                              'Issue Date: ${issueDate.day}/${issueDate.month}/${issueDate.year}',
                            )
                          else
                            const Text('Issue Date: N/A'),
                          const SizedBox(height: 8),
                          if (expiryDate != null)
                            Text(
                              'Expiry Date: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                            )
                          else
                            const Text('Expiry Date: N/A'),
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
        onPressed: _showComplianceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
        backgroundColor: const Color(0xFF9C27B0),
      ),
    );
  }
}