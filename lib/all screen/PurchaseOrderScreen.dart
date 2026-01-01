import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final supplierController = TextEditingController();
  final gstController = TextEditingController();
  final preparedByController = TextEditingController();

  List<Map<String, TextEditingController>> items = [];

  double subTotal = 0;
  double gst = 0;
  double grandTotal = 0;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  void _addItem() {
    setState(() {
      items.add({
        'name': TextEditingController(),
        'qty': TextEditingController(),
        'rate': TextEditingController(),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
    _calculateTotal();
  }

  void _calculateTotal() {
    subTotal = 0;
    for (var item in items) {
      final qty = int.tryParse(item['qty']!.text) ?? 0;
      final rate = double.tryParse(item['rate']!.text) ?? 0;
      subTotal += qty * rate;
    }
    gst = subTotal * 0.18;
    grandTotal = subTotal + gst;
    setState(() {});
  }

  Future<void> _savePO() async {
    if (!_formKey.currentState!.validate()) return;

    final poNumber = "PO-${DateTime.now().millisecondsSinceEpoch}";

    await _firestore.collection('purchase_orders').add({
      'poNumber': poNumber,
      'supplierName': supplierController.text,
      'supplierGST': gstController.text,
      'items': items.map((e) {
        final qty = int.tryParse(e['qty']!.text) ?? 0;
        final rate = double.tryParse(e['rate']!.text) ?? 0;
        return {
          'name': e['name']!.text,
          'qty': qty,
          'rate': rate,
          'amount': qty * rate,
        };
      }).toList(),
      'subTotal': subTotal,
      'gstAmount': gst,
      'grandTotal': grandTotal,
      'status': 'Draft',
      'preparedBy': preparedByController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Purchase Order Saved")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Purchase Order"),
        backgroundColor: const Color(0xFF3F51B5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _sectionCard(
                title: "Supplier Details",
                child: Column(
                  children: [
                    _input(supplierController, "Supplier Name"),
                    _input(gstController, "Supplier GST"),
                  ],
                ),
              ),

              _sectionCard(
                title: "Item Details",
                child: Column(
                  children: [
                    ...items.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      return Row(
                        children: [
                          Expanded(child: _input(item['name']!, "Item")),
                          const SizedBox(width: 6),
                          Expanded(child: _input(item['qty']!, "Qty", number: true, onChanged: (_) => _calculateTotal())),
                          const SizedBox(width: 6),
                          Expanded(child: _input(item['rate']!, "Rate", number: true, onChanged: (_) => _calculateTotal())),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(i),
                          )
                        ],
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Item"),
                      ),
                    )
                  ],
                ),
              ),

              _sectionCard(
                title: "Summary",
                child: Column(
                  children: [
                    _summaryRow("Subtotal", subTotal),
                    _summaryRow("GST (5%)", gst),
                    _summaryRow("Grand Total", grandTotal, bold: true),
                  ],
                ),
              ),

              _sectionCard(
                title: "Approval",
                child: Column(
                  children: [
                    _input(preparedByController, "Prepared By"),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _savePO,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Save Purchase Order",style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          child
        ]),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, {bool number = false, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          "₹ ${value.toStringAsFixed(2)}",
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}
