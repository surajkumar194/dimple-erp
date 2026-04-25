import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const Color primary = Color(0xFF169a8d);
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFFFFA500);
  static const Color success = Color(0xFF2ECC71);
  static const Color info = Color(0xFF3498DB);
  static const Color warning = Color(0xFFE74C3C);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF2C3E50);
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient successGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient blueGradient = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class _PackagingEntry {
  final String machineDocId;
  final Map<String, dynamic> data;
  const _PackagingEntry({required this.machineDocId, required this.data});
  String get productName => data['productName'] ?? '';
  String get customerName {
    final cn = data['customerName']?.toString().trim() ?? '';
    final co = data['companyName']?.toString().trim() ?? '';
    if (cn.isNotEmpty) return cn;
    if (co.isNotEmpty) return co;
    return '';
  }

  String get jobCardNumber => data['jobCardNumber'] ?? '';
  String get machineName => data['machineName'] ?? '';
  String get labelPart => data['labelPart'] ?? '';
  int get quantity => int.tryParse(data['quantity']?.toString() ?? '') ?? 0;
}

class _ProductGroup {
  final String productName;
  final List<_PackagingEntry> entries;
  const _ProductGroup({required this.productName, required this.entries});
  int get totalQty => entries.fold(0, (s, e) => s + e.quantity);
  int get totalLabels => entries.length;
}

class PackagingScreen extends StatelessWidget {
  const PackagingScreen({super.key});

  List<_ProductGroup> _groupByProduct(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<_PackagingEntry>> grouped = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['productName'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      grouped.putIfAbsent(name, () => []);
      grouped[name]!.add(_PackagingEntry(machineDocId: doc.id, data: data));
    }
    final list = grouped.entries
        .map((e) => _ProductGroup(productName: e.key, entries: e.value))
        .toList();
    list.sort(
      (a, b) =>
          a.productName.toLowerCase().compareTo(b.productName.toLowerCase()),
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: Image.asset('assets/dpl.png', height: 36),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ready To Packaging',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage paper stock items',
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
            .collection('unit2MachineProcess')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: _LoadingWidget(message: "Loading machine data…"),
            );
          }
          final groups = _groupByProduct(snap.data!.docs);
          if (groups.isEmpty) {
            return const Center(child: _EmptyWidget());
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            itemCount: groups.length,
            itemBuilder: (context, i) =>
                _ProductGroupCard(group: groups[i], serialNo: i + 1),
          );
        },
      ),
    );
  }
}

class _ProductGroupCard extends StatefulWidget {
  final _ProductGroup group;
  final int serialNo;

  const _ProductGroupCard({required this.group, required this.serialNo});

  @override
  State<_ProductGroupCard> createState() => _ProductGroupCardState();
}

