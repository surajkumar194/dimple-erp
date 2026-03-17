import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════
//  COLOR PALETTE  — matches EditSalesOrderScreen exactly
// ══════════════════════════════════════════════════════════
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
  static const Gradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ══════════════════════════════════════════════════════════

class PackagingScreen extends StatelessWidget {
  const PackagingScreen({super.key});

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
            .collection('unit2MachineProcess')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: _LoadingWidget(message: "Loading machine data…"),
            );
          }
          final docs = snap.data!.docs;
          Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final key = "${data['jobCardNumber']}_${data['productName']}";
            grouped.putIfAbsent(key, () => []);
            grouped[key]!.add(doc);
          }
          final groupedList = grouped.entries.toList();
          if (groupedList.isEmpty) return const Center(child: _EmptyWidget());
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            itemCount: groupedList.length,
            itemBuilder: (context, i) =>
                _MachineDataCardGroup(docs: groupedList[i].value),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  GROUP TILE
// ══════════════════════════════════════════════════════════
class _MachineDataCardGroup extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const _MachineDataCardGroup({required this.docs});

  @override
  Widget build(BuildContext context) {
    final firstData = docs.first.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
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
            collapsedIconColor: AppColors.primary,
            iconColor: AppColors.primary,
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            title: Text(
              firstData['productName'] ?? '',
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  _groupChip(
                    Icons.assignment_rounded,
                    "Job: ${firstData['jobCardNumber']}",
                    AppColors.info,
                  ),
                  _groupChip(
                    Icons.label_rounded,
                    "${docs.length} label${docs.length > 1 ? 's' : ''}",
                    AppColors.success,
                  ),
                ],
              ),
            ),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final label = data['labelPart'] ?? '';
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade50, Colors.amber.shade50],
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.orange.shade100),
                        bottom: BorderSide(color: Colors.orange.shade100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: label == 'Top'
                                ? Colors.blue.shade100
                                : Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            label == 'Top'
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 13,
                            color: label == 'Top'
                                ? Colors.blue.shade700
                                : Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Label $label",
                          style: TextStyle(
                            color: label == 'Top'
                                ? Colors.blue.shade700
                                : Colors.purple.shade700,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MachineDataCard(machineDocId: doc.id, data: data),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _groupChip(IconData icon, String label, Color color) => Container(
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
//  MACHINE DATA CARD
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
    final machineName = widget.data['machineName'] ?? '—';
    final productName = widget.data['productName'] ?? '—';
    final jobCardNumber = widget.data['jobCardNumber'] ?? '—';
    final labelPart = widget.data['labelPart'] ?? '';
    final bool isManual = machineName.toLowerCase().contains('manual');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          left: BorderSide(
            color: _isSaved ? AppColors.success : AppColors.accent,
            width: 4,
          ),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          childrenPadding: EdgeInsets.zero,
          collapsedIconColor: AppColors.primary,
          iconColor: AppColors.primary,
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: isManual
                  ? AppColors.accentGradient
                  : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: (isManual ? AppColors.secondary : AppColors.primary)
                      .withOpacity(0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              isManual
                  ? Icons.back_hand_outlined
                  : Icons.precision_manufacturing_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          title: Text(
            productName,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                _miniChip(
                  Icons.precision_manufacturing_rounded,
                  machineName,
                  AppColors.primary,
                ),
                _miniChip(
                  Icons.assignment_rounded,
                  jobCardNumber,
                  AppColors.info,
                ),
                if (labelPart.isNotEmpty)
                  _miniChip(
                    labelPart == 'Top'
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    'Label $labelPart',
                    labelPart == 'Top'
                        ? Colors.blue.shade600
                        : Colors.purple.shade600,
                  ),
                _miniChip(
                  Icons.scale_outlined,
                  "Ref: $_originalQty pcs",
                  AppColors.accent,
                ),
              ],
            ),
          ),
          trailing: _statusBadge(_isSaved),
          children: [
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primary,
                    Colors.cyan.shade400,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 400),
              crossFadeState: _isSaved
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Padding(
                padding: const EdgeInsets.all(18),
                child: _buildForm(),
              ),
              secondChild: _isSaved
                  ? Padding(
                      padding: const EdgeInsets.all(18),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildSavedView(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════
  //  FORM
  // ════════════════════════════════
  Widget _buildForm() {
    final dateStr = DateFormat('EEEE, dd MMM yyyy').format(_autoDate);
    final labelPart = widget.data['labelPart'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Product Info Banner ──────────────────────────────
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
                    Text(
                      "${widget.data['machineName'] ?? '—'}  ·  "
                      "${widget.data['jobCardNumber'] ?? '—'}"
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

        // ── Date ─────────────────────────────────────────────
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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

        // ── Quantity ──────────────────────────────────────────
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

        // ── Approval ──────────────────────────────────────────
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

        // ── Remark ────────────────────────────────────────────
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

        // ── Save Button ───────────────────────────────────────
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

  // ════════════════════════════════
  //  SAVED VIEW
  // ════════════════════════════════
  Widget _buildSavedView() {
    final approved = _savedData?['approved'] as bool? ?? false;
    final remark = (_savedData?['remark'] ?? '') as String;
    final savedQty = _savedData?['quantity'] ?? widget.data['quantity'] ?? 0;
    final originalQty = _savedData?['originalQty'] ?? _originalQty;
    final dateRaw = _savedData?['date'];
    String dateStr = '—';
    if (dateRaw is Timestamp)
      dateStr = DateFormat('dd MMM yyyy').format(dateRaw.toDate());
    else if (dateRaw is DateTime)
      dateStr = DateFormat('dd MMM yyyy').format(dateRaw);

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
          // Header
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

  // ─── Helpers ──────────────────────────────────────────
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

  Widget _miniChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _statusBadge(bool saved) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: saved
            ? [
                AppColors.success.withOpacity(0.15),
                AppColors.success.withOpacity(0.05),
              ]
            : [
                AppColors.accent.withOpacity(0.15),
                AppColors.accent.withOpacity(0.05),
              ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: (saved ? AppColors.success : AppColors.accent).withOpacity(0.6),
        width: 1.2,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          saved ? Icons.check_circle_rounded : Icons.pending_rounded,
          size: 12,
          color: saved ? AppColors.success : AppColors.accent,
        ),
        const SizedBox(width: 5),
        Text(
          saved ? "SAVED" : "PENDING",
          style: TextStyle(
            color: saved ? AppColors.success : AppColors.accent,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
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

// ══════════════════════════════════════════════════════════
//  SNACK BARS
// ══════════════════════════════════════════════════════════
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
