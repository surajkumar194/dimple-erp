import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AddProductionScreen extends StatefulWidget {
  const AddProductionScreen({super.key});

  @override
  State<AddProductionScreen> createState() => _AddProductionScreenState();
}

class _AddProductionScreenState extends State<AddProductionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController machineController = TextEditingController();
  final TextEditingController plannedQtyController = TextEditingController();
  final TextEditingController actualQtyController = TextEditingController();
  final TextEditingController rejectionController = TextEditingController();
  final TextEditingController operatorController = TextEditingController();
  final TextEditingController remarkController = TextEditingController(); // ← Naya controller

  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String shift = "Morning";
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Auto Calculations
  int get goodQty {
    final actual = int.tryParse(actualQtyController.text) ?? 0;
    final rejection = int.tryParse(rejectionController.text) ?? 0;
    return actual - rejection;
  }

  double get efficiency {
    final actual = int.tryParse(actualQtyController.text) ?? 0;
    final planned = int.tryParse(plannedQtyController.text) ?? 0;
    if (planned == 0) return 0.0;
    return (actual / planned) * 100;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    machineController.dispose();
    plannedQtyController.dispose();
    actualQtyController.dispose();
    rejectionController.dispose();
    operatorController.dispose();
    remarkController.dispose(); // ← Dispose bhi kiya
    _animController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF667eea), onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) startTime = picked;
        else endTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'Not Selected';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Start Time and End Time'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('machine_production').add({
        'machine': machineController.text.trim(),
        'plannedQty': int.parse(plannedQtyController.text),
        'actualQty': int.parse(actualQtyController.text),
        'rejection': int.parse(rejectionController.text),
        'goodQty': goodQty,
        'efficiency': efficiency,
        'operator': operatorController.text.trim(),
        'shift': shift,
        'startTime': _formatTime(startTime),
        'endTime': _formatTime(endTime),
        'remark': remarkController.text.trim(), // ← Remark save kar rahe hain
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved successfully!'), backgroundColor: Colors.green),
      );

      // Reset Everything
      _formKey.currentState!.reset();
      machineController.clear();
      plannedQtyController.clear();
      actualQtyController.clear();
      rejectionController.clear();
      operatorController.clear();
      remarkController.clear(); // ← Remark bhi clear
      setState(() {
        startTime = null;
        endTime = null;
        shift = "Morning";
      });
      _animController.reset();
      _animController.forward();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Reusable TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        inputFormatters: keyboardType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
        validator: (value) {
          // Remark ke liye validator nahi lagaya (optional)
          if (controller != remarkController) {
            if (value == null || value.isEmpty) return 'Please enter $label';
            if (keyboardType == TextInputType.number && int.tryParse(value) == null) {
              return 'Enter a valid number';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF667eea).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF667eea), size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF667eea), width: 2)),
        ),
      ),
    );
  }

  // Time Field
  Widget _buildTimeField({required String label, required IconData icon, required TimeOfDay? time, required bool isStart}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: () => _selectTime(isStart),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF667eea).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: const Color(0xFF667eea), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(_formatTime(time), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: time != null ? Colors.black87 : Colors.grey.shade400)),
                  ],
                ),
              ),
              Icon(Icons.access_time, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  // Shift Dropdown
  Widget _buildShiftDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DropdownButtonFormField<String>(
        value: shift,
        decoration: InputDecoration(
          labelText: "Shift",
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF667eea).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFF667eea)),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF667eea), width: 2)),
        ),
        items: ["Morning", "Night"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => shift = val!),
      ),
    );
  }

  // Calculation Card
  Widget _buildCalculationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF667eea).withOpacity(0.1), const Color(0xFF764ba2).withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(children: [Icon(Icons.check_box_rounded, color: Colors.teal, size: 28), const SizedBox(width: 12), const Text("Good Quantity", style: TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Text("$goodQty pcs", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal))]),
          const Divider(height: 30),
          Row(children: [Icon(Icons.speed_rounded, color: efficiency >= 90 ? Colors.green : efficiency >= 70 ? Colors.orange : Colors.red, size: 28), const SizedBox(width: 12), const Text("Efficiency", style: TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Text("${efficiency.toStringAsFixed(1)}%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: efficiency >= 90 ? Colors.green : efficiency >= 70 ? Colors.orange : Colors.red))]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Add Production Entry", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]))),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      const Icon(Icons.precision_manufacturing_rounded, size: 60, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text('Production Entry', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                _buildTextField(controller: machineController, label: "Machine/Table Name", icon: Icons.settings, hint: "e.g. CNC-01"),
                _buildTextField(controller: plannedQtyController, label: "Planned Quantity", icon: Icons.text_rotation_angleup_outlined, hint: "100", keyboardType: TextInputType.number),
                _buildTextField(controller: actualQtyController, label: "Actual Quantity", icon: Icons.check_circle_outline, hint: "95", keyboardType: TextInputType.number),
                _buildTextField(controller: rejectionController, label: "Rejection Count", icon: Icons.cancel_outlined, hint: "5", keyboardType: TextInputType.number),
                _buildTextField(controller: operatorController, label: "Operator Name", icon: Icons.person_outline, hint: "Ramesh Kumar"),

                _buildShiftDropdown(),
                _buildTimeField(label: "Start Time", icon: Icons.play_circle_outline, time: startTime, isStart: true),
                _buildTimeField(label: "End Time", icon: Icons.stop_circle_outlined, time: endTime, isStart: false),

                _buildCalculationCard(),

                // ← Naya Remark Field yahan add kiya gaya hai
                _buildTextField(
                  controller: remarkController,
                  label: "Remark (Optional)",
                  icon: Icons.note_alt_outlined,
                  hint: "Any additional notes or comments",
                  maxLines: 3,
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667eea), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 5),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text("Submit & Save", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}