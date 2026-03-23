import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/PRODUCTION/kappaproduction.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  KAPPA PRODUCTION LIST SCREEN
//  Dashboard se yahan aao → order select karo → KappaProductionScreen
// ═══════════════════════════════════════════════════════════════
class KappaProductionListScreen extends StatefulWidget {
  const KappaProductionListScreen({super.key});

  @override
  State<KappaProductionListScreen> createState() =>
      _KappaProductionListScreenState();
}

class _KappaProductionListScreenState
    extends State<KappaProductionListScreen> {
  String _search = '';

  // ─── Colors ──────────────────────────────────────────────────
  static const _primary = Color(0xFF169a8d);
  static const _darkText = Color(0xFF2C3E50);
  static const _lightBg = Color(0xFFF8F9FA);
  static const _success = Color(0xFF2ECC71);
  static const _warning = Color(0xFFE74C3C);
  static const _accent = Color(0xFFFFA500);
  static const _primaryGrad = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Priority color ───────────────────────────────────────────
  Color _pColor(String p) {
    if (p == 'High') return _warning;
    if (p == 'Medium') return _accent;
    return _success;
  }

  // ─── Count Kappa products in order ───────────────────────────
 int _kappaCount(List products) =>
    products.where((p) {
      final cat = (p['productCategory'] ?? '')
          .toString()
          .toLowerCase();
      return cat.contains('kappa');
    }).length;
  // ─── Count completed stages across all Kappa products ────────
  int _completedStages(List products) {
    int done = 0;
    const stages = [
      'raw_material',
      'kappa_cutting',
      'die',
      'box_ready',
      'quality_checking',
      'ready_for_dispatch',
    ];
for (final p in products) {
  final cat = (p['productCategory'] ?? '')
      .toString()
      .toLowerCase();

  if (!cat.contains('kappa')) continue;     final prod = _kappaProduction(p);
      for (final s in stages) {
        if (prod[s]?['done'] == true) done++;
      }
    }
    return done;
  }

  int _totalStages(List products) {
    const stageCount = 6;
    return _kappaCount(products) * stageCount;
  }

  Map _kappaProduction(dynamic p) => (p['kappaProduction'] as Map?) ?? {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(color: _primary)),
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
                  'Kappa Production',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Manage Kappa production stages',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by customer or company...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _primary.withOpacity(0.7),
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
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

          // ── Orders list ────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                // filter: only orders that have at least 1 Kappa product
                final allDocs = snap.data!.docs;
                final filtered = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final products = data['products'] is List
                      ? data['products'] as List
                      : [];
                  final hasKappa = _kappaCount(products) > 0;
                  if (!hasKappa) return false;

                  if (_search.isEmpty) return true;
                  final customer = (data['customerName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final company = (data['companyName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return customer.contains(_search) ||
                      company.contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.layers_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Kappa Orders Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _search.isEmpty
                              ? 'No orders have Kappa products yet.'
                              : 'No matching orders found.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final doc = filtered[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _orderCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Order card ───────────────────────────────────────────────
  Widget _orderCard(String orderId, Map<String, dynamic> data) {
    final customer = data['customerName'] ?? '-';
    final company = data['companyName'] ?? '';
    final priority = data['priority'] ?? 'Medium';
    final sp = data['salesPerson'] ?? '-';
    final unit = data['unit'] ?? '-';
    final products = data['products'] is List ? data['products'] as List : [];

    final kappaCount = _kappaCount(products);
 return FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
      .collection('kappaProduction')
      .doc(orderId)
      .get(),
  builder: (context, snap) {

    List prod = products;

    if (snap.hasData && snap.data!.exists) {
      final kappaData = snap.data!.data() as Map<String, dynamic>;
      prod = kappaData['products'] ?? products;
    }

    final doneStages = _completedStages(prod);
    final totalStages = _totalStages(prod);
    final pct = totalStages > 0 ? doneStages / totalStages : 0.0;

    final delivery = (data['deliveryDate'] as Timestamp?)?.toDate();
    final delivStr = delivery != null
        ? '${delivery.day}/${delivery.month}/${delivery.year}'
        : '-';

    // collect Kappa product names
  final kappaNames = products
    .where((p) {
      final cat = (p['productCategory'] ?? '')
          .toString()
          .toLowerCase();

      return cat.contains('kappa');
    })
    .map((p) => (p['productName'] ?? '').toString())
    .where((n) => n.isNotEmpty)
    .toList();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KappaProductionScreen(orderId: orderId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF169a8d).withOpacity(0.08),
                    const Color(0xFF0d7c70).withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _primaryGrad,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.layers_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _darkText,
                          ),
                        ),
                        if (company.isNotEmpty)
                          Text(
                            company,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sp,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _pColor(priority).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _pColor(priority)),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        color: _pColor(priority),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info row ──────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _infoChip(Icons.factory_outlined, unit),
                  const SizedBox(width: 10),
                  _infoChip(Icons.calendar_today, delivStr),
                  const SizedBox(width: 10),
                  _infoChip(
                      Icons.inventory_2_outlined, '$kappaCount Kappa'),
                ],
              ),
            ),

            // ── Kappa product names ────────────────────────────────
            if (kappaNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kappaNames
                      .map(
                        (name) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF169a8d).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  const Color(0xFF169a8d).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            // ── Progress bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Production Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: pct == 1
                              ? _success.withOpacity(0.15)
                              : _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pct == 1
                              ? '✅ Complete'
                              : '$doneStages / $totalStages stages',
                          style: TextStyle(
                            color: pct == 1 ? _success : _primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct == 1 ? _success : _primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Open button ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: _primaryGrad,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Open Production',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
    );
  }

  Widget _infoChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}
