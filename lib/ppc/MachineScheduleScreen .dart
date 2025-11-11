import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MachineScheduleScreen extends StatefulWidget {
  const MachineScheduleScreen({super.key});

  @override
  State<MachineScheduleScreen> createState() => _MachineScheduleScreenState();
}

class _MachineScheduleScreenState extends State<MachineScheduleScreen> {
  DateTime selectedDate = DateTime.now();

  void _showScheduleDialog() {
    final machineController = TextEditingController();
    final productController = TextEditingController();
    final operatorController = TextEditingController();
    String shift = 'Morning';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Machine'),
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
                TextFormField(
                  controller: productController,
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: operatorController,
                  decoration: const InputDecoration(
                    labelText: 'Operator',
                    prefixIcon: Icon(Icons.person),
                  ),
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
                    productController.text.isEmpty ||
                    operatorController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('machineSchedules').add({
                    'machine': machineController.text,
                    'product': productController.text,
                    'operator': operatorController.text,
                    'shift': shift,
                    'date': Timestamp.fromDate(selectedDate),
                    'status': 'Scheduled',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Machine scheduled')),
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
        title: const Text('Machine Scheduling'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2026),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFF9800),
            child: Text(
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('machineSchedules')
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
                  ))
                  .where('date', isLessThan: Timestamp.fromDate(
                    DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1),
                  ))
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
                      'No schedules for this date',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var schedule = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFF9800),
                          child: Icon(
                            Icons.precision_manufacturing,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          schedule['machine'] ?? 'Unknown Machine',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${schedule['product'] ?? 'N/A'} | Operator: ${schedule['operator'] ?? 'N/A'}',
                        ),
                        trailing: Chip(
                          label: Text(
                            schedule['shift'] ?? 'N/A',
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: const Color(0xFFFF9800).withOpacity(0.2),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
        backgroundColor: const Color(0xFFFF9800),
      ),
    );
  }
}