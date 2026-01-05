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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  @override
  void dispose() {
    supplierController.dispose();
    gstController.dispose();
    preparedByController.dispose();
    for (var item in items) {
      item['name']?.dispose();
      item['qty']?.dispose();
      item['rate']?.dispose();
    }
    super.dispose();
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
    if (items.length > 1) {
      setState(() {
        items[index]['name']?.dispose();
        items[index]['qty']?.dispose();
        items[index]['rate']?.dispose();
        items.removeAt(index);
      });
      _calculateTotal();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("At least one item is required"),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text("Purchase Order $poNumber saved successfully"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // appBar: AppBar(
      //   elevation: 0,
      //   title: const Text(
      //     "Create Purchase Order",
      //     style: TextStyle(fontWeight: FontWeight.w600),
      //   ),
      //   backgroundColor: const Color(0xFF1976D2),
      //   foregroundColor: Colors.white,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.info_outline),
      //       onPressed: () {
      //         showDialog(
      //           context: context,
      //           builder: (context) => AlertDialog(
      //             title: const Text("Purchase Order Info"),
      //             content: const Text(
      //               "Fill in supplier details, add items with quantities and rates. "
      //               "GST will be calculated automatically at 18%.",
      //             ),
      //             actions: [
      //               TextButton(
      //                 onPressed: () => Navigator.pop(context),
      //                 child: const Text("Got it"),
      //               ),
      //             ],
      //           ),
      //         );
      //       },
      //     ),
      //   ],
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                   
                    Expanded(
                     child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Purchase Order 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Manage your purchase orders",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Image.asset("assets/dpl.png", scale: 3.5),
        ],
      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Supplier Details Section
              _sectionCard(
                icon: Icons.business,
                title: "Supplier Details",
                color: const Color(0xFF1976D2),
                child: Column(
                  children: [
                    _input(
                      controller: supplierController,
                      label: "Supplier Name",
                      icon: Icons.person_outline,
                      hint: "Enter supplier name",
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: gstController,
                      label: "Supplier GST Number",
                      icon: Icons.numbers,
                      hint: "Enter GST number",
                    ),
                  ],
                ),
              ),

              // Items Section
              _sectionCard(
                icon: Icons.inventory_2,
                title: "Items (${items.length})",
                color: const Color(0xFF4CAF50),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text("Item", style: TextStyle(fontWeight: FontWeight.w600))),
                          SizedBox(width: 8),
                          Expanded(flex: 2, child: Text("Qty", style: TextStyle(fontWeight: FontWeight.w600))),
                          SizedBox(width: 8),
                          Expanded(flex: 2, child: Text("Rate", style: TextStyle(fontWeight: FontWeight.w600))),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Items List
                    ...items.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      final qty = int.tryParse(item['qty']!.text) ?? 0;
                      final rate = double.tryParse(item['rate']!.text) ?? 0;
                      final amount = qty * rate;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _compactInput(
                                    controller: item['name']!,
                                    label: "Item",
                                    hint: "Item name",
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _compactInput(
                                    controller: item['qty']!,
                                    label: "Qty",
                                    hint: "0",
                                    number: true,
                                    onChanged: (_) => _calculateTotal(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _compactInput(
                                    controller: item['rate']!,
                                    label: "Rate",
                                    hint: "0.00",
                                    number: true,
                                    onChanged: (_) => _calculateTotal(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => _removeItem(i),
                                  tooltip: "Remove item",
                                ),
                              ],
                            ),
                            if (amount > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Amount:", style: TextStyle(fontSize: 12)),
                                    Text(
                                      "₹ ${amount.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Add Another Item"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              // Summary Section
              _sectionCard(
                icon: Icons.calculate,
                title: "Order Summary",
                color: const Color(0xFFFF9800),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[50]!, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _summaryRow("Subtotal", subTotal, icon: Icons.receipt_long),
                      const Divider(height: 24),
                      _summaryRow("GST (18%)", gst, icon: Icons.percent),
                      const Divider(height: 24),
                      _summaryRow(
                        "Grand Total",
                        grandTotal,
                        bold: true,
                        icon: Icons.attach_money,
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ),

              // Approval Section
              _sectionCard(
                icon: Icons.edit_note,
                title: "Prepared By",
                color: const Color(0xFF9C27B0),
                child: _input(
                  controller: preparedByController,
                  label: "Your Name",
                  icon: Icons.person,
                  hint: "Enter your name",
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _savePO,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isSaving ? "Saving..." : "Save Purchase Order",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: Colors.blue.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: color, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool number = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      validator: (v) => v == null || v.isEmpty ? "$label is required" : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _compactInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool number = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false, IconData? icon, bool highlight = false}) {
    return Container(
      padding: highlight ? const EdgeInsets.all(12) : EdgeInsets.zero,
      decoration: highlight
          ? BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: highlight ? const Color(0xFF1976D2) : Colors.grey[600]),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: bold ? 18 : 15,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: highlight ? const Color(0xFF1976D2) : Colors.grey[700],
                ),
              ),
            ],
          ),
          Text(
            "₹ ${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: bold ? 20 : 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: highlight ? const Color(0xFF1976D2) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}