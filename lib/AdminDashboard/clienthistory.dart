import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

enum TimeFilter { all, today, thisWeek, thisMonth, custom }

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  bool _showAll = true;
  String? _selectedClient;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  TimeFilter _timeFilter = TimeFilter.all;
  DateTimeRange? _customRange;
  String? _selectedAlphabet;
  bool _filtersExpanded = false;

  // Track which cards are expanded — key = docId
  final Set<String> _expandedCards = {};

  // Color palette
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _accent = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _surface = Color(0xFFF8F9FF);
  static const Color _textPrimary = Color(0xFF1E1B4B);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  final List<String> _clientNames = const [
    "Abhijit Sinha",
    "Komal Kalra",
    "Ajay Talwar",
    "Amarjit Singh",
    "Ashish",
    "Gunnet Singh",
    "Hardeep Singh",
    "Jagdish Chawla",
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';

  String _monthName(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[m - 1];
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  DateTimeRange? _resolveRange() {
    final now = DateTime.now();
    switch (_timeFilter) {
      case TimeFilter.all:
        return null;
      case TimeFilter.today:
        return DateTimeRange(
            start: _startOfDay(now), end: _endOfDay(now));
      case TimeFilter.thisWeek:
        final start =
            _startOfDay(now.subtract(Duration(days: now.weekday - 1)));
        final end = _endOfDay(start.add(const Duration(days: 6)));
        return DateTimeRange(start: start, end: end);
      case TimeFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = _endOfDay(DateTime(now.year, now.month + 1, 0));
        return DateTimeRange(start: start, end: end);
      case TimeFilter.custom:
        return _customRange;
    }
  }

  DateTime? _latestFollowupDate(Map<String, dynamic> d) {
    final List<dynamic> log = (d['log'] as List?) ?? [];
    if (log.isNotEmpty) {
      final ts = (log.last as Map)['date'] as Timestamp?;
      if (ts != null) return ts.toDate();
    }
    final fu = d['followUpDate'] as Timestamp?;
    if (fu != null) return fu.toDate();
    final ca = d['createdAt'] as Timestamp?;
    return ca?.toDate();
  }

  Future<void> _addNextFollowup(String docId, Map<String, dynamic> d) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final int currentCount = (d['followupCount'] as int?) ?? 1;
    await FirebaseFirestore.instance.collection('followups').doc(docId).update({
      'log': FieldValue.arrayUnion([{
        'date': Timestamp.fromDate(picked),
        'createdAt': Timestamp.now(),
      }]),
      'followUpDate': Timestamp.fromDate(picked),
      'followupCount': currentCount + 1,
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;
    _showSnackBar('Follow-up set for ${_fmt(picked)} 📅');
  }

  Future<void> _editLatestDate(String docId) async {
    final snap = await FirebaseFirestore.instance
        .collection('followups')
        .doc(docId)
        .get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final List<dynamic> log = (data['log'] as List?) ?? [];
    if (log.isEmpty) return;

    final latest = Map<String, dynamic>.from(log.last as Map);
    final currentDate = (latest['date'] as Timestamp?)?.toDate();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? today,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final newLog = List<Map<String, dynamic>>.from(
        log.map((e) => Map<String, dynamic>.from(e as Map)));
    newLog[newLog.length - 1] = {
      ...latest,
      'date': Timestamp.fromDate(picked)
    };

    await FirebaseFirestore.instance.collection('followups').doc(docId).update({
      'log': newLog,
      'followUpDate': Timestamp.fromDate(picked),
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;
    _showSnackBar('Date updated to ${_fmt(picked)} ✨');
  }

  Future<void> _deleteDoc(String docId) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;
    await FirebaseFirestore.instance.collection('followups').doc(docId).delete();
    if (!mounted) return;
    _expandedCards.remove(docId);
    _showSnackBar('Record deleted successfully 🗑️', isError: true);
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _danger.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: _danger, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Delete Record',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone. The customer record will be permanently removed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: _border),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _danger,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Delete',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: isError ? _danger : _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _editTextField(
      String docId, String field, String currentValue, String title,
      {Color accentColor = _primary}) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      field == 'description'
                          ? Icons.description_outlined
                          : Icons.report_problem_outlined,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 5,
                autofocus: true,
                style: const TextStyle(fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Enter ${title.toLowerCase()}...',
                  hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
                  filled: true,
                  fillColor: _surface,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: _border),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result != currentValue) {
      await FirebaseFirestore.instance
          .collection('followups')
          .doc(docId)
          .update({field: result, 'createdAt': Timestamp.now()});
      _showSnackBar('$title updated successfully ✨');
    }
  }

  @override
  Widget build(BuildContext context) {
    final allStream = FirebaseFirestore.instance
        .collection('followups')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final filteredStream = FirebaseFirestore.instance
        .collection('followups')
        .where('client', isEqualTo: _selectedClient)
        .snapshots();

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildFilterPanel(),
            Expanded(
              child: _showAll
                  ? _buildAllList(allStream)
                  : (_selectedClient == null
                      ? _buildEmptyState()
                      : _buildFilteredList(filteredStream)),
            ),
          ],
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
              colors: [
                Color(0xFF4F46E5),
                Color(0xFF7C3AED),
                Color(0xFF0EA5E9)
              ],
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
                    border:
                        Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Image.asset('assets/dpl.png', height: 32),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Customer History',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                            color: Colors.white,
                            letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('View & manage all records',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTabButton('All Customers', Icons.people_outline, _showAll,
                      () => setState(() {
                            _showAll = true;
                            _selectedClient = null;
                          })),
                  _buildTabButton(
                      'By Sales Person', Icons.person_search_outlined, !_showAll,
                      () => setState(() => _showAll = false)),
                ],
              ),
            ),
          ),

          InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: _primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('Advanced Filters',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary)),
                  const Spacer(),
                  _buildActiveFiltersCount(),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _filtersExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary, size: 20),
                  ),
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _filtersExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        _buildFilterRow(
                          icon: Icons.access_time_rounded,
                          label: 'Time Period',
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<TimeFilter>(
                              value: _timeFilter,
                              isDense: true,
                              style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: _primary, size: 18),
                              items: const [
                                DropdownMenuItem(
                                    value: TimeFilter.all,
                                    child: Text('All Dates')),
                                DropdownMenuItem(
                                    value: TimeFilter.today,
                                    child: Text('Today')),
                                DropdownMenuItem(
                                    value: TimeFilter.thisWeek,
                                    child: Text('This Week')),
                                DropdownMenuItem(
                                    value: TimeFilter.thisMonth,
                                    child: Text('This Month')),
                                DropdownMenuItem(
                                    value: TimeFilter.custom,
                                    child: Text('Custom Range')),
                              ],
                              onChanged: (v) async {
                                if (v == null) return;
                                if (v == TimeFilter.custom) {
                                  final now = DateTime.now();
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(now.year - 2),
                                    lastDate: DateTime(now.year + 2),
                                    initialDateRange: _customRange ??
                                        DateTimeRange(
                                          start: now.subtract(
                                              const Duration(days: 7)),
                                          end: now,
                                        ),
                                    builder: (context, child) => Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme:
                                            const ColorScheme.light(
                                          primary: _primary,
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (picked == null) return;
                                  setState(() {
                                    _timeFilter = v;
                                    _customRange = DateTimeRange(
                                      start: _startOfDay(picked.start),
                                      end: _endOfDay(picked.end),
                                    );
                                  });
                                } else {
                                  setState(() => _timeFilter = v);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildFilterRow(
                          icon: Icons.sort_by_alpha_rounded,
                          label: 'Name Filter',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedAlphabet,
                                  isDense: true,
                                  style: const TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: _primary, size: 18),
                                  hint: const Text('All Names',
                                      style: TextStyle(
                                          color: _textSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('All Names')),
                                    ...List.generate(
                                      26,
                                      (i) {
                                        final l = String.fromCharCode(65 + i);
                                        return DropdownMenuItem<String?>(
                                            value: l, child: Text(l));
                                      },
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedAlphabet = v),
                                ),
                              ),
                              if (_selectedAlphabet != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedAlphabet = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _danger.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        size: 14, color: _danger),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!_showAll) ...[
                          const SizedBox(height: 10),
                          _buildFilterRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Sales Person',
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedClient,
                                isDense: true,
                                hint: const Text('Select...',
                                    style: TextStyle(
                                        color: _textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                style: const TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: _primary, size: 18),
                                items: _clientNames
                                    .map((c) => DropdownMenuItem(
                                        value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedClient = v),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          Container(height: 1, color: _border),
        ],
      ),
    );
  }

  Widget _buildTabButton(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: _primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : _textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(
      {required IconData icon,
      required String label,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary)),
          const Spacer(),
          child,
        ],
      ),
    );
  }

  Widget _buildActiveFiltersCount() {
    int count = 0;
    if (_timeFilter != TimeFilter.all) count++;
    if (_selectedAlphabet != null) count++;
    if (!_showAll && _selectedClient != null) count++;

    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count active',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilters(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final range = _resolveRange();
    var filtered = range == null
        ? docs
        : docs.where((doc) {
            final dt = _latestFollowupDate(doc.data());
            if (dt == null) return false;
            return !dt.isBefore(range.start) && !dt.isAfter(range.end);
          }).toList();

    if (_selectedAlphabet != null) {
      filtered = filtered.where((doc) {
        final customer = (doc.data()['customer'] as String? ?? '').trim();
        if (customer.isEmpty) return false;
        return customer[0].toUpperCase() == _selectedAlphabet;
      }).toList();
    }
    return filtered;
  }

  Widget _buildAllList(Stream<QuerySnapshot<Map<String, dynamic>>> stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snap.hasError) {
          return _buildErrorState('${snap.error}');
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _buildNoDataState();

        final filtered = _applyFilters(docs);
        if (filtered.isEmpty) {
          return _buildNoDataState(
            message: _selectedAlphabet != null
                ? 'No customers starting with "$_selectedAlphabet"'
                : 'No records in this period',
          );
        }

        return _historyListView(filtered);
      },
    );
  }

  Widget _buildFilteredList(Stream<QuerySnapshot<Map<String, dynamic>>> stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snap.hasError) {
          return _buildErrorState('${snap.error}');
        }
        final raw = snap.data?.docs ?? [];
        if (raw.isEmpty) {
          return _buildNoDataState(message: 'No records for this client');
        }

        final sorted = [...raw]
          ..sort((a, b) {
            final ta = a.data()['createdAt'] as Timestamp?;
            final tb = b.data()['createdAt'] as Timestamp?;
            return (tb?.toDate() ?? DateTime(0))
                .compareTo(ta?.toDate() ?? DateTime(0));
          });

        final filtered = _applyFilters(sorted);
        if (filtered.isEmpty) {
          return _buildNoDataState(
            message: _selectedAlphabet != null
                ? 'No customers starting with "$_selectedAlphabet"'
                : 'No records in this period',
          );
        }
        return _historyListView(filtered);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: const CircularProgressIndicator(
              color: _primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Loading records...',
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search_rounded,
                  size: 48, color: _primary),
            ),
            const SizedBox(height: 20),
            const Text('Select a Sales Person',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            const Text(
                'Use the filter above to select a specific sales person and view their records.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 48, color: _danger),
            ),
            const SizedBox(height: 20),
            const Text('Something went wrong',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: _textSecondary, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState({String message = 'No records found'}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined,
                  size: 48, color: _textSecondary),
            ),
            const SizedBox(height: 20),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            const Text('Try adjusting your filters',
                style: TextStyle(fontSize: 13, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _historyListView(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final doc = docs[i];
        final d = doc.data();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCustomerCard(doc.id, d),
        );
      },
    );
  }

  // ─── MAIN CARD — collapsed header + animated body ───────────────────────────
  Widget _buildCustomerCard(String docId, Map<String, dynamic> d) {
    final client = d['client'] as String? ?? '-';
    final customer = d['customer'] as String? ?? '-';
    final phone = d['phone'] as String? ?? '-';
    final desc = d['description'] as String? ?? '';
    final problem = d['problem'] as String? ?? '';
    final fuCount = (d['followupCount'] as int?) ?? 1;
    final List<dynamic> log = (d['log'] as List?) ?? [];

    DateTime? latestDate;
    if (log.isNotEmpty) {
      latestDate = ((log.last as Map)['date'] as Timestamp?) != null
          ? ((log.last as Map)['date'] as Timestamp).toDate()
          : null;
    }

    final isOverdue =
        latestDate != null && latestDate.isBefore(DateTime.now());
    final isToday =
        latestDate != null && DateUtils.isSameDay(latestDate, DateTime.now());

    final isExpanded = _expandedCards.contains(docId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue && !isToday
              ? _danger.withOpacity(0.3)
              : isToday
                  ? _warning.withOpacity(0.4)
                  : _border,
          width: isOverdue || isToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── HEADER (always visible) — tap to expand/collapse ──────────────
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedCards.remove(docId);
              } else {
                _expandedCards.add(docId);
              }
            }),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: isExpanded ? Radius.zero : const Radius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primary.withOpacity(0.05),
                    _primary.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        customer.isNotEmpty ? customer[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + sales person badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(client,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primary)),
                            ),
                            // Show date chip in collapsed state
                            if (!isExpanded && latestDate != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isOverdue && !isToday
                                          ? _danger
                                          : isToday
                                              ? _warning
                                              : _accent)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _fmt(latestDate),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOverdue && !isToday
                                          ? _danger
                                          : isToday
                                              ? _warning
                                              : _accent),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Follow-up count badge
                  _buildFollowupBadge(fuCount),
                  const SizedBox(width: 10),

                  // Expand / collapse arrow
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BODY (shown only when expanded) ──────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Phone + date chips
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoChip(Icons.phone_rounded, phone,
                                  const Color(0xFF0EA5E9)),
                            ),
                            const SizedBox(width: 10),
                            if (latestDate != null)
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.event_rounded,
                                  _fmt(latestDate),
                                  isOverdue && !isToday
                                      ? _danger
                                      : isToday
                                          ? _warning
                                          : _accent,
                                ),
                              ),
                          ],
                        ),

                        // Overdue / today banners
                        if (isOverdue && !isToday) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: _danger.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded,
                                    color: _danger, size: 16),
                                SizedBox(width: 8),
                                Text('Follow-up overdue!',
                                    style: TextStyle(
                                        color: _danger,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                        if (isToday) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _warning.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _warning.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.today_rounded,
                                    color: _warning, size: 16),
                                SizedBox(width: 8),
                                Text('Follow-up due today!',
                                    style: TextStyle(
                                        color: _warning,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],

                        // Description
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildTextSection(
                            icon: Icons.description_outlined,
                            title: 'Description',
                            content: desc,
                            color: _primary,
                            onEdit: () => _editTextField(
                                docId, 'description', desc, 'Description',
                                accentColor: _primary),
                          ),
                        ],

                        // Problem
                        if (problem.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildTextSection(
                            icon: Icons.report_problem_outlined,
                            title: 'Problem',
                            content: problem,
                            color: _warning,
                            onEdit: () => _editTextField(
                                docId, 'problem', problem, 'Problem',
                                accentColor: _warning),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildActionButton(
                                label: 'Add Follow-up',
                                icon: Icons.add_circle_outline_rounded,
                                color: _accent,
                                onTap: () => _addNextFollowup(docId, d),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(
                                Icons.edit_calendar_rounded,
                                const Color(0xFF0EA5E9),
                                () => _editLatestDate(docId)),
                            const SizedBox(width: 8),
                            _buildIconButton(Icons.delete_outline_rounded,
                                _danger, () => _deleteDoc(docId)),
                          ],
                        ),

                        // Timeline
                        if (log.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildTimeline(log),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowupBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withOpacity(0.15),
            _accent.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$count',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                  height: 1)),
          const Text('follow-ups',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _accent)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.3)),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_outlined, size: 14, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(
                  fontSize: 13, color: _textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildTimeline(List<dynamic> log) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: _primary, size: 18),
              const SizedBox(width: 8),
              const Text('Follow-up Timeline',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${log.length} entries',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(log.length, (idx) {
            final item = Map<String, dynamic>.from(log[idx] as Map);
            final dt = (item['date'] as Timestamp?)?.toDate();
            final crt = (item['createdAt'] as Timestamp?)?.toDate();
            final isLatest = idx == log.length - 1;
            final isFirst = idx == 0;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isLatest
                                ? _accent
                                : _primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLatest
                                  ? _accent
                                  : _primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isLatest
                                ? Icons.schedule_rounded
                                : Icons.check_rounded,
                            color: isLatest ? Colors.white : _primary,
                            size: 14,
                          ),
                        ),
                        if (!isFirst || log.length > 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin:
                                  const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _primary.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: idx < log.length - 1 ? 12 : 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isLatest
                              ? _accent.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isLatest
                                ? _accent.withOpacity(0.3)
                                : _border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dt != null
                                        ? _fmt(dt)
                                        : 'Invalid Date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isLatest
                                          ? _accent
                                          : _textPrimary,
                                    ),
                                  ),
                                  if (crt != null) ...[
                                    const SizedBox(height: 2),
                                    Text('Added ${_fmt(crt)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: _textSecondary)),
                                  ],
                                ],
                              ),
                            ),
                            if (isLatest)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('NEXT',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}