import 'package:flutter/material.dart';

class StockPurchaseScreen extends StatefulWidget {
  const StockPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<StockPurchaseScreen> createState() => _StockPurchaseScreenState();
}

class _StockPurchaseScreenState extends State<StockPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // List of items
  List<Map<String, dynamic>> items = [
    {'name': '', 'quantity': '', 'price': '', 'total': 0.0},
  ];

  double grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _calculateItemTotal(int index) {
    final qty = double.tryParse(items[index]['quantity'] ?? '0') ?? 0;
    final price = double.tryParse(items[index]['price'] ?? '0') ?? 0;
    setState(() {
      items[index]['total'] = qty * price;
      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    grandTotal = items.fold(0, (sum, item) => sum + (item['total'] as double));
  }

  void _addItem() {
    setState(() {
      items.add({'name': '', 'quantity': '', 'price': '', 'total': 0.0});
    });
  }

  void _removeItem(int index) {
    if (items.length > 1) {
      setState(() {
        items.removeAt(index);
        _calculateGrandTotal();
      });
    }
  }

  void _submitPurchase() {
    if (_formKey.currentState!.validate()) {
      // Simulate submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase Order Submitted Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Here you can send data to backend
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Purchase Order'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor & Date Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vendorController,
                      decoration: InputDecoration(
                        labelText: 'Vendor Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter vendor name' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF9C27B0)),
                  ),
                ],
              ),
              const Divider(),

              // Dynamic Item List
              ...items.asMap().entries.map((entry) {
                int index = entry.key;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: items[index]['name'],
                          decoration: InputDecoration(
                            labelText: 'Item Name (e.g., Cardboard Sheet)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) => items[index]['name'] = val,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter item name' : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: items[index]['quantity'],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Qty',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) {
                                  items[index]['quantity'] = val;
                                  _calculateItemTotal(index);
                                },
                                validator: (value) =>
                                    value!.isEmpty ? 'Enter qty' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: items[index]['price'],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Price/Unit',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  prefixText: '₹ ',
                                ),
                                onChanged: (val) {
                                  items[index]['price'] = val;
                                  _calculateItemTotal(index);
                                },
                                validator: (value) =>
                                    value!.isEmpty ? 'Enter price' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '₹ ${items[index]['total'].toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              // Grand Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9C27B0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹ ${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Purchase Order',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}