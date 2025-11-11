import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockTrackingScreen extends StatefulWidget {
  const StockTrackingScreen({super.key});

  @override
  State<StockTrackingScreen> createState() => _StockTrackingScreenState();
}

class _StockTrackingScreenState extends State<StockTrackingScreen> {
  String filterType = 'All';

  void _showStockMovementDialog() {
    final materialController = TextEditingController();
    final quantityController = TextEditingController();
    final referenceController = TextEditingController();
    String movementType = 'IN';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record Stock Movement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: movementType,
                  decoration: const InputDecoration(
                    labelText: 'Movement Type',
                    prefixIcon: Icon(Icons.swap_horiz),
                  ),
                  items: ['IN', 'OUT', 'ADJUST']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => setState(() => movementType = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: materialController,
                  decoration: const InputDecoration(
                    labelText: 'Material Name',
                    prefixIcon: Icon(Icons.inventory),
                  ),
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
                TextFormField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference (PO/Order No)',
                    prefixIcon: Icon(Icons.receipt),
                  ),
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
                await FirebaseFirestore.instance.collection('stockMovements').add({
                  'material': materialController.text,
                  'quantity': double.parse(quantityController.text),
                  'type': movementType,
                  'reference': referenceController.text,
                  'date': DateTime.now(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock movement recorded')),
                );
              },
              child: const Text('Record'),
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
        title: const Text('Stock Tracking'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'IN', 'OUT', 'ADJUST'].map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: filterType == type,
                      onSelected: (selected) {
                        setState(() => filterType = type);
                      },
                      selectedColor: const Color(0xFF4CAF50),
                      labelStyle: TextStyle(
                        color: filterType == type ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stockMovements')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var movements = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (filterType == 'All') return true;
                  return data['type'] == filterType;
                }).toList();

                if (movements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('No stock movements', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: movements.length,
                  itemBuilder: (context, index) {
                    var movement = movements[index].data() as Map<String, dynamic>;
                    String type = movement['type'];
                    Color typeColor = type == 'IN'
                        ? Colors.green
                        : type == 'OUT'
                            ? Colors.red
                            : Colors.orange;
                    IconData typeIcon = type == 'IN'
                        ? Icons.arrow_downward
                        : type == 'OUT'
                            ? Icons.arrow_upward
                            : Icons.sync;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: typeColor.withOpacity(0.2),
                          child: Icon(typeIcon, color: typeColor),
                        ),
                        title: Text(
                          movement['material'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ref: ${movement['reference']}'),
                            Text(
                              '${(movement['date'] as Timestamp).toDate().day}/${(movement['date'] as Timestamp).toDate().month}/${(movement['date'] as Timestamp).toDate().year}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${type == 'OUT' ? '-' : '+'}${movement['quantity']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                            ),
                            Chip(
                              label: Text(type, style: const TextStyle(fontSize: 10)),
                              backgroundColor: typeColor.withOpacity(0.2),
                              labelStyle: TextStyle(color: typeColor),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStockMovementDialog,
        icon: const Icon(Icons.add),
        label: const Text('Record Movement'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
}