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
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF2C3E50);
  static const Gradient primaryGrad = LinearGradient(

    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient blueGrad = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient successGrad = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient accentGrad = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient orangeGrad = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient purpleGrad = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class Unit2MachineScreen extends StatelessWidget {
  const Unit2MachineScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.lightBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _C.blueGrad),
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
                  'UNIT 2 MACHINE PROCESS',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Inventory Machine Assignment',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('unit2Inventory')
            .orderBy('inventoryCreatedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
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
                    "Loading inventory…",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
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
                        color: _C.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _C.primary.withOpacity(0.1),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.inbox_outlined,
                      color: _C.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "No Inventory Found",
                    style: TextStyle(
                      color: _C.darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Add inventory to get started",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final products = data['products'] as List? ?? [];
              final dispatchedQty =
                  int.tryParse(data['dispatchedQty']?.toString() ?? '') ?? 0;
              return _JobCard(
                inventoryDocId: docs[i].id,
                data: data,
                products: products,
                dispatchedQty: dispatchedQty,
              );
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  JOB CARD
// ══════════════════════════════════════════════════════════
class _JobCard extends StatelessWidget {
  final String inventoryDocId;
  final Map<String, dynamic> data;
  final List products;
  final int dispatchedQty;

  const _JobCard({
    required this.inventoryDocId,
    required this.data,
    required this.products,
    required this.dispatchedQty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            childrenPadding: EdgeInsets.zero,
            collapsedIconColor: _C.primary,
            iconColor: _C.primary,
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _C.primaryGrad,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withOpacity(0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.assignment_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            title: Text(
              data['jobCardNumber'] ?? '—',
              style: const TextStyle(
                color: _C.darkText,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                letterSpacing: 0.3,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  _chip(
                    Icons.business_rounded,
                    data['companyName'] ?? '—',
                    _C.info,
                  ),
                  _chip(
                    Icons.inventory_2_rounded,
                    "${products.length} items",
                    _C.success,
                  ),
                  if (dispatchedQty > 0)
                    _chip(
                      Icons.arrow_downward_rounded,
                      "LOW QTY: $dispatchedQty",
                      _C.warning,
                    ),
                ],
              ),
            ),
            children: [
              // Rainbow divider
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _C.primary,
                      Colors.cyan.shade400,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              ...products.asMap().entries.map((entry) {
                final isLast = entry.key == products.length - 1;
                return Column(
                  children: [
                    _MachineTile(
                      inventoryDocId: inventoryDocId,
                      jobCardNumber: data['jobCardNumber'] ?? '',
                      product: Map<String, dynamic>.from(entry.value),
                      labelMinQty: dispatchedQty,
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: Colors.grey.shade100,
                        indent: 20,
                        endIndent: 20,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  MACHINE TILE
// ══════════════════════════════════════════════════════════
class _MachineTile extends StatefulWidget {
  final String inventoryDocId;
  final String jobCardNumber;
  final Map<String, dynamic> product;
  final int labelMinQty;

  const _MachineTile({
    required this.inventoryDocId,
    required this.jobCardNumber,
    required this.product,
    required this.labelMinQty,
  });

  @override
  State<_MachineTile> createState() => _MachineTileState();
}

class _MachineTileState extends State<_MachineTile>
    with SingleTickerProviderStateMixin {
  String? _topMachine;
  final TextEditingController _topRemarkCtrl = TextEditingController();
  String? _botMachine;
  final TextEditingController _botRemarkCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _isSaving = false;
  bool _topSaved = false, _botSaved = false;
  Map<String, dynamic>? _topSavedData, _botSavedData;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const List<Map<String, dynamic>> _machines = [
    {'name': 'M/c 1 Zhengrun', 'icon': Icons.looks_one_rounded},
    {'name': 'M/c 2 Zhongke', 'icon': Icons.looks_two_rounded},
    {'name': 'M/c 3 Zhengrun', 'icon': Icons.looks_3_rounded},
    {'name': 'M/c 4 Zhengrun', 'icon': Icons.looks_4_rounded},
    {'name': 'M/c 5 Ample', 'icon': Icons.looks_5_rounded},
    {'name': 'M/c 6 Ample', 'icon': Icons.looks_6_rounded},
    {'name': 'M/c 7 Hongming', 'icon': Icons.looks_rounded},
    {'name': 'M/c 8 Hongming', 'icon': Icons.library_books_outlined},
    {
      'name': 'M/c 9 Hongming double Head',
      'icon': Icons.my_library_books_rounded,
    },
    {
      'name': 'M/c 10 Hongming double Head',
      'icon': Icons.library_books_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _checkIfAlreadySaved();
  }

  String get _topDocId =>
      "${widget.inventoryDocId}_${widget.product['productName']}_top";
  String get _botDocId =>
      "${widget.inventoryDocId}_${widget.product['productName']}_bottom";

  Future<void> _checkIfAlreadySaved() async {
    final topDoc = await FirebaseFirestore.instance
        .collection('unit2MachineProcess')
        .doc(_topDocId)
        .get();
    final botDoc = await FirebaseFirestore.instance
        .collection('unit2MachineProcess')
        .doc(_botDocId)
        .get();
    if (!mounted) return;
    setState(() {
      if (topDoc.exists) {
        _topSaved = true;
        _topSavedData = topDoc.data();
      }
      if (botDoc.exists) {
        _botSaved = true;
        _botSavedData = botDoc.data();
      }
    });
    if (_topSaved && _botSaved) _animCtrl.forward();
  }

  Future<void> _saveData() async {
    if (_topMachine == null || _botMachine == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Please select both machines and a date",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    final qty = widget.labelMinQty > 0
        ? widget.labelMinQty
        : (widget.product['quantity'] ?? 0);
    final dateTs = Timestamp.fromDate(_selectedDate!);
    final now = FieldValue.serverTimestamp();

    final topData = {
      'inventoryDocId': widget.inventoryDocId,
      'jobCardNumber': widget.jobCardNumber,
      'productName': widget.product['productName'],
      'quantity': qty,
      'labelMinQty': qty,
      'labelPart': 'Top',
      'machineName': _topMachine,
      'remark': _topRemarkCtrl.text.trim(),
      'date': dateTs,
      'createdAt': now,
    };
    final botData = {
      'inventoryDocId': widget.inventoryDocId,
      'jobCardNumber': widget.jobCardNumber,
      'productName': widget.product['productName'],
      'quantity': qty,
      'labelMinQty': qty,
      'labelPart': 'Bottom',
      'machineName': _botMachine,
      'remark': _botRemarkCtrl.text.trim(),
      'date': dateTs,
      'createdAt': now,
    };

    await Future.wait([
      FirebaseFirestore.instance
          .collection('unit2MachineProcess')
          .doc(_topDocId)
          .set(topData, SetOptions(merge: true)),
      FirebaseFirestore.instance
          .collection('unit2MachineProcess')
          .doc(_botDocId)
          .set(botData, SetOptions(merge: true)),
    ]);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _topSaved = true;
      _botSaved = true;
      _topSavedData = topData;
      _botSavedData = botData;
    });
    _animCtrl.forward();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1B5E20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _C.success),
        ),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              "Saved! Both using qty: $qty",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bothSaved = _topSaved && _botSaved;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: bothSaved
          ? FadeTransition(opacity: _fadeAnim, child: _buildSavedState())
          : _buildFormState(),
    );
  }

  // ════════════════════════════════
  //  SAVED STATE
  // ════════════════════════════════
  Widget _buildSavedState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.success.withOpacity(0.45), width: 1.5),
        boxShadow: [
          BoxShadow(color: _C.success.withOpacity(0.12), blurRadius: 14),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: _C.successGrad,
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
                Expanded(
                  child: Text(
                    widget.product['productName'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                // Qty badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Text(
                    "QTY: ${_topSavedData?['quantity'] ?? widget.labelMinQty}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
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
                          letterSpacing: 1.2,
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
            child: Row(
              children: [
                Expanded(
                  child: _savedPartCard(
                    'Top',
                    _topSavedData,
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _savedPartCard(
                    'Bottom',
                    _botSavedData,
                    Colors.purple.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedPartCard(String part, Map<String, dynamic>? saved, Color color) {
    final machine = saved?['machineName'] ?? '—';
    final qty = saved?['quantity']?.toString() ?? '0';
    final remark = (saved?['remark'] ?? '') as String;
    final dateRaw = saved?['date'];
    String dateStr = '—';
    if (dateRaw is Timestamp)
      dateStr = DateFormat('dd MMM yyyy').format(dateRaw.toDate());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.07), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Part header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  part == 'Top'
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  'Label $part',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.precision_manufacturing_rounded, machine, _C.primary),
          const SizedBox(height: 5),
          _infoRow(Icons.scale_outlined, 'Qty: $qty', _C.accent),
          const SizedBox(height: 5),
          _infoRow(Icons.calendar_today_rounded, dateStr, _C.info),
          if (remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 12,
                    color: Colors.purple.shade600,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      remark,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, Color color) => Row(
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  // ════════════════════════════════
  //  FORM STATE
  // ════════════════════════════════
  Widget _buildFormState() {
    final displayQty = widget.labelMinQty > 0
        ? widget.labelMinQty
        : (widget.product['quantity'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Product Banner ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: _C.primaryGrad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: _C.primary.withOpacity(0.3), blurRadius: 12),
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
                      widget.product['productName'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_downward_rounded,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Label Low Qty: $displayQty",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // PENDING badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: const Text(
                  "PENDING",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Info Banner ─────────────────────────────────────
        if (widget.labelMinQty > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade50, Colors.amber.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Label min qty ($displayQty) will be saved for both Label Top & Label Bottom machine records.",
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // ── Top & Bottom Machine Selectors ──────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MachineSelector(
                part: 'Top',
                color: Colors.blue.shade600,
                gradient: _C.blueGrad,
                bgColor: Colors.blue.shade50,
                borderColor: Colors.blue.shade200,
                icon: Icons.arrow_upward_rounded,
                selectedMachine: _topMachine,
                machines: _machines,
                remarkController: _topRemarkCtrl,
                onMachineChanged: (v) => setState(() => _topMachine = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MachineSelector(
                part: 'Bottom',
                color: Colors.purple.shade600,
                gradient: _C.purpleGrad,
                bgColor: Colors.purple.shade50,
                borderColor: Colors.purple.shade200,
                icon: Icons.arrow_downward_rounded,
                selectedMachine: _botMachine,
                machines: _machines,
                remarkController: _botRemarkCtrl,
                onMachineChanged: (v) => setState(() => _botMachine = v),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ── Date Picker ─────────────────────────────────────
        _sectionLabel(
          Icons.calendar_month_rounded,
          "SELECT DATE (SHARED)",
          _C.info,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: _C.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: _C.darkText,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: _selectedDate != null
                  ? LinearGradient(
                      colors: [Colors.teal.shade50, Colors.cyan.shade50],
                    )
                  : null,
              color: _selectedDate == null ? Colors.white : null,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _selectedDate != null
                    ? _C.primary.withOpacity(0.6)
                    : Colors.grey.shade300,
                width: _selectedDate != null ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _selectedDate != null
                        ? _C.primary.withOpacity(0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: _selectedDate != null
                        ? _C.primary
                        : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate == null
                      ? "Choose date"
                      : DateFormat('EEEE, dd MMM yyyy').format(_selectedDate!),
                  style: TextStyle(
                    color: _selectedDate != null
                        ? _C.darkText
                        : Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: _selectedDate != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                if (_selectedDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: _C.primaryGrad,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "SET",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Save Button ─────────────────────────────────────
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: _isSaving
                ? LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                  )
                : _C.primaryGrad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isSaving
                ? []
                : [
                    BoxShadow(
                      color: _C.primary.withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveData,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.save_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "SAVE  (QTY: $displayQty)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
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
    _topRemarkCtrl.dispose();
    _botRemarkCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════
//  MACHINE SELECTOR WIDGET
// ══════════════════════════════════════════════════════════
class _MachineSelector extends StatelessWidget {
  final String part;
  final Color color;
  final Gradient gradient;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final String? selectedMachine;
  final List<Map<String, dynamic>> machines;
  final TextEditingController remarkController;
  final ValueChanged<String?> onMachineChanged;

  const _MachineSelector({
    required this.part,
    required this.color,
    required this.gradient,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.selectedMachine,
    required this.machines,
    required this.remarkController,
    required this.onMachineChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedMachine != null ? color.withOpacity(0.6) : borderColor,
          width: selectedMachine != null ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Part header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  'Label $part',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Machine label
          Row(
            children: [
              Icon(
                Icons.precision_manufacturing_rounded,
                size: 11,
                color: color.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'MACHINE',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dropdown
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selectedMachine != null
                    ? color.withOpacity(0.5)
                    : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMachine,
                isExpanded: true,
                dropdownColor: Colors.white,
                hint: Text(
                  "Choose machine",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: selectedMachine != null ? color : Colors.grey.shade400,
                  size: 20,
                ),
                style: const TextStyle(color: _C.darkText, fontSize: 13),
                items: machines
                    .map(
                      (m) => DropdownMenuItem<String>(
                        value: m['name'] as String,
                        child: Row(
                          children: [
                            Icon(m['icon'] as IconData, size: 14, color: color),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                m['name'] as String,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onMachineChanged,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Remark label
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 11,
                color: color.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'REMARK',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          TextField(
            controller: remarkController,
            maxLines: 2,
            style: const TextStyle(color: _C.darkText, fontSize: 12.5),
            decoration: InputDecoration(
              hintText: "Optional…",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: color, width: 1.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
