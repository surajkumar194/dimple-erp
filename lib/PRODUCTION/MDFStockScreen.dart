import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
enum DateFilter { all, today, week, month, custom }
enum StatusFilter { all, pending, approved, delivered }
class MDFCommonScreen extends StatefulWidget {
  const MDFCommonScreen({super.key});

  @override
  State<MDFCommonScreen> createState() => _MDFCommonScreenState();
}

class _MDFCommonScreenState extends State<MDFCommonScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  DateFilter _selectedFilter = DateFilter.all;
  StatusFilter _statusFilter = StatusFilter.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  final Map<String, Map<String, dynamic>> _customerCache = {};
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(
          () => _searchQuery = _searchCtrl.text.toLowerCase().trim()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getCustomer(String orderId) async {
    if (_customerCache.containsKey(orderId))
      return _customerCache[orderId]!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      final data = doc.data() ?? {};
      _customerCache[orderId] = data;
      return data;
    } catch (_) {
      return {};
    }
  }

  DateTime? get _filterStart {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DateFilter.week:
        return now.subtract(const Duration(days: 7));
      case DateFilter.month:
        return now.subtract(const Duration(days: 30));
      case DateFilter.custom:
        return _customStart;
      default:
        return null;
    }
  }

  DateTime? get _filterEnd =>
      _selectedFilter == DateFilter.custom ? _customEnd : null;

  List<QueryDocumentSnapshot> _applyFilters(
      List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // ── Status filter ────────────────────────────────────────
      final deliveryStatus = data['deliveryStatus'] ?? '';
      final isDelivered = deliveryStatus == 'DELIVERED';
      final statusHistory = data['statusHistory'] ?? '';
      final isApproved = statusHistory == 'APPROVED';

      if (_statusFilter == StatusFilter.pending && (isApproved || isDelivered))
        return false;
      if (_statusFilter == StatusFilter.approved &&
          (!isApproved || isDelivered)) return false;
      if (_statusFilter == StatusFilter.delivered && !isDelivered)
        return false;

      // ── Search filter ────────────────────────────────────────
      if (_searchQuery.isNotEmpty) {
        final orderId =
            (data['orderId'] ?? '').toString().toLowerCase();
        final custName =
            (data['customerName'] ?? '').toString().toLowerCase();
        final custPhone =
            (data['customerPhone'] ?? '').toString().toLowerCase();
        final custAddress =
            (data['customerAddress'] ?? '').toString().toLowerCase();
        if (!orderId.contains(_searchQuery) &&
            !custName.contains(_searchQuery) &&
            !custPhone.contains(_searchQuery) &&
            !custAddress.contains(_searchQuery)) {
          return false;
        }
      }

      // ── Date filter ──────────────────────────────────────────
      final start = _filterStart;
      final end = _filterEnd;
      if (start != null) {
        final ts = data['completedAt'] as Timestamp?;
        if (ts == null) return false;
        final dt = ts.toDate();
        if (dt.isBefore(start)) return false;
        if (end != null) {
          final endDay =
              DateTime(end.year, end.month, end.day, 23, 59, 59);
          if (dt.isAfter(endDay)) return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: (_customStart != null && _customEnd != null)
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.blue.shade700,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _selectedFilter = DateFilter.custom;
      });
    }
  }

  // ─── Action: Approve → then Delivered ────────────────────────
  Future<void> _handleMainAction(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    final deliveryStatus = data['deliveryStatus'] ?? '';
    final isDelivered = deliveryStatus == 'DELIVERED';
    final statusHistory = data['statusHistory'] ?? '';
    final isApproved = statusHistory == 'APPROVED';

    if (isDelivered) return; // already done

    if (!isApproved) {
      // ── Step 1: APPROVE (Order Received check) ────────────────
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.verified_outlined, color: Colors.blue),
              SizedBox(width: 10),
              Text('Approve Order?',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Confirm that this order has been received and is approved.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      try {
        await FirebaseFirestore.instance
            .collection('mdfProduction')
            .doc(docId)
            .update({
          'statusHistory': 'APPROVED',
          'approvedAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(_snackBar(
            'Order Approved ✅',
            Colors.blue.shade700,
            Icons.verified,
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    } else {
      // ── Step 2: Mark Delivered ────────────────────────────────
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.done_all, color: Color(0xFF169a8d)),
              SizedBox(width: 10),
              Text('Mark as Delivered?',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'This order will be marked as Delivery Done.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF169a8d),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Yes, Delivered'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      try {
        await FirebaseFirestore.instance
            .collection('mdfProduction')
            .doc(docId)
            .update({
          'deliveryStatus': 'DELIVERED',
          'deliveredAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(_snackBar(
            'Delivery Done ✅',
            const Color(0xFF169a8d),
            Icons.done_all,
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  SnackBar _snackBar(String msg, Color color, IconData icon) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(msg,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
  }

  String _customLabel() {
    if (_customStart != null && _customEnd != null) {
      return '${_customStart!.day}/${_customStart!.month}–${_customEnd!.day}/${_customEnd!.month}';
    }
    return 'Custom';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
              color: Color.fromARGB(255, 10, 165, 248)),
        ),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset('assets/dpl.png', height: 28),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Common Orders',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                Text('Manage common orders details',
                    style:
                        TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mdfProduction')
            .where('finalStatus', isEqualTo: 'COMMON')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF169a8d)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          final filteredDocs = _applyFilters(allDocs);

          // Counts for status filter badges
          int pendingCount = 0, approvedCount = 0, deliveredCount = 0;
          for (final doc in allDocs) {
            final d = doc.data() as Map<String, dynamic>;
            final isDelivered = (d['deliveryStatus'] ?? '') == 'DELIVERED';
            final isApproved = (d['statusHistory'] ?? '') == 'APPROVED';
            if (isDelivered)
              deliveredCount++;
            else if (isApproved)
              approvedCount++;
            else
              pendingCount++;
          }

          return Column(
            children: [
              // ── Header ─────────────────────────────────────
              Container(
                color: Colors.blue.shade700,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    // Counts row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${filteredDocs.length} shown  •  ${allDocs.length} total',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _MiniCount(
                                  label: 'Pending',
                                  count: pendingCount,
                                  color: Colors.orange.shade300),
                              const SizedBox(width: 8),
                              _MiniCount(
                                  label: 'Done',
                                  count: deliveredCount,
                                  color: const Color(0xFF80ffed)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── STATUS Filter (Pending / Approved / Done / All) ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatusChip(
                            label: 'All',
                            icon: Icons.all_inclusive,
                            selected:
                                _statusFilter == StatusFilter.all,
                            color: Colors.white,
                            onTap: () => setState(() =>
                                _statusFilter = StatusFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Pending ($pendingCount)',
                            icon: Icons.pending_outlined,
                            selected:
                                _statusFilter == StatusFilter.pending,
                            color: Colors.orange.shade300,
                            onTap: () => setState(() =>
                                _statusFilter = StatusFilter.pending),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Approved ($approvedCount)',
                            icon: Icons.verified_outlined,
                            selected:
                                _statusFilter == StatusFilter.approved,
                            color: Colors.lightBlue.shade200,
                            onTap: () => setState(() =>
                                _statusFilter = StatusFilter.approved),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Done ($deliveredCount)',
                            icon: Icons.done_all,
                            selected: _statusFilter ==
                                StatusFilter.delivered,
                            color: const Color(0xFF80ffed),
                            onTap: () => setState(() =>
                                _statusFilter = StatusFilter.delivered),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Search
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'Search order ID, customer, phone...',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.blue.shade700, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Date filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            icon: Icons.all_inclusive,
                            selected:
                                _selectedFilter == DateFilter.all,
                            onTap: () => setState(
                                () => _selectedFilter = DateFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Today',
                            icon: Icons.today,
                            selected:
                                _selectedFilter == DateFilter.today,
                            onTap: () => setState(() =>
                                _selectedFilter = DateFilter.today),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '1 Week',
                            icon: Icons.date_range,
                            selected:
                                _selectedFilter == DateFilter.week,
                            onTap: () => setState(() =>
                                _selectedFilter = DateFilter.week),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '1 Month',
                            icon: Icons.calendar_month,
                            selected:
                                _selectedFilter == DateFilter.month,
                            onTap: () => setState(() =>
                                _selectedFilter = DateFilter.month),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: _customLabel(),
                            icon: Icons.tune,
                            selected:
                                _selectedFilter == DateFilter.custom,
                            onTap: _pickCustomRange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── List ────────────────────────────────────────
              Expanded(
                child: filteredDocs.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final orderId =
                              (data['orderId'] ?? doc.id).toString();
                          final isExpanded =
                              _expandedIds.contains(doc.id);

                          return FutureBuilder<Map<String, dynamic>>(
                            future: _getCustomer(orderId),
                            builder: (ctx, snap) {
                              final customerData = snap.data ?? {};
                              return _AccordionCard(
                                data: data,
                                customerData: customerData,
                                docId: doc.id,
                                isExpanded: isExpanded,
                                onToggle: () => setState(() {
                                  if (isExpanded) {
                                    _expandedIds.remove(doc.id);
                                  } else {
                                    _expandedIds.add(doc.id);
                                  }
                                }),
                                onAction: () => _handleMainAction(
                                    context, doc.id, data),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category_outlined,
                size: 64, color: Colors.blue.shade200),
          ),
          const SizedBox(height: 20),
          const Text('No Orders Found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50))),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'No orders match the selected filter.',
            style:
                TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  ACCORDION CARD
// ════════════════════════════════════════════════════════════════
class _AccordionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> customerData;
  final String docId;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAction;

  const _AccordionCard({
    required this.data,
    required this.customerData,
    required this.docId,
    required this.isExpanded,
    required this.onToggle,
    required this.onAction,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final orderId = data['orderId'] ?? '—';
    final products = (data['products'] as List?) ?? [];

    // Customer
    final custName =
        customerData['customerName'] ?? data['customerName'] ?? '—';
    final custPhone = customerData['customerPhone'] ??
        customerData['phone'] ??
        data['customerPhone'] ??
        '—';
    final custAddress = customerData['customerAddress'] ??
        customerData['address'] ??
        customerData['deliveryAddress'] ??
        data['customerAddress'] ??
        '—';
    final custEmail = customerData['customerEmail'] ??
        customerData['email'] ??
        data['customerEmail'] ??
        '';
    final companyName =
        customerData['companyName'] ?? data['companyName'] ?? '';
    final salesPerson =
        customerData['salesPerson'] ?? data['salesPerson'] ?? '';
    final priority =
        customerData['priority'] ?? data['priority'] ?? '';
    final deliveryDate =
        (customerData['deliveryDate'] as Timestamp?)?.toDate();

    // Status
    final deliveryStatus = data['deliveryStatus'] ?? '';
    final isDelivered = deliveryStatus == 'DELIVERED';
    final statusHistory = data['statusHistory'] ?? '';
    final isApproved = statusHistory == 'APPROVED';

    final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
    final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();
    // ★ NEW: approvedAt
    final approvedAt = (data['approvedAt'] as Timestamp?)?.toDate();

    // Colors
    Color borderColor = Colors.blue.shade100;
    Color headerColor = Colors.blue.shade700;
    if (isDelivered) {
      borderColor = const Color(0xFF169a8d);
      headerColor = const Color(0xFF169a8d);
    } else if (isApproved) {
      borderColor = Colors.blue.shade400;
      headerColor = Colors.blue.shade600;
    }

    // Priority color
    Color pColor = Colors.grey;
    if (priority == 'High') pColor = Colors.red;
    if (priority == 'Medium') pColor = Colors.orange;
    if (priority == 'Low') pColor = Colors.green;

    // Button config — 2-step: Approve → Delivered
    String btnLabel;
    Color btnColor;
    IconData btnIcon;
    if (isDelivered) {
      btnLabel = 'Delivery Done ✓';
      btnColor = const Color(0xFF169a8d);
      btnIcon = Icons.verified;
    } else if (isApproved) {
      btnLabel = 'Mark as Delivered';
      btnColor = Colors.orange.shade600;
      btnIcon = Icons.done_all;
    } else {
      btnLabel = 'Approved';          // ★ Changed from "Send to Dispatch"
      btnColor = Colors.blue.shade700;
      btnIcon = Icons.verified_outlined;
    }

    // Status badge
    String statusBadge;
    Color badgeColor;
    IconData badgeIcon;
    if (isDelivered) {
      statusBadge = 'Delivered';
      badgeColor = const Color(0xFF169a8d);
      badgeIcon = Icons.verified;
    } else if (isApproved) {
      statusBadge = 'Approved';
      badgeColor = Colors.blue.shade600;
      badgeIcon = Icons.verified_outlined;
    } else {
      statusBadge = 'Pending';
      badgeColor = Colors.orange.shade600;
      badgeIcon = Icons.pending_outlined;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: headerColor.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── HEADER ───────────────────────────────────────────
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color:
                    headerColor.withOpacity(isExpanded ? 1.0 : 0.06),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: isExpanded
                      ? Radius.zero
                      : const Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? Colors.white.withOpacity(0.2)
                          : headerColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDelivered
                          ? Icons.verified
                          : isApproved
                              ? Icons.verified_outlined
                              : Icons.receipt_long_outlined,
                      color: isExpanded ? Colors.white : headerColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order: $orderId',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isExpanded
                                ? Colors.white
                                : const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 13,
                                color: isExpanded
                                    ? Colors.white70
                                    : Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                custName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpanded
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // ★ Show approved date right in header when approved
                        if (isApproved && approvedAt != null && !isDelivered)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 11,
                                    color: isExpanded
                                        ? Colors.white60
                                        : Colors.blue.shade400),
                                const SizedBox(width: 3),
                                Text(
                                  'Approved: ${_fmt(approvedAt)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isExpanded
                                        ? Colors.white60
                                        : Colors.blue.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? Colors.white.withOpacity(0.2)
                          : badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isExpanded
                            ? Colors.white.withOpacity(0.5)
                            : badgeColor.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon,
                            size: 12,
                            color: isExpanded
                                ? Colors.white
                                : badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          statusBadge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isExpanded
                                ? Colors.white
                                : badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color:
                          isExpanded ? Colors.white : Colors.grey,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── EXPANDED BODY ─────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _ExpandedBody(
              orderId: orderId,
              custName: custName,
              custPhone: custPhone,
              custAddress: custAddress,
              custEmail: custEmail,
              companyName: companyName,
              salesPerson: salesPerson,
              priority: priority,
              pColor: pColor,
              deliveryDate: deliveryDate,
              products: products,
              completedAt: completedAt,
              approvedAt: approvedAt,    // ★ NEW
              deliveredAt: deliveredAt,
              isApproved: isApproved,    // ★ CHANGED from isDispatched
              isDelivered: isDelivered,
              btnLabel: btnLabel,
              btnColor: btnColor,
              btnIcon: btnIcon,
              onAction: onAction,
              fmtFn: _fmt,
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  EXPANDED BODY WIDGET
// ════════════════════════════════════════════════════════════════
class _ExpandedBody extends StatelessWidget {
  final String orderId;
  final String custName;
  final String custPhone;
  final String custAddress;
  final String custEmail;
  final String companyName;
  final String salesPerson;
  final String priority;
  final Color pColor;
  final DateTime? deliveryDate;
  final List products;
  final DateTime? completedAt;
  final DateTime? approvedAt;   // ★ NEW
  final DateTime? deliveredAt;
  final bool isApproved;        // ★ CHANGED
  final bool isDelivered;
  final String btnLabel;
  final Color btnColor;
  final IconData btnIcon;
  final VoidCallback onAction;
  final String Function(DateTime?) fmtFn;

  const _ExpandedBody({
    required this.orderId,
    required this.custName,
    required this.custPhone,
    required this.custAddress,
    required this.custEmail,
    required this.companyName,
    required this.salesPerson,
    required this.priority,
    required this.pColor,
    required this.deliveryDate,
    required this.products,
    required this.completedAt,
    required this.approvedAt,
    required this.deliveredAt,
    required this.isApproved,
    required this.isDelivered,
    required this.btnLabel,
    required this.btnColor,
    required this.btnIcon,
    required this.onAction,
    required this.fmtFn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Customer Details ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Customer Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _DR(
                    icon: Icons.badge_outlined,
                    label: 'Name',
                    value: custName),
                if (companyName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _DR(
                      icon: Icons.business_outlined,
                      label: 'Company',
                      value: companyName),
                ],
                const SizedBox(height: 4),
                _DR(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: custPhone),
                const SizedBox(height: 4),
                _DR(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: custAddress),
                if (custEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _DR(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: custEmail),
                ],
                if (salesPerson.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _DR(
                      icon: Icons.support_agent_outlined,
                      label: 'Sales',
                      value: salesPerson),
                ],
                if (priority.isNotEmpty || deliveryDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (priority.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: pColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: pColor),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              color: pColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (priority.isNotEmpty && deliveryDate != null)
                        const SizedBox(width: 10),
                      if (deliveryDate != null)
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 13,
                                color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              'Delivery: ${fmtFn(deliveryDate)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Completed At ──────────────────────────────────
          if (completedAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: Colors.blue.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Completed: ${fmtFn(completedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ── Products ──────────────────────────────────────
          ...products.asMap().entries.map((e) {
            final idx = e.key;
            final p = e.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF169a8d).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF169a8d),
                          Color(0xFF0d7c70)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['productName'] ?? '—',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Qty: ${p['quantity'] ?? '—'}${p['size'] != null ? '  •  Size: ${p['size']}' : ''}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      '✓ Ready',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF2ECC71),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Timeline chips ────────────────────────────────
          // ★ NEW: Show Approved date/time chip
          if (isApproved && approvedAt != null) ...[
            const SizedBox(height: 4),
            _TimeChip(
              icon: Icons.verified_outlined,
              label: 'Approved: ${fmtFn(approvedAt)}',
              color: Colors.blue.shade600,
            ),
          ],
          if (isDelivered && deliveredAt != null) ...[
            const SizedBox(height: 6),
            _TimeChip(
              icon: Icons.done_all,
              label: 'Delivered: ${fmtFn(deliveredAt)}',
              color: const Color(0xFF169a8d),
            ),
          ],

          const SizedBox(height: 12),

          // ── ACTION BUTTON ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDelivered ? null : onAction,
              icon: Icon(btnIcon, size: 17),
              label: Text(
                btnLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF169a8d),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isDelivered ? 0 : 3,
                shadowColor: btnColor.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  SMALL HELPERS
// ════════════════════════════════════════════════════════════════
class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TimeChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DR extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DR(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color:
                    selected ? Colors.blue.shade700 : Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.blue.shade700
                        : Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ★ NEW: Status filter chip (with colored accent)
class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? Colors.blue.shade900
                    : Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.blue.shade900
                        : Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _MiniCount(
      {required this.label,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}