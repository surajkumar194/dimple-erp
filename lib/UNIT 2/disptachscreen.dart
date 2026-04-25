import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _C {
  static const Color primary = Color(0xFF169a8d);
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFFFFA500);
  static const Color success = Color(0xFF2ECC71);
  static const Color info = Color(0xFF3498DB);
  static const Color warning = Color(0xFFE74C3C);
  static const Color purple = Color(0xFF8E24AA);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color grey = Color(0xFF90A4AE);

  static const Gradient primaryGrad = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient successGrad = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient infoGrad = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient warningGrad = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient orangeGrad = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ══════════════════════════════════════════════════════════
//  DISPATCH TABLE SCREEN
// ══════════════════════════════════════════════════════════
class DispatchTableScreen extends StatefulWidget {
  const DispatchTableScreen({super.key});

  @override
  State<DispatchTableScreen> createState() => _DispatchTableScreenState();
}

class _DispatchTableScreenState extends State<DispatchTableScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All';   // All / Dispatched / Pending
  String _filterLabel  = 'All';   // All / Top / Bottom

  // Map<productionDocId, totalDispatchedQty>
  Map<String, int> _dispatchedMap = {};

  @override
  void initState() {
    super.initState();
    _loadDispatchedData();
  }

  Future<void> _loadDispatchedData() async {
    final snap = await FirebaseFirestore.instance
        .collection('unit2Dispatch')
        .get();
    final map = <String, int>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final id  = d['productionId'] as String? ?? '';
      final qty = (d['quantity']    as num?)?.toInt() ?? 0;
      map[id] = (map[id] ?? 0) + qty;
    }
    if (mounted) setState(() => _dispatchedMap = map);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.lightBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade600,
                  Colors.blue.shade600,
                  Colors.teal.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_chart_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Dispatch Table',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All production dispatch records',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('productionunit2')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          // ── Loading ─────────────────────────────────────
          if (!snap.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation(_C.primary),
                      backgroundColor: Colors.teal.shade100,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading dispatch data…',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final allDocs = snap.data!.docs;

          // ── Filter logic ────────────────────────────────
          final q = _searchController.text.trim().toLowerCase();
          final filtered = allDocs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final refQty      = (d['quantity'] as num?)?.toInt() ?? 0;
            final dispatched  = _dispatchedMap[doc.id] ?? 0;
            final isLocked    = dispatched >= refQty && refQty > 0;
            final labelPart   = (d['labelPart'] ?? '') as String;

            // search
            if (q.isNotEmpty) {
              final haystack =
                  '${d['productName']} ${d['jobCardNumber']} '
                  '${d['machineName']} ${d['customerName']} $labelPart'
                      .toLowerCase();
              if (!haystack.contains(q)) return false;
            }
            // status filter
            if (_filterStatus == 'Dispatched' && !isLocked) return false;
            if (_filterStatus == 'Pending'    &&  isLocked) return false;
            // label filter
            if (_filterLabel != 'All' && labelPart != _filterLabel)
              return false;

            return true;
          }).toList();

          // ── Empty state ─────────────────────────────────
          if (allDocs.isEmpty) return _buildEmptyState();

          // ── Stats ────────────────────────────────────────
          int totalRefQty = 0, totalDispatchedQty = 0;
          int dispatchedCount = 0;
          for (final doc in filtered) {
            final d = doc.data() as Map<String, dynamic>;
            final refQty     = (d['quantity'] as num?)?.toInt() ?? 0;
            final dispatched = _dispatchedMap[doc.id] ?? 0;
            totalRefQty      += refQty;
            totalDispatchedQty += dispatched;
            if (dispatched >= refQty && refQty > 0) dispatchedCount++;
          }

          return Column(
            children: [
              // ── Search + Filter bar ─────────────────────
              _buildFilterBar(),

              // ── Stat chips ──────────────────────────────
              _buildStatRow(
                total: filtered.length,
                dispatched: dispatchedCount,
                pending: filtered.length - dispatchedCount,
                totalRefQty: totalRefQty,
                totalDispQty: totalDispatchedQty,
              ),

              // ── Table ───────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildNoResultState()
                    : _buildTable(filtered),
              ),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════
  //  FILTER BAR
  // ════════════════════════════════
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: _C.darkText, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Search by product, job card, machine…',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.grey.shade400, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: Colors.grey.shade400, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _C.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips row
          Row(
            children: [
              // Status filter
              Expanded(
                child: _filterDropdown(
                  icon: Icons.local_shipping_rounded,
                  value: _filterStatus,
                  items: const ['All', 'Dispatched', 'Pending'],
                  color: _C.info,
                  onChanged: (v) => setState(() => _filterStatus = v!),
                ),
              ),
              const SizedBox(width: 10),
              // Label filter
              Expanded(
                child: _filterDropdown(
                  icon: Icons.label_rounded,
                  value: _filterLabel,
                  items: const ['All', 'Top', 'Bottom'],
                  color: _C.purple,
                  onChanged: (v) => setState(() => _filterLabel = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required IconData icon,
    required String value,
    required List<String> items,
    required Color color,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: color, size: 18),
          isExpanded: true,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w700),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Row(
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(e),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ════════════════════════════════
  //  STAT ROW
  // ════════════════════════════════
  Widget _buildStatRow({
    required int total,
    required int dispatched,
    required int pending,
    required int totalRefQty,
    required int totalDispQty,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statChip('Total', '$total', _C.primary,
                Icons.inventory_2_rounded),
            const SizedBox(width: 8),
            _statChip('Dispatched', '$dispatched', _C.success,
                Icons.check_circle_rounded),
            const SizedBox(width: 8),
            _statChip('Pending', '$pending', _C.info,
                Icons.pending_rounded),
            const SizedBox(width: 8),
            _statChip('Ref Qty', '$totalRefQty pcs', _C.accent,
                Icons.info_outline_rounded),
            const SizedBox(width: 8),
            _statChip('Dispatched Qty', '$totalDispQty pcs', _C.purple,
                Icons.local_shipping_rounded),
          ],
        ),
      ),
    );
  }

  Widget _statChip(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════
  //  TABLE
  // ════════════════════════════════
  Widget _buildTable(List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF2C3E50),
              ),
              dataRowMinHeight: 58,
              dataRowMaxHeight: 70,
              columnSpacing: 18,
              horizontalMargin: 16,
              dividerThickness: 0.5,
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
              columns: const [
                DataColumn(label: Text('Sr')),
                DataColumn(label: Text('Product Name')),
                DataColumn(label: Text('Job Card')),
                DataColumn(label: Text('Machine')),
                DataColumn(label: Text('Label Part')),
                DataColumn(label: Text('Ref Qty')),
                DataColumn(label: Text('Dispatched Qty')),
                DataColumn(label: Text('Remaining Qty')),
                DataColumn(label: Text('Dispatch Date')),
                DataColumn(label: Text('Remark')),
                DataColumn(label: Text('Status')),
              ],
              rows: List.generate(docs.length, (i) {
                final doc = docs[i];
                final d   = doc.data() as Map<String, dynamic>;

                final refQty     = (d['quantity']  as num?)?.toInt() ?? 0;
                final dispatched = _dispatchedMap[doc.id] ?? 0;
                final remaining  = refQty - dispatched;
                final isLocked   = dispatched >= refQty && refQty > 0;
                final labelPart  = (d['labelPart'] ?? '') as String;

                // dispatch date from unit2Dispatch (shown via snapshot)
                final dispDateStr = '—'; // loaded separately if needed

                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    if (i.isEven) return Colors.grey.shade50;
                    return Colors.white;
                  }),
                  cells: [
                    // Sr
                    DataCell(
                      Text('${i + 1}',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12)),
                    ),

                    // Product Name + Customer
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['productName'] ?? '—',
                            style: const TextStyle(
                              color: _C.darkText,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if ((d['customerName'] ?? '').isNotEmpty)
                            Text(
                              d['customerName'],
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11),
                            ),
                        ],
                      ),
                    ),

                    // Job Card
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _C.purple.withOpacity(0.3)),
                        ),
                        child: Text(
                          d['jobCardNumber'] ?? '—',
                          style: const TextStyle(
                            color: _C.purple,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    // Machine
                    DataCell(
                      _tableChip(
                        Icons.precision_manufacturing_rounded,
                        d['machineName'] ?? '—',
                        _C.info,
                      ),
                    ),

                    // Label Part
                    DataCell(
                      labelPart.isEmpty
                          ? Text('—',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12))
                          : _tableChip(
                              labelPart == 'Top'
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              'Label $labelPart',
                              labelPart == 'Top'
                                  ? Colors.blue.shade600
                                  : Colors.purple.shade600,
                            ),
                    ),

                    // Ref Qty
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          '$refQty pcs',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),

                    // Dispatched Qty
                    DataCell(
                      Text(
                        '$dispatched pcs',
                        style: TextStyle(
                          color: dispatched == 0
                              ? Colors.grey.shade400
                              : _C.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // Remaining Qty
                    DataCell(
                      Text(
                        '$remaining pcs',
                        style: TextStyle(
                          color: remaining == 0
                              ? _C.success
                              : remaining == refQty
                                  ? _C.info
                                  : _C.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // Dispatch Date
                    DataCell(
                      _DispatchDateCell(productionId: doc.id),
                    ),

                    // Remark
                    DataCell(
                      _DispatchRemarkCell(productionId: doc.id),
                    ),

                    // Status
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: isLocked
                              ? _C.successGrad
                              : _C.infoGrad,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isLocked ? _C.success : _C.info)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLocked
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isLocked ? 'DISPATCHED' : 'PENDING',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════
  //  EMPTY / NO RESULT STATES
  // ════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [Colors.teal.shade50, Colors.cyan.shade50]),
              shape: BoxShape.circle,
              border: Border.all(
                  color: _C.primary.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                    color: _C.primary.withOpacity(0.12), blurRadius: 20),
              ],
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: _C.primary, size: 38),
          ),
          const SizedBox(height: 18),
          const Text('No Production Data',
              style: TextStyle(
                  color: _C.darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Dispatches will appear here once production is complete',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          Text('No matching records',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Try changing your search or filters',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Helper ─────────────────────────────────────────────
  Widget _tableChip(IconData icon, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════
//  HELPER CELLS — live dispatch date & remark from Firestore
// ══════════════════════════════════════════════════════════
class _DispatchDateCell extends StatelessWidget {
  final String productionId;
  const _DispatchDateCell({required this.productionId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('unit2Dispatch')
          .where('productionId', isEqualTo: productionId)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Text('—',
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12));
        }
        Timestamp? latest;
        for (final doc in snap.data!.docs) {
          final d = doc.data() as Map<String, dynamic>;
          final ts = d['dispatchDate'] as Timestamp?;
          if (ts != null && (latest == null || ts.compareTo(latest) > 0)) {
            latest = ts;
          }
        }
        if (latest == null) {
          return Text('—',
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12));
        }
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _C.info.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.info.withOpacity(0.25)),
          ),
          child: Text(
            DateFormat('dd MMM yyyy').format(latest.toDate()),
            style: const TextStyle(
                color: _C.info,
                fontSize: 11.5,
                fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }
}

class _DispatchRemarkCell extends StatelessWidget {
  final String productionId;
  const _DispatchRemarkCell({required this.productionId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('unit2Dispatch')
          .where('productionId', isEqualTo: productionId)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Text('—',
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12));
        }
        final remarks = snap.data!.docs
            .map((doc) =>
                ((doc.data() as Map<String, dynamic>)['remark'] ?? '')
                    as String)
            .where((r) => r.isNotEmpty)
            .toSet()
            .join(', ');

        if (remarks.isEmpty) {
          return Text('—',
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 12));
        }
        return SizedBox(
          width: 120,
          child: Text(
            remarks,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}