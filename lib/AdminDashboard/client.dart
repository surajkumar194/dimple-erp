import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/AdminDashboard/clienthistory.dart';
class ClientFormPage extends StatefulWidget {
  const ClientFormPage({super.key});
  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}
class _ClientFormPageState extends State<ClientFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  bool _isLoading = false;
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _successCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  Key _formKeyWidget = UniqueKey();

  final List<String> _clientNames = const [
    "Abhijit Sinha",
    "Komal Kalra",
    "Ajay Talwar",
    "Amarjit Singh",
    "Ashish",
    "Gunnet Singh",
    "Hardeep Singh",
    "Jagdish Chawla",
    "JAGDISH SURI JI",
    "Karan",
    "Krishna Arora",
    "Kuldeep Singh",
    "Neeraj Batta",
    "Prabhu Dayal",
    "Rajiv Markanda",
    "Raju",
    "Sanjeev Jain",
    "SUMEET TIARULA",
    "Sunny Kalra",
  ];

  // Color palette
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _primaryLight = Color(0xFF818CF8);
  static const Color _accent = Color(0xFF10B981);
  static const Color _surface = Color(0xFFF8F9FF);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF1E1B4B);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  String? _selectedClient;
  final _customerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  DateTime? _followUpDate;

  // NEW: existing customer names loaded from Firestore.
  // Stored lowercase for case-insensitive duplicate checking.
  Set<String> _existingCustomerNames = {};
  bool _loadingNames = true;

  // NEW: real-time duplicate flag, updated as user types (before submit)
  bool _isDuplicateName = false;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _successCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.easeInOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();

    _loadExistingCustomerNames();

    // NEW: listen to every keystroke in customer name field
    // and check for duplicates in real time, before submit.
    _customerCtrl.addListener(_checkDuplicateNameRealtime);
  }

  // NEW: called on every change of the customer name field.
  void _checkDuplicateNameRealtime() {
    final text = _customerCtrl.text.trim().toLowerCase();
    final isDup = text.isNotEmpty && _existingCustomerNames.contains(text);
    if (isDup != _isDuplicateName) {
      setState(() => _isDuplicateName = isDup);
    }
  }

  // NEW: fetch all existing customer names from Firestore,
  // dedupe + sort a-z (case-insensitive) using SplayTreeSet.
  Future<void> _loadExistingCustomerNames() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('followups')
          .get();

      final names = snapshot.docs
          .map((doc) => (doc.data()['customer'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty);

      final sortedSet = SplayTreeSet<String>(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      )..addAll(names);

      if (!mounted) return;
      setState(() {
        _existingCustomerNames = sortedSet.map((n) => n.toLowerCase()).toSet();
        _loadingNames = false;
      });
      // re-check whatever the user has already typed against the
      // freshly loaded name list
      _checkDuplicateNameRealtime();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingNames = false);
    }
  }

  @override
  void dispose() {
    _customerCtrl.removeListener(_checkDuplicateNameRealtime);
    _customerCtrl.dispose();
    _phoneCtrl.dispose();
    _descriptionCtrl.dispose();
    _problemCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? today,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
      selectableDayPredicate: (d) =>
          !DateTime(d.year, d.month, d.day).isBefore(today),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  void _onSave() async {
    setState(() => _submitted = true);

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields correctly', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'client': _selectedClient,
      'customer': _customerCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'followUpDate': _followUpDate != null
          ? Timestamp.fromDate(_followUpDate!)
          : null,
      'description': _descriptionCtrl.text.trim(),
      'problem': _problemCtrl.text.trim(),
      'followupCount': 1,
      'log': [
        {
          'date': _followUpDate != null
              ? Timestamp.fromDate(_followUpDate!)
              : Timestamp.now(),
          'createdAt': Timestamp.now(),
        },
      ],
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('followups').add(data);
      if (!mounted) return;

      // NEW: add the freshly saved name into our local set so it's
      // immediately blocked if the same user tries to add it again
      // in this session, without waiting for a fresh Firestore fetch.
      _existingCustomerNames.add(_customerCtrl.text.trim().toLowerCase());

      await _successCtrl.forward();
      await _successCtrl.reverse();

      FocusScope.of(context).unfocus();

      _customerCtrl.clear();
      _phoneCtrl.clear();
      _descriptionCtrl.clear();
      _problemCtrl.clear();

      setState(() {
        _selectedClient = null;
        _followUpDate = null;
        _submitted = false;
        _isLoading = false;
        _isDuplicateName = false;
        _formKeyWidget = UniqueKey();
      });

      _showSnackBar(
        'Customer saved successfully!',
        isError: false,
        action: SnackBarAction(
          label: 'VIEW HISTORY',
          textColor: Colors.white,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HistoryPage())),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showSnackBar('Error saving: $e', isError: true);
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: action,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: _textSecondary,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _primary, size: 18),
      ),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double width = constraints.maxWidth;

                double horizontalPadding;
                if (width > 1400) {
                  horizontalPadding = width * 0.2;
                } else if (width > 1000) {
                  horizontalPadding = width * 0.15;
                } else if (width > 700) {
                  horizontalPadding = width * 0.08;
                } else {
                  horizontalPadding = 16;
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildFormCard()],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(65),
      child: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Image.asset('assets/dpl.png', height: 32),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Add Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Create new customer record',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
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

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: KeyedSubtree(key: _formKeyWidget, child: _buildFormFields()),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Basic Information', Icons.info_outline_rounded),
        const SizedBox(height: 16),

        // Sales Person Dropdown
        DropdownButtonFormField<String>(
          value: _selectedClient,
          decoration: _inputDecoration(
            label: 'Sales Person',
            icon: Icons.badge_outlined,
          ),
          items: _clientNames
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedClient = val),
          validator: (v) => v == null ? 'Please select a sales person' : null,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
        ),
        const SizedBox(height: 16),

        // Customer Name (with real-time + submit-time duplicate check)
        TextFormField(
          controller: _customerCtrl,
          decoration:
              _inputDecoration(
                label: 'Customer Name',
                icon: Icons.person_outline_rounded,
                hint: _loadingNames
                    ? 'Loading existing customers...'
                    : 'Enter customer full name',
              ).copyWith(
                // NEW: show a live "already exists" hint under the field
                // as soon as the typed name matches an existing one,
                // even before the user taps Save.
                helperText: _isDuplicateName
                    ? 'This customer already exists'
                    : null,
                helperStyle: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                suffixIcon: _isDuplicateName
                    ? const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFEF4444),
                      )
                    : null,
              ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
          // Validator still runs as a final safety check on Save.
          validator: (v) {
            final text = (v ?? '').trim();
            if (text.isEmpty) return 'Please enter a customer name';
            if (_existingCustomerNames.contains(text.toLowerCase())) {
              return 'This customer already exists';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Phone Number
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: _inputDecoration(
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            hint: '10-digit mobile number',
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
          validator: (v) {
            final text = (v ?? '').trim();
            if (text.isEmpty) return 'Phone is required';
            if (text.length != 10) return 'Enter a valid 10-digit number';
            return null;
          },
        ),
        const SizedBox(height: 28),

        _sectionTitle('Follow-up Details', Icons.schedule_rounded),
        const SizedBox(height: 16),

        // Follow-up Date Picker
        FormField<DateTime>(
          validator: (_) =>
              _followUpDate == null ? 'Please select a follow-up date' : null,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: state.hasError
                          ? const Color(0xFFEF4444)
                          : _followUpDate != null
                          ? _primary
                          : _border,
                      width: state.hasError || _followUpDate != null ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: _primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Follow-up Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _followUpDate == null
                                  ? 'Tap to select date'
                                  : _formatDate(_followUpDate!),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _followUpDate == null
                                    ? _textSecondary.withOpacity(0.6)
                                    : _textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _followUpDate != null
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_ios_rounded,
                        color: _followUpDate != null ? _accent : _textSecondary,
                        size: _followUpDate != null ? 20 : 16,
                      ),
                    ],
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 6),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        _sectionTitle('Additional Notes', Icons.notes_rounded),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionCtrl,
          maxLines: 4,
          decoration:
              _inputDecoration(
                label: 'Description',
                icon: Icons.description_outlined,
                hint: 'Enter product/service description...',
              ).copyWith(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 60,
                    left: 12,
                    right: 12,
                    top: 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: _primary,
                      size: 18,
                    ),
                  ),
                ),
                alignLabelWithHint: true,
              ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: _textPrimary,
            height: 1.5,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter a description'
              : null,
        ),
        const SizedBox(height: 16),

        // Problem
        TextFormField(
          controller: _problemCtrl,
          maxLines: 4,
          decoration:
              _inputDecoration(
                label: 'Problem / Issue',
                icon: Icons.report_problem_outlined,
                hint: 'Describe the customer\'s problem...',
              ).copyWith(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 60,
                    left: 12,
                    right: 12,
                    top: 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.report_problem_outlined,
                      color: Colors.orange,
                      size: 18,
                    ),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
                alignLabelWithHint: true,
              ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: _textPrimary,
            height: 1.5,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please describe the problem'
              : null,
        ),

        const SizedBox(height: 32),

        // Save Button
        _buildSaveButton(),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isLoading
            ? null
            : const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: _isLoading ? const Color(0xFFE5E7EB) : null,
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: _primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _onSave,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Saving...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Save Customer Record',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}
