import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConstructionProductionDashboard extends StatefulWidget {
  const ConstructionProductionDashboard({super.key});

  @override
  State<ConstructionProductionDashboard> createState() =>
      _ConstructionProductionDashboardState();
}

class _ConstructionProductionDashboardState
    extends State<ConstructionProductionDashboard>
    with TickerProviderStateMixin {
  static const _primary    = Color(0xFF169a8d);
  static const _primaryDk  = Color(0xFF0d7c70);
  static const _lightBg    = Color(0xFFF0F8F7);
  static const _darkText   = Color(0xFF2C3E50);
  static const _success    = Color(0xFF2ECC71);
  static const _danger     = Color(0xFFE74C3C);
  static const _warning    = Color(0xFFFFA500);
  static const _blue       = Color(0xFF3B82F6);
  static const _purple     = Color(0xFF8B5CF6);

  static const _primaryGrad = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String _selectedFilter = "All";

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  List _mdfProducts(List products) => products.where((p) {
        final cat = (p['productCategory'] ?? '').toString().toLowerCase();
        return cat == 'mdf' || cat == 'construction';
      }).toList();

  int _parseQty(dynamic qty) {
    if (qty is int) return qty;
    if (qty is double) return qty.toInt();
    if (qty is String) return int.tryParse(qty) ?? 0;
    return 0;
  }

  Color _priorityColor(String p) {
    if (p == 'High') return _danger;
    if (p == 'Medium') return _warning;
    return _success;
  }

  int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<_DashboardData> _loadData() async {
    final ordersSnap = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .get();

    final prodSnap = await FirebaseFirestore.instance
        .collection('constructionProduction')
        .get();

    final Map<String, Map<String, dynamic>> savedMap = {};
    for (final doc in prodSnap.docs) {
      savedMap[doc.id] = doc.data();
    }

    int totalOrders = 0, doneOrders = 0, partialOrders = 0, pendingOrders = 0;
    int totalProducts = 0, doneProducts = 0;
    int empType = 0, conType = 0, bothType = 0;
    int totalQty = 0, empQty = 0, conQty = 0;

    final List<_OrderProgress> orderList = [];

    for (final doc in ordersSnap.docs) {
      final data = doc.data();
      final products = data['products'] is List ? data['products'] as List : [];
      final mdfProds = _mdfProducts(products);
      if (mdfProds.isEmpty) continue;

      totalOrders++;
      final saved = savedMap[doc.id];
      final arr = saved != null
          ? List.from(saved['productsProduction'] ?? [])
          : <dynamic>[];

      int orderDone = 0;
      final List<_ProductProgress> prodList = [];

      for (int i = 0; i < mdfProds.length; i++) {
        final prod = mdfProds[i] as Map<String, dynamic>;
        final qty = _parseQty(prod['quantity']);
        totalProducts++;
        totalQty += qty;

        Map<String, dynamic>? sp;
        if (i < arr.length && arr[i] != null && (arr[i] as Map).isNotEmpty) {
          sp = Map<String, dynamic>.from(arr[i] as Map);
        }

        if (sp != null) {
          orderDone++;
          doneProducts++;
          final type = sp['productionType'] ?? '';
          final eQ = _safeInt(sp['employeeQuantity']);
          final cQ = _safeInt(sp['contractorQuantity']);
          if (type == 'employee') {
            empType++;
            empQty += qty;
          } else if (type == 'contractor') {
            conType++;
            conQty += qty;
          } else if (type == 'both') {
            bothType++;
            empQty += eQ;
            conQty += cQ;
          }
        }

        prodList.add(_ProductProgress(
          name: (prod['productName'] ?? 'Product ${i + 1}').toString(),
          qty: qty,
          isDone: sp != null,
          productionType: sp?['productionType'],
          boxContractor: sp?['boxContractor'],
          cuttingContractor: sp?['cuttingContractor'],
          pastingContractor: sp?['pastingContractor'],
          employeeQty: _safeInt(sp?['employeeQuantity']),
          contractorQty: _safeInt(sp?['contractorQuantity']),
        ));
      }

      if (orderDone >= mdfProds.length) {
        doneOrders++;
      } else if (orderDone > 0) {
        partialOrders++;
      } else {
        pendingOrders++;
      }

      orderList.add(_OrderProgress(
        orderId: doc.id,
        customerName: data['customerName'] ?? '-',
        companyName: data['companyName'] ?? '',
        salesPerson: data['salesPerson'] ?? '-',
        priority: data['priority'] ?? 'Medium',
        totalProducts: mdfProds.length,
        doneProducts: orderDone,
        products: prodList,
        deliveryDate: (data['deliveryDate'] as Timestamp?)?.toDate(),
      ));
    }

    return _DashboardData(
      totalOrders: totalOrders,
      doneOrders: doneOrders,
      partialOrders: partialOrders,
      pendingOrders: pendingOrders,
      totalProducts: totalProducts,
      doneProducts: doneProducts,
      pendingProducts: totalProducts - doneProducts,
      empType: empType,
      conType: conType,
      bothType: bothType,
      totalQty: totalQty,
      empQty: empQty,
      conQty: conQty,
      orderList: orderList,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: _appBar(),
      body: FutureBuilder<_DashboardData>(
        future: _loadData(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: _danger)),
            );
          }
          final d = snap.data!;
          return FadeTransition(
            opacity: _fadeAnim,
            child: RefreshIndicator(
              color: _primary,
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _overviewCard(d),
                  const SizedBox(height: 5),
                  _statGrid(d),
                  const SizedBox(height: 5),
                  _typeSplitCard(d),
                  const SizedBox(height: 5),
                  _qtyCard(d),
                  const SizedBox(height: 5),
                  _sectionTitle('📋 Orders Detail'),
                  const SizedBox(height: 5),
                  _filterRow(),
                  const SizedBox(height: 5),
                  ..._orderCards(d),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        elevation: 0,
        flexibleSpace:
            Container(decoration: const BoxDecoration(gradient: _primaryGrad)),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
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
              child: Image.asset('assets/dpl.png', height: 26),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Contractor Dashboard',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.3)),
                Text('Construction & MDF Overview',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => setState(() {}),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      );

  Widget _overviewCard(_DashboardData d) {
    final pct = d.totalProducts == 0
        ? 0.0
        : d.doneProducts / d.totalProducts;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: _primaryGrad,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall Progress',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          height: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.doneProducts} / ${d.totalProducts} products complete',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 9,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                    ),
                    Text('${(pct * 100).toInt()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('✅ Done', '${d.doneOrders}'),
              Container(height: 32, width: 1, color: Colors.white24),
              _miniStat('⏳ Partial', '${d.partialOrders}'),
              Container(height: 32, width: 1, color: Colors.white24),
              _miniStat('🔴 Pending', '${d.pendingOrders}'),
              Container(height: 32, width: 1, color: Colors.white24),
              _miniStat('📦 Total', '${d.totalOrders}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val) => Column(
        children: [
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      );

  Widget _statGrid(_DashboardData d) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2,
      children: [
        _statCard('Total Orders', '${d.totalOrders}',
            Icons.receipt_long_rounded, _blue,
            const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)])),
        _statCard('Done Orders', '${d.doneOrders}',
            Icons.check_circle_rounded, _success,
            const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)])),
        _statCard('Total Products', '${d.totalProducts}',
            Icons.inventory_2_rounded, _warning,
            const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)])),
        _statCard('Pending Products', '${d.pendingProducts}',
            Icons.pending_actions_rounded, _danger,
            const LinearGradient(
                colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)])),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      LinearGradient bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.0)),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeSplitCard(_DashboardData d) {
    final total = d.empType + d.conType + d.bothType;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _primaryGrad,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Production Type Split',
                  style: TextStyle(
                      color: _darkText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$total Saved',
                    style: const TextStyle(
                        color: _primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _typeBox('Employee', d.empType, total,
                      Icons.person_rounded, _blue,
                      const LinearGradient(colors: [
                        Color(0xFFEFF6FF),
                        Color(0xFFDBEAFE)
                      ]))),
              const SizedBox(width: 10),
              Expanded(
                  child: _typeBox('Contractor', d.conType, total,
                      Icons.engineering_rounded, _warning,
                      const LinearGradient(colors: [
                        Color(0xFFFFFBEB),
                        Color(0xFFFEF3C7)
                      ]))),
              const SizedBox(width: 10),
              Expanded(
                  child: _typeBox('Both', d.bothType, total,
                      Icons.groups_rounded, _purple,
                      const LinearGradient(colors: [
                        Color(0xFFF5F3FF),
                        Color(0xFFEDE9FE)
                      ]))),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (d.empType > 0)
                    Expanded(
                        flex: d.empType,
                        child: Container(height: 14, color: _blue)),
                  if (d.conType > 0)
                    Expanded(
                        flex: d.conType,
                        child: Container(height: 14, color: _warning)),
                  if (d.bothType > 0)
                    Expanded(
                        flex: d.bothType,
                        child: Container(height: 14, color: _purple)),
                  if (d.pendingProducts > 0)
                    Expanded(
                        flex: d.pendingProducts,
                        child: Container(
                            height: 14, color: Colors.grey.shade200)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _dot(_blue, 'Employee'),
                const SizedBox(width: 14),
                _dot(_warning, 'Contractor'),
                const SizedBox(width: 14),
                _dot(_purple, 'Both'),
                const SizedBox(width: 14),
                _dot(Colors.grey.shade300, 'Pending'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeBox(String label, int count, int total, IconData icon,
      Color color, LinearGradient bg) {
    final pct = total == 0 ? 0.0 : count / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text('$count',
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(pct * 100).toInt()}%',
              style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 10)),
        ],
      );

  // ── Qty Card ──────────────────────────────────────────────────
  Widget _qtyCard(_DashboardData d) {
    final pendingQty = d.totalQty - d.empQty - d.conQty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF6366F1), size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Quantity Distribution',
                  style: TextStyle(
                      color: _darkText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _qtyBox('Total', d.totalQty, _primary,
                      Icons.all_inclusive_rounded,
                      const LinearGradient(colors: [
                        Color(0xFFECFDF5),
                        Color(0xFFD1FAE5)
                      ]))),
              const SizedBox(width: 10),
              Expanded(
                  child: _qtyBox('Employee', d.empQty, _blue,
                      Icons.person_rounded,
                      const LinearGradient(colors: [
                        Color(0xFFEFF6FF),
                        Color(0xFFDBEAFE)
                      ]))),
              const SizedBox(width: 10),
              Expanded(
                  child: _qtyBox('Contractor', d.conQty, _warning,
                      Icons.engineering_rounded,
                      const LinearGradient(colors: [
                        Color(0xFFFFFBEB),
                        Color(0xFFFEF3C7)
                      ]))),
              const SizedBox(width: 10),
              Expanded(
                  child: _qtyBox(
                      'Pending',
                      pendingQty < 0 ? 0 : pendingQty,
                      _danger,
                      Icons.hourglass_empty_rounded,
                      const LinearGradient(colors: [
                        Color(0xFFFFF1F2),
                        Color(0xFFFFE4E6)
                      ]))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBox(String label, int val, Color color, IconData icon,
      LinearGradient bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text('$val',
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: _darkText, fontWeight: FontWeight.bold, fontSize: 16));

  // ── Filter Row ────────────────────────────────────────────────
  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _fchip('All', Colors.grey.shade700, Colors.grey.shade100),
          _fchip('Employee', _blue, const Color(0xFFEFF6FF)),
          _fchip('Contractor', _warning, const Color(0xFFFFFBEB)),
          _fchip('Both', _purple, const Color(0xFFF5F3FF)),
          _fchip('Done', _success, const Color(0xFFF0FDF4)),
          _fchip('Pending', _danger, const Color(0xFFFFF1F2)),
        ],
      ),
    );
  }

  Widget _fchip(String label, Color textColor, Color bg) {
    final isSel = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? textColor : bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    isSel ? textColor : textColor.withOpacity(0.3)),
            boxShadow: isSel
                ? [
                    BoxShadow(
                        color: textColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSel ? Colors.white : textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ── Order Cards ───────────────────────────────────────────────
  List<Widget> _orderCards(_DashboardData d) {
    List<_OrderProgress> list = d.orderList;

    switch (_selectedFilter) {
      case 'Employee':
        list = list
            .where((o) => o.products
                .any((p) => p.isDone && p.productionType == 'employee'))
            .toList();
        break;
      case 'Contractor':
        list = list
            .where((o) => o.products
                .any((p) => p.isDone && p.productionType == 'contractor'))
            .toList();
        break;
      case 'Both':
        list = list
            .where((o) => o.products
                .any((p) => p.isDone && p.productionType == 'both'))
            .toList();
        break;
      case 'Done':
        list = list
            .where((o) => o.doneProducts >= o.totalProducts)
            .toList();
        break;
      case 'Pending':
        list = list
            .where((o) => o.doneProducts < o.totalProducts)
            .toList();
        break;
    }

    if (list.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle),
                  child: Icon(Icons.inbox_rounded,
                      color: Colors.grey.shade400, size: 48),
                ),
                const SizedBox(height: 16),
                Text('No orders for "$_selectedFilter"',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          ),
        )
      ];
    }

    return list.map((o) => _orderCard(o)).toList();
  }

  Widget _orderCard(_OrderProgress o) {
    final pct =
        o.totalProducts == 0 ? 0.0 : o.doneProducts / o.totalProducts;
    final allDone = o.doneProducts >= o.totalProducts;
    final anyDone = o.doneProducts > 0;

    final statusColor =
        allDone ? _success : anyDone ? _warning : _danger;
    final statusGrad = allDone
        ? const LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)])
        : anyDone
            ? const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)])
            : const LinearGradient(
                colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)]);
    final pColor = _priorityColor(o.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: statusColor.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Theme(
        data: ThemeData(
            dividerColor: Colors.transparent,
            colorScheme: const ColorScheme.light()),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: statusGrad,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: statusColor.withOpacity(0.3)),
            ),
            child: Icon(
              allDone
                  ? Icons.check_circle_rounded
                  : anyDone
                      ? Icons.pending_rounded
                      : Icons.schedule_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(o.customerName,
                    style: const TextStyle(
                        color: _darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: pColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: pColor.withOpacity(0.4)),
                ),
                child: Text(o.priority,
                    style: TextStyle(
                        color: pColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (o.companyName.isNotEmpty)
                  Text(o.companyName,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge_outlined,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(o.salesPerson,
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11)),
                    if (o.deliveryDate != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                          '${o.deliveryDate!.day}/${o.deliveryDate!.month}/${o.deliveryDate!.year}',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 7,
                          backgroundColor:
                              statusColor.withOpacity(0.15),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${o.doneProducts}/${o.totalProducts}  ${(pct * 100).toInt()}%',
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.precision_manufacturing_rounded,
                    size: 14, color: _primary),
                const SizedBox(width: 6),
                const Text('MDF Products',
                    style: TextStyle(
                        color: _darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            ...o.products.map((p) => _productRow(p)),
          ],
        ),
      ),
    );
  }

  Widget _productRow(_ProductProgress p) {
    Color typeColor;
    IconData typeIcon;
    LinearGradient typeBg;

    if (!p.isDone) {
      typeColor = Colors.grey.shade400;
      typeIcon = Icons.hourglass_empty_rounded;
      typeBg = LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100]);
    } else if (p.productionType == 'employee') {
      typeColor = _blue;
      typeIcon = Icons.person_rounded;
      typeBg = const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]);
    } else if (p.productionType == 'contractor') {
      typeColor = _warning;
      typeIcon = Icons.engineering_rounded;
      typeBg = const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)]);
    } else {
      typeColor = _purple;
      typeIcon = Icons.groups_rounded;
      typeBg = const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)]);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: typeBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: typeColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p.name,
                    style: const TextStyle(
                        color: _darkText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Qty: ${p.qty}',
                    style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.isDone
                      ? _success.withOpacity(0.12)
                      : _danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: p.isDone
                          ? _success.withOpacity(0.35)
                          : _danger.withOpacity(0.3)),
                ),
                child: Text(
                  p.isDone ? '✅ Done' : '⏳ Pending',
                  style: TextStyle(
                      color: p.isDone ? _success : _danger,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (p.isDone) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (p.productionType != null)
                  _chip2('🏭 ${p.productionType!.toUpperCase()}',
                      typeColor),
                if ((p.productionType == 'employee' ||
                        p.productionType == 'both') &&
                    p.employeeQty > 0)
                  _chip2('👤 Emp: ${p.employeeQty}', _blue),
                if ((p.productionType == 'contractor' ||
                        p.productionType == 'both') &&
                    p.contractorQty > 0)
                  _chip2('🔧 Con: ${p.contractorQty}', _warning),
                if (p.boxContractor is List &&
                    (p.boxContractor as List).isNotEmpty)
                  _chip2(
                      '📦 ${(p.boxContractor as List).join(", ")}',
                      Colors.grey.shade600),
                if (p.cuttingContractor != null &&
                    p.cuttingContractor!.isNotEmpty)
                  _chip2('✂️ ${p.cuttingContractor}',
                      Colors.grey.shade600),
                if (p.pastingContractor != null &&
                    p.pastingContractor!.isNotEmpty)
                  _chip2('🖌 ${p.pastingContractor}',
                      Colors.grey.shade600),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip2(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      );
}

// ─── Data Models ──────────────────────────────────────────────────────────────

class _DashboardData {
  final int totalOrders, doneOrders, partialOrders, pendingOrders;
  final int totalProducts, doneProducts, pendingProducts;
  final int empType, conType, bothType;
  final int totalQty, empQty, conQty;
  final List<_OrderProgress> orderList;

  const _DashboardData({
    required this.totalOrders,
    required this.doneOrders,
    required this.partialOrders,
    required this.pendingOrders,
    required this.totalProducts,
    required this.doneProducts,
    required this.pendingProducts,
    required this.empType,
    required this.conType,
    required this.bothType,
    required this.totalQty,
    required this.empQty,
    required this.conQty,
    required this.orderList,
  });
}

class _OrderProgress {
  final String orderId, customerName, companyName, salesPerson, priority;
  final int totalProducts, doneProducts;
  final List<_ProductProgress> products;
  final DateTime? deliveryDate;

  const _OrderProgress({
    required this.orderId,
    required this.customerName,
    required this.companyName,
    required this.salesPerson,
    required this.priority,
    required this.totalProducts,
    required this.doneProducts,
    required this.products,
    this.deliveryDate,
  });
}

class _ProductProgress {
  final String name;
  final int qty;
  final bool isDone;
  final String? productionType, cuttingContractor, pastingContractor;
  final dynamic boxContractor;
  final int employeeQty, contractorQty;

  const _ProductProgress({
    required this.name,
    required this.qty,
    required this.isDone,
    this.productionType,
    this.boxContractor,
    this.cuttingContractor,
    this.pastingContractor,
    this.employeeQty = 0,
    this.contractorQty = 0,
  });
}