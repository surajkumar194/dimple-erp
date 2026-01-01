import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MinutesOfMeetingScreen extends StatefulWidget {
  const MinutesOfMeetingScreen({super.key});

  @override
  State<MinutesOfMeetingScreen> createState() => _MinutesOfMeetingScreenState();
}

class _MinutesOfMeetingScreenState extends State<MinutesOfMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController departmentController = TextEditingController();
  final TextEditingController chairpersonController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController attendeesController = TextEditingController();
  final TextEditingController agendaController = TextEditingController();
  final TextEditingController discussionController = TextEditingController();
  final TextEditingController decisionController = TextEditingController();
  final TextEditingController actionController = TextEditingController();
  final TextEditingController responsibleController = TextEditingController();
  final TextEditingController preparedByController = TextEditingController();
  final TextEditingController approvedByController = TextEditingController();

  DateTime meetingDate = DateTime.now();
  DateTime dueDate = DateTime.now();
  String actionStatus = 'Open';
  bool isLoading = false;

  Future<void> _pickDate(bool isMeeting) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isMeeting ? meetingDate : dueDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        isMeeting ? meetingDate = picked : dueDate = picked;
      });
    }
  }

  Future<void> _saveMoM() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await _firestore.collection('mom').add({
        'meetingDate': DateFormat('dd MMM yyyy').format(meetingDate),
        'department': departmentController.text.trim(),
        'chairperson': chairpersonController.text.trim(),
        'location': locationController.text.trim(),
        'attendees': attendeesController.text.trim(),
        'agenda': agendaController.text.trim(),
        'discussion': discussionController.text.trim(),
        'decision': decisionController.text.trim(),
        'actionItem': actionController.text.trim(),
        'responsible': responsibleController.text.trim(),
        'dueDate': DateFormat('dd MMM yyyy').format(dueDate),
        'status': actionStatus,
        'preparedBy': preparedByController.text.trim(),
        'approvedBy': approvedByController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Minutes of Meeting Saved Successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Minutes of Meeting'),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
              _sectionTitle('Meeting Details'),
              _dateField('Meeting Date', meetingDate, () => _pickDate(true)),
              _field(departmentController, 'Department'),
              _field(chairpersonController, 'Chairperson'),
              _field(locationController, 'Location'),

              _sectionTitle('Participants'),
              _field(attendeesController, 'Attendees (comma separated)', maxLines: 2),

              _sectionTitle('Agenda & Discussion'),
              _field(agendaController, 'Agenda Points', maxLines: 2),
              _field(discussionController, 'Discussion Summary', maxLines: 3),
              _field(decisionController, 'Decisions Taken', maxLines: 2),

              _sectionTitle('Action Item'),
              _field(actionController, 'Action Description'),
              _field(responsibleController, 'Responsible Person'),
              _dateField('Due Date', dueDate, () => _pickDate(false)),

              DropdownButtonFormField<String>(
                value: actionStatus,
                items: ['Open', 'In Progress', 'Completed']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => actionStatus = v!),
                decoration: _inputDecoration('Action Status'),
              ),

              _sectionTitle('Approval'),
              _field(preparedByController, 'Prepared By'),
              _field(approvedByController, 'Approved By'),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _saveMoM,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Minutes of Meeting',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
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

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: _inputDecoration(label),
      ),
    );
  }

  Widget _dateField(String label, DateTime date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: _inputDecoration(label),
          child: Text(DateFormat('dd MMM yyyy').format(date)),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
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
