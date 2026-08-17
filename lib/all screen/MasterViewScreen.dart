import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _C {
  static const primary = Color(0xFF169a8d);
  static const primaryDark = Color(0xFF0d7c70);
  static const bg = Color(0xFFF0F4F8);
  static const card = Colors.white;
  static const muted = Color(0xFF8896A5);
  static const mutedLight = Color(0xFFCDD5DE);
  static const danger = Color(0xFFE74C3C);
  static const success = Color(0xFF2ECC71);
  static const amber = Color(0xFFE67E22);
  static const surface = Color(0xFFFAFBFD);
  static const grad = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class _Stats {
  final int total;
  final int today;
  final int week;
  final int month;
  _Stats({
    required this.total,
    required this.today,
    required this.week,
    required this.month,
  });
}

DateTime? _parseCreatedAt(String iso) {
  try {
    return DateTime.parse(iso);
  } catch (_) {
    return null;
  }
}

_Stats _computeStats(List<_FlatProduct> items) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(const Duration(days: 6));
  final monthStart = DateTime(now.year, now.month, 1);
  int today = 0;
  int week = 0;
  int month = 0;

  for (final it in items) {
    final raw = (it.data['createdAt'] ?? '').toString();
    final dt = _parseCreatedAt(raw);
    if (dt == null) continue;
    final d = DateTime(dt.year, dt.month, dt.day);

    if (d.year == todayStart.year &&
        d.month == todayStart.month &&
        d.day == todayStart.day) {
      today++;
    }
    if (!d.isBefore(weekStart) && !d.isAfter(todayStart)) {
      week++;
    }
    if (d.year == monthStart.year && d.month == monthStart.month) {
      month++;
    }
  }

  return _Stats(total: items.length, today: today, week: week, month: month);
}