class _ProductGroupCardState extends State<_ProductGroupCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _rotateAnim;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _rotateAnim = Tween(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withOpacity(0.4)
              : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              decoration: BoxDecoration(
                gradient: _expanded
                    ? LinearGradient(
                        colors: [
                          Colors.purple.shade600,
                          Colors.blue.shade600,
                          Colors.teal.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.teal.shade50.withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: _expanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(17),
                        topRight: Radius.circular(17),
                      )
                    : BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _expanded
                            ? [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.15),
                              ]
                            : [AppColors.primary, const Color(0xFF0d7c70)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.serialNo}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 20,
                      color: _expanded ? Colors.white : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.productName,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: _expanded
                                ? Colors.white
                                : AppColors.darkText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            _headerChip(
                              Icons.label_rounded,
                              '${g.totalLabels} label${g.totalLabels > 1 ? 's' : ''}',
                              _expanded,
                            ),
                            _headerChip(
                              Icons.scale_outlined,
                              '${g.totalQty} pcs total',
                              _expanded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: _expanded
                          ? LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.15),
                              ],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Qty',
                          style: TextStyle(
                            fontSize: 9,
                            color: _expanded ? Colors.white70 : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${g.totalQty}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  RotationTransition(
                    turns: _rotateAnim,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _expanded
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: _expanded ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                // Column header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade700,
                        Colors.blue.shade700,
                        Colors.teal.shade600,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          'Sr',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Job Card / Customer / Label',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          'Qty',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'Status',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Entry rows
                ...g.entries.asMap().entries.map((mapEntry) {
                  final idx = mapEntry.key;
                  final entry = mapEntry.value;
                  final isLast = idx == g.entries.length - 1;
                  return _LabelEntryRow(
                    entry: entry,
                    index: idx,
                    isEven: idx % 2 == 0,
                    isLast: isLast,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String label, bool isExpanded) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: isExpanded
          ? Colors.white.withOpacity(0.2)
          : AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 10,
          color: isExpanded ? Colors.white70 : AppColors.primary,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isExpanded ? Colors.white70 : AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  LABEL ENTRY ROW
// ══════════════════════════════════════════════════════════
class _LabelEntryRow extends StatefulWidget {
  final _PackagingEntry entry;
  final int index;
  final bool isEven;
  final bool isLast;

  const _LabelEntryRow({
    required this.entry,
    required this.index,
    required this.isEven,
    required this.isLast,
  });

  @override
  State<_LabelEntryRow> createState() => _LabelEntryRowState();
}

class _LabelEntryRowState extends State<_LabelEntryRow> {
  bool _formExpanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final labelPart = entry.labelPart;

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _formExpanded = !_formExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _formExpanded
                  ? AppColors.primary.withOpacity(0.06)
                  : widget.isEven
                  ? Colors.white
                  : const Color(0xFFF3F7F4),
              borderRadius: widget.isLast && !_formExpanded
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(17),
                      bottomRight: Radius.circular(17),
                    )
                  : BorderRadius.zero,
              border: Border(
                top: BorderSide(color: Colors.grey.shade100, width: 1),
                left: _formExpanded
                    ? BorderSide(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 3,
                      )
                    : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                // Sr
                SizedBox(
                  width: 28,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _formExpanded
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${widget.index + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _formExpanded
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Job Card + Customer Name + Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Card Number
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          entry.jobCardNumber,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),

                      // ✅ FIX: customerName show karo
                      if (entry.customerName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.indigo.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.business_rounded,
                                size: 11,
                                color: Colors.indigo.shade400,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  entry.customerName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.indigo.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Label Part
                      if (labelPart.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: labelPart == 'Top'
                                    ? Colors.blue.shade100
                                    : Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Icon(
                                labelPart == 'Top'
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 11,
                                color: labelPart == 'Top'
                                    ? Colors.blue.shade700
                                    : Colors.purple.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Label $labelPart',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: labelPart == 'Top'
                                    ? Colors.blue.shade600
                                    : Colors.purple.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Qty
                SizedBox(
                  width: 56,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Status + arrow
                SizedBox(
                  width: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _SavedStatusBadge(machineDocId: entry.machineDocId),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _formExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: _formExpanded
                              ? AppColors.primary
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Form expansion
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          child: _formExpanded
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.4),
                    borderRadius: widget.isLast
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(17),
                            bottomRight: Radius.circular(17),
                          )
                        : BorderRadius.zero,
                    border: Border(
                      left: BorderSide(
                        color: AppColors.primary.withOpacity(0.4),
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _MachineDataCard(
                    machineDocId: entry.machineDocId,
                    data: entry.data,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SAVED STATUS BADGE
// ══════════════════════════════════════════════════════════
class _SavedStatusBadge extends StatelessWidget {
  final String machineDocId;
  const _SavedStatusBadge({required this.machineDocId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('productionunit2')
          .doc(machineDocId)
          .snapshots(),
      builder: (context, snap) {
        final saved = snap.hasData && snap.data!.exists;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: (saved ? AppColors.success : AppColors.accent).withOpacity(
              0.12,
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: (saved ? AppColors.success : AppColors.accent).withOpacity(
                0.5,
              ),
            ),
          ),
          child: Icon(
            saved ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 13,
            color: saved ? AppColors.success : AppColors.accent,
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  MACHINE DATA CARD (form)
// ══════════════════════════════════════════════════════════
class _MachineDataCard extends StatefulWidget {
  final String machineDocId;
  final Map<String, dynamic> data;
  const _MachineDataCard({required this.machineDocId, required this.data});

  @override
  State<_MachineDataCard> createState() => _MachineDataCardState();
}

class _MachineDataCardState extends State<_MachineDataCard>
    with SingleTickerProviderStateMixin {
  bool? _isApproved;
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  String? _qtyError;
  final DateTime _autoDate = DateTime.now();
  bool _isSaving = false, _isSaved = false;
  Map<String, dynamic>? _savedData;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  int get _originalQty =>
      int.tryParse(widget.data['quantity']?.toString() ?? '') ?? 0;

  // ✅ FIX: customerName getter
  String get _customerName {
    final cn = widget.data['customerName']?.toString().trim() ?? '';
    final co = widget.data['companyName']?.toString().trim() ?? '';
    if (cn.isNotEmpty) return cn;
    if (co.isNotEmpty) return co;
    return '';
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _qtyController.text = _originalQty > 0 ? _originalQty.toString() : '';
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final doc = await FirebaseFirestore.instance
        .collection('productionunit2')
        .doc(widget.machineDocId)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _isSaved = true;
        _savedData = doc.data();
      });
      _animCtrl.forward();
    }
  }

  bool _validateQty() {
    final entered = int.tryParse(_qtyController.text.trim());
    if (entered == null || entered <= 0) {
      setState(() => _qtyError = 'Please enter a valid quantity');
      return false;
    }
    setState(() => _qtyError = null);
    return true;
  }

  Future<void> _save() async {
    if (_isApproved == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_warnSnack("Please select Approved or Not Approved"));
      return;
    }
    if (!_validateQty()) return;
    setState(() => _isSaving = true);
    try {
      final enteredQty = int.parse(_qtyController.text.trim());
      final docData = {
        'machineDocId': widget.machineDocId,
        'jobCardNumber':
            widget.data['jobCardNumber'] ??
            widget.data['jobCardNo'] ??
            'UNKNOWN',
        'productName': widget.data['productName'] ?? '',
        'customerName': _customerName, // ✅ FIX
        'quantity': enteredQty,
        'originalQty': _originalQty,
        'machineName': widget.data['machineName'] ?? '',
        'labelPart': widget.data['labelPart'] ?? '',
        'approved': _isApproved,
        'remark': _remarkController.text.trim(),
        'date': Timestamp.fromDate(_autoDate),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('productionunit2')
          .doc(widget.machineDocId)
          .set(docData, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
          _savedData = docData;
        });
        _animCtrl.forward();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_greenSnack("Saved to Production Unit 2 ✓"));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 400),
      crossFadeState: _isSaved
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: _buildForm(),
      secondChild: _isSaved
          ? FadeTransition(opacity: _fadeAnim, child: _buildSavedView())
          : const SizedBox.shrink(),
    );
  }

  Widget _buildForm() {
    final dateStr = DateFormat('EEEE, dd MMM yyyy').format(_autoDate);
    final labelPart = widget.data['labelPart'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data['productName'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ✅ FIX: customerName banner mein bhi show karo
                    Text(
                      "${widget.data['machineName'] ?? '—'}  ·  "
                      "${widget.data['jobCardNumber'] ?? '—'}"
                      "${_customerName.isNotEmpty ? '  ·  $_customerName' : ''}"
                      "${labelPart.isNotEmpty ? '  ·  Label $labelPart' : ''}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Date
        _sectionLabel(
          Icons.calendar_today_rounded,
          "DATE (AUTO)",
          AppColors.info,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.cyan.shade50],
            ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.info.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 17,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              Text(
                dateStr,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "AUTO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Quantity
        _sectionLabel(
          Icons.production_quantity_limits_rounded,
          "ENTER QUANTITY",
          AppColors.success,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade50, Colors.amber.shade50],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 7),
              Text(
                "Reference qty from machine: $_originalQty pcs",
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: _qtyController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          onChanged: (_) {
            if (_qtyError != null) _validateQty();
          },
          decoration: InputDecoration(
            hintText: "Enter quantity…",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
            filled: true,
            fillColor: Colors.white,
            errorText: _qtyError,
            errorStyle: const TextStyle(color: AppColors.warning, fontSize: 12),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.production_quantity_limits_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            suffixText: "pcs",
            suffixStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _qtyError != null
                    ? AppColors.warning
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _qtyError != null
                    ? AppColors.warning
                    : AppColors.success,
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Approval
        _sectionLabel(
          Icons.verified_rounded,
          "APPROVAL STATUS",
          AppColors.secondary,
        ),
        const SizedBox(height: 8),
        _ApprovalDropdown(
          value: _isApproved,
          onChanged: (v) => setState(() => _isApproved = v),
        ),

        const SizedBox(height: 20),

        // Remark
        _sectionLabel(
          Icons.notes_rounded,
          "REMARK (OPTIONAL)",
          Colors.purple.shade600,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _remarkController,
          maxLines: 3,
          style: const TextStyle(color: AppColors.darkText, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: "Enter remark…",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 26),

        // Save Button
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: _isSaving
                ? LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                  )
                : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isSaving
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "SAVE TO PRODUCTION",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedView() {
    final approved = _savedData?['approved'] as bool? ?? false;
    final remark = (_savedData?['remark'] ?? '') as String;
    final savedQty = _savedData?['quantity'] ?? widget.data['quantity'] ?? 0;
    final originalQty = _savedData?['originalQty'] ?? _originalQty;
    // ✅ FIX: saved view mein bhi customerName dikhao
    final savedCustomer =
        (_savedData?['customerName'] ?? _customerName) as String;
    final dateRaw = _savedData?['date'];
    String dateStr = '—';
    if (dateRaw is Timestamp) {
      dateStr = DateFormat('dd MMM yyyy').format(dateRaw.toDate());
    } else if (dateRaw is DateTime) {
      dateStr = DateFormat('dd MMM yyyy').format(dateRaw);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: AppColors.success.withOpacity(0.15), blurRadius: 14),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: const BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Saved to Production Unit 2",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 11, color: Colors.white70),
                      SizedBox(width: 4),
                      Text(
                        "LOCKED",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _chip(
                      approved
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_down_rounded,
                      approved ? "Approved" : "Not Approved",
                      approved ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      Icons.calendar_today_rounded,
                      dateStr,
                      AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chip(
                      Icons.production_quantity_limits_rounded,
                      "Qty: $savedQty pcs",
                      AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      Icons.compare_arrows_rounded,
                      "Ref: $originalQty pcs",
                      AppColors.accent,
                    ),
                  ],
                ),
                // ✅ FIX: saved view mein customer name chip
                if (savedCustomer.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip(
                        Icons.business_rounded,
                        savedCustomer,
                        Colors.indigo,
                      ),
                    ],
                  ),
                ],
                if (remark.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade50, Colors.indigo.shade50],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 14,
                          color: Colors.purple.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            remark,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Flexible(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sectionLabel(IconData icon, String text, Color color) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 13, color: color),
      ),
      const SizedBox(width: 8),
      Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _remarkController.dispose();
    _qtyController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════
//  APPROVAL DROPDOWN
// ══════════════════════════════════════════════════════════
class _ApprovalDropdown extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;
  const _ApprovalDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final Color activeColor = value == null
        ? Colors.grey.shade400
        : value == true
        ? AppColors.success
        : AppColors.warning;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: value == null ? Colors.white : activeColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: activeColor.withOpacity(value == null ? 0.4 : 0.7),
            width: value == null ? 1 : 2,
          ),
          boxShadow: value != null
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.15),
                    blurRadius: 12,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                value == null
                    ? Icons.how_to_vote_rounded
                    : value == true
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_down_rounded,
                size: 17,
                color: activeColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value == null
                  ? "Select approval status"
                  : value == true
                  ? "Approved ✓"
                  : "Not Approved ✗",
              style: TextStyle(
                color: value == null ? Colors.grey.shade500 : activeColor,
                fontSize: 14.5,
                fontWeight: value == null ? FontWeight.w400 : FontWeight.w800,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Select Approval Status",
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade200, height: 1),
            _PickerOption(
              icon: Icons.thumb_up_rounded,
              label: "Approved",
              sublabel: "Mark this item as approved",
              color: AppColors.success,
              isSelected: value == true,
              onTap: () {
                onChanged(true);
                Navigator.pop(context);
              },
            ),
            Divider(
              color: Colors.grey.shade100,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            _PickerOption(
              icon: Icons.thumb_down_rounded,
              label: "Not Approved",
              sublabel: "Mark this item as not approved",
              color: AppColors.warning,
              isSelected: value == false,
              onTap: () {
                onChanged(false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [color, color.withOpacity(0.75)])
                    : LinearGradient(
                        colors: [
                          color.withOpacity(0.12),
                          color.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]
                    : [],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : AppColors.darkText,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sublabel,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [color, color.withOpacity(0.7)])
                    : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]
                    : [],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  LOADING & EMPTY
// ══════════════════════════════════════════════════════════
class _LoadingWidget extends StatelessWidget {
  final String message;
  const _LoadingWidget({required this.message});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 52,
        height: 52,
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          backgroundColor: Colors.teal.shade100,
          strokeWidth: 3,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        message,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
    ],
  );
}

class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.cyan.shade50],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 16,
            ),
          ],
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          color: AppColors.primary,
          size: 36,
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        "No Machine Data Found",
        style: TextStyle(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        "Unit 2 Machine Process data will appear here",
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
      ),
    ],
  );
}


SnackBar _greenSnack(String msg) => SnackBar(
  backgroundColor: const Color(0xFF1B5E20),
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: AppColors.success),
  ),
  content: Row(
    children: [
      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 10),
      Text(
        msg,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
      ),
    ],
  ),
);

SnackBar _errorSnack(String msg) => SnackBar(
  backgroundColor: AppColors.warning,
  behavior: SnackBarBehavior.floating,
  duration: const Duration(seconds: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  content: Row(
    children: [
      const Icon(Icons.error_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          "Error: $msg",
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    ],
  ),
);

SnackBar _warnSnack(String msg) => SnackBar(
  backgroundColor: Colors.orange.shade800,
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  content: Row(
    children: [
      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 10),
      Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
    ],
  ),
);
