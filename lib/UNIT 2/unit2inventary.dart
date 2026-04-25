import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/UNIT%202/Unit2ProductSimpleScreen.dart';
import 'package:flutter/material.dart';
const _kGreen900 = Color(0xFF0A3D1F);
const _kGreen700 = Color(0xFF1B6B3A);
const _kGreen500 = Color(0xFF2ECC71);
const _kGreen100 = Color(0xFFE8F5E9);
const _kBg = Color(0xFFF3F7F4);
const _kCard = Colors.white;
const _kText = Color(0xFF1A2E22);
const _kSubText = Color(0xFF6B8F71);
class Unit2InventoryScreen extends StatefulWidget {
  const Unit2InventoryScreen({super.key});
  @override
  State<Unit2InventoryScreen> createState() => _Unit2InventoryScreenState();
}
class _Unit2InventoryScreenState extends State<Unit2InventoryScreen> {
  final _searchCtrl = TextEditingController();
  final ValueNotifier<String> _query = ValueNotifier('');
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _query.value = _searchCtrl.text;
    });
  }

  int _totalQty(List<QueryDocumentSnapshot> docs, String productName) {
    int total = 0;
    final q = productName.toLowerCase().trim();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final products = List<Map<String, dynamic>>.from(data['products'] ?? []);
      for (final p in products) {
        if ((p['productName'] ?? '').toString().toLowerCase().contains(q)) {
          total += int.tryParse(p['quantity']?.toString() ?? '0') ?? 0;
        }
      }
    }
    return total;
  }

  int _grandTotal(List<QueryDocumentSnapshot> docs) {
    int total = 0;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final products = List<Map<String, dynamic>>.from(data['products'] ?? []);
      for (final p in products) {
        total += int.tryParse(p['quantity']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
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
                // 🔙 BACK BUTTON
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

                // 🏷️ LOGO
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset('assets/dpl.png', height: 36),
                ),

                const SizedBox(width: 8),

                // 📝 TITLE
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Unit 2 Inventory 👷‍♂️',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage Inventory for Unit 2',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // 🕘 HISTORY ICON
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Unit2ProductSimpleScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('unit2JobCards')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _FullLoader();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyState();
          }

          final allDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['jobCardNumber'] ?? '').toString().trim().isNotEmpty;
          }).toList();

          if (allDocs.isEmpty) return const _EmptyState();

          return ValueListenableBuilder<String>(
            valueListenable: _query,
            builder: (context, query, _) {
              final hasQuery = query.trim().isNotEmpty;

              // Qty summary
              final summaryQty = hasQuery
                  ? _totalQty(allDocs, query.trim())
                  : _grandTotal(allDocs);
              final summaryLabel = hasQuery
                  ? 'Total qty — "${query.trim()}"'
                  : 'Total Qty (All Products)';

              // Filter cards
              final filteredDocs = hasQuery
                  ? allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final products = List<Map<String, dynamic>>.from(
                        data['products'] ?? [],
                      );
                      return products.any(
                        (p) => (p['productName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(query.trim().toLowerCase()),
                      );
                    }).toList()
                  : allDocs;

              return Column(
                children: [
                  // ── Search bar ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by product name...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _kGreen700.withOpacity(0.7),
                          ),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey.shade400,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Qty Summary banner ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasQuery
                              ? [Colors.blue.shade700, Colors.blue.shade500]
                              : [_kGreen900, _kGreen700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (hasQuery ? Colors.blue : _kGreen700)
                                .withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              hasQuery
                                  ? Icons.filter_alt_rounded
                                  : Icons.inventory_2_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              summaryLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              '$summaryQty',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Cards list ──────────────────────────────────────
                  Expanded(
                    child: filteredDocs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 56,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No results for "$query"',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  filteredDocs[index].data()
                                      as Map<String, dynamic>;
                              return _InventoryCard(
                                data: data,
                                docId: filteredDocs[index].id,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}


class _FullLoader extends StatelessWidget {
  const _FullLoader();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(_kGreen700),
      strokeWidth: 3,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _kGreen100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded, size: 48, color: _kGreen700),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Job Cards Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Job cards will appear here once created.',
            style: TextStyle(fontSize: 13, color: _kSubText),
          ),
        ],
      ),
    );
  }
}