class _StatsBar extends StatelessWidget {
  final _Stats stats;
  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              'Total',
              stats.total,
              Icons.inventory_2_outlined,
              _C.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              'Today',
              stats.today,
              Icons.today_outlined,
              _C.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              'This Week',
              stats.week,
              Icons.calendar_view_week_outlined,
              _C.amber,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              'This Month',
              stats.month,
              Icons.calendar_month_outlined,
              _C.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: _C.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class MasterViewScreen extends StatefulWidget {
  const MasterViewScreen({super.key});

  @override
  State<MasterViewScreen> createState() => _MasterViewScreenState();
}

class _MasterViewScreenState extends State<MasterViewScreen> {
  String _search = '';
  bool _groupByName = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: _C.grad),
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
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Master View',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All saved products & packaging details',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _search = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by product name...',
                prefixIcon: const Icon(Icons.search, color: _C.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _groupByName = !_groupByName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _groupByName
                            ? _C.primary.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _groupByName ? _C.primary : _C.mutedLight,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 18,
                            color: _groupByName ? _C.primary : _C.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Group same-name products together',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _groupByName ? _C.primary : _C.muted,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _groupByName,
                            activeColor: _C.primary,
                            onChanged: (v) => setState(() => _groupByName = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('masterProducts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _C.primary),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _emptyState();
                }

                // Flatten: each product (with its parent entry id) becomes one card.
                final List<_FlatProduct> items = [];
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final entryId = data['entryId']?.toString() ?? doc.id;
                  final products = (data['products'] as List?) ?? [];
                  for (int i = 0; i < products.length; i++) {
                    final p = Map<String, dynamic>.from(products[i] as Map);
                    items.add(
                      _FlatProduct(
                        entryId: entryId,
                        docId: doc.id,
                        index: i,
                        data: p,
                      ),
                    );
                  }
                }

                  final stats = _computeStats(items);

                final filtered = _search.isEmpty
                    ? items
                    : items.where((it) {
                        final name = (it.data['productName'] ?? '')
                            .toString()
                            .toLowerCase();
                        return name.contains(_search);
                      }).toList();

                Widget listArea;
                if (filtered.isEmpty) {
                  listArea = _emptyState(
                    message: 'No products match "$_search"',
                  );
                } else if (_groupByName) {
                        final Map<String, List<_FlatProduct>> groups = {};
                  final Map<String, String> displayNames = {};
                  for (final it in filtered) {
                    final rawName =
                        (it.data['productName'] ?? 'Unnamed Product')
                            .toString();
                    final key = rawName.trim().toLowerCase();
                    groups.putIfAbsent(key, () => []).add(it);
                    displayNames.putIfAbsent(
                      key,
                      () => rawName.trim().isEmpty
                          ? 'Unnamed Product'
                          : rawName.trim(),
                    );
                  }
                   final duplicateKeys =
                      groups.keys.where((k) => groups[k]!.length > 1).toList()
                        ..sort(
                          (a, b) => displayNames[a]!.toLowerCase().compareTo(
                            displayNames[b]!.toLowerCase(),
                          ),
                        );

                  if (duplicateKeys.isEmpty) {
                    listArea = _emptyState(
                      message: 'No duplicate product names found 🎉',
                    );
                  } else {
                    listArea = ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                      itemCount: duplicateKeys.length,
                      itemBuilder: (context, i) {
                        final key = duplicateKeys[i];
                        return _GroupedProductCard(
                          name: displayNames[key]!,
                          items: groups[key]!,
                        );
                      },
                    );
                  }
                } else {
                  listArea = ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _ProductCard(item: filtered[i]),
                  );
                }

                return Column(
                  children: [
                    _StatsBar(stats: stats),
                    Expanded(child: listArea),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({String? message}) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: _C.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message ?? 'No products saved yet',
          style: const TextStyle(
            color: _C.muted,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

class _FlatProduct {
  final String entryId;
  final String docId; // actual Firestore document id (needed for updates)
  final int index; // index of this product inside the doc's `products` array
  final Map<String, dynamic> data;
  _FlatProduct({
    required this.entryId,
    required this.docId,
    required this.index,
    required this.data,
  });
}

/// ─────────────────────────────────────────────────────────────────────────
/// GROUPED PRODUCT CARD — shows every entry that shares the same product
/// name together, with a combined total, and lets you expand to see (and
/// edit) each individual matching entry.
/// ─────────────────────────────────────────────────────────────────────────
class _GroupedProductCard extends StatefulWidget {
  final String name;
  final List<_FlatProduct> items;
  const _GroupedProductCard({required this.name, required this.items});

  @override
  State<_GroupedProductCard> createState() => _GroupedProductCardState();
}

class _GroupedProductCardState extends State<_GroupedProductCard> {
  bool _expanded = false;

  num _toNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final totalQty = items.fold<num>(
      0,
      (sum, it) => sum + _toNum(it.data['quantity']),
    );
    final totalAmount = items.fold<num>(
      0,
      (sum, it) =>
          sum + (_toNum(it.data['quantity']) * _toNum(it.data['price'])),
    );
    final count = items.length;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.amber.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.amber.withOpacity(0.10),
                    _C.amber.withOpacity(0.02),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _C.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.layers_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: _C.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _C.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count ${count == 1 ? 'entry' : 'entries'}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _C.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Qty: $totalQty   •   ₹${totalAmount.toStringAsFixed(2)} total',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _C.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: _C.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                children: items
                    .map(
                      (it) => Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: _ProductCard(item: it, dense: true),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final _FlatProduct item;
  final bool dense;
  const _ProductCard({required this.item, this.dense = false});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _expanded = false;
  bool _saving = false;

  Future<void> _openEditDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: !_saving,
      builder: (_) => _EditProductDialog(initialData: widget.item.data),
    );
    if (result == null) return; // cancelled

    setState(() => _saving = true);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('masterProducts')
          .doc(widget.item.docId);
      final snap = await docRef.get();
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) throw Exception('Entry not found');

      final products = List<Map<String, dynamic>>.from(
        (data['products'] as List? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );

      if (widget.item.index < 0 || widget.item.index >= products.length) {
        throw Exception('Product not found in entry');
      }

      // Merge edited fields into the existing product map, keep other fields (sections etc.) intact.
      final updated = Map<String, dynamic>.from(products[widget.item.index]);
      updated['productName'] = result['productName'];
      updated['quantity'] = result['quantity'];
      updated['price'] = result['price'];
      updated['images'] = result['images'];

      products[widget.item.index] = updated;

      await docRef.update({'products': products});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated'),
            backgroundColor: _C.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: _C.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final p = widget.item.data;
    final name = (p['productName'] ?? 'this product').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete "$name" (Entry: ${widget.item.entryId})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _C.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: _C.danger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('masterProducts')
          .doc(widget.item.docId);
      final snap = await docRef.get();
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) throw Exception('Entry not found');

      final products = List<Map<String, dynamic>>.from(
        (data['products'] as List? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      );

      if (widget.item.index < 0 || widget.item.index >= products.length) {
        throw Exception('Product not found in entry');
      }

      products.removeAt(widget.item.index);
      await docRef.update({'products': products});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted'),
            backgroundColor: _C.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: _C.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item.data;
    final name = (p['productName'] ?? 'Unnamed Product').toString();
    final qty = p['quantity'] ?? 0;
    final price = p['price'] ?? 0;
    final details = (p['details'] ?? '').toString();
    final images = (p['images'] as List?)?.cast<dynamic>() ?? [];
    final fixedSections =
        (p['fixedSections'] as Map?)?.cast<String, dynamic>() ?? {};
    final customSections =
        (p['customSections'] as List?)?.cast<dynamic>() ?? [];
    final createdAt = (p['createdAt'] ?? '').toString();
    final total = (qty is num && price is num)
        ? (qty * price)
        : (double.tryParse(qty.toString()) ?? 0) *
              (double.tryParse(price.toString()) ?? 0);

    return Container(
      margin: EdgeInsets.only(top: widget.dense ? 8 : 14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.primary.withOpacity(0.15), width: 1.2),
        boxShadow: widget.dense
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.primary.withOpacity(0.08),
                    _C.primary.withOpacity(0.02),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: _C.grad,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
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
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _C.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Qty: $qty   •   ₹${total.toStringAsFixed(2)} total',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _C.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _C.primary,
                        ),
                      ),
                    )
                  else ...[
                    IconButton(
                      onPressed: _openEditDialog,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: _C.primary,
                        size: 20,
                      ),
                      tooltip: 'Edit product',
                      splashRadius: 20,
                    ),
                    IconButton(
                      onPressed: _confirmDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: _C.danger,
                        size: 20,
                      ),
                      tooltip: 'Delete product',
                      splashRadius: 20,
                    ),
                  ],
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: _C.primary,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded details (A to Z) ──
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Entry ID', widget.item.entryId),
                  _row('Quantity', qty.toString()),
                  _row('Price (₹)', price.toString()),
                  _row('Total Amount', '₹${total.toStringAsFixed(2)}'),
                  if (details.isNotEmpty) _row('Details', details),
                  if (createdAt.isNotEmpty)
                    _row('Created At', _formatDate(createdAt)),

                  if (fixedSections.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _sectionTitle(
                      'Fixed Sections',
                      Icons.category_outlined,
                      _C.primary,
                    ),
                    ...fixedSections.entries.map(
                      (e) => _sectionBlock(
                        Map<String, dynamic>.from(e.value as Map),
                        color: _C.primary,
                      ),
                    ),
                  ],

                  if (customSections.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _sectionTitle(
                      'Extra Sections',
                      Icons.add_box_outlined,
                      _C.amber,
                    ),
                    ...customSections.map(
                      (s) => _sectionBlock(
                        Map<String, dynamic>.from(s as Map),
                        color: _C.amber,
                      ),
                    ),
                  ],

                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _sectionTitle(
                      'Images (${images.length})',
                      Icons.photo_library_outlined,
                      _C.primary,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: images
                          .map((url) => _imageThumb(url.toString()))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: _C.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String text, IconData icon, Color color) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, color: color, size: 13),
      ),
      const SizedBox(width: 8),
      Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    ],
  );

  Widget _sectionBlock(Map<String, dynamic> section, {required Color color}) {
    final sectionName = (section['sectionName'] ?? 'Section').toString();
    final rows = (section['rows'] as List?)?.cast<dynamic>() ?? [];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionName,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map((r) {
            final row = Map<String, dynamic>.from(r as Map);
            final detail = (row['detail'] ?? '').toString();
            final qty = row['qty'] ?? 0;
            final price = (row['price'] ?? '').toString();
            if (detail.isEmpty && qty == 0 && price.isEmpty)
              return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      detail.isEmpty ? '—' : detail,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Qty: $qty',
                      style: const TextStyle(fontSize: 12, color: _C.muted),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹$price',
                      style: const TextStyle(fontSize: 12, color: _C.muted),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _imageThumb(String url) => GestureDetector(
    onTap: () => showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 80,
            height: 80,
            color: _C.surface,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _C.primary,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: 80,
          height: 80,
          color: _C.surface,
          child: const Icon(
            Icons.broken_image_outlined,
            color: _C.muted,
            size: 20,
          ),
        ),
      ),
    ),
  );
}

