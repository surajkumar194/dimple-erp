import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MinutesOfMeetingScreen extends StatefulWidget {
  const MinutesOfMeetingScreen({super.key});

  @override
  State<MinutesOfMeetingScreen> createState() => _MinutesOfMeetingScreenState();
}

class _MinutesOfMeetingScreenState extends State<MinutesOfMeetingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController meetingTitleController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController chairpersonController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController attendeesController = TextEditingController();
  final TextEditingController absenteesController = TextEditingController();
  final TextEditingController agendaController = TextEditingController();
  final TextEditingController discussionController = TextEditingController();
  final TextEditingController decisionController = TextEditingController();
  final TextEditingController actionController = TextEditingController();
  final TextEditingController responsibleController = TextEditingController();
  final TextEditingController preparedByController = TextEditingController();
  final TextEditingController approvedByController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime meetingDate = DateTime.now();
  TimeOfDay meetingTime = TimeOfDay.now();
  DateTime dueDate = DateTime.now();
  String actionStatus = 'Open';
  String meetingType = 'Regular';
  String priority = 'Medium';
  bool isLoading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    meetingTitleController.dispose();
    departmentController.dispose();
    chairpersonController.dispose();
    locationController.dispose();
    attendeesController.dispose();
    absenteesController.dispose();
    agendaController.dispose();
    discussionController.dispose();
    decisionController.dispose();
    actionController.dispose();
    responsibleController.dispose();
    preparedByController.dispose();
    approvedByController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isMeeting) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isMeeting ? meetingDate : dueDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        isMeeting ? meetingDate = picked : dueDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: meetingTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => meetingTime = picked);
    }
  }

  Future<void> _saveMoM({bool asDraft = false}) async {
    if (!asDraft && !_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final docData = {
        'meetingTitle': meetingTitleController.text.trim(),
        'meetingDate': DateFormat('dd MMM yyyy').format(meetingDate),
        'meetingTime': meetingTime.format(context),
        'meetingType': meetingType,
        'department': departmentController.text.trim(),
        'chairperson': chairpersonController.text.trim(),
        'location': locationController.text.trim(),
        'attendees': attendeesController.text.trim(),
        'absentees': absenteesController.text.trim(),
        'agenda': agendaController.text.trim(),
        'discussion': discussionController.text.trim(),
        'decision': decisionController.text.trim(),
        'actionItem': actionController.text.trim(),
        'responsible': responsibleController.text.trim(),
        'dueDate': DateFormat('dd MMM yyyy').format(dueDate),
        'status': actionStatus,
        'priority': priority,
        'notes': notesController.text.trim(),
        'preparedBy': preparedByController.text.trim(),
        'approvedBy': approvedByController.text.trim(),
        'isDraft': asDraft,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('mom').add(docData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                asDraft ? Icons.drafts : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                asDraft
                    ? 'Draft Saved Successfully!'
                    : 'MoM Saved Successfully!',
              ),
            ],
          ),
          backgroundColor: asDraft ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.preview,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Meeting Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (meetingTitleController.text.isNotEmpty)
                      _previewItem(
                        'Meeting Title',
                        meetingTitleController.text,
                        Icons.title,
                      ),
                    _previewItem(
                      'Date',
                      DateFormat('dd MMM yyyy').format(meetingDate),
                      Icons.calendar_today,
                    ),
                    _previewItem(
                      'Time',
                      meetingTime.format(context),
                      Icons.access_time,
                    ),
                    _previewItem('Type', meetingType, Icons.category),
                    if (departmentController.text.isNotEmpty)
                      _previewItem(
                        'Department',
                        departmentController.text,
                        Icons.business,
                      ),
                    if (chairpersonController.text.isNotEmpty)
                      _previewItem(
                        'Chairperson',
                        chairpersonController.text,
                        Icons.person,
                      ),
                    if (locationController.text.isNotEmpty)
                      _previewItem(
                        'Location',
                        locationController.text,
                        Icons.place,
                      ),
                    if (attendeesController.text.isNotEmpty)
                      _previewItem(
                        'Attendees',
                        attendeesController.text,
                        Icons.people,
                      ),
                    if (absenteesController.text.isNotEmpty)
                      _previewItem(
                        'Absentees',
                        absenteesController.text,
                        Icons.person_off,
                      ),
                    if (agendaController.text.isNotEmpty)
                      _previewItem(
                        'Agenda',
                        agendaController.text,
                        Icons.list_alt,
                      ),
                    if (discussionController.text.isNotEmpty)
                      _previewItem(
                        'Discussion',
                        discussionController.text,
                        Icons.forum,
                      ),
                    if (decisionController.text.isNotEmpty)
                      _previewItem(
                        'Decisions',
                        decisionController.text,
                        Icons.gavel,
                      ),
                    if (actionController.text.isNotEmpty)
                      _previewItem(
                        'Action Item',
                        actionController.text,
                        Icons.assignment,
                      ),
                    if (responsibleController.text.isNotEmpty)
                      _previewItem(
                        'Responsible',
                        responsibleController.text,
                        Icons.person_pin,
                      ),
                    _previewItem(
                      'Due Date',
                      DateFormat('dd MMM yyyy').format(dueDate),
                      Icons.event,
                    ),
                    _previewItem('Priority', priority, Icons.flag),
                    _previewItem('Status', actionStatus, Icons.track_changes),
                    if (notesController.text.isNotEmpty)
                      _previewItem('Notes', notesController.text, Icons.note),
                    if (preparedByController.text.isNotEmpty)
                      _previewItem(
                        'Prepared By',
                        preparedByController.text,
                        Icons.edit,
                      ),
                    if (approvedByController.text.isNotEmpty)
                      _previewItem(
                        'Approved By',
                        approvedByController.text,
                        Icons.verified_user,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewItem(String label, String value, IconData icon) {
    if (value.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF667eea)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Minutes of Meeting',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview_outlined),
            tooltip: 'Preview',
            onPressed: _showPreview,
          ),
          IconButton(
            icon: const Icon(Icons.drafts_outlined),
            tooltip: 'Save as Draft',
            onPressed: () => _saveMoM(asDraft: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Details'),
            Tab(icon: Icon(Icons.people_outline, size: 20), text: 'People'),
            Tab(
              icon: Icon(Icons.assignment_outlined, size: 20),
              text: 'Content',
            ),
            Tab(icon: Icon(Icons.task_alt, size: 20), text: 'Actions'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(),
            _buildPeopleTab(),
            _buildContentTab(),
            _buildActionsTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => _saveMoM(asDraft: true),
                  icon: const Icon(Icons.drafts, size: 20),
                  label: const Text(
                    'Save Draft',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF667eea),
                    side: const BorderSide(
                      color: Color(0xFF667eea),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () => _saveMoM(asDraft: false),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle, size: 20),
                  label: Text(
                    isLoading ? 'Saving...' : 'Save & Submit',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
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

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            icon: Icons.title,
            title: 'Meeting Information',
            children: [
              _field(meetingTitleController, 'Meeting Title', Icons.subject),
              _dateTimeRow(),
              _dropdownField(
                'Meeting Type',
                meetingType,
                ['Regular', 'Emergency', 'Review', 'Planning', 'Other'],
                (v) => setState(() => meetingType = v!),
                Icons.category,
              ),
              _field(departmentController, 'Department', Icons.business),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.location_on,
            title: 'Venue Details',
            children: [
              _field(locationController, 'Location/Platform', Icons.place),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            icon: Icons.person,
            title: 'Organizer',
            children: [
              _field(
                chairpersonController,
                'Chairperson',
                Icons.person_outline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.people,
            title: 'Participants',
            children: [
              _field(
                attendeesController,
                'Attendees (comma separated)',
                Icons.people,
                maxLines: 3,
              ),
              _field(
                absenteesController,
                'Absentees (comma separated)',
                Icons.person_off,
                maxLines: 2,
                required: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.approval,
            title: 'Authorization',
            children: [
              _field(preparedByController, 'Prepared By', Icons.edit),
              _field(approvedByController, 'Approved By', Icons.verified_user),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            icon: Icons.list_alt,
            title: 'Agenda',
            children: [
              _field(
                agendaController,
                'Agenda Points',
                Icons.checklist,
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.forum,
            title: 'Discussion',
            children: [
              _field(
                discussionController,
                'Discussion Summary',
                Icons.chat,
                maxLines: 4,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.gavel,
            title: 'Decisions',
            children: [
              _field(
                decisionController,
                'Decisions Taken',
                Icons.done_all,
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            icon: Icons.note,
            title: 'Additional Notes',
            children: [
              _field(
                notesController,
                'Other Notes/Comments',
                Icons.notes,
                maxLines: 3,
                required: false,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            icon: Icons.assignment,
            title: 'Action Items',
            children: [
              _field(
                actionController,
                'Action Description',
                Icons.description,
                maxLines: 2,
              ),
              _field(
                responsibleController,
                'Responsible Person',
                Icons.person_pin,
              ),
              _dateField(
                'Due Date',
                dueDate,
                () => _pickDate(false),
                Icons.event,
              ),
              _dropdownField(
                'Priority',
                priority,
                ['Low', 'Medium', 'High', 'Critical'],
                (v) => setState(() => priority = v!),
                Icons.flag,
              ),
              _dropdownField(
                'Status',
                actionStatus,
                ['Open', 'In Progress', 'Completed', 'On Hold'],
                (v) => setState(() => actionStatus = v!),
                Icons.track_changes,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.1),
                  const Color(0xFF764ba2).withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _dateField(
            'Meeting Date',
            meetingDate,
            () => _pickDate(true),
            Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _inputDecoration('Time', Icons.access_time),
              child: Text(
                meetingTime.format(context),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: required
            ? (v) => v == null || v.trim().isEmpty
                  ? 'This field is required'
                  : null
            : null,
        decoration: _inputDecoration(label, icon),
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime date,
    VoidCallback onTap,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _inputDecoration(label, icon),
          child: Text(
            DateFormat('dd MMM yyyy').format(date),
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: _inputDecoration(label, icon),
        dropdownColor: Colors.white,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF667eea), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