class _InventoryCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _InventoryCard({required this.data, required this.docId});
  @override
  State<_InventoryCard> createState() => _InventoryCardState();
}
class _InventoryCardState extends State<_InventoryCard> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final products = List<Map<String, dynamic>>.from(
      widget.data['products'] ?? [],
    );
    final jobCardNumber = widget.data['jobCardNumber'] ?? '';
    final companyName = widget.data['companyName'] ?? '';
    final customerName = widget.data['customerName'] ?? '';
    final status = widget.data['status'] ?? '';
    final isDispatched = status == 'Dispatched';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDispatched
              ? _kGreen500.withOpacity(0.5)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_kGreen900, _kGreen700]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job card number
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white60,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$jobCardNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$companyName • $customerName',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                isDispatched
                    ? _StatusBadge(label: 'Dispatched', color: _kGreen500)
                    : _StatusBadge(label: 'In Progress', color: Colors.orange),
              ],
            ),
          ),

     
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.category_rounded,
                      size: 14,
                      color: _kSubText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${products.length} Product(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _kSubText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...products.asMap().entries.map((entry) {
                  final index = entry.key;
                  final p = entry.value;
                  final isOpen = expandedIndex == index;
                  final prodName = p['productName'] ?? '';
                  final qty = p['quantity'] ?? 0;

                  return Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(
                          () => expandedIndex = isOpen ? null : index,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen ? _kGreen100 : _kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOpen
                                  ? _kGreen500.withOpacity(0.4)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _kGreen700.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  prodName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _kText,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _kGreen700.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Qty: $qty',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _kGreen700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: isOpen ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: _kSubText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isOpen
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _ProcessChecklist(
                                  jobCardId: widget.docId,
                                  productQty: int.tryParse(qty.toString()) ?? 0,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (index < products.length - 1)
                        const SizedBox(height: 10),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


class _ProcessChecklist extends StatefulWidget {
  final String jobCardId;
  final int productQty;
  const _ProcessChecklist({required this.jobCardId, required this.productQty});
  @override
  State<_ProcessChecklist> createState() => _ProcessChecklistState();
}

class _ProcessChecklistState extends State<_ProcessChecklist> {
  bool _isDispatching = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('unit2JobCards')
          .doc(widget.jobCardId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_kGreen700),
              ),
            ),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final processStatus = Map<String, dynamic>.from(
          data['processStatus'] ?? {},
        );
        final isAlreadyDispatched = data['status'] == 'Dispatched';

        int kappaQty =
            int.tryParse(processStatus['kappa']?['qty']?.toString() ?? '') ??
            widget.productQty;
        int labelPassQty =
            int.tryParse(
              processStatus['label_pass']?['qty']?.toString() ?? '',
            ) ??
            0;

        bool kappaDone = processStatus['kappa']?['done'] == true;
        bool labelTopDone = processStatus['label_top']?['done'] == true;
        bool labelBotDone = processStatus['label_bottom']?['done'] == true;
        bool labelDone = labelTopDone && labelBotDone;
        bool trayDone = processStatus['tray']?['done'] == true;
        bool grovingDone = processStatus['groving']?['done'] == true;
        bool pvcDone = processStatus['pvc/butter']?['done'] == true;
        bool allDone =kappaDone && labelDone && trayDone && grovingDone && pvcDone;
        bool kappaEnabled = !isAlreadyDispatched;
        bool labelEnabled = kappaDone && !isAlreadyDispatched;
        bool trayEnabled = labelDone && !isAlreadyDispatched;
        bool grovingEnabled = trayDone && !isAlreadyDispatched;
        bool pvcEnabled = grovingDone && !isAlreadyDispatched;
        int trayQty = labelPassQty > 0 ? labelPassQty : widget.productQty;
        int grovingQty =
            int.tryParse(processStatus['tray']?['qty']?.toString() ?? '') ??
            trayQty;
        int pvcQty =
            int.tryParse(processStatus['groving']?['qty']?.toString() ?? '') ??
            grovingQty;
        int doneCount = [
          kappaDone,
          labelDone,
          trayDone,
          grovingDone,
          pvcDone,
        ].where((e) => e).length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.checklist_rounded,
                    size: 16,
                    color: _kGreen700,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Process Checklist',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _kText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$doneCount/5 Done',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSubText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: doneCount / 5,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(_kGreen500),
                ),
              ),
              const SizedBox(height: 16),
              _ProcessRow(
                label: 'Kappa',
                icon: Icons.layers_rounded,
                done: kappaDone,
                enabled: kappaEnabled,
                remarkController: TextEditingController(
                  text: (processStatus['kappa']?['remark'] ?? '') as String,
                ),
                time: processStatus['kappa']?['time'] as Timestamp?,
                qtyHint: 'Qty: ${widget.productQty}',
                onToggle: (val) => _saveProcess(
                  'kappa',
                  val,
                  widget.productQty,
                  (processStatus['kappa']?['remark'] ?? '') as String,
                ),
                onRemarkSave: (val) => _saveRemark('kappa', val),
              ),
              const SizedBox(height: 8),
              _LabelSplitRow(
                enabled: labelEnabled,
                isAlreadyDispatched: isAlreadyDispatched,
                processStatus: processStatus,
                inputQty: kappaQty,
                jobCardId: widget.jobCardId,
              ),
              const SizedBox(height: 8),
              _ProcessRow(
                label: 'Tray',
                icon: Icons.inventory_rounded,
                done: trayDone,
                enabled: trayEnabled,
                remarkController: TextEditingController(
                  text: (processStatus['tray']?['remark'] ?? '') as String,
                ),
                time: processStatus['tray']?['time'] as Timestamp?,
                qtyHint: 'Qty passed: $trayQty',
                onToggle: (val) => _saveProcess(
                  'tray',
                  val,
                  trayQty,
                  (processStatus['tray']?['remark'] ?? '') as String,
                ),
                onRemarkSave: (val) => _saveRemark('tray', val),
              ),
              const SizedBox(height: 8),
              _ProcessRow(
                label: 'Groving',
                icon: Icons.build_circle_rounded,
                done: grovingDone,
                enabled: grovingEnabled,
                remarkController: TextEditingController(
                  text: (processStatus['groving']?['remark'] ?? '') as String,
                ),
                time: processStatus['groving']?['time'] as Timestamp?,
                qtyHint: 'Qty passed: $grovingQty',
                onToggle: (val) => _saveProcess(
                  'groving',
                  val,
                  grovingQty,
                  (processStatus['groving']?['remark'] ?? '') as String,
                ),
                onRemarkSave: (val) => _saveRemark('groving', val),
              ),
              const SizedBox(height: 8),
              _ProcessRow(
                label: 'PVC/Butter',
                icon: Icons.verified_rounded,
                done: pvcDone,
                enabled: pvcEnabled,
                remarkController: TextEditingController(
                  text:
                      (processStatus['pvc/butter']?['remark'] ?? '') as String,
                ),
                time: processStatus['pvc/butter']?['time'] as Timestamp?,
                qtyHint: 'Qty passed: $pvcQty',
                onToggle: (val) => _saveProcess(
                  'pvc/butter',
                  val,
                  pvcQty,
                  (processStatus['pvc/butter']?['remark'] ?? '') as String,
                ),
                onRemarkSave: (val) => _saveRemark('pvc/butter', val),
              ),
              const SizedBox(height: 16),
              _DispatchButton(
                allDone: allDone,
                isDispatched: isAlreadyDispatched,
                isLoading: _isDispatching,
                onDispatch: () => _handleDispatch(context, data, labelPassQty),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProcess(
    String key,
    bool? val,
    int qty,
    String remark,
  ) async {
    await FirebaseFirestore.instance
        .collection('unit2JobCards')
        .doc(widget.jobCardId)
        .set({
          'processStatus': {
            key: {
              'done': val,
              'qty': qty,
              'remark': remark,
              'time': FieldValue.serverTimestamp(),
            },
          },
        }, SetOptions(merge: true));
  }

  Future<void> _saveRemark(String key, String val) async {
    await FirebaseFirestore.instance
        .collection('unit2JobCards')
        .doc(widget.jobCardId)
        .set({
          'processStatus': {
            key: {'remark': val},
          },
        }, SetOptions(merge: true));
  }

  Future<void> _handleDispatch(
    BuildContext context,
    Map<String, dynamic> jobData,
    int labelMinQty,
  ) async {
    if (_isDispatching) return;
    setState(() => _isDispatching = true);
    try {
      final existing = await FirebaseFirestore.instance
          .collection('unit2Inventory')
          .where('originalJobCardId', isEqualTo: widget.jobCardId)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        final rawProducts = List<Map<String, dynamic>>.from(
          jobData['products'] ?? [],
        );
        final updatedProducts = rawProducts.map((p) {
          return {
            ...p,
            'quantity': labelMinQty > 0 ? labelMinQty : p['quantity'],
          };
        }).toList();
        await FirebaseFirestore.instance.collection('unit2Inventory').add({
          ...jobData,
          'products': updatedProducts,
          'originalJobCardId': widget.jobCardId,
          'inventoryStatus': 'In Stock',
          'dispatchedQty': labelMinQty,
          'inventoryCreatedAt': FieldValue.serverTimestamp(),
        });
      }
      await FirebaseFirestore.instance
          .collection('unit2JobCards')
          .doc(widget.jobCardId)
          .update({
            'status': 'Dispatched',
            'dispatchedAt': FieldValue.serverTimestamp(),
          });
      if (context.mounted) _showSuccessSnack(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDispatching = false);
    }
  }

  void _showSuccessSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _kGreen700,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Dispatched & saved to Inventory!',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _LabelSplitRow extends StatefulWidget {
  final bool enabled;
  final bool isAlreadyDispatched;
  final Map<String, dynamic> processStatus;
  final int inputQty;
  final String jobCardId;
  const _LabelSplitRow({
    required this.enabled,
    required this.isAlreadyDispatched,
    required this.processStatus,
    required this.inputQty,
    required this.jobCardId,
  });
  @override
  State<_LabelSplitRow> createState() => _LabelSplitRowState();
}

class _LabelSplitRowState extends State<_LabelSplitRow> {
  late TextEditingController _topQtyCtrl;
  late TextEditingController _botQtyCtrl;
  late TextEditingController _topRemarkCtrl;
  late TextEditingController _botRemarkCtrl;
  String? _qtyError;

  @override
  void initState() {
    super.initState();
    final topData = Map<String, dynamic>.from(
      widget.processStatus['label_top'] ?? {},
    );
    final botData = Map<String, dynamic>.from(
      widget.processStatus['label_bottom'] ?? {},
    );
    _topQtyCtrl = TextEditingController(text: topData['qty']?.toString() ?? '');
    _botQtyCtrl = TextEditingController(text: botData['qty']?.toString() ?? '');
    _topRemarkCtrl = TextEditingController(
      text: topData['remark']?.toString() ?? '',
    );
    _botRemarkCtrl = TextEditingController(
      text: botData['remark']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _topQtyCtrl.dispose();
    _botQtyCtrl.dispose();
    _topRemarkCtrl.dispose();
    _botRemarkCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final topQty = int.tryParse(_topQtyCtrl.text) ?? 0;
    final botQty = int.tryParse(_botQtyCtrl.text) ?? 0;
    if (topQty > widget.inputQty || botQty > widget.inputQty) {
      setState(
        () => _qtyError = '⚠️ Qty cannot exceed total qty (${widget.inputQty})',
      );
      return false;
    }
    setState(() => _qtyError = null);
    return true;
  }

  Future<void> _save(String subKey, bool? done, int qty, String remark) async {
    if (!_validate()) return;
    final topQty = int.tryParse(_topQtyCtrl.text) ?? 0;
    final botQty = int.tryParse(_botQtyCtrl.text) ?? 0;
    int passQty = 0;
    if (topQty > 0 || botQty > 0) {
      if (topQty == botQty) {
        passQty = topQty;
      } else {
        passQty = topQty < botQty ? topQty : botQty;
      }
    }
    await FirebaseFirestore.instance
        .collection('unit2JobCards')
        .doc(widget.jobCardId)
        .set({
          'processStatus': {
            subKey: {
              'done': done,
              'qty': qty,
              'remark': remark,
              'time': FieldValue.serverTimestamp(),
            },
            'label_pass': {
              'qty': passQty,
              'time': FieldValue.serverTimestamp(),
            },
          },
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final topData = Map<String, dynamic>.from(
      widget.processStatus['label_top'] ?? {},
    );
    final botData = Map<String, dynamic>.from(
      widget.processStatus['label_bottom'] ?? {},
    );
    final topDone = topData['done'] == true;
    final botDone = botData['done'] == true;
    final topQty = int.tryParse(_topQtyCtrl.text) ?? 0;
    final botQty = int.tryParse(_botQtyCtrl.text) ?? 0;
    final isOverLimit = topQty > widget.inputQty || botQty > widget.inputQty;
    final minQty = (topQty > 0 && botQty > 0)
        ? (topQty < botQty ? topQty : botQty)
        : 0;
    final maxQty = topQty > botQty ? topQty : botQty;
    final topIsHigher = topQty >= botQty && topQty > 0 && botQty > 0;
    final botIsHigher = botQty > topQty && topQty > 0 && botQty > 0;

    return Container(
      decoration: BoxDecoration(
        color: isOverLimit
            ? Colors.red.withOpacity(0.04)
            : _kGreen500.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverLimit
              ? Colors.red.withOpacity(0.4)
              : _kGreen500.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? _kGreen700.withOpacity(0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.label_rounded,
                  size: 18,
                  color: widget.enabled ? _kGreen700 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Label',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: widget.enabled ? _kText : Colors.grey.shade400,
                  ),
                ),
              ),
              if (!widget.enabled)
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              if (topDone && botDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kGreen500.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kGreen500.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: _kGreen500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Both Done • Pass: $minQty',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kGreen500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LabelSubCard(
                  title: 'Top',
                  icon: Icons.arrow_upward_rounded,
                  done: topDone,
                  enabled: widget.enabled,
                  isHighlighted: topIsHigher,
                  highlightLabel: topIsHigher ? 'Stays here' : '',
                  qtyController: _topQtyCtrl,
                  remarkController: _topRemarkCtrl,
                  time: topData['time'] as Timestamp?,
                  inputQty: widget.inputQty,
                  isOverLimit: isOverLimit,
                  onToggle: () {
                    final qty = int.tryParse(_topQtyCtrl.text) ?? 0;
                    _save('label_top', !topDone, qty, _topRemarkCtrl.text);
                  },
                  onSave: () {
                    _validate();
                    final qty = int.tryParse(_topQtyCtrl.text) ?? 0;
                    _save('label_top', topDone, qty, _topRemarkCtrl.text);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabelSubCard(
                  title: 'Bottom',
                  icon: Icons.arrow_downward_rounded,
                  done: botDone,
                  enabled: widget.enabled,
                  isHighlighted: botIsHigher,
                  highlightLabel: botIsHigher ? 'Stays here' : '',
                  qtyController: _botQtyCtrl,
                  remarkController: _botRemarkCtrl,
                  time: botData['time'] as Timestamp?,
                  inputQty: widget.inputQty,
                  isOverLimit: isOverLimit,
                  onToggle: () {
                    final qty = int.tryParse(_botQtyCtrl.text) ?? 0;
                    _save('label_bottom', !botDone, qty, _botRemarkCtrl.text);
                  },
                  onSave: () {
                    _validate();
                    final qty = int.tryParse(_botQtyCtrl.text) ?? 0;
                    _save('label_bottom', botDone, qty, _botRemarkCtrl.text);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          if (isOverLimit) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Qty cannot exceed total qty (${widget.inputQty})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!isOverLimit && (topQty > 0 || botQty > 0)) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kGreen900.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip(
                    label: 'Top',
                    value: '$topQty',
                    color: Colors.blue,
                  ),
                  const Text(
                    '+',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _kSubText,
                    ),
                  ),
                  _SummaryChip(
                    label: 'Bottom',
                    value: '$botQty',
                    color: Colors.purple,
                  ),
                  const Text(
                    '→',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _kSubText,
                    ),
                  ),
                  _SummaryChip(
                    label: 'Pass Forward',
                    value: '$minQty',
                    color: _kGreen700,
                  ),
                  if (maxQty > minQty && minQty > 0)
                    _SummaryChip(
                      label: 'Held',
                      value: '${maxQty - minQty}',
                      color: Colors.orange,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LabelSubCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool done;
  final bool enabled;
  final bool isHighlighted;
  final String highlightLabel;
  final TextEditingController qtyController;
  final TextEditingController remarkController;
  final Timestamp? time;
  final int inputQty;
  final bool isOverLimit;
  final VoidCallback onToggle;
  final VoidCallback onSave;
  const _LabelSubCard({
    required this.title,
    required this.icon,
    required this.done,
    required this.enabled,
    required this.isHighlighted,
    required this.highlightLabel,
    required this.qtyController,
    required this.remarkController,
    required this.time,
    required this.inputQty,
    required this.isOverLimit,
    required this.onToggle,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOverLimit
            ? Colors.red.withOpacity(0.05)
            : done
            ? _kGreen500.withOpacity(0.08)
            : isHighlighted
            ? Colors.orange.withOpacity(0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverLimit
              ? Colors.red.withOpacity(0.4)
              : done
              ? _kGreen500.withOpacity(0.4)
              : isHighlighted
              ? Colors.orange.withOpacity(0.5)
              : Colors.grey.shade200,
          width: isHighlighted || isOverLimit ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: enabled ? _kGreen700 : Colors.grey.shade400,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Label $title',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: enabled ? _kText : Colors.grey.shade400,
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: done,
                  onChanged: (enabled && !isOverLimit)
                      ? (_) => onToggle()
                      : null,
                  activeColor: _kGreen500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  side: BorderSide(
                    color: enabled
                        ? _kGreen700.withOpacity(0.4)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (isHighlighted && highlightLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                highlightLabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (enabled) ...[
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => onSave(),
              decoration: InputDecoration(
                hintText: 'Qty (total ≤ $inputQty)',
                hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                isDense: true,
                prefixIcon: Icon(
                  Icons.production_quantity_limits,
                  size: 14,
                  color: isOverLimit ? Colors.red : _kGreen700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isOverLimit
                        ? Colors.red.withOpacity(0.5)
                        : Colors.grey.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isOverLimit ? Colors.red : _kGreen500,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: remarkController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Remark...',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 13,
                    color: _kGreen700,
                  ),
                  onPressed: onSave,
                  padding: EdgeInsets.zero,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kGreen500, width: 1.5),
                ),
              ),
              onSubmitted: (_) => onSave(),
            ),
          ] else ...[
            if (qtyController.text.isNotEmpty)
              Text(
                'Qty: ${qtyController.text}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSubText,
                ),
              ),
          ],
          if (time != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 11,
                  color: _kSubText,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    _formatTime(time!),
                    style: const TextStyle(fontSize: 10, color: _kSubText),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(Timestamp ts) {
    final d = ts.toDate();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  $h:$m';
  }
}


class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _ProcessRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool done;
  final bool enabled;
  final TextEditingController remarkController;
  final Timestamp? time;
  final String qtyHint;
  final ValueChanged<bool?> onToggle;
  final ValueChanged<String> onRemarkSave;
  const _ProcessRow({
    required this.label,
    required this.icon,
    required this.done,
    required this.enabled,
    required this.remarkController,
    required this.time,
    required this.qtyHint,
    required this.onToggle,
    required this.onRemarkSave,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done
            ? _kGreen500.withOpacity(0.08)
            : enabled
            ? Colors.white
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? _kGreen500.withOpacity(0.4) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: done
                      ? _kGreen500.withOpacity(0.15)
                      : enabled
                      ? _kGreen700.withOpacity(0.08)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: done
                      ? _kGreen500
                      : enabled
                      ? _kGreen700
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: enabled ? _kText : Colors.grey.shade400,
                      ),
                    ),
                    if (qtyHint.isNotEmpty)
                      Text(
                        qtyHint,
                        style: const TextStyle(fontSize: 11, color: _kSubText),
                      ),
                  ],
                ),
              ),
              if (!enabled)
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: done,
                  onChanged: enabled ? onToggle : null,
                  activeColor: _kGreen500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  side: BorderSide(
                    color: enabled
                        ? _kGreen700.withOpacity(0.4)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            TextField(
              controller: remarkController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add remark...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: _kGreen500, width: 1.5),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 16,
                    color: _kGreen700,
                  ),
                  onPressed: () => onRemarkSave(remarkController.text),
                ),
              ),
              onSubmitted: onRemarkSave,
            ),
          ],
          if (time != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: _kSubText,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(time!),
                  style: const TextStyle(fontSize: 11, color: _kSubText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(Timestamp ts) {
    final d = ts.toDate();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  $h:$m';
  }
}

// ─────────────────────────────────────────────────────────────
//  Dispatch Button (unchanged)
// ─────────────────────────────────────────────────────────────
class _DispatchButton extends StatelessWidget {
  final bool allDone;
  final bool isDispatched;
  final bool isLoading;
  final VoidCallback onDispatch;
  const _DispatchButton({
    required this.allDone,
    required this.isDispatched,
    required this.isLoading,
    required this.onDispatch,
  });

  @override
  Widget build(BuildContext context) {
    if (isDispatched) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kGreen500.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kGreen500.withOpacity(0.5), width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: _kGreen500, size: 18),
            SizedBox(width: 8),
            Text(
              'Ready for Production',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _kGreen500,
              ),
            ),
          ],
        ),
      );
    }
    final canDispatch = allDone && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canDispatch ? onDispatch : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canDispatch ? _kGreen700 : Colors.grey.shade300,
          disabledBackgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: canDispatch ? 3 : 0,
          shadowColor: _kGreen700.withOpacity(0.4),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    allDone
                        ? Icons.local_shipping_rounded
                        : Icons.lock_clock_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    allDone
                        ? 'Ready for Production'
                        : 'COMPLETE ALL PROCESSES FIRST',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