/// ─────────────────────────────────────────────────────────────────────────
/// EDIT PRODUCT DIALOG — lets the user change name, quantity, price & images.
/// Returns a map with the new values via Navigator.pop, or null if cancelled.
/// ─────────────────────────────────────────────────────────────────────────
class _EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const _EditProductDialog({required this.initialData});

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: (widget.initialData['productName'] ?? '').toString(),
    );
    _qtyCtrl = TextEditingController(
      text: (widget.initialData['quantity'] ?? '').toString(),
    );
    _priceCtrl = TextEditingController(
      text: (widget.initialData['price'] ?? '').toString(),
    );
    _images = ((widget.initialData['images'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product name cannot be empty'),
          backgroundColor: _C.danger,
        ),
      );
      return;
    }

    final qtyText = _qtyCtrl.text.trim();
    final priceText = _priceCtrl.text.trim();
    final num? qty = num.tryParse(qtyText) ?? 0;
    final num? price = num.tryParse(priceText) ?? 0;

    Navigator.pop(context, {
      'productName': name,
      'quantity': qty,
      'price': price,
      'images': _images,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: _C.grad,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Edit Product',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                _label('Product Name'),
                TextField(
                  controller: _nameCtrl,
                  decoration: _inputDecoration('Enter product name'),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Quantity'),
                          TextField(
                            controller: _qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration('0'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Price (₹)'),
                          TextField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration('0'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _label('Images'),
                const SizedBox(height: 6),
                if (_images.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_images.length, (i) {
                      final url = _images[i];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 70,
                                    height: 70,
                                    color: _C.surface,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: _C.muted,
                                      size: 18,
                                    ),
                                  ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => _removeImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: _C.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                if (_images.isEmpty)
                  const Text(
                    'No images',
                    style: TextStyle(fontSize: 12.5, color: _C.muted),
                  ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _C.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        color: _C.muted,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: _C.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _C.mutedLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _C.mutedLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _C.primary, width: 1.5),
    ),
  );
}
