import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class QualityCheckScreen extends StatefulWidget {
  const QualityCheckScreen({super.key});

  @override
  State<QualityCheckScreen> createState() => _QualityCheckScreenState();
}

class _QualityCheckScreenState extends State<QualityCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController jobNoController = TextEditingController();
  final TextEditingController productController = TextEditingController();
  final TextEditingController checkedQtyController = TextEditingController();
  final TextEditingController rejectedQtyController = TextEditingController();
  final TextEditingController inspectorController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  String rejectionReason = 'None';
  String qcStatus = 'Pass';
  bool isLoading = false;

  int get acceptedQty {
    final checked = int.tryParse(checkedQtyController.text) ?? 0;
    final rejected = int.tryParse(rejectedQtyController.text) ?? 0;
    final value = checked - rejected;
    return value < 0 ? 0 : value;
  }

  void _updateStatus() {
    final rejected = int.tryParse(rejectedQtyController.text) ?? 0;
    if (rejected == 0) {
      qcStatus = 'Pass';
    } else if (rejected <= 5) {
      qcStatus = 'Hold';
    } else {
      qcStatus = 'Fail';
    }
  }

  Future<void> _submitQC() async {
    if (!_formKey.currentState!.validate()) return;

    final checked = int.parse(checkedQtyController.text);
    final rejected = int.parse(rejectedQtyController.text);

    if (rejected > checked) {
      _showSnackBar('❌ Rejected qty cannot exceed checked qty', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      await _firestore.collection('quality_checks').add({
        'jobNo': jobNoController.text.trim(),
        'product': productController.text.trim(),
        'checkedQty': checked,
        'acceptedQty': acceptedQty,
        'rejectedQty': rejected,
        'rejectionReason': rejectionReason,
        'qcStatus': qcStatus,
        'inspector': inspectorController.text.trim(),
        'remarks': remarksController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
      });

      _showSnackBar('✅ QC Record Saved Successfully', Colors.green);
      _formKey.currentState!.reset();
      setState(() {
        rejectionReason = 'None';
        qcStatus = 'Pass';
      });
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Quality Check'),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(jobNoController, 'Job No', Icons.assignment),
              _field(productController, 'Product Name', Icons.inventory),
              _field(checkedQtyController, 'Checked Quantity', Icons.fact_check,
                  isNumber: true, onChange: (_) => setState(_updateStatus)),
              _field(rejectedQtyController, 'Rejected Quantity', Icons.cancel,
                  isNumber: true, onChange: (_) => setState(_updateStatus)),

              _infoTile('Accepted Quantity', '$acceptedQty pcs', Colors.green),

              DropdownButtonFormField<String>(
                value: rejectionReason,
                items: [
                  'None',
                  'Printing Defect',
                  'Cutting Issue',
                  'Glue Issue',
                  'Color Mismatch',
                  'Damage',
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => rejectionReason = v!),
                decoration: _dropdownDecoration('Rejection Reason'),
              ),

              _infoTile('QC Status', qcStatus,
                  qcStatus == 'Pass'
                      ? Colors.green
                      : qcStatus == 'Hold'
                          ? Colors.orange
                          : Colors.red),

              _field(inspectorController, 'QC Inspector', Icons.person),
              _field(remarksController, 'Remarks', Icons.notes, maxLines: 3),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submitQC,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save QC',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43cea2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    Function(String)? onChange,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onChanged: onChange,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
