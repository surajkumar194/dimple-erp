import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MachineMaintenanceScreen extends StatefulWidget {
  const MachineMaintenanceScreen({super.key});

  @override
  State<MachineMaintenanceScreen> createState() => _MachineMaintenanceScreenState();
}

class _MachineMaintenanceScreenState extends State<MachineMaintenanceScreen> {
  void _showMaintenanceDialog() {
    final machineController = TextEditingController();
    final descriptionController = TextEditingController();
    final technicianController = TextEditingController();
    DateTime date = DateTime.now();
    String type = 'Preventive';
    String status = 'Scheduled';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Maintenance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: machineController,
                  decoration: const InputDecoration(
                    labelText: 'Machine Name/Number',
                    prefixIcon: Icon(Icons.precision_manufacturing),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Type',
                    prefixIcon: Icon(Icons.build),
                  ),
                  items: ['Preventive', 'Corrective', 'Emergency']
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
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: technicianController,
                  decoration: const InputDecoration(
                    labelText: 'Technician',
                    prefixIcon: Icon(Icons.engineering),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text('${date.day}/${date.month}/${date.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2026),
                    );
                    if (picked != null) {
                      setDialogState(() => date = picked);
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
                if (machineController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    technicianController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('maintenance').add({
                  'machine': machineController.text,
                  'type': type,
                  'description': descriptionController.text,
                  'technician': technicianController.text,
                  'date': Timestamp.fromDate(date),
                  'status': status,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Maintenance scheduled')),
                  );
                }
              },
              child: const Text('Schedule'),
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
        title: const Text('Machine Maintenance'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('maintenance')
            .orderBy('date')
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
                'No maintenance records',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var maintenance = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              String status = maintenance['status'] ?? 'Scheduled';
              Color statusColor = status == 'Completed'
                  ? Colors.green
                  : status == 'In Progress'
                      ? Colors.orange
                      : Colors.blue;

              // Safely parse date
              DateTime? maintenanceDate;
              if (maintenance['date'] != null) {
                if (maintenance['date'] is Timestamp) {
                  maintenanceDate = (maintenance['date'] as Timestamp).toDate();
                } else if (maintenance['date'] is DateTime) {
                  maintenanceDate = maintenance['date'] as DateTime;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2196F3),
                    child: Icon(Icons.build, color: Colors.white),
                  ),
                  title: Text(
                    maintenance['machine'] ?? 'Unknown Machine',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(maintenance['type'] ?? 'N/A'),
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
                          Text('Description: ${maintenance['description'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('Technician: ${maintenance['technician'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          if (maintenanceDate != null)
                            Text(
                              'Date: ${maintenanceDate.day}/${maintenanceDate.month}/${maintenanceDate.year}',
                            )
                          else
                            const Text('Date: N/A'),
                          const SizedBox(height: 16),
                          if (status != 'Completed')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('maintenance')
                                        .doc(docId)
                                        .update({'status': 'Completed'});
                                    
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Maintenance marked as completed'),
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
                                child: const Text('Mark Completed'),
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
        onPressed: _showMaintenanceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }
}