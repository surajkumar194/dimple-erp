import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ════════════════════════════════════════════════════════════════
//  FILTER ENUM
// ════════════════════════════════════════════════════════════════
enum _DateFilter { all, today, week, month, custom }

// ════════════════════════════════════════════════════════════════
//  DISPATCH MANAGER SCREEN
// ════════════════════════════════════════════════════════════════
class DispatchManagerScreen extends StatefulWidget {
  const DispatchManagerScreen({super.key});

  @override
  State<DispatchManagerScreen> createState() => _DispatchManagerScreenState();
}

class _DispatchManagerScreenState extends State<DispatchManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Colors.green),
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
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
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
                Text(
                  'Dispatch Data',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  'Manage dispatch records',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Dispatch',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 16),
                  SizedBox(width: 6),
                  Text('Delivered',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DispatchTab(),
          _DeliveredTab(),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  TAB 1 — DISPATCH
// ════════════════════════════════════════════════════════════════
class _DispatchTab extends StatefulWidget {
  const _DispatchTab();

  @override
  State<_DispatchTab> createState() => _DispatchTabState();
}

class _DispatchTabState extends State<_DispatchTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _DateFilter _filter = _DateFilter.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  final Map<String, Map<String, dynamic>> _customerCache = {};
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getCustomer(String orderId) async {
    if (_customerCache.containsKey(orderId)) return _customerCache[orderId]!;
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

  DateTime? get _start {
    final now = DateTime.now();
    switch (_filter) {
      case _DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case _DateFilter.week:
        return now.subtract(const Duration(days: 7));
      case _DateFilter.month:
        return now.subtract(const Duration(days: 30));
      case _DateFilter.custom:
        return _customStart;
      default:
        return null;
    }
  }

  List<QueryDocumentSnapshot> _applyFilter(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (_searchQuery.isNotEmpty) {
        final id = (data['orderId'] ?? '').toString().toLowerCase();
        final nm = (data['customerName'] ?? '').toString().toLowerCase();
        final ph = (data['customerPhone'] ?? '').toString().toLowerCase();
        if (!id.contains(_searchQuery) &&
            !nm.contains(_searchQuery) &&
            !ph.contains(_searchQuery)) return false;
      }
      final s = _start;
      if (s != null) {
        final ts = data['dispatchAt'] as Timestamp? ??
            data['completedAt'] as Timestamp?;
        if (ts == null) return false;
        final dt = ts.toDate();
        if (dt.isBefore(s)) return false;
        if (_filter == _DateFilter.custom && _customEnd != null) {
          final end = DateTime(
              _customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59);
          if (dt.isAfter(end)) return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
                primary: Colors.green.shade700, onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _filter = _DateFilter.custom;
      });
    }
  }

  String _customLabel() {
    if (_customStart != null && _customEnd != null) {
      return '${_customStart!.day}/${_customStart!.month}–${_customEnd!.day}/${_customEnd!.month}';
    }
    return 'Custom';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mdfProduction')
          .where('statusHistory', isEqualTo: 'DISPATCH')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF169a8d)));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        final allDocs = snapshot.data?.docs ?? [];
        final filtered = _applyFilter(allDocs);

        return Column(
          children: [
            // ── Header ───────────────────────────────────────────
            Container(
              color: Colors.green.shade700,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            color: Colors.white, size: 17),
                        const SizedBox(width: 8),
                        Text(
                          '${filtered.length} order${filtered.length != 1 ? 's' : ''}  •  Total: ${allDocs.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search order ID, customer, phone...',
                        hintStyle:
                            TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.green.shade700, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FChip(
                            label: 'All',
                            icon: Icons.all_inclusive,
                            selected: _filter == _DateFilter.all,
                            onTap: () =>
                                setState(() => _filter = _DateFilter.all)),
                        const SizedBox(width: 8),
                        _FChip(
                            label: 'Today',
                            icon: Icons.today,
                            selected: _filter == _DateFilter.today,
                            onTap: () =>
                                setState(() => _filter = _DateFilter.today)),
                        const SizedBox(width: 8),
                        _FChip(
                            label: '1 Week',
                            icon: Icons.date_range,
                            selected: _filter == _DateFilter.week,
                            onTap: () =>
                                setState(() => _filter = _DateFilter.week)),
                        const SizedBox(width: 8),
                        _FChip(
                            label: '1 Month',
                            icon: Icons.calendar_month,
                            selected: _filter == _DateFilter.month,
                            onTap: () =>
                                setState(() => _filter = _DateFilter.month)),
                        const SizedBox(width: 8),
                        _FChip(
                            label: _customLabel(),
                            icon: Icons.tune,
                            selected: _filter == _DateFilter.custom,
                            onTap: _pickRange),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _emptyWidget('No orders in dispatch queue',
                      Icons.local_shipping_outlined, Colors.green)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final doc = filtered[i];
                        final data = doc.data() as Map<String, dynamic>;
                        final orderId =
                            (data['orderId'] ?? doc.id).toString();
                        final isExpanded = _expanded.contains(doc.id);

                        return FutureBuilder<Map<String, dynamic>>(
                          future: _getCustomer(orderId),
                          builder: (ctx2, snap) {
                            final cust = snap.data ?? {};
                            return _DispatchAccordionCard(
                              data: data,
                              customerData: cust,
                              docId: doc.id,
                              isExpanded: isExpanded,
                              onToggle: () => setState(() {
                                isExpanded
                                    ? _expanded.remove(doc.id)
                                    : _expanded.add(doc.id);
                              }),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  DISPATCH ACCORDION CARD
// ════════════════════════════════════════════════════════════════
class _DispatchAccordionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> customerData;
  final String docId;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DispatchAccordionCard({
    required this.data,
    required this.customerData,
    required this.docId,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<_DispatchAccordionCard> createState() => _DispatchAccordionCardState();
}

class _DispatchAccordionCardState extends State<_DispatchAccordionCard> {
  late List<Map<String, TextEditingController>> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final products = (widget.data['products'] as List?) ?? [];
    _controllers = List.generate(products.length, (i) {
      final p = products[i] as Map<String, dynamic>;
      final dispatchInfo = (p['dispatchInfo'] as Map<String, dynamic>?) ?? {};
      return {
        'qty': TextEditingController(
            text: dispatchInfo['dispatchQty']?.toString() ?? ''),
        'remark': TextEditingController(
            text: dispatchInfo['remark']?.toString() ?? ''),
      };
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c['qty']!.dispose();
      c['remark']!.dispose();
    }
    super.dispose();
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isAllQtyFilled() {
    final products = (widget.data['products'] as List?) ?? [];
    if (products.isEmpty) return false;
    for (int i = 0; i < products.length; i++) {
      final p = products[i] as Map<String, dynamic>;
      final orderQty = int.tryParse(p['quantity']?.toString() ?? '') ?? 0;
      final dispQty = int.tryParse(_controllers[i]['qty']!.text.trim()) ?? 0;
      if (dispQty < orderQty || dispQty == 0) return false;
    }
    return true;
  }

  Future<void> _saveRemarks() async {
    setState(() => _saving = true);
    try {
      final products = (widget.data['products'] as List?) ?? [];
      final updated = <Map<String, dynamic>>[];
      for (int i = 0; i < products.length; i++) {
        final p = Map<String, dynamic>.from(products[i] as Map);
        p['dispatchInfo'] = {
          'dispatchQty': _controllers[i]['qty']!.text.trim(),
          'remark': _controllers[i]['remark']!.text.trim(),
          'savedAt': DateTime.now().toIso8601String(),
        };
        updated.add(p);
      }
      await FirebaseFirestore.instance
          .collection('mdfProduction')
          .doc(widget.docId)
          .update({'products': updated});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Saved!', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _markDelivered() async {
    if (!_isAllQtyFilled()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF2ECC71)),
            SizedBox(width: 10),
            Text('Mark as Delivered?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'All quantities are fulfilled. Mark this order as delivered?',
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
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _saveRemarks();

    try {
      await FirebaseFirestore.instance
          .collection('mdfProduction')
          .doc(widget.docId)
          .update({
        'deliveryStatus': 'DELIVERED',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.done_all, color: Colors.white),
            SizedBox(width: 8),
            Text('Delivery Complete ✅',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFF169a8d),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final cust = widget.customerData;

    final orderId = data['orderId'] ?? '—';
    final products = (data['products'] as List?) ?? [];

    final custName = cust['customerName'] ?? data['customerName'] ?? '—';
    final custPhone =
        cust['customerPhone'] ?? cust['phone'] ?? data['customerPhone'] ?? '—';
    final custAddress = cust['customerAddress'] ??
        cust['address'] ??
        cust['deliveryAddress'] ??
        data['customerAddress'] ??
        '—';
    final custEmail =
        cust['customerEmail'] ?? cust['email'] ?? data['customerEmail'] ?? '';
    final companyName = cust['companyName'] ?? data['companyName'] ?? '';
    final salesPerson = cust['salesPerson'] ?? data['salesPerson'] ?? '';
    final priority = cust['priority'] ?? data['priority'] ?? '';
    final deliveryDate = (cust['deliveryDate'] as Timestamp?)?.toDate();

    final dispatchAt = (data['dispatchAt'] as Timestamp?)?.toDate();
    final isDelivered = data['deliveryStatus'] == 'DELIVERED';

    Color pColor = Colors.grey;
    if (priority == 'High') pColor = Colors.red;
    if (priority == 'Medium') pColor = Colors.orange;
    if (priority == 'Low') pColor = Colors.green;

    final allQtyOk = _isAllQtyFilled();

    final Color btnColor = isDelivered
        ? const Color(0xFF169a8d)
        : (allQtyOk ? const Color(0xFF2ECC71) : Colors.grey.shade400);
    final String btnLabel = isDelivered
        ? 'Delivery Complete ✓'
        : (allQtyOk ? 'Mark as Delivered' : 'Fill All Quantities First');
    final IconData btnIcon = isDelivered
        ? Icons.verified
        : (allQtyOk ? Icons.check_circle_outline : Icons.lock_outline);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDelivered ? const Color(0xFF169a8d) : Colors.green.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Collapsed Header ─────────────────────────────────
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: widget.isExpanded
                    ? (isDelivered
                        ? const Color(0xFF169a8d)
                        : Colors.green.shade600)
                    : (isDelivered
                        ? const Color(0xFF169a8d).withOpacity(0.07)
                        : Colors.green.withOpacity(0.06)),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: widget.isExpanded
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
                      color: widget.isExpanded
                          ? Colors.white.withOpacity(0.2)
                          : Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDelivered
                          ? Icons.verified
                          : Icons.local_shipping_outlined,
                      color: widget.isExpanded
                          ? Colors.white
                          : Colors.green.shade600,
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
                            color: widget.isExpanded
                                ? Colors.white
                                : const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 13,
                                color: widget.isExpanded
                                    ? Colors.white70
                                    : Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                custName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isExpanded
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.isExpanded
                          ? Colors.white.withOpacity(0.2)
                          : (isDelivered
                              ? const Color(0xFF169a8d).withOpacity(0.1)
                              : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isExpanded
                            ? Colors.white.withOpacity(0.4)
                            : (isDelivered
                                ? const Color(0xFF169a8d).withOpacity(0.4)
                                : Colors.green.withOpacity(0.4)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDelivered ? Icons.verified : Icons.local_shipping,
                          size: 12,
                          color: widget.isExpanded
                              ? Colors.white
                              : (isDelivered
                                  ? const Color.fromARGB(255, 253, 3, 3)
                                  : const Color.fromARGB(255, 2, 2, 251)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDelivered ? 'Delivered' : 'Dispatched',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.isExpanded
                                ? Colors.white
                                : (isDelivered
                                    ? const Color.fromARGB(255, 253, 3, 3)
                                    : const Color.fromARGB(255, 2, 2, 251)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: widget.isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.isExpanded ? Colors.white : Colors.grey,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Body ────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Customer Details ─────────────────────────
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
                            Text('Customer Details',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _DR(icon: Icons.badge_outlined, label: 'Name', value: custName),
                        if (companyName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _DR(icon: Icons.business_outlined, label: 'Company', value: companyName),
                        ],
                        const SizedBox(height: 4),
                        _DR(icon: Icons.phone_outlined, label: 'Phone', value: custPhone),
                        const SizedBox(height: 4),
                        _DR(icon: Icons.location_on_outlined, label: 'Address', value: custAddress),
                        if (custEmail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _DR(icon: Icons.email_outlined, label: 'Email', value: custEmail),
                        ],
                        if (salesPerson.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _DR(icon: Icons.support_agent_outlined, label: 'Sales', value: salesPerson),
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
                                  child: Text(priority,
                                      style: TextStyle(
                                          color: pColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              if (priority.isNotEmpty && deliveryDate != null)
                                const SizedBox(width: 10),
                              if (deliveryDate != null)
                                Row(children: [
                                  Icon(Icons.calendar_today,
                                      size: 13,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text('Del: ${_fmt(deliveryDate)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600)),
                                ]),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (dispatchAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping,
                              size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 6),
                          Text('Dispatched: ${_fmt(dispatchAt)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),

                  // ── Products with qty + remark ────────────────
                  ...List.generate(products.length, (i) {
                    final p = products[i] as Map<String, dynamic>;
                    final orderQty = p['quantity']?.toString() ?? '—';
                    final orderQtyInt = int.tryParse(orderQty) ?? 0;
                    final dispQtyInt =
                        int.tryParse(_controllers[i]['qty']!.text.trim()) ?? 0;
                    final qtyOk = dispQtyInt >= orderQtyInt && orderQtyInt > 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: qtyOk
                              ? const Color(0xFF2ECC71).withOpacity(0.4)
                              : Colors.green.withOpacity(0.2),
                          width: qtyOk ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(p['productName'] ?? '—',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Color(0xFF2C3E50))),
                              ),
                              if (qtyOk)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2ECC71)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Text('✓ OK',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF2ECC71),
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('Order Qty: $orderQty',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _controllers[i]['qty'],
                                  enabled: !isDelivered,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: 'Dispatch Qty',
                                    labelStyle:
                                        const TextStyle(fontSize: 12),
                                    prefixIcon: Icon(Icons.numbers,
                                        color: Colors.green.shade600,
                                        size: 18),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: qtyOk
                                                ? const Color(0xFF2ECC71)
                                                : Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.green.shade600,
                                            width: 2)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _controllers[i]['remark'],
                                  enabled: !isDelivered,
                                  decoration: InputDecoration(
                                    labelText: 'Remark',
                                    labelStyle:
                                        const TextStyle(fontSize: 12),
                                    prefixIcon: Icon(Icons.edit_note,
                                        color: Colors.green.shade600,
                                        size: 18),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.green.shade600,
                                            width: 2)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  if (!isDelivered) ...[
                    const SizedBox(height: 4),
                    _QtyProgressBar(
                        products: products, controllers: _controllers),
                    const SizedBox(height: 12),
                  ] else
                    const SizedBox(height: 8),

                  if (!isDelivered) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _saveRemarks,
                        icon: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.green))
                            : const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Save Remarks & Qty',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isDelivered
                          ? null
                          : (allQtyOk ? _markDelivered : null),
                      icon: Icon(btnIcon, size: 17),
                      label: Text(btnLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDelivered
                            ? const Color(0xFF169a8d)
                            : Colors.grey.shade300,
                        disabledForegroundColor: isDelivered
                            ? Colors.white
                            : Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: allQtyOk && !isDelivered ? 3 : 0,
                        shadowColor:
                            const Color(0xFF2ECC71).withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  QTY PROGRESS BAR
// ════════════════════════════════════════════════════════════════
class _QtyProgressBar extends StatelessWidget {
  final List products;
  final List<Map<String, TextEditingController>> controllers;

  const _QtyProgressBar(
      {required this.products, required this.controllers});

  @override
  Widget build(BuildContext context) {
    int totalOrder = 0;
    int totalDispatched = 0;
    for (int i = 0; i < products.length; i++) {
      final p = products[i] as Map<String, dynamic>;
      totalOrder += int.tryParse(p['quantity']?.toString() ?? '0') ?? 0;
      totalDispatched +=
          int.tryParse(controllers[i]['qty']!.text.trim()) ?? 0;
    }
    final pct = totalOrder == 0
        ? 0.0
        : (totalDispatched / totalOrder).clamp(0.0, 1.0);
    final isComplete = pct >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Qty Progress',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
            Text(
              '$totalDispatched / $totalOrder',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isComplete
                      ? const Color(0xFF2ECC71)
                      : Colors.orange.shade700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? const Color(0xFF2ECC71) : Colors.orange.shade500,
            ),
          ),
        ),
        if (!isComplete) ...[
          const SizedBox(height: 4),
          Text(
            'Fill all dispatch quantities to enable delivery',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  TAB 2 — DELIVERED
// ════════════════════════════════════════════════════════════════
class _DeliveredTab extends StatefulWidget {
  const _DeliveredTab();

  @override
  State<_DeliveredTab> createState() => _DeliveredTabState();
}

class _DeliveredTabState extends State<_DeliveredTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _DateFilter _filter = _DateFilter.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  final Map<String, Map<String, dynamic>> _customerCache = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() =>
        setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getCustomer(String orderId) async {
    if (_customerCache.containsKey(orderId)) return _customerCache[orderId]!;
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

  DateTime? get _start {
    final now = DateTime.now();
    switch (_filter) {
      case _DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case _DateFilter.week:
        return now.subtract(const Duration(days: 7));
      case _DateFilter.month:
        return now.subtract(const Duration(days: 30));
      case _DateFilter.custom:
        return _customStart;
      default:
        return null;
    }
  }

  List<QueryDocumentSnapshot> _applyFilter(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (_searchQuery.isNotEmpty) {
        final id = (data['orderId'] ?? '').toString().toLowerCase();
        if (!id.contains(_searchQuery)) return false;
      }
      final s = _start;
      if (s != null) {
        final ts = data['deliveredAt'] as Timestamp?;
        if (ts == null) return false;
        final dt = ts.toDate();
        if (dt.isBefore(s)) return false;
        if (_filter == _DateFilter.custom && _customEnd != null) {
          final end = DateTime(_customEnd!.year, _customEnd!.month,
              _customEnd!.day, 23, 59, 59);
          if (dt.isAfter(end)) return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
                primary: const Color(0xFF2ECC71), onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _filter = _DateFilter.custom;
      });
    }
  }

  String _customLabel() {
    if (_customStart != null && _customEnd != null) {
      return '${_customStart!.day}/${_customStart!.month}–${_customEnd!.day}/${_customEnd!.month}';
    }
    return 'Custom';
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mdfProduction')
          .where('deliveryStatus', isEqualTo: 'DELIVERED')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF2ECC71)));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        final allDocs = snapshot.data?.docs ?? [];
        final filtered = _applyFilter(allDocs);

        return Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Container(
              color: const Color(0xFF2ECC71),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 17),
                        const SizedBox(width: 8),
                        Text(
                          '${filtered.length} delivered  •  Total: ${allDocs.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search order ID...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF2ECC71), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FChip2(
                            label: 'All',
                            icon: Icons.all_inclusive,
                            selected: _filter == _DateFilter.all,
                            onTap: () =>
                                setState(() => _filter = _DateFilter.all)),
                        const SizedBox(width: 8),
                        _FChip2(
                            label: 'Today',
                            icon: Icons.today,
                            selected: _filter == _DateFilter.today,
                            onTap: () =>
                                setState(() => _filter = _DateFilter.today)),
                        const SizedBox(width: 8),
                        _FChip2(
                            label: '1 Week',
                            icon: Icons.date_range,
                            selected: _filter == _DateFilter.week,
                            onTap: () =>
                                setState(() => _filter = _DateFilter.week)),
                        const SizedBox(width: 8),
                        _FChip2(
                            label: '1 Month',
                            icon: Icons.calendar_month,
                            selected: _filter == _DateFilter.month,
                            onTap: () =>
                                setState(() => _filter = _DateFilter.month)),
                        const SizedBox(width: 8),
                        _FChip2(
                            label: _customLabel(),
                            icon: Icons.tune,
                            selected: _filter == _DateFilter.custom,
                            onTap: _pickRange),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── FULL SCREEN TABLE ───────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _emptyWidget('No delivered orders yet',
                      Icons.check_circle_outline, const Color(0xFF2ECC71))
                  : FutureBuilder<List<_DeliveredRow>>(
                      future: _buildRows(filtered),
                      builder: (ctx, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF2ECC71)));
                        }
                        final rows = snap.data ?? [];
                        return _DeliveredTable(rows: rows);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<List<_DeliveredRow>> _buildRows(
      List<QueryDocumentSnapshot> docs) async {
    final rows = <_DeliveredRow>[];
    int sr = 1;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final orderId = (data['orderId'] ?? doc.id).toString();
      final cust = await _getCustomer(orderId);

      final custName = cust['customerName'] ?? data['customerName'] ?? '—';
      final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();
      final products = (data['products'] as List?) ?? [];

      for (final p in products) {
        final pm = p as Map<String, dynamic>;
        final dispInfo = (pm['dispatchInfo'] as Map<String, dynamic>?) ?? {};
        final qty = dispInfo['dispatchQty']?.toString() ??
            pm['quantity']?.toString() ??
            '—';
        final remark = dispInfo['remark']?.toString() ?? '—';

        rows.add(_DeliveredRow(
          sr: sr++,
          orderId: orderId,
          customerName: custName,
          productName: pm['productName']?.toString() ?? '—',
          quantity: qty,
          date: _fmt(deliveredAt),
          remark: remark,
        ));
      }
    }
    return rows;
  }
}

// ════════════════════════════════════════════════════════════════
//  DELIVERED ROW MODEL
// ════════════════════════════════════════════════════════════════
class _DeliveredRow {
  final int sr;
  final String orderId;
  final String customerName;
  final String productName;
  final String quantity;
  final String date;
  final String remark;

  const _DeliveredRow({
    required this.sr,
    required this.orderId,
    required this.customerName,
    required this.productName,
    required this.quantity,
    required this.date,
    required this.remark,
  });
}

// ════════════════════════════════════════════════════════════════
//  DELIVERED TABLE — FULL SCREEN RESPONSIVE
//  DataTable hataya — ab LayoutBuilder + ListView use hota hai
//  Phone aur Web dono pe screen ka poora width use hoga
// ════════════════════════════════════════════════════════════════
class _DeliveredTable extends StatelessWidget {
  final List<_DeliveredRow> rows;
  const _DeliveredTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final isWide = screenW > 600;

        // Fixed columns only — Remark column uses Expanded (no fixed width)
        // Sr | OrderID | Customer | Product | Qty | Date
        final List<double> colW = isWide
            ? [36, 90, 140, 160, 64, 100]
            : [26, 68, 90,  100, 48, 76];

        final headers = ['#', 'Order ID', 'Customer', 'Product', 'Qty', 'Date', 'Remark'];
        final fontSize = isWide ? 12.0 : 10.5;

        // Helper: fixed cols row (header or data)
        Widget fixedCols(List<Widget> fixedChildren, Widget remarkChild) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...List.generate(fixedChildren.length, (i) =>
                SizedBox(width: colW[i], child: fixedChildren[i])),
              Expanded(child: remarkChild),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // ── Header Row ──────────────────────────────────
                  Container(
                    color: const Color(0xFF2ECC71).withOpacity(0.15),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: isWide ? 13 : 10,
                    ),
                    child: fixedCols(
                      List.generate(headers.length - 1, (i) => Text(
                        headers[i],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isWide ? 12 : 10,
                          color: const Color(0xFF2C3E50),
                        ),
                      )),
                      Text(
                        'Remark',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isWide ? 12 : 10,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),

                  // ── Data Rows ───────────────────────────────────
                  Expanded(
                    child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1, thickness: 1, color: Color(0xFFEEEEEE),
                      ),
                      itemBuilder: (ctx, idx) {
                        final r = rows[idx];
                        final isEven = idx % 2 == 0;
                        return Container(
                          color: isEven ? Colors.white : Colors.grey.shade50,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: isWide ? 12 : 9,
                          ),
                          child: fixedCols(
                            [
                              // Sr
                              Container(
                                width: isWide ? 26 : 20,
                                height: isWide ? 26 : 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2ECC71).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text('${r.sr}',
                                    style: TextStyle(
                                      fontSize: isWide ? 11 : 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2ECC71),
                                    ),
                                  ),
                                ),
                              ),
                              // Order ID
                              Text(r.orderId,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: fontSize,
                                  color: const Color(0xFF2C3E50),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Customer
                              Text(r.customerName,
                                style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              // Product
                              Text(r.productName,
                                style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              // Qty
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 8 : 5, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2ECC71).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(r.quantity,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2ECC71),
                                    fontSize: fontSize,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Date
                              Text(r.date,
                                style: TextStyle(
                                  fontSize: isWide ? 11 : 9,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            // Remark — Expanded fills remaining space
                            Text(
                              r.remark == '—' ? '—' : r.remark,
                              style: TextStyle(
                                fontSize: isWide ? 11 : 9,
                                color: r.remark == '—'
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                                fontStyle: r.remark == '—'
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ),
         ) );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  SHARED HELPERS
// ════════════════════════════════════════════════════════════════
class _DR extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DR({required this.icon, required this.label, required this.value});

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

class _FChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FChip(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.green.shade700 : Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.green.shade700 : Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _FChip2 extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FChip2(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? const Color(0xFF2ECC71) : Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? const Color(0xFF2ECC71) : Colors.white)),
          ],
        ),
      ),
    );
  }
}

Widget _emptyWidget(String msg, IconData icon, Color color) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 64, color: color.withOpacity(0.4)),
        ),
        const SizedBox(height: 20),
        Text(msg,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50))),
        const SizedBox(height: 8),
        Text('Items will appear here automatically.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      ],
    ),
  );
}