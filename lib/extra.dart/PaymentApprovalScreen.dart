import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PaymentApprovalScreen extends StatefulWidget {
  const PaymentApprovalScreen({super.key});

  @override
  State<PaymentApprovalScreen> createState() => _PaymentApprovalScreenState();
}

class _PaymentApprovalScreenState extends State<PaymentApprovalScreen>
    with TickerProviderStateMixin {
  String _statusFilter = 'All';
  String _dateFilter = 'All';
  DateTimeRange? _customRange;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      final labels = ['All', 'Pending', 'Approved', 'Declined'];
      if (!_tabCtrl.indexIsChanging) return;
      setState(() => _statusFilter = labels[_tabCtrl.index]);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _passesDateFilter(dynamic createdAt) {
    if (_dateFilter == 'All') return true;
    DateTime? dt;
    if (createdAt is Timestamp) {
      dt = createdAt.toDate();
    } else {
      return true;
    }
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'Today':
        return dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day;
      case 'Week':
        return dt.isAfter(now.subtract(const Duration(days: 7)));
      case 'Month':
        return dt.year == now.year && dt.month == now.month;
      case 'Custom':
        if (_customRange == null) return true;
        final start = _customRange!.start;
        final end = _customRange!.end.add(const Duration(days: 1));
        return dt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            dt.isBefore(end);
      default:
        return true;
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.purple.shade600,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _dateFilter = 'Custom';
      });
    }
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('payments').doc(docId).update({
      'approvalStatus': status,
      'approvedAt': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
    });
  }

  void _showConfirmDialog(
    String docId,
    Map<String, dynamic> data,
    bool approve,
  ) {
    final animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => ScaleTransition(
        scale: CurvedAnimation(parent: animCtrl, curve: Curves.easeOutBack),
        child: _ConfirmDialog(
          approve: approve,
          data: data,
          onConfirm: () async {
            await _updateStatus(docId, approve ? 'Approved' : 'Declined');
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  String _fmt(double v) => NumberFormat('#,##,###').format(v.toInt());

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('payments').snapshots(),
          builder: (context, snapshot) {
            // ── Compute stats once for both header & list ──────────────────
            double totalAmount = 0;
            double approvedAmount = 0;
            double pendingAmount = 0;
            double declinedAmount = 0;
            int pendingCount = 0;
            int approvedCount = 0;
            int declinedCount = 0;

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                if (!_passesDateFilter(d['createdAt'])) continue;
                final amt = (d['finalAmount'] ?? 0).toDouble();
                totalAmount += amt;
                final status = d['approvalStatus'] ?? 'Pending';
                if (status == 'Approved') {
                  approvedAmount += amt;
                  approvedCount++;
                } else if (status == 'Declined') {
                  declinedAmount += amt;
                  declinedCount++;
                } else {
                  pendingAmount += amt;
                  pendingCount++;
                }
              }
            }

            return Column(
              children: [
                // ── Compact Header ─────────────────────────────────────────
                _buildCompactHeader(
                  totalAmount: totalAmount,
                  pendingCount: pendingCount,
                  pendingAmount: pendingAmount,
                  approvedCount: approvedCount,
                  approvedAmount: approvedAmount,
                  declinedCount: declinedCount,
                  declinedAmount: declinedAmount,
                ),
                // ── Date Filter ────────────────────────────────────────────
                _buildDateFilterRow(),
                // ── Tab Bar ────────────────────────────────────────────────
                _buildTabBar(),
                // ── Search Bar ─────────────────────────────────────────────
                _buildSearchBar(),
                // ── List (takes all remaining space) ──────────────────────
                Expanded(child: _buildPaymentList(snapshot)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── COMPACT HEADER ──────────────────────────────────────────────────────────
  Widget _buildCompactHeader({
    required double totalAmount,
    required int pendingCount,
    required double pendingAmount,
    required int approvedCount,
    required double approvedAmount,
    required int declinedCount,
    required double declinedAmount,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top bar: back + title + total ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Logo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Image.asset('assets/dpl.png', height: 18),
                  ),
                  const SizedBox(width: 8),
                  // Title
                  const Expanded(
                    child: Text(
                      'Payment Approvals',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Total pill — ONLY final total shown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.currency_rupee,
                          color: Colors.white70,
                          size: 11,
                        ),
                        Text(
                          _fmt(totalAmount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Stats row ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _StatCell(
                      label: 'Pending',
                      count: pendingCount,
                      amount: pendingAmount,
                      color: const Color(0xFFF97316),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: Colors.white.withOpacity(0.15),
                      indent: 6,
                      endIndent: 6,
                    ),
                    _StatCell(
                      label: 'Approved',
                      count: approvedCount,
                      amount: approvedAmount,
                      color: const Color(0xFF22C55E),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: Colors.white.withOpacity(0.15),
                      indent: 6,
                      endIndent: 6,
                    ),
                    _StatCell(
                      label: 'Declined',
                      count: declinedCount,
                      amount: declinedAmount,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DATE FILTER ROW ─────────────────────────────────────────────────────────
  Widget _buildDateFilterRow() {
    final filters = ['All', 'Today', 'Week', 'Month', 'Custom'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: filters.map((f) {
          final selected = _dateFilter == f;
          return GestureDetector(
            onTap: () {
              if (f == 'Custom') {
                _pickCustomRange();
              } else {
                setState(() => _dateFilter = f);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                      )
                    : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? Colors.transparent : Colors.grey.shade300,
                  width: 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  if (f == 'Custom') ...[
                    Icon(
                      Icons.date_range_rounded,
                      size: 11,
                      color: selected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    f == 'Custom' && _customRange != null
                        ? '${DateFormat('dd MMM').format(_customRange!.start)} - ${DateFormat('dd MMM').format(_customRange!.end)}'
                        : f,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── TAB BAR ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(3),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Approved'),
          Tab(text: 'Declined'),
        ],
      ),
    );
  }

  // ── SEARCH BAR ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search by order no or customer...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 0,
            ),
          ),
        ),
      ),
    );
  }

  // ── PAYMENT LIST ─────────────────────────────────────────────────────────────
  Widget _buildPaymentList(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
              ).createShader(b),
              child: const Text(
                'Loading Payments...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    var docs = snapshot.data!.docs;

    // ── Firestore ordering already applied; apply local filters ──────────
    if (_statusFilter != 'All') {
      docs = docs.where((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return (d['approvalStatus'] ?? 'Pending') == _statusFilter;
      }).toList();
    }

    docs = docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return _passesDateFilter(d['createdAt']);
    }).toList();

    if (_searchQuery.isNotEmpty) {
      docs = docs.where((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final orderNo = (d['salesOrderNo'] ?? '').toString().toLowerCase();
        final customer = (d['customerName'] ?? '').toString().toLowerCase();
        return orderNo.contains(_searchQuery) ||
            customer.contains(_searchQuery);
      }).toList();
    }

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade100.withOpacity(0.4),
                    Colors.blue.shade100.withOpacity(0.4),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                color: Colors.grey.shade400,
                size: 44,
              ),
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
              ).createShader(b),
              child: const Text(
                'No Payments Found',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust filters or search query',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        return _PaymentApprovalCard(
          docId: doc.id,
          data: data,
          onApprove: () => _showConfirmDialog(doc.id, data, true),
          onDecline: () => _showConfirmDialog(doc.id, data, false),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAT CELL
// ═══════════════════════════════════════════════════════════════════════════════
class _StatCell extends StatelessWidget {
  final String label;
  final int count;
  final double amount;
  final Color color;

  const _StatCell({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            Text(
              '₹${NumberFormat('#,##,###').format(amount.toInt())}',
              style: const TextStyle(fontSize: 9, color: Colors.white60),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAYMENT APPROVAL CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _PaymentApprovalCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  const _PaymentApprovalCard({
    required this.docId,
    required this.data,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  State<_PaymentApprovalCard> createState() => _PaymentApprovalCardState();
}

class _PaymentApprovalCardState extends State<_PaymentApprovalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final customer = d['customerName'] ?? '';
    final orderNo = d['salesOrderNo'] ?? '';
    final location = d['location'] ?? 'N/A';
    final advance = (d['advanceAmount'] ?? 0).toDouble();
    final extra = (d['extraAmount'] ?? 0).toDouble();
    final finalAmount = (d['finalAmount'] ?? 0).toDouble();
    final amount = (d['amount'] ?? 0).toDouble();
    final receivedBy = d['receivedBy'] ?? '';
    final receivedAt = d['receivedAt'] ?? '';
    final approvedAt = d['approvedAt'] ?? '';
    final status = d['approvalStatus'] ?? 'Pending';

    List<Color> statusColors;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'Approved':
        statusColors = [const Color(0xFF22C55E), const Color(0xFF15803D)];
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Approved';
        break;
      case 'Declined':
        statusColors = [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Declined';
        break;
      default:
        statusColors = [const Color(0xFFF97316), const Color(0xFFEA580C)];
        statusIcon = Icons.hourglass_empty_rounded;
        statusLabel = 'Pending';
    }

    final isPending = status == 'Pending';
    final isApproved = status == 'Approved';

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top Row ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          customer.isNotEmpty ? customer[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    // Name + order + location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_outlined,
                                color: Colors.grey.shade500,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                orderNo,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey.shade500,
                                size: 10,
                              ),
                              const SizedBox(width: 1),
                              Flexible(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: statusColors),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: statusColors[0].withOpacity(0.35),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 9),
                          const SizedBox(width: 2),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info Row ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount block
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Amount Received',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Final: ₹${finalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Advance: ₹${advance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            'Amount: ₹${amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            'Extra: ₹${extra.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Received block
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE9D5FF),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7C3AED),
                                        Color(0xFF2563EB),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white,
                                    size: 9,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    receivedBy,
                                    style: const TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              receivedAt,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 9,
                              ),
                            ),
                            if (approvedAt.isNotEmpty && !isPending) ...[
                              const SizedBox(height: 3),
                              Text(
                                '${isApproved ? '✓ Approved' : '✗ Declined'}: $approvedAt',
                                style: TextStyle(
                                  color: statusColors[0],
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Divider ──────────────────────────────────────────────────
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.shade300,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // ── Action Buttons ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Decline
                    Expanded(
                      child: GestureDetector(
                        onTap: isPending ? widget.onDecline : null,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: isPending
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFF87171),
                                      Color(0xFFDC2626),
                                    ],
                                  )
                                : null,
                            color: isPending ? null : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isPending
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                color: isPending
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status == 'Declined' ? 'Declined' : 'Decline',
                                style: TextStyle(
                                  color: isPending
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    // Approve
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: isPending ? widget.onApprove : null,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: isPending
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFF2563EB),
                                      Color(0xFF0D9488),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: isPending ? null : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isPending
                                ? [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: isPending
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status == 'Approved' ? 'Approved ✓' : 'Approve',
                                style: TextStyle(
                                  color: isPending
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIRM DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _ConfirmDialog extends StatefulWidget {
  final bool approve;
  final Map<String, dynamic> data;
  final Future<void> Function() onConfirm;

  const _ConfirmDialog({
    required this.approve,
    required this.data,
    required this.onConfirm,
  });

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isApprove = widget.approve;
    final colors = isApprove
        ? [const Color(0xFF22C55E), const Color(0xFF15803D)]
        : [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
    final amount = (widget.data['amount'] ?? 0).toDouble();
    final customer = widget.data['customerName'] ?? '';
    final orderNo = widget.data['salesOrderNo'] ?? '';
    final receivedBy = widget.data['receivedBy'] ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isApprove
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (b) =>
                    LinearGradient(colors: colors).createShader(b),
                child: Text(
                  isApprove ? 'Approve Payment?' : 'Decline Payment?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$customer · $orderNo',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Amount',
                      value:
                          '₹${NumberFormat('#,##,###').format(amount.toInt())}',
                      valueColor: colors[0],
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(label: 'Received By', value: receivedBy),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'Action Time',
                      value: DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(DateTime.now()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _loading
                          ? null
                          : () async {
                              setState(() => _loading = true);
                              await widget.onConfirm();
                              if (mounted) setState(() => _loading = false);
                            },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _loading
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : colors,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _loading
                              ? []
                              : [
                                  BoxShadow(
                                    color: colors[0].withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  isApprove ? 'Yes, Approve' : 'Yes, Decline',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.grey.shade800,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
