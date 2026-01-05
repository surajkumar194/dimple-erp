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

  @override
  void dispose() {
    jobNoController.dispose();
    productController.dispose();
    checkedQtyController.dispose();
    rejectedQtyController.dispose();
    inspectorController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  int get acceptedQty {
    final checked = int.tryParse(checkedQtyController.text) ?? 0;
    final rejected = int.tryParse(rejectedQtyController.text) ?? 0;
    final value = checked - rejected;
    return value < 0 ? 0 : value;
  }

  double get passPercentage {
    final checked = int.tryParse(checkedQtyController.text) ?? 0;
    if (checked == 0) return 0;
    return (acceptedQty / checked) * 100;
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
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', Colors.red, Icons.error_outline);
      return;
    }

    final checked = int.parse(checkedQtyController.text);
    final rejected = int.parse(rejectedQtyController.text);

    if (rejected > checked) {
      _showSnackBar('Rejected qty cannot exceed checked qty', Colors.red, Icons.warning);
      return;
    }

    setState(() => isLoading = true);

    try {
      final qcId = 'QC-${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.collection('quality_checks').add({
        'qcId': qcId,
        'jobNo': jobNoController.text.trim(),
        'product': productController.text.trim(),
        'checkedQty': checked,
        'acceptedQty': acceptedQty,
        'rejectedQty': rejected,
        'passPercentage': passPercentage,
        'rejectionReason': rejectionReason,
        'qcStatus': qcStatus,
        'inspector': inspectorController.text.trim(),
        'remarks': remarksController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
      });

      if (mounted) {
        _showSnackBar('QC Record $qcId saved successfully', Colors.green, Icons.check_circle);
        _resetForm();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', Colors.red, Icons.error);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    jobNoController.clear();
    productController.clear();
    checkedQtyController.clear();
    rejectedQtyController.clear();
    inspectorController.clear();
    remarksController.clear();
    setState(() {
      rejectionReason = 'None';
      qcStatus = 'Pass';
    });
  }

  void _showSnackBar(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getStatusColor() {
    switch (qcStatus) {
      case 'Pass':
        return Colors.green;
      case 'Hold':
        return Colors.orange;
      case 'Fail':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (qcStatus) {
      case 'Pass':
        return Icons.check_circle;
      case 'Hold':
        return Icons.pause_circle;
      case 'Fail':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
     
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF43cea2).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
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
                "Quality Check 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Manage your quality checks",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Image.asset("assets/dpl.png", scale: 3.5),
        ],
      ),
              ),
             ] ),
              ),

              const SizedBox(height: 20),

              // Job Details Section
              _sectionCard(
                icon: Icons.assignment_outlined,
                title: 'Job Details',
                color: const Color(0xFF3F51B5),
                child: Column(
                  children: [
                    _field(
                      controller: jobNoController,
                      label: 'Job Number',
                      icon: Icons.tag,
                      hint: 'Enter job number',
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: productController,
                      label: 'Product Name',
                      icon: Icons.inventory_2_outlined,
                      hint: 'Enter product name',
                    ),
                  ],
                ),
              ),

              // Inspection Data Section
              _sectionCard(
                icon: Icons.fact_check,
                title: 'Inspection Data',
                color: const Color(0xFFFF9800),
                child: Column(
                  children: [
                    _field(
                      controller: checkedQtyController,
                      label: 'Checked Quantity',
                      icon: Icons.search,
                      hint: '0',
                      isNumber: true,
                      onChange: (_) => setState(_updateStatus),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: rejectedQtyController,
                      label: 'Rejected Quantity',
                      icon: Icons.cancel_outlined,
                      hint: '0',
                      isNumber: true,
                      onChange: (_) => setState(_updateStatus),
                    ),
                    const SizedBox(height: 16),

                    // Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _statsCard(
                            label: 'Accepted',
                            value: '$acceptedQty',
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statsCard(
                            label: 'Pass Rate',
                            value: '${passPercentage.toStringAsFixed(1)}%',
                            icon: Icons.trending_up,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Rejection Details Section
              _sectionCard(
                icon: Icons.report_problem_outlined,
                title: 'Rejection Details',
                color: const Color(0xFFE91E63),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: rejectionReason,
                        decoration: InputDecoration(
                          labelText: 'Rejection Reason',
                          prefixIcon: const Icon(Icons.error_outline),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        items: [
                          'None',
                          'Printing Defect',
                          'Cutting Issue',
                          'Glue Issue',
                          'Color Mismatch',
                          'Damage',
                          'Measurement Error',
                          'Material Defect',
                          'Other',
                        ].map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        )).toList(),
                        onChanged: (v) => setState(() => rejectionReason = v!),
                      ),
                    ),
                  ],
                ),
              ),

              // QC Status Display
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor().withOpacity(0.1),
                      _getStatusColor().withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor().withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QC Status',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            qcStatus,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        qcStatus.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Inspector Details Section
              _sectionCard(
                icon: Icons.person_outline,
                title: 'Inspector Details',
                color: const Color(0xFF9C27B0),
                child: Column(
                  children: [
                    _field(
                      controller: inspectorController,
                      label: 'QC Inspector Name',
                      icon: Icons.badge_outlined,
                      hint: 'Enter inspector name',
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: remarksController,
                      label: 'Remarks / Notes',
                      icon: Icons.notes,
                      hint: 'Additional comments (optional)',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submitQC,
                  icon: isLoading
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
                    isLoading ? 'Saving QC Record...' : 'Save QC Record',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43cea2),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF43cea2).withOpacity(0.5),
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
            left: BorderSide(color: color, width: 4),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isNumber = false,
    int maxLines = 1,
    Function(String)? onChange,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChange,
      validator: (v) => v == null || v.isEmpty ? '$label is required' : null,
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
          borderSide: const BorderSide(color: Color(0xFF43cea2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _statsCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}