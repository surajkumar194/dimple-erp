import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/PRODUCTION/MdfProductionScreen.dart';
import 'package:flutter/material.dart';

class MdfProductionListScreen extends StatefulWidget {
  const MdfProductionListScreen({super.key});

  @override
  State<MdfProductionListScreen> createState() =>
      _MdfProductionListScreenState();
}

class _MdfProductionListScreenState extends State<MdfProductionListScreen>
    with SingleTickerProviderStateMixin {
  String _search = '';
  String _selectedFilter = 'All'; 

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

  final List<_FilterOption> _filters = [
    _FilterOption('All', 'All', Icons.all_inclusive_rounded, Colors.grey.shade600),
    _FilterOption('0', '0/5', Icons.hourglass_empty_rounded, Color(0xFFE74C3C)),
    _FilterOption('1', '1/5', Icons.looks_one_rounded, Color(0xFFFF6B6B)),
    _FilterOption('2', '2/5', Icons.looks_two_rounded, Color(0xFFFF9800)),
    _FilterOption('3', '3/5', Icons.looks_3_rounded, Color(0xFFFFC107)),
    _FilterOption('4', '4/5', Icons.looks_4_rounded, Color(0xFF8BC34A)),
    _FilterOption('Done', '5/5 ✅', Icons.check_circle_rounded, Color(0xFF2ECC71)),
  ];

  Color _pColor(String p) {
    if (p == 'High') return _warning;
    if (p == 'Medium') return _accent;
    return _success;
  }

  int _mdfCount(List products) =>
      products.where((p) => (p['productCategory'] ?? '') == 'MDF').length;

  int _completedStages(List products) {
    int done = 0;
    const stages = [
      'raw_material', 'mdf_cutting', 'die', 'box_ready', 'quality_checking',
    ];
    for (final p in products) {
      if ((p['productCategory'] ?? '') != 'MDF') continue;
      final prod = _mdfProduction(p);
      for (final s in stages) {
        if (prod[s]?['done'] == true) done++;
      }
    }
    return done;
  }

  int _totalStages(List products) => _mdfCount(products) * 5;

  Map _mdfProduction(dynamic p) => (p['mdfProduction'] as Map?) ?? {};
  int _minProductDoneStages(List products) {
    const stages = [
      'raw_material', 'mdf_cutting', 'die', 'box_ready', 'quality_checking',
    ];
    int min = 5;
    bool hasMdf = false;
    for (final p in products) {
      if ((p['productCategory'] ?? '') != 'MDF') continue;
      hasMdf = true;
      final prod = _mdfProduction(p);
      int done = 0;
      for (final s in stages) {
        if (prod[s]?['done'] == true) done++;
      }
      if (done < min) min = done;
    }
    return hasMdf ? min : 0;
  }
  bool _matchesFilter(List products) {
    if (_selectedFilter == 'All') return true;
    final minDone = _minProductDoneStages(products);
    if (_selectedFilter == 'Done') return minDone == 5;
    return minDone == int.tryParse(_selectedFilter);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(color: _primary)),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
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
                  'MDF Production',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.3),
                ),
                Text(
                  'Manage MDF production stages',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by customer or company...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: _primary.withOpacity(0.7)),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final f = _filters[i];
                final isSelected = _selectedFilter == f.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? f.color : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? f.color : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: f.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(f.icon, size: 15, color: isSelected ? Colors.white : f.color),
                        const SizedBox(width: 6),
                        Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : f.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _primary));
                }

                final allDocs = snap.data!.docs;
                final filtered = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final products = data['products'] is List ? data['products'] as List : [];
                  if (_mdfCount(products) == 0) return false;
                  if (_search.isNotEmpty) {
                    final customer = (data['customerName'] ?? '').toString().toLowerCase();
                    final company = (data['companyName'] ?? '').toString().toLowerCase();
                    if (!customer.contains(_search) && !company.contains(_search)) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmpty();
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

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(Icons.precision_manufacturing, size: 64, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 20),
        const Text(
          'No MDF Orders Found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText),
        ),
        const SizedBox(height: 8),
        Text(
          _search.isEmpty ? 'No orders have MDF products yet.' : 'No matching orders found.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    ),
  );

  Widget _orderCard(String orderId, Map<String, dynamic> data) {
    final customer = data['customerName'] ?? '-';
    final company = data['companyName'] ?? '';
    final priority = data['priority'] ?? 'Medium';
    final sp = data['salesPerson'] ?? '-';
    final unit = data['unit'] ?? '-';
    final products = data['products'] is List ? data['products'] as List : [];
    final mdfCount = _mdfCount(products);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('mdfProduction').doc(orderId).get(),
      builder: (context, snap) {
        List prod = products;
        if (snap.hasData && snap.data!.exists) {
          final mdfData = snap.data!.data() as Map<String, dynamic>;
          prod = mdfData['products'] ?? products;
        }

        if (!_matchesFilter(prod)) return const SizedBox.shrink();

        final doneStages = _completedStages(prod);
        final totalStages = _totalStages(prod);
        final pct = totalStages > 0 ? doneStages / totalStages : 0.0;

        final delivery = (data['deliveryDate'] as Timestamp?)?.toDate();
        final delivStr = delivery != null
            ? '${delivery.day}/${delivery.month}/${delivery.year}'
            : '-';

        final mdfProducts = prod
            .where((p) => (p['productCategory'] ?? '') == 'MDF')
            .toList();

        final mdfNames = mdfProducts
            .map((p) => (p['productName'] ?? '').toString())
            .where((n) => n.isNotEmpty)
            .toList();

        // Per-product progress chips
        final productProgressChips = mdfProducts.map((p) {
          const stages = ['raw_material', 'mdf_cutting', 'die', 'box_ready', 'quality_checking'];
          final mdfProd = _mdfProduction(p);
          final done = stages.where((s) => mdfProd[s]?['done'] == true).length;
          final name = (p['productName'] ?? '').toString();
          final shortName = name.length > 12 ? '${name.substring(0, 12)}…' : name;
          Color chipColor;
          if (done == 5) chipColor = _success;
          else if (done >= 3) chipColor = _accent;
          else chipColor = _warning;
          // Check if finalStatus is set
          final finalStatus = p['finalStatus']?.toString();
          return _ProductProgressChip(
            name: shortName,
            done: done,
            total: 5,
            color: chipColor,
            finalStatus: finalStatus,
          );
        }).toList();

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MdfProductionScreen(orderId: orderId)),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _primaryGrad,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 10),
                          ],
                        ),
                        child: const Icon(Icons.precision_manufacturing, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkText),
                            ),
                            if (company.isNotEmpty)
                              Text(company, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.badge_outlined, size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(sp, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _pColor(priority).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _pColor(priority)),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(color: _pColor(priority), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _infoChip(Icons.factory_outlined, unit),
                      const SizedBox(width: 10),
                      _infoChip(Icons.calendar_today, delivStr),
                      const SizedBox(width: 10),
                      _infoChip(Icons.inventory_2_outlined, '$mdfCount MDF'),
                    ],
                  ),
                ),

                if (productProgressChips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: productProgressChips.map((chip) => _buildProductChip(chip)).toList(),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overall Progress',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: pct == 1 ? _success.withOpacity(0.15) : _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              pct == 1 ? '✅ Complete' : '$doneStages / $totalStages stages',
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
                          valueColor: AlwaysStoppedAnimation<Color>(pct == 1 ? _success : _primary),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: _primaryGrad,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Open Production',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductChip(_ProductProgressChip chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chip.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chip.color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini progress dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(chip.total, (i) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < chip.done ? chip.color : Colors.grey.shade300,
              ),
            )),
          ),
          const SizedBox(width: 6),
          Text(
            chip.name,
            style: TextStyle(fontSize: 11, color: chip.color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          if (chip.finalStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: chip.finalStatus == 'DISPATCH' ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chip.finalStatus == 'DISPATCH' ? '🚚' : '📦',
                style: const TextStyle(fontSize: 10),
              ),
            )
          else
            Text(
              '${chip.done}/${chip.total}',
              style: TextStyle(fontSize: 10, color: chip.color, fontWeight: FontWeight.bold),
            ),
        ],
      ),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}
class _FilterOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _FilterOption(this.key, this.label, this.icon, this.color);
}
class _ProductProgressChip {
  final String name;
  final int done;
  final int total;
  final Color color;
  final String? finalStatus;
  const _ProductProgressChip({
    required this.name,
    required this.done,
    required this.total,
    required this.color,
    this.finalStatus,
  });
}