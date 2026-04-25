import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

const _kGreen700 = Color(0xFF1B6B3A);

// ══════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════

/// Ek product row ka data — doc reference ke saath
class _ProductEntry {
  final String inventoryDocId;
  final String jobCardNumber;
  final String companyName;
  final int productIndexInDoc; // us doc ke andar index
  final Map<String, dynamic> productData;
  final int dispatchedQty;
  final Map<String, dynamic> fullDocData;

  const _ProductEntry({
    required this.inventoryDocId,
    required this.jobCardNumber,
    required this.companyName,
    required this.productIndexInDoc,
    required this.productData,
    required this.dispatchedQty,
    required this.fullDocData,
  });
}

// ══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════
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

          // ════════════════════════════════════════════════
          // KEY CHANGE: Saare docs ke saare products ko
          // productName se group karo (cross-document grouping)
          // Normalize key: lowercase + collapse whitespace + trim
          // Taaki "8x8 " aur "8x8" same group mein aayein
          // ════════════════════════════════════════════════

          // normalizedKey -> {displayName, entries}
          final Map<String, String> keyToDisplay = {};
          final Map<String, List<_ProductEntry>> grouped = {};

          String _normalizeKey(String name) =>
              name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
List<Map<String, dynamic>> products = [];

if (data['products'] is List && (data['products'] as List).isNotEmpty) {
  products = List<Map<String, dynamic>>.from(data['products']);
} else if (data['product'] != null) {
  products = [Map<String, dynamic>.from(data['product'])];
}            final dispatchedQty =
                int.tryParse(data['dispatchedQty']?.toString() ?? '') ?? 0;

            final companyName =
                (data['companyName']?.toString().trim().isNotEmpty == true
                    ? data['companyName']?.toString().trim()
                    : data['customerName']?.toString().trim()) ??
                '';

            final jobCardNumber = data['jobCardNumber']?.toString() ?? '';

            for (int i = 0; i < products.length; i++) {
              final product = Map<String, dynamic>.from(products[i] as Map);
              final rawName = product['productName']?.toString().trim() ?? '—';
              final groupKey = _normalizeKey(rawName);

              // Pehli baar aane wala display name rakh lo
              keyToDisplay.putIfAbsent(groupKey, () => rawName);

              grouped
                  .putIfAbsent(groupKey, () => [])
                  .add(
                    _ProductEntry(
                      inventoryDocId: doc.id,
                      jobCardNumber: jobCardNumber,
                      companyName: companyName,
                      productIndexInDoc: i,
                      productData: product,
                      dispatchedQty: dispatchedQty,
                      fullDocData: data,
                    ),
                  );
            }
          }

          final groupKeys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            itemCount: groupKeys.length,
            itemBuilder: (context, i) {
              final key = groupKeys[i];
              final entries = grouped[key]!;
              // Display name: original casing wala naam use karo
              final displayName = keyToDisplay[key] ?? key;
              return _ProductGroupCard(
                productName: displayName,
                entries: entries,
              );
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  PRODUCT GROUP CARD
//  Ek product name ka card — andar multiple customer rows
// ══════════════════════════════════════════════════════════
class _ProductGroupCard extends StatefulWidget {
  final String productName;
  final List<_ProductEntry> entries;

  const _ProductGroupCard({required this.productName, required this.entries});

  @override
  State<_ProductGroupCard> createState() => _ProductGroupCardState();
}

class _ProductGroupCardState extends State<_ProductGroupCard> {
  final Set<int> _savedIndexes = {}; // entries list ke indexes
  final Set<int> _selected = {};
  bool _showMachinePanel = false;
  bool _loadingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadSavedIndexes();
  }

  Future<void> _loadSavedIndexes() async {
    // Saare unique inventoryDocIds collect karo
    final docIds = widget.entries.map((e) => e.inventoryDocId).toSet().toList();

    final Set<String> savedKeys = {};

    // Har doc ke liye saved check karo
    for (final docId in docIds) {
      final snapshot = await FirebaseFirestore.instance
          .collection('unit2MachineProcess')
          .where('inventoryDocId', isEqualTo: docId)
          .get();

      for (final d in snapshot.docs) {
        final pName = d['productName']?.toString() ?? '';
        // key = docId + productName (unique combination)
        savedKeys.add('${docId}_$pName');
      }
    }

    final Set<int> saved = {};
    for (int i = 0; i < widget.entries.length; i++) {
      final e = widget.entries[i];
      final key =
          '${e.inventoryDocId}_${e.productData['productName']?.toString() ?? ''}';
      if (savedKeys.contains(key)) saved.add(i);
    }

    if (!mounted) return;
    setState(() {
      _savedIndexes.addAll(saved);
      _selected.addAll(saved);
      _loadingSaved = false;
    });
  }

  void _toggleIndex(int i) {
    if (_savedIndexes.contains(i)) return;
    setState(() {
      if (_selected.contains(i)) {
        _selected.remove(i);
      } else {
        _selected.add(i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalQty = widget.entries.fold<int>(
      0,
      (sum, e) =>
          sum +
          (int.tryParse(e.productData['quantity']?.toString() ?? '0') ?? 0),
    );

    // Unique customers
    final customers = widget.entries.map((e) => e.companyName).toSet().toList();

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
              widget.productName,
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
                    Icons.people_rounded,
                    '${widget.entries.length} entr${widget.entries.length > 1 ? 'ies' : 'y'}',
                    _C.info,
                  ),
                  _chip(
                    Icons.inventory_2_rounded,
                    'Total Qty: $totalQty',
                    _C.success,
                  ),
                  // Customers badges
                  ...customers.map(
                    (c) => _chip(Icons.business_rounded, c, _C.primary),
                  ),
                ],
              ),
            ),
            children: [
              // Gradient separator
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

              // ── TABLE HEADER ──
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
                    SizedBox(width: 36, child: _HCell('✓', center: true)),
                    SizedBox(width: 6),
                    SizedBox(width: 28, child: _HCell('Sr')),
                    SizedBox(width: 10),
                    Expanded(flex: 3, child: _HCell('Customer / Job Card')),
                    SizedBox(width: 48, child: _HCell('Qty', center: true)),
                    SizedBox(width: 8),
                    SizedBox(width: 56, child: _HCell('Image', center: true)),
                  ],
                ),
              ),

              if (_loadingSaved)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_C.primary),
                      ),
                    ),
                  ),
                ),

              // ── ROWS ──
              ...widget.entries.asMap().entries.map((entry) {
                final rowNum = entry.key;
                final idx = rowNum;
                final e = entry.value;
                final qty = e.dispatchedQty > 0
                    ? e.dispatchedQty
                    : (int.tryParse(
                            e.productData['quantity']?.toString() ?? '0',
                          ) ??
                          0);

                final imgs =
                    (e.productData['images'] as List?)
                        ?.map((x) => x.toString())
                        .where((x) => x.isNotEmpty)
                        .toList() ??
                    [];
                final imageUrl = imgs.isNotEmpty ? imgs.first : null;

                final isSaved = _savedIndexes.contains(idx);
                final isTicked = _selected.contains(idx);
                final isEven = rowNum % 2 == 0;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleIndex(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isTicked
                              ? (isSaved
                                    ? _C.success.withOpacity(0.06)
                                    : _C.primary.withOpacity(0.06))
                              : isEven
                              ? Colors.white
                              : const Color(0xFFF3F7F4),
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade100,
                              width: 1,
                            ),
                            left: isTicked
                                ? BorderSide(
                                    color: isSaved ? _C.success : _C.primary,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Checkbox
                            SizedBox(
                              width: 36,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: isSaved
                                      ? _C.successGrad
                                      : isTicked
                                      ? _C.primaryGrad
                                      : null,
                                  color: (isTicked || isSaved)
                                      ? null
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSaved
                                        ? _C.success
                                        : isTicked
                                        ? _C.primary
                                        : Colors.grey.shade300,
                                    width: (isTicked || isSaved) ? 0 : 1.5,
                                  ),
                                  boxShadow: (isTicked || isSaved)
                                      ? [
                                          BoxShadow(
                                            color:
                                                (isSaved
                                                        ? _C.success
                                                        : _C.primary)
                                                    .withOpacity(0.3),
                                            blurRadius: 5,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: (isTicked || isSaved)
                                    ? Icon(
                                        isSaved
                                            ? Icons.verified_rounded
                                            : Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Sr No
                            SizedBox(
                              width: 28,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  '${rowNum + 1}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Customer + Job Card
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.companyName.isNotEmpty
                                          ? e.companyName
                                          : '—',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue.shade700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (e.jobCardNumber.isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.tag_rounded,
                                            size: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              e.jobCardNumber,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Qty
                            SizedBox(
                              width: 48,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _kGreen700,
                                        Colors.teal.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$qty',
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

                            const SizedBox(width: 8),

                            // Image
                            SizedBox(
                              width: 56,
                              child: Center(
                                child: imageUrl != null
                                    ? GestureDetector(
                                        onTap: () => _openImages(context, imgs),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.purple.withOpacity(
                                                0.3,
                                              ),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                            child: Image.network(
                                              imageUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(
                                                    Icons.broken_image_rounded,
                                                    size: 22,
                                                    color: Colors.grey.shade400,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 22,
                                        color: Colors.grey.shade300,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      indent: 14,
                      endIndent: 14,
                    ),
                  ],
                );
              }),

              // ── SELECT ALL / CLEAR ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            for (int i = 0; i < widget.entries.length; i++) {
                              _selected.add(i);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            gradient: _C.primaryGrad,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _C.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.select_all_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'SELECT ALL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selected
                            ..clear()
                            ..addAll(_savedIndexes);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.deselect_rounded,
                                size: 15,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'CLEAR',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _selected.isEmpty
                              ? [Colors.grey.shade200, Colors.grey.shade300]
                              : [Colors.purple.shade600, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_selected.length}/${widget.entries.length}',
                        style: TextStyle(
                          color: _selected.isEmpty
                              ? Colors.grey.shade500
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── ASSIGN MACHINE BUTTON ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: GestureDetector(
                  onTap: () {
                    final unsavedSelected = _selected
                        .where((i) => !_savedIndexes.contains(i))
                        .toSet();
                    if (unsavedSelected.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.orange.shade800,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          content: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Please tick at least one NEW product first',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() => _showMachinePanel = !_showMachinePanel);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _showMachinePanel
                            ? [Colors.purple.shade600, Colors.blue.shade600]
                            : [Colors.grey.shade100, Colors.grey.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showMachinePanel
                            ? Colors.purple.withOpacity(0.4)
                            : Colors.grey.shade300,
                        width: _showMachinePanel ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _showMachinePanel
                              ? Colors.purple.withOpacity(0.22)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _showMachinePanel
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.precision_manufacturing_rounded,
                            size: 15,
                            color: _showMachinePanel
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _showMachinePanel
                                    ? 'Hide Machine Assignment'
                                    : 'Assign Machine',
                                style: TextStyle(
                                  color: _showMachinePanel
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                () {
                                  final unsaved = _selected
                                      .where((i) => !_savedIndexes.contains(i))
                                      .length;
                                  return unsaved == 0
                                      ? 'Tick new items above first'
                                      : '$unsaved new item(s) selected • Top & Bottom';
                                }(),
                                style: TextStyle(
                                  color: _showMachinePanel
                                      ? Colors.white70
                                      : Colors.grey.shade500,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _showMachinePanel
                                ? Colors.white.withOpacity(0.18)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _showMachinePanel
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showMachinePanel ? 'CLOSE' : 'OPEN',
                                style: TextStyle(
                                  color: _showMachinePanel
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _showMachinePanel
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: _showMachinePanel
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── ANIMATED MACHINE PANEL ──
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showMachinePanel
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: _SharedMachinePanel(
                    productName: widget.productName,
                    selectedEntries: _selected
                        .where((i) => !_savedIndexes.contains(i))
                        .map((i) => widget.entries[i])
                        .toList(),
                    onSaved: (savedSet) {
                      setState(() {
                        _savedIndexes.addAll(savedSet);
                        _selected.addAll(savedSet);
                        _showMachinePanel = false;
                      });
                    },
                  ),
                ),
                secondChild: const SizedBox(height: 14),
              ),
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

  void _openImages(BuildContext context, List<String> urls) {
    if (urls.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView(
              children: urls
                  .map(
                    (url) => InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.network(url, fit: BoxFit.contain),
                      ),
                    ),
                  )
                  .toList(),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SHARED MACHINE PANEL
//  Ab multiple entries handle karta hai (cross-doc)
// ══════════════════════════════════════════════════════════
class _SharedMachinePanel extends StatefulWidget {
  final String productName;
  final List<_ProductEntry> selectedEntries;
  final void Function(Set<int> savedIndexes) onSaved;

  const _SharedMachinePanel({
    required this.productName,
    required this.selectedEntries,
    required this.onSaved,
  });

  @override
  State<_SharedMachinePanel> createState() => _SharedMachinePanelState();
}

class _SharedMachinePanelState extends State<_SharedMachinePanel> {
  String? _topMachine;
  final TextEditingController _topRemarkCtrl = TextEditingController();
  String? _botMachine;
  final TextEditingController _botRemarkCtrl = TextEditingController();
  bool _isSaving = false;

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

  Future<void> _saveAll() async {
    if (_topMachine == null || _botMachine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Please select both Top & Bottom machines",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = FieldValue.serverTimestamp();
      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < widget.selectedEntries.length; i++) {
        final e = widget.selectedEntries[i];
        final qty = e.dispatchedQty > 0
            ? e.dispatchedQty
            : (int.tryParse(e.productData['quantity']?.toString() ?? '0') ?? 0);

        final topDocId = '${e.inventoryDocId}_${e.productIndexInDoc}_top';
        final botDocId = '${e.inventoryDocId}_${e.productIndexInDoc}_bottom';

        batch.set(
          FirebaseFirestore.instance
              .collection('unit2MachineProcess')
              .doc(topDocId),
          {
            'inventoryDocId': e.inventoryDocId,
            'jobCardNumber': e.jobCardNumber,
            'customerName': e.companyName,
            'productName': e.productData['productName'],
            'quantity': qty,
            'labelMinQty': qty,
            'labelPart': 'Top',
            'machineName': _topMachine,
            'remark': _topRemarkCtrl.text.trim(),
            'createdAt': now,
          },
          SetOptions(merge: true),
        );

        batch.set(
          FirebaseFirestore.instance
              .collection('unit2MachineProcess')
              .doc(botDocId),
          {
            'inventoryDocId': e.inventoryDocId,
            'jobCardNumber': e.jobCardNumber,
            'customerName': e.companyName,
            'productName': e.productData['productName'],
            'quantity': qty,
            'labelMinQty': qty,
            'labelPart': 'Bottom',
            'machineName': _botMachine,
            'remark': _botRemarkCtrl.text.trim(),
            'createdAt': now,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _C.success),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                "Saved ${widget.selectedEntries.length} item(s) successfully!",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

      // Parent ko saved indexes bhejo
      widget.onSaved(
        Set<int>.from(List.generate(widget.selectedEntries.length, (i) => i)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _C.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text(
            "Error: $e",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uniqueCustomers = widget.selectedEntries
        .map((e) => e.companyName)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.precision_manufacturing_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      uniqueCustomers.join(' • '),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
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

        const SizedBox(height: 12),

        // Selected items preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade50, Colors.cyan.shade50],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_box_rounded, size: 13, color: _C.primary),
                  const SizedBox(width: 6),
                  Text(
                    'ITEMS TO SAVE (${widget.selectedEntries.length})',
                    style: const TextStyle(
                      color: _C.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.selectedEntries
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: _C.primaryGrad,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _C.primary.withOpacity(0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          e.companyName.isNotEmpty ? e.companyName : '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Machine selectors
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

        const SizedBox(height: 20),

        // Save button
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
            onPressed: _isSaving ? null : _saveAll,
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
                        "SAVE  (${widget.selectedEntries.length} ITEMS)",
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

  @override
  void dispose() {
    _topRemarkCtrl.dispose();
    _botRemarkCtrl.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════
//  MACHINE SELECTOR WIDGET  (unchanged)
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
                  part,
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

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────
class _HCell extends StatelessWidget {
  final String text;
  final bool center;

  const _HCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: center ? TextAlign.center : TextAlign.left,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      letterSpacing: 0.4,
    ),
  );
}
