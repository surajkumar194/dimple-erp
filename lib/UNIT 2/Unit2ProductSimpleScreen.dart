import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const _kPurple = Color(0xFF7B2FBE);
const _kBlue = Color(0xFF1565C0);
const _kTeal = Color(0xFF00695C);
const _kGreen900 = Color(0xFF0A3D1F);
const _kGreen700 = Color(0xFF1B6B3A);
const _kGreen500 = Color(0xFF2ECC71);
const _kGreen100 = Color(0xFFE8F5E9);
const _kBg = Color(0xFFF3F7F4);
const _kCard = Colors.white;
const _kText = Color(0xFF1A2E22);
const _kSubText = Color(0xFF6B8F71);

// ── Helper: sanitize product name for Firestore key ──────────────────────────
String _sanitizeKey(String productName) {
  // Replace any character that's not alphanumeric or underscore with underscore
  return productName
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
      .toLowerCase();
}

String _processStatusKey(String productName) {
  return 'processStatus_${_sanitizeKey(productName)}';
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProductEntry {
  final String customerName;
  final int qty;
  final String? imageUrl;
  final List<String> allImages;
  final String jobCardId;
  final String jobCardNumber;
  final Map<String, dynamic> fullJobData;
  final String productName; // ← NEW: needed for per-product key

  const _ProductEntry({
    required this.customerName,
    required this.qty,
    required this.allImages,
    required this.jobCardId,
    required this.jobCardNumber,
    required this.fullJobData,
    required this.productName, // ← NEW
    this.imageUrl,
  });
}

class _GroupedProduct {
  final String productName;
  final List<_ProductEntry> entries;

  const _GroupedProduct({required this.productName, required this.entries});

  int get totalQty => entries.fold(0, (s, e) => s + e.qty);
  int get totalCustomers => entries.length;
}


class Unit2ProductSimpleScreen extends StatefulWidget {
  const Unit2ProductSimpleScreen({super.key});

  @override
  State<Unit2ProductSimpleScreen> createState() =>
      _Unit2ProductSimpleScreenState();
}

class _Unit2ProductSimpleScreenState extends State<Unit2ProductSimpleScreen> {
  final _searchCtrl = TextEditingController();
  final ValueNotifier<String> _query = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => _query.value = _searchCtrl.text.trim());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _query.dispose();
    super.dispose();
  }

  List<_GroupedProduct> _groupProducts(
    List<QueryDocumentSnapshot> docs,
    String query,
  ) {
    final Map<String, List<_ProductEntry>> grouped = {};

    for (final doc in docs) {
  final data = doc.data() as Map<String, dynamic>;

  // ✅ FIX START
  List<Map<String, dynamic>> products = [];

  if (data['products'] is List) {
    products = List<Map<String, dynamic>>.from(data['products']);
  } else if (data['product'] != null) {
    products = [Map<String, dynamic>.from(data['product'])];
  }
  // ✅ FIX END

  final customerName = data['customerName']?.toString() ?? '-';
  final jobCardId = doc.id;
  final jobCardNumber = data['jobCardNumber']?.toString() ?? '';

  for (final p in products) {
    final name = (p['productName'] ?? '').toString().trim();
    if (name.isEmpty) continue;

    if (query.isNotEmpty &&
        !name.toLowerCase().contains(query.toLowerCase())) continue;

    final qty = int.tryParse(p['quantity']?.toString() ?? '0') ?? 0;

    final imgs = (p['images'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    grouped.putIfAbsent(name, () => []).add(
      _ProductEntry(
        customerName: customerName,
        qty: qty,
        imageUrl: imgs.isNotEmpty ? imgs.first : null,
        allImages: imgs,
        jobCardId: jobCardId,
        jobCardNumber: jobCardNumber,
        fullJobData: data,
        productName: name,
      ),
    );
  }
}

    final list = grouped.entries
        .map((e) => _GroupedProduct(productName: e.key, entries: e.value))
        .toList();

    list.sort((a, b) =>
        a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
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
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
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
                        'Product List 📦',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Unit 2 — Products with Process Checklist',
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
            .collection('unit2ProductJobCards')
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
              final groups = _groupProducts(allDocs, query);

              return Column(
                children: [
                  // ── Search Bar ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 10)
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by product name...',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: _kGreen700.withOpacity(0.7)),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: Colors.grey.shade400),
                                  onPressed: () => _searchCtrl.clear(),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  // ── Stats Banner ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: query.isNotEmpty
                              ? [Colors.blue.shade700, Colors.blue.shade500]
                              : [Colors.purple.shade700, Colors.teal.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.purple.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
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
                              query.isNotEmpty
                                  ? Icons.filter_alt_rounded
                                  : Icons.inventory_2_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  query.isNotEmpty
                                      ? 'Results for "$query"'
                                      : 'Total Unique Products',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                                if (groups.isNotEmpty)
                                  Text(
                                    'Total Qty: ${groups.fold(0, (s, g) => s + g.totalQty)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4)),
                            ),
                            child: Text(
                              '${groups.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Grouped Cards List ───────────────────────────────
                  if (groups.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No results for "$query"',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: groups.length,
                        itemBuilder: (context, index) => _ProductGroupCard(
                          group: groups[index],
                          serialNo: index + 1,
                        ),
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


class _ProductGroupCard extends StatefulWidget {
  final _GroupedProduct group;
  final int serialNo;

  const _ProductGroupCard({required this.group, required this.serialNo});

  @override
  State<_ProductGroupCard> createState() => _ProductGroupCardState();
}

class _ProductGroupCardState extends State<_ProductGroupCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  int? _expandedEntryIndex;
  late AnimationController _animCtrl;
  late Animation<double> _rotateAnim;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _rotateAnim = Tween(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _expandAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (!_expanded) _expandedEntryIndex = null;
    });
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.purple.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
        border: Border.all(
            color: _expanded ? Colors.purple.shade200 : Colors.grey.shade100,
            width: 1.5),
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
                          Colors.purple.shade50.withOpacity(0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: _expanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(17),
                        topRight: Radius.circular(17))
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
                                Colors.white.withOpacity(0.15)
                              ]
                            : [Colors.purple.shade400, Colors.blue.shade400],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.serialNo}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _expanded ? Colors.white : _kText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${g.totalCustomers} customer${g.totalCustomers > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _expanded
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: _expanded
                          ? LinearGradient(colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15)
                            ])
                          : LinearGradient(
                              colors: [_kGreen700, Colors.teal.shade600]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('Total',
                            style: TextStyle(
                                fontSize: 9,
                                color: _expanded
                                    ? Colors.white70
                                    : Colors.white70,
                                fontWeight: FontWeight.w600)),
                        Text('${g.totalQty}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
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

          // ── Expanded Content ─────────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                _buildColumnHeader(),
                ...g.entries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  final isEntryExpanded = _expandedEntryIndex == idx;
                  return Column(
                    children: [
                      _buildDetailRow(
                        context: context,
                        entry: e,
                        index: idx,
                        isEven: idx % 2 == 0,
                        isLast: idx == g.entries.length - 1 &&
                            !isEntryExpanded,
                        isExpanded: isEntryExpanded,
                        onTap: () {
                          setState(() {
                            _expandedEntryIndex =
                                isEntryExpanded ? null : idx;
                          });
                        },
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOut,
                        child: isEntryExpanded
                            ? _EntryProcessSection(
                                entry: e,
                                isLast: idx == g.entries.length - 1,
                              )
                            : const SizedBox.shrink(),
                      ),
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

  Widget _buildColumnHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          SizedBox(width: 28, child: _HCell('Sr')),
          SizedBox(width: 10),
          Expanded(flex: 3, child: _HCell('Customer Name')),
          SizedBox(width: 48, child: _HCell('Qty', center: true)),
          SizedBox(width: 8),
          SizedBox(width: 56, child: _HCell('Image', center: true)),
          SizedBox(width: 8),
          SizedBox(width: 28, child: _HCell('', center: true)),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required _ProductEntry entry,
    required int index,
    required bool isEven,
    required bool isLast,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isExpanded
              ? Colors.purple.withOpacity(0.06)
              : isEven
                  ? Colors.white
                  : const Color(0xFFF3F7F4),
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(17),
                  bottomRight: Radius.circular(17))
              : BorderRadius.zero,
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1),
            left: isExpanded
                ? BorderSide(color: Colors.purple.shade200, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sr
            SizedBox(
              width: 28,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? Colors.purple.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isExpanded
                          ? Colors.purple.shade700
                          : Colors.grey.shade600),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Customer Name
            Expanded(
              flex: 3,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: Colors.blue.withOpacity(0.25), width: 1),
                ),
                child: Text(
                  entry.customerName,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [_kGreen700, Colors.teal.shade600]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entry.qty}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Image
            SizedBox(
              width: 56,
              child: Center(
                child: entry.imageUrl != null
                    ? GestureDetector(
                        onTap: () =>
                            _openImages(context, entry.allImages),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.purple.withOpacity(0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.network(
                              entry.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                  Icons.broken_image_rounded,
                                  size: 22,
                                  color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      )
                    : Icon(Icons.image_not_supported_rounded,
                        size: 22, color: Colors.grey.shade300),
              ),
            ),

            const SizedBox(width: 8),

            // Expand arrow
            SizedBox(
              width: 28,
              child: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: isExpanded
                      ? Colors.purple.shade400
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  .map((url) => InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: Image.network(url, fit: BoxFit.contain),
                        ),
                      ))
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
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _EntryProcessSection extends StatelessWidget {
  final _ProductEntry entry;
  final bool isLast;

  const _EntryProcessSection({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.purple.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.checklist_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Process Checklist',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Job: ${entry.jobCardNumber}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Checklist body
          Padding(
            padding: const EdgeInsets.all(12),
            child: _ProcessChecklist(
              jobCardId: entry.jobCardId,
              productQty: entry.qty,
              fullJobData: entry.fullJobData,
              productName: entry.productName, // ← KEY FIX: pass product name
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// PROCESS CHECKLIST  ← FIXED: now uses per-product Firestore key
// ─────────────────────────────────────────────────────────────

class _ProcessChecklist extends StatefulWidget {
  final String jobCardId;
  final int productQty;
  final Map<String, dynamic> fullJobData;
  final String productName; // ← NEW

  const _ProcessChecklist({
    required this.jobCardId,
    required this.productQty,
    required this.fullJobData,
    required this.productName, // ← NEW
  });

  @override
  State<_ProcessChecklist> createState() => _ProcessChecklistState();
}

class _ProcessChecklistState extends State<_ProcessChecklist> {
  bool _isDispatching = false;

  // ── Returns the Firestore field key for THIS product's processStatus ──────
  String get _statusKey => _processStatusKey(widget.productName);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('unit2ProductJobCards')
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

        // ── Read THIS product's processStatus only ─────────────────────────
        final processStatus =
            Map<String, dynamic>.from(data[_statusKey] ?? {});

        // For "Dispatched" status, also check per-product dispatch
        final isAlreadyDispatched = data['${_statusKey}_dispatched'] == true;

        int kappaQty =
            int.tryParse(processStatus['kappa']?['qty']?.toString() ?? '') ??
                widget.productQty;
        int labelPassQty = int.tryParse(
                processStatus['label_pass']?['qty']?.toString() ?? '') ??
            0;

        bool kappaDone = processStatus['kappa']?['done'] == true;
        bool labelTopDone = processStatus['label_top']?['done'] == true;
        bool labelBotDone = processStatus['label_bottom']?['done'] == true;
        bool labelDone = labelTopDone && labelBotDone;
        bool trayDone = processStatus['tray']?['done'] == true;
        bool grovingDone = processStatus['groving']?['done'] == true;
        bool pvcDone = processStatus['pvc/butter']?['done'] == true;
        bool allDone =
            kappaDone && labelDone && trayDone && grovingDone && pvcDone;

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            Row(
              children: [
                const Icon(Icons.checklist_rounded,
                    size: 14, color: _kGreen700),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Process Steps',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _kText)),
                ),
                Text('$doneCount/5 Done',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kSubText)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: doneCount / 5,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(_kGreen500),
              ),
            ),
            const SizedBox(height: 14),

            // Kappa
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
                'kappa', val, widget.productQty,
                (processStatus['kappa']?['remark'] ?? '') as String,
              ),
              onRemarkSave: (val) => _saveRemark('kappa', val),
            ),
            const SizedBox(height: 8),

            // Label
            _LabelSplitRow(
              enabled: labelEnabled,
              isAlreadyDispatched: isAlreadyDispatched,
              processStatus: processStatus,
              inputQty: kappaQty,
              jobCardId: widget.jobCardId,
              productName: widget.productName, // ← NEW
            ),
            const SizedBox(height: 8),

            // Tray
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
                'tray', val, trayQty,
                (processStatus['tray']?['remark'] ?? '') as String,
              ),
              onRemarkSave: (val) => _saveRemark('tray', val),
            ),
            const SizedBox(height: 8),

            // Groving
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
                'groving', val, grovingQty,
                (processStatus['groving']?['remark'] ?? '') as String,
              ),
              onRemarkSave: (val) => _saveRemark('groving', val),
            ),
            const SizedBox(height: 8),

            // PVC/Butter
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
                'pvc/butter', val, pvcQty,
                (processStatus['pvc/butter']?['remark'] ?? '') as String,
              ),
              onRemarkSave: (val) => _saveRemark('pvc/butter', val),
            ),
            const SizedBox(height: 14),

            // Dispatch Button
            _DispatchButton(
              allDone: allDone,
              isDispatched: isAlreadyDispatched,
              isLoading: _isDispatching,
              onDispatch: () =>
                  _handleDispatch(context, data, labelPassQty),
            ),
          ],
        );
      },
    );
  }

  // ── Save process step under per-product key ────────────────────────────────
  Future<void> _saveProcess(
      String key, bool? val, int qty, String remark) async {
    await FirebaseFirestore.instance
        .collection('unit2ProductJobCards')
        .doc(widget.jobCardId)
        .set({
      _statusKey: {          // ← uses processStatus_<productName>
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
        .collection('unit2ProductJobCards')
        .doc(widget.jobCardId)
        .set({
      _statusKey: {          // ← uses processStatus_<productName>
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
      // ── Check if THIS specific product from this job card is already dispatched ──
      final existing = await FirebaseFirestore.instance
          .collection('unit2Inventory')
          .where('originalJobCardId', isEqualTo: widget.jobCardId)
          .where('inventoryProductName', isEqualTo: widget.productName)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        final rawProducts =
            List<Map<String, dynamic>>.from(jobData['products'] ?? []);

        // Only include THIS product in the inventory entry
        final thisProduct = rawProducts
            .where((p) =>
                (p['productName'] ?? '').toString().trim() ==
                widget.productName)
            .map((p) => {
                  ...p,
                  'quantity': labelMinQty > 0 ? labelMinQty : p['quantity'],
                })
            .toList();

        await FirebaseFirestore.instance
            .collection('unit2Inventory')
            .add({
          ...jobData,
          'products': thisProduct,
          'originalJobCardId': widget.jobCardId,
          'inventoryProductName': widget.productName, // ← for unique check
          'inventoryStatus': 'In Stock',
          'dispatchedQty': labelMinQty,
          'inventoryCreatedAt': FieldValue.serverTimestamp(),
        });
      }

      // ── Mark only THIS product as dispatched (not the whole job card) ──────
      await FirebaseFirestore.instance
          .collection('unit2ProductJobCards')
          .doc(widget.jobCardId)
          .update({
        '${_statusKey}_dispatched': true,
        '${_statusKey}_dispatchedAt': FieldValue.serverTimestamp(),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _kGreen700,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Dispatched & saved to Inventory!',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LABEL SPLIT ROW  ← FIXED: now uses per-product Firestore key
// ─────────────────────────────────────────────────────────────

class _LabelSplitRow extends StatefulWidget {
  final bool enabled;
  final bool isAlreadyDispatched;
  final Map<String, dynamic> processStatus;
  final int inputQty;
  final String jobCardId;
  final String productName; // ← NEW

  const _LabelSplitRow({
    required this.enabled,
    required this.isAlreadyDispatched,
    required this.processStatus,
    required this.inputQty,
    required this.jobCardId,
    required this.productName, // ← NEW
  });

  @override
  State<_LabelSplitRow> createState() => _LabelSplitRowState();
}

class _LabelSplitRowState extends State<_LabelSplitRow> {
  late TextEditingController _topQtyCtrl;
  late TextEditingController _botQtyCtrl;
  late TextEditingController _topRemarkCtrl;
  late TextEditingController _botRemarkCtrl;

  // ── Per-product Firestore key ──────────────────────────────────────────────
  String get _statusKey => _processStatusKey(widget.productName);

  @override
  void initState() {
    super.initState();
    final topData =
        Map<String, dynamic>.from(widget.processStatus['label_top'] ?? {});
    final botData =
        Map<String, dynamic>.from(widget.processStatus['label_bottom'] ?? {});
    _topQtyCtrl =
        TextEditingController(text: topData['qty']?.toString() ?? '');
    _botQtyCtrl =
        TextEditingController(text: botData['qty']?.toString() ?? '');
    _topRemarkCtrl =
        TextEditingController(text: topData['remark']?.toString() ?? '');
    _botRemarkCtrl =
        TextEditingController(text: botData['remark']?.toString() ?? '');
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
    return !(topQty > widget.inputQty || botQty > widget.inputQty);
  }

  Future<void> _save(
      String subKey, bool? done, int qty, String remark) async {
    if (!_validate()) return;
    final topQty = int.tryParse(_topQtyCtrl.text) ?? 0;
    final botQty = int.tryParse(_botQtyCtrl.text) ?? 0;
    int passQty = 0;
    if (topQty > 0 || botQty > 0) {
      passQty = topQty < botQty ? topQty : botQty;
    }
    await FirebaseFirestore.instance
        .collection('unit2ProductJobCards')
        .doc(widget.jobCardId)
        .set({
      _statusKey: {          // ← uses processStatus_<productName>
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
        widget.processStatus['label_top'] ?? {});
    final botData = Map<String, dynamic>.from(
        widget.processStatus['label_bottom'] ?? {});
    final topDone = topData['done'] == true;
    final botDone = botData['done'] == true;
    final topQty = int.tryParse(_topQtyCtrl.text) ?? 0;
    final botQty = int.tryParse(_botQtyCtrl.text) ?? 0;
    final isOverLimit =
        topQty > widget.inputQty || botQty > widget.inputQty;
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
                child: Icon(Icons.label_rounded,
                    size: 18,
                    color:
                        widget.enabled ? _kGreen700 : Colors.grey.shade400),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Label',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: widget.enabled
                            ? _kText
                            : Colors.grey.shade400)),
              ),
              if (!widget.enabled)
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: Colors.grey),
              if (topDone && botDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kGreen500.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _kGreen500.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 13, color: _kGreen500),
                      const SizedBox(width: 4),
                      Text('Both Done • Pass: $minQty',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _kGreen500)),
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
                    _save(
                        'label_bottom', !botDone, qty, _botRemarkCtrl.text);
                  },
                  onSave: () {
                    final qty = int.tryParse(_botQtyCtrl.text) ?? 0;
                    _save(
                        'label_bottom', botDone, qty, _botRemarkCtrl.text);
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 15, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Qty cannot exceed total qty (${widget.inputQty})',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kGreen900.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip(
                      label: 'Top', value: '$topQty', color: Colors.blue),
                  const Text('+',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _kSubText)),
                  _SummaryChip(
                      label: 'Bottom',
                      value: '$botQty',
                      color: Colors.purple),
                  const Text('→',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _kSubText)),
                  _SummaryChip(
                      label: 'Pass Forward',
                      value: '$minQty',
                      color: _kGreen700),
                  if (maxQty > minQty && minQty > 0)
                    _SummaryChip(
                        label: 'Held',
                        value: '${maxQty - minQty}',
                        color: Colors.orange),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LABEL SUB CARD  (unchanged)
// ─────────────────────────────────────────────────────────────

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
              Icon(icon,
                  size: 14,
                  color: enabled ? _kGreen700 : Colors.grey.shade400),
              const SizedBox(width: 5),
              Expanded(
                child: Text('Label $title',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: enabled ? _kText : Colors.grey.shade400)),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: done,
                  onChanged:
                      (enabled && !isOverLimit) ? (_) => onToggle() : null,
                  activeColor: _kGreen500,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  side: BorderSide(
                      color: enabled
                          ? _kGreen700.withOpacity(0.4)
                          : Colors.grey.shade300,
                      width: 1.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (isHighlighted && highlightLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(highlightLabel,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange)),
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
                hintStyle:
                    TextStyle(fontSize: 10, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                isDense: true,
                prefixIcon: Icon(Icons.production_quantity_limits,
                    size: 14,
                    color: isOverLimit ? Colors.red : _kGreen700),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isOverLimit
                            ? Colors.red.withOpacity(0.5)
                            : Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isOverLimit ? Colors.red : _kGreen500,
                        width: 1.5)),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: remarkController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Remark...',
                hintStyle:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded,
                      size: 13, color: _kGreen700),
                  onPressed: onSave,
                  padding: EdgeInsets.zero,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: _kGreen500, width: 1.5)),
              ),
              onSubmitted: (_) => onSave(),
            ),
          ] else ...[
            if (qtyController.text.isNotEmpty)
              Text('Qty: ${qtyController.text}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSubText)),
          ],
          if (time != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 11, color: _kSubText),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(_formatTime(time!),
                      style:
                          const TextStyle(fontSize: 10, color: _kSubText)),
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
// SUMMARY CHIP  (unchanged)
// ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.7))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROCESS ROW  (unchanged)
// ─────────────────────────────────────────────────────────────

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
            color:
                done ? _kGreen500.withOpacity(0.4) : Colors.grey.shade200),
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
                child: Icon(icon,
                    size: 18,
                    color: done
                        ? _kGreen500
                        : enabled
                            ? _kGreen700
                            : Colors.grey.shade400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color:
                                enabled ? _kText : Colors.grey.shade400)),
                    if (qtyHint.isNotEmpty)
                      Text(qtyHint,
                          style: const TextStyle(
                              fontSize: 11, color: _kSubText)),
                  ],
                ),
              ),
              if (!enabled)
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: Colors.grey),
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: done,
                  onChanged: enabled ? onToggle : null,
                  activeColor: _kGreen500,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  side: BorderSide(
                      color: enabled
                          ? _kGreen700.withOpacity(0.4)
                          : Colors.grey.shade300,
                      width: 1.5),
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
                hintStyle:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide:
                        const BorderSide(color: _kGreen500, width: 1.5)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded,
                      size: 16, color: _kGreen700),
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
                const Icon(Icons.access_time_rounded,
                    size: 12, color: _kSubText),
                const SizedBox(width: 4),
                Text(_formatTime(time!),
                    style:
                        const TextStyle(fontSize: 11, color: _kSubText)),
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
// DISPATCH BUTTON  (unchanged)
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
          border:
              Border.all(color: _kGreen500.withOpacity(0.5), width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: _kGreen500, size: 18),
            SizedBox(width: 8),
            Text('Ready for Production',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _kGreen500)),
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
          backgroundColor:
              canDispatch ? _kGreen700 : Colors.grey.shade300,
          disabledBackgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: canDispatch ? 3 : 0,
          shadowColor: _kGreen700.withOpacity(0.4),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation(Colors.white)),
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
                        letterSpacing: 0.5),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPERS  (unchanged)
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
            letterSpacing: 0.4),
      );
}

class _FullLoader extends StatelessWidget {
  const _FullLoader();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_kGreen700), strokeWidth: 3),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.purple.shade100, Colors.teal.shade100]),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.inbox_rounded, size: 48, color: _kGreen700),
          ),
          const SizedBox(height: 16),
          const Text('No Products Found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kText)),
          const SizedBox(height: 6),
          const Text('Products will appear once job cards are created.',
              style: TextStyle(fontSize: 13, color: _kSubText)),
        ],
      ),
    );
  }
}