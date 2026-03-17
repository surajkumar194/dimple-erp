import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const Gradient infoGrad = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient orangeGrad = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient warningGrad = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
// ══════════════════════════════════════════════════════════

class DispatchScreen extends StatelessWidget {
  const DispatchScreen({super.key});

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
                  'Ready To Dispatch',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage dispatch items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
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
                    "Loading dispatch data…",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _DispatchCard(docId: docs[i].id, data: data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.cyan.shade50],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: _C.primary.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(color: _C.primary.withOpacity(0.12), blurRadius: 20),
              ],
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: _C.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Production Data',
            style: TextStyle(
              color: _C.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
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
}

// ══════════════════════════════════════════════════════════
//  DISPATCH CARD
// ══════════════════════════════════════════════════════════
class _DispatchCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _DispatchCard({required this.docId, required this.data});

  @override
  State<_DispatchCard> createState() => _DispatchCardState();
}

class _DispatchCardState extends State<_DispatchCard> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  DateTime? _date;
  bool _isSaving = false;
  bool _isLocked = false;
  String? _qtyError;

  int get _refQty =>
      int.tryParse(widget.data['quantity']?.toString() ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _qtyController.text = _refQty > 0 ? _refQty.toString() : '';
    _checkDispatchStatus();
  }

  Future<void> _checkDispatchStatus() async {
    final snap = await FirebaseFirestore.instance
        .collection('unit2Dispatch')
        .where('productionId', isEqualTo: widget.docId)
        .get();
    int total = 0;
    for (var doc in snap.docs) {
      total += (doc.data()['quantity'] ?? 0) as int;
    }
    if (mounted) setState(() => _isLocked = total >= _refQty);
  }

  bool _validateQty() {
    final entered = int.tryParse(_qtyController.text.trim());
    if (entered == null || entered <= 0) {
      setState(() => _qtyError = 'Enter a valid quantity');
      return false;
    }
    setState(() => _qtyError = null);
    return true;
  }

  Future<void> _dispatch() async {
    if (_date == null) {
      _snack(
        "Please select a dispatch date",
        Colors.orange.shade700,
        Icons.calendar_today_rounded,
      );
      return;
    }
    if (!_validateQty()) return;

    final int enteredQty = int.parse(_qtyController.text.trim());
    final snap = await FirebaseFirestore.instance
        .collection('unit2Dispatch')
        .where('productionId', isEqualTo: widget.docId)
        .get();
    int totalDispatched = 0;
    for (var doc in snap.docs) {
      totalDispatched += (doc.data()['quantity'] ?? 0) as int;
    }
    int remaining = _refQty - totalDispatched;
    if (enteredQty > remaining) {
      _snack(
        "Only $remaining qty remaining to dispatch",
        _C.warning,
        Icons.warning_rounded,
      );
      return;
    }

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('unit2Dispatch').add({
      'productionId': widget.docId,
      'jobCardNumber': widget.data['jobCardNumber'],
      'productName': widget.data['productName'],
      'machineName': widget.data['machineName'],
      'labelPart': widget.data['labelPart'] ?? '',
      'quantity': enteredQty,
      'referenceQty': _refQty,
      'remark': _remarkController.text.trim(),
      'dispatchDate': Timestamp.fromDate(_date!),
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _isSaving = false);
    await _checkDispatchStatus();
    _snack("Dispatched Successfully ✓", _C.success, Icons.check_circle_rounded);
  }

  void _snack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: _isLocked ? _C.success : _C.info, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isLocked ? _C.success : _C.primary).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _isLocked ? _buildLockedView() : _buildFormView(),
      ),
    );
  }

  // ════════════════════════════════
  //  FORM VIEW
  // ════════════════════════════════
  Widget _buildFormView() {
    final labelPart = widget.data['labelPart'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Banner ────────────────────────────────────
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
                  Icons.local_shipping_rounded,
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Job Card: ${widget.data['jobCardNumber'] ?? '—'}  ·  "
                      "${widget.data['customerName'] ?? ''}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // DISPATCH badge
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
                  "DISPATCH",
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

        const SizedBox(height: 16),

        // ── Info chips row ────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _infoChip(
              Icons.precision_manufacturing_rounded,
              widget.data['machineName'] ?? '—',
              _C.info,
            ),
            if (labelPart.isNotEmpty)
              _infoChip(
                labelPart == 'Top'
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                'Label $labelPart',
                labelPart == 'Top'
                    ? Colors.blue.shade600
                    : Colors.purple.shade600,
              ),
            _infoChip(
              Icons.assignment_rounded,
              widget.data['jobCardNumber'] ?? '—',
              _C.purple,
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Reference Qty Banner ──────────────────────────────
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
                  "Reference qty (from production): $_refQty pcs",
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Section label ─────────────────────────────────────
        _sectionLabel(
          Icons.production_quantity_limits_rounded,
          "DISPATCH QUANTITY",
          _C.success,
        ),
        const SizedBox(height: 8),

        // ── Qty Input ─────────────────────────────────────────
        TextField(
          controller: _qtyController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: _C.darkText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          onChanged: (_) {
            if (_qtyError != null) _validateQty();
          },
          decoration: InputDecoration(
            hintText: 'Enter quantity to dispatch',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
            filled: true,
            fillColor: Colors.white,
            errorText: _qtyError,
            errorStyle: const TextStyle(color: _C.warning, fontSize: 12),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: _C.successGrad,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.production_quantity_limits_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            suffixText: 'pcs',
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
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: _qtyError != null ? _C.warning : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                color: _qtyError != null ? _C.warning : _C.success,
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Section label ─────────────────────────────────────
        _sectionLabel(Icons.calendar_month_rounded, "DISPATCH DATE", _C.info),
        const SizedBox(height: 8),

        // ── Date Picker ───────────────────────────────────────
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
            if (picked != null) setState(() => _date = picked);
          },
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: _date != null
                  ? LinearGradient(
                      colors: [Colors.blue.shade50, Colors.cyan.shade50],
                    )
                  : null,
              color: _date == null ? Colors.white : null,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _date != null
                    ? _C.info.withOpacity(0.6)
                    : Colors.grey.shade300,
                width: _date != null ? 1.8 : 1,
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
                    color: _date != null
                        ? _C.info.withOpacity(0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: _date != null ? _C.info : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _date == null
                      ? 'Select Dispatch Date'
                      : DateFormat('dd MMM yyyy').format(_date!),
                  style: TextStyle(
                    color: _date != null ? _C.darkText : Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: _date != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                if (_date != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: _C.infoGrad,
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

        const SizedBox(height: 16),

        // ── Section label ─────────────────────────────────────
        _sectionLabel(
          Icons.note_alt_rounded,
          "REMARK (OPTIONAL)",
          Colors.purple.shade600,
        ),
        const SizedBox(height: 8),

        // ── Remark ────────────────────────────────────────────
        TextField(
          controller: _remarkController,
          maxLines: 2,
          style: const TextStyle(color: _C.darkText, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: "Enter remark…",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: Colors.purple.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
            ),
            prefixIcon: Icon(
              Icons.note_alt_rounded,
              color: Colors.purple.shade400,
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 22),

        // ── Dispatch Button ───────────────────────────────────
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: _isSaving
                ? LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                  )
                : _C.infoGrad,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isSaving
                ? []
                : [
                    BoxShadow(
                      color: _C.info.withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _dispatch,
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
                        Icons.local_shipping_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'DISPATCH NOW',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════
  //  LOCKED VIEW
  // ════════════════════════════════
  Widget _buildLockedView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('unit2Dispatch')
          .where('productionId', isEqualTo: widget.docId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Dispatched',
              style: TextStyle(color: _C.success, fontWeight: FontWeight.w700),
            ),
          );
        }

        int totalDispatched = 0;
        Timestamp? lastDispatchDate;
        String labelPart = '', remark = '';

        for (var doc in snap.data!.docs) {
          final d = doc.data() as Map<String, dynamic>;
          totalDispatched += (d['quantity'] ?? 0) as int;
          if (d['dispatchDate'] != null) lastDispatchDate = d['dispatchDate'];
          labelPart = d['labelPart'] ?? '';
          remark = d['remark'] ?? '';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dispatched Header Banner ──────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _C.successGrad,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: _C.success.withOpacity(0.3), blurRadius: 12),
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
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
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
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Job Card: ${widget.data['jobCardNumber'] ?? '—'}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // DISPATCHED badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "DISPATCHED",
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

            const SizedBox(height: 14),

            // ── Info tiles ────────────────────────────────────
            _lockedTile(
              Icons.precision_manufacturing_rounded,
              'Machine',
              widget.data['machineName'] ?? '-',
              _C.info,
            ),

            if (labelPart.isNotEmpty)
              _lockedTile(
                labelPart == 'Top'
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                'Label Part',
                labelPart,
                labelPart == 'Top'
                    ? Colors.blue.shade600
                    : Colors.purple.shade600,
              ),

            _lockedTile(
              Icons.local_shipping_rounded,
              'Dispatched Qty',
              '$totalDispatched pcs',
              _C.success,
            ),

            _lockedTile(
              Icons.compare_arrows_rounded,
              'Reference Qty',
              '$_refQty pcs',
              _C.accent,
            ),

            if (lastDispatchDate != null)
              _lockedTile(
                Icons.calendar_month_rounded,
                'Dispatch Date',
                DateFormat('dd MMM yyyy').format(lastDispatchDate.toDate()),
                _C.info,
              ),

            if (remark.isNotEmpty)
              _lockedTile(
                Icons.note_alt_rounded,
                'Remark',
                remark,
                Colors.purple.shade600,
              ),
          ],
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _infoChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _lockedTile(IconData icon, String label, String value, Color color) =>
      Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              '$label  ',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
    _qtyController.dispose();
    _remarkController.dispose();
    super.dispose();
  }
}
