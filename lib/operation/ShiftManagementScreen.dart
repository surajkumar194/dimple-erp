import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// shift_management_screen.dart
class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  void _showAddShiftDialog() {
    final employeeController = TextEditingController();
    final positionController = TextEditingController();
    DateTime date = DateTime.now();
    String shift = 'Morning';
    String status = 'Present';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Shift Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text('${date.day}/${date.month}/${date.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2026),
                    );
                    if (picked != null) {
                      setDialogState(() => date = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: shift,
                  decoration: const InputDecoration(
                    labelText: 'Shift',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  items: ['Morning', 'Evening', 'Night']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => shift = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: employeeController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.check_circle),
                  ),
                  items: ['Present', 'Absent', 'Late', 'Half Day']
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
                if (employeeController.text.isEmpty ||
                    positionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('shifts').add({
                    'date': Timestamp.fromDate(date),
                    'shift': shift,
                    'employee': employeeController.text,
                    'position': positionController.text,
                    'status': status,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shift entry added')),
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
        title: const Text('Shift Management'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shifts')
            .orderBy('date', descending: true)
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
                'No shift entries',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var shift = doc.data() as Map<String, dynamic>;
              String status = shift['status'] ?? 'Present';
              Color statusColor = status == 'Present'
                  ? Colors.green
                  : status == 'Absent'
                      ? Colors.red
                      : status == 'Late'
                          ? Colors.orange
                          : Colors.blue;

              // Safely parse date
              DateTime? shiftDate;
              if (shift['date'] != null) {
                if (shift['date'] is Timestamp) {
                  shiftDate = (shift['date'] as Timestamp).toDate();
                } else if (shift['date'] is DateTime) {
                  shiftDate = shift['date'] as DateTime;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Icon(
                      status == 'Present'
                          ? Icons.check
                          : status == 'Absent'
                              ? Icons.close
                              : Icons.watch_later,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    shift['employee'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${shift['position'] ?? 'N/A'} | ${shift['shift'] ?? 'N/A'} Shift',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (shiftDate != null)
                        Text(
                          '${shiftDate.day}/${shiftDate.month}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )
                      else
                        const Text('N/A'),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          status,
                          style: const TextStyle(fontSize: 9),
                        ),
                        backgroundColor: statusColor.withOpacity(0.2),
                        labelStyle: TextStyle(color: statusColor),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddShiftDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }
}