import 'package:flutter/material.dart';

class GoodPurchaseScreen extends StatefulWidget {
  const GoodPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<GoodPurchaseScreen> createState() => _GoodPurchaseScreenState();
}

class _GoodPurchaseScreenState extends State<GoodPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _purchaseNoController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Items List
  List<Map<String, dynamic>> items = [
    {
      'name': '',
      'quantity': '',
      'rate': '',
      'amount': 0.0,
    }
  ];

  // Totals
  double subtotal = 0.0;
  double gstPercent = 18.0; // Default GST
  double gstAmount = 0.0;
  double grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(DateTime.now());
    _generatePurchaseNumber();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _generatePurchaseNumber() {
    final now = DateTime.now();
    final year = now.year;
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    _purchaseNoController.text = 'PUR-$year-${random.toString().padLeft(3, '0')}';
  }

  void _calculateItemAmount(int index) {
    final qty = double.tryParse(items[index]['quantity'] ?? '0') ?? 0;
    final rate = double.tryParse(items[index]['rate'] ?? '0') ?? 0;
    setState(() {
      items[index]['amount'] = qty * rate;
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    subtotal = items.fold(0, (sum, item) => sum + (item['amount'] as double));
    gstAmount = subtotal * (gstPercent / 100);
    grandTotal = subtotal + gstAmount;
  }

  void _addItem() {
    setState(() {
      items.add({
        'name': '',
        'quantity': '',
        'rate': '',
        'amount': 0.0,
      });
    });
  }

  void _removeItem(int index) {
    if (items.length > 1) {
      setState(() {
        items.removeAt(index);
        _calculateTotals();
      });
    }
  }

  void _submitPurchase() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Goods Purchase Saved Successfully!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      // TODO: Save to database / API
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goods Purchase Entry'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purchase No & Date
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchaseNoController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Purchase No.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.confirmation_number, color: Color(0xFFFF9800)),
                        filled: true,
                        fillColor: Colors.orange[50],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Vendor
              TextFormField(
                controller: _vendorController,
                decoration: InputDecoration(
                  labelText: 'Vendor / Supplier Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (v) => v!.isEmpty ? 'Enter vendor name' : null,
              ),
              const SizedBox(height: 20),

              // Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Purchase Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, color: Color(0xFFFF9800)),
                    label: const Text('Add Item'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF9800)),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),

              // Dynamic Items
              ...items.asMap().entries.map((entry) {
                int idx = entry.key;
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: items[idx]['name'],
                          decoration: InputDecoration(
                            labelText: 'Item Name (e.g., Kraft Paper Roll)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (v) => items[idx]['name'] = v,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: items[idx]['quantity'],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Qty',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (v) {
                                  items[idx]['quantity'] = v;
                                  _calculateItemAmount(idx);
                                },
                                validator: (v) => v!.isEmpty ? 'Req' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: items[idx]['rate'],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Rate/Unit',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  prefixText: '₹ ',
                                ),
                                onChanged: (v) {
                                  items[idx]['rate'] = v;
                                  _calculateItemAmount(idx);
                                },
                                validator: (v) => v!.isEmpty ? 'Req' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  border: Border.all(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '₹ ${items[idx]['amount'].toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD84315)),
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
                            onPressed: () => _removeItem(idx),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              // GST Dropdown - FIXED
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<double>(
                      value: gstPercent,
                      decoration: InputDecoration(
                        labelText: 'GST %',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [0, 5, 12, 18, 28].map((rate) {
                        return DropdownMenuItem<double>(
                          value: rate.toDouble(), // FIXED: int to double
                          child: Text('$rate%'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          gstPercent = val!;
                          _calculateTotals();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF9800)),
                      ),
                      child: Text(
                        'GST: ₹ ${gstAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Grand Total
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '₹ ${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Remarks / Transport / Payment Terms',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  child: const Text(
                    'SAVE PURCHASE',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
    _purchaseNoController.dispose();
    _vendorController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}