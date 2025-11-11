import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  // Controllers
  final _poNoController = TextEditingController(text: '419');
  final _vendorNameController = TextEditingController();
  final _vendorAddressController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _vendorPanController = TextEditingController();
  final _vendorGstController = TextEditingController();
  final _otherRefController = TextEditingController();
  final _termsDeliveryController = TextEditingController();
  final _exchangeRateController = TextEditingController(text: '1');
  final _remarksController = TextEditingController();
  final _otherTermsController = TextEditingController();

  // Dropdown Values
  String _storeLocation = 'Dimple Packaging Pvt Ltd';
  String _billTo = 'Dimple Packaging Pvt Ltd';
  String _deliveryAddress = 'Dimple Packaging Pvt Ltd';
  String _supplier = 'Select Supplier';
  String _currency = 'INR';
  bool _showDiscount = false;

  DateTime _poDate = DateTime.now();

  // Table Rows
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _addEmptyRow();
  }

  void _addEmptyRow() {
    setState(() {
      _items.add({
        'itemCode': '',
        'hsn': '',
        'weight': '',
        'qty': '',
        'reorder': '',
        'noOfSht': '',
        'units': '',
        'rate': '',
        'quoteRate': '',
        'discount': '',
        'amount': 0.0,
        'cgstRate': '',
        'cgstAmt': 0.0,
        'sgstRate': '',
        'sgstAmt': 0.0,
        'delDate': DateTime.now(),
        'vendorRef': '',
      });
    });
  }

  void _removeRow(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _calculateRow(int index) {
    final item = _items[index];
    final qty = double.tryParse(item['qty'] ?? '0') ?? 0;
    final rate = double.tryParse(item['rate'] ?? '0') ?? 0;
    final discount = double.tryParse(item['discount'] ?? '0') ?? 0;

    final amount = qty * rate * (1 - discount / 100);
    final cgstRate = double.tryParse(item['cgstRate'] ?? '0') ?? 0;
    final sgstRate = double.tryParse(item['sgstRate'] ?? '0') ?? 0;

    setState(() {
      item['amount'] = amount;
      item['cgstAmt'] = amount * cgstRate / 100;
      item['sgstAmt'] = amount * sgstRate / 100;
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + (item['amount'] as double));
  double get _cgstTotal => _items.fold(0, (sum, item) => sum + (item['cgstAmt'] as double));
  double get _sgstTotal => _items.fold(0, (sum, item) => sum + (item['sgstAmt'] as double));
  double get _grandTotal => _subtotal + _cgstTotal + _sgstTotal;

  Future<void> _submitPO() async {
    if (_items.isEmpty || _items.first['itemCode'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('purchaseOrders').add({
      'poNo': _poNoController.text,
      'storeLocation': _storeLocation,
      'poDate': _poDate,
      'vendorName': _vendorNameController.text,
      'vendorAddress': _vendorAddressController.text,
      'billTo': _billTo,
      'deliveryAddress': _deliveryAddress,
      'paymentTerms': _paymentTermsController.text,
      'vendorPan': _vendorPanController.text,
      'vendorGst': _vendorGstController.text,
      'otherRef': _otherRefController.text,
      'termsDelivery': _termsDeliveryController.text,
      'currency': _currency,
      'exchangeRate': _exchangeRateController.text,
      'showDiscount': _showDiscount,
      'items': _items,
      'subtotal': _subtotal,
      'cgstTotal': _cgstTotal,
      'sgstTotal': _sgstTotal,
      'grandTotal': _grandTotal,
      'remarks': _remarksController.text,
      'otherTerms': _otherTermsController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchase Order Saved!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTopRow(),
            const SizedBox(height: 16),
            _buildAddressSection(),
            const SizedBox(height: 16),
            _buildBottomFields(),
            const SizedBox(height: 24),
            _buildItemsTable(),
            const SizedBox(height: 16),
            _buildRemarksSection(),
            const SizedBox(height: 16),
            _buildTotalSection(),
            const SizedBox(height: 16),
            _buildOtherTerms(),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submitPO,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.business, size: 60, color: Color(0xFF4CAF50)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dimple Packaging Pvt. Ltd.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('NEAR NAVDEEP RESORTS, OPP HOTEL AMALTAS, G.T ROAD (WEST), LUDHIANA (PUNJAB)', style: TextStyle(fontSize: 12)),
                  Text('Email: store@dimplepackaging.com Ph: 7888490399', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const Divider(thickness: 1.5, color: Colors.grey),
      ],
    );
  }

  // ===================== TOP ROW =====================
  Widget _buildTopRow() {
    return Row(
      children: [
        Expanded(child: _buildField('PO No.', _poNoController, readOnly: true)),
        const SizedBox(width: 8),
        Expanded(child: _buildDropdown('Store Location', _storeLocation, ['Dimple Packaging Pvt Ltd'], (v) => _storeLocation = v!)),
        const SizedBox(width: 8),
        Expanded(child: _buildDateField('Date', _poDate, (d) => setState(() => _poDate = d!))),
        const SizedBox(width: 8),
        Expanded(child: _buildDropdown('Show Discount Column(s)', _showDiscount ? 'Yes' : 'No', ['No', 'Yes'], (v) => setState(() => _showDiscount = v == 'Yes'))),
      ],
    );
  }

  // ===================== ADDRESS SECTION =====================
  Widget _buildAddressSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildDropdown('Vendor Name', _supplier, ['Select Supplier', 'Supplier A', 'Supplier B'], (v) => _supplier = v!),
              const SizedBox(height: 8),
              _buildField('Vendor Address', _vendorAddressController, maxLines: 3),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildDropdown('Bill To', _billTo, ['Dimple Packaging Pvt Ltd'], (v) => _billTo = v!)),
        const SizedBox(width: 8),
        Expanded(child: _buildDropdown('Delivery Name & Address', _deliveryAddress, ['Dimple Packaging Pvt Ltd'], (v) => _deliveryAddress = v!)),
        const SizedBox(width: 8),
        Expanded(child: _buildField('Supplier (if other)', TextEditingController())),
      ],
    );
  }

  // ===================== BOTTOM FIELDS =====================
  Widget _buildBottomFields() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildField('Payment Terms(days)', _paymentTermsController),
        _buildField('Vendor GST No.', _vendorGstController),
        _buildField('Terms of Delivery', _termsDeliveryController),
        _buildField('Vendor PAN No.', _vendorPanController),
        _buildField('Other Reference(PI)', _otherRefController),
        _buildDropdown('Currency (Only For Import)', _currency, ['INR', 'USD'], (v) => _currency = v!),
        _buildField('Exchange Rate', _exchangeRateController),
      ].map((e) => SizedBox(width: 200, child: e)).toList(),
    );
  }

  // ===================== ITEMS TABLE =====================
  Widget _buildItemsTable() {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          columns: [
            'Sr.No', 'Item Code', 'HSN', 'Weight', 'Qty.', 'Re-order', 'No of Sht', 'Units', 'Rate', 'Quote Rate', 'Discount', 'Amount', 'CGST', '', 'SGST/UTGST', ''
          ].map((e) => DataColumn(label: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
          rows: _items.asMap().entries.map((entry) {
            int idx = entry.key;
            var item = entry.value;
            return DataRow(cells: [
              DataCell(Text('${idx + 1}')),
              DataCell(_buildSearchField(item, 'itemCode', idx)),
              DataCell(_buildField('', TextEditingController(text: item['hsn']), onChanged: (v) => item['hsn'] = v)),
              DataCell(_buildField('', TextEditingController(text: item['weight']), onChanged: (v) => item['weight'] = v)),
              DataCell(_buildField('', TextEditingController(text: item['qty']), onChanged: (v) { item['qty'] = v; _calculateRow(idx); })),
              DataCell(_buildField('', TextEditingController(text: item['reorder']), onChanged: (v) => item['reorder'] = v)),
              DataCell(_buildField('', TextEditingController(text: item['noOfSht']), onChanged: (v) => item['noOfSht'] = v)),
              DataCell(_buildField('', TextEditingController(text: item['units']), onChanged: (v) => item['units'] = v)),
              DataCell(_buildField('', TextEditingController(text: item['rate']), onChanged: (v) { item['rate'] = v; _calculateRow(idx); })),
              DataCell(_buildField('', TextEditingController(text: item['quoteRate']), onChanged: (v) => item['quoteRate'] = v)),
              DataCell(_buildField('', TextEditingController(text: item['discount']), onChanged: (v) { item['discount'] = v; _calculateRow(idx); })),
              DataCell(Text(item['amount'].toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(_buildField('', TextEditingController(text: item['cgstRate']), onChanged: (v) { item['cgstRate'] = v; _calculateRow(idx); })),
              DataCell(Text(item['cgstAmt'].toStringAsFixed(2))),
              DataCell(_buildField('', TextEditingController(text: item['sgstRate']), onChanged: (v) { item['sgstRate'] = v; _calculateRow(idx); })),
              DataCell(Text(item['sgstAmt'].toStringAsFixed(2))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ===================== REMARKS =====================
  Widget _buildRemarksSection() {
    return Row(
      children: [
        Expanded(child: _buildField('Purchase against UDF', TextEditingController())),
        const SizedBox(width: 8),
        Expanded(child: _buildField('Enter Remarks', _remarksController)),
        const SizedBox(width: 8),
        Expanded(child: _buildField('Remarks: Purchase for but not show in PO other than Purchase', TextEditingController(), readOnly: true)),
      ],
    );
  }

  // ===================== TOTAL SECTION (FIXED) =====================
  Widget _buildTotalSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Text(_subtotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [Checkbox(value: false, onChanged: (_) {}), const Text('Add. Tax Only')]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('HSN Code:'),
                const SizedBox(width: 20),
                const Text('Amount:'),
                const SizedBox(width: 20),
                const Text('-select-'),
                const SizedBox(width: 8),
                const Text('%'),
                const SizedBox(width: 20),
                Text(_cgstTotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 16),
                Text(_grandTotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== OTHER TERMS =====================
  Widget _buildOtherTerms() {
    return _buildField('Other Terms & Conditions (Max. 250 characters)', _otherTermsController, maxLines: 3);
  }

  // ===================== HELPERS =====================
  Widget _buildField(String label, TextEditingController controller, {bool readOnly = false, int maxLines = 1, Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(DateFormat('dd/MM/yyyy').format(date)),
      ),
    );
  }

  Widget _buildSearchField(Map item, String key, int index) {
    return TextFormField(
      initialValue: item[key],
      decoration: const InputDecoration(hintText: 'Search for an item', border: OutlineInputBorder()),
      onChanged: (v) => setState(() => item[key] = v),
    );
  }
}