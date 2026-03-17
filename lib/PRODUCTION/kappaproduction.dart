import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  KAPPA PRODUCTION SCREEN
//  Kappa order ke sabhi products ke stages manage karo
// ═══════════════════════════════════════════════════════════════

class _C {
  static const primary = Color(0xFF169a8d);
  static const darkText = Color(0xFF2C3E50);
  static const lightBg = Color(0xFFF8F9FA);
  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFE74C3C);
  static const accent = Color(0xFFFFA500);

  static const Gradient primaryGrad = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class _Stage {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  const _Stage(this.id, this.title, this.icon, this.color);
}

// ─── Kappa ke stages (MDF jaisi hi structure, kappa-specific names) ──
const List<_Stage> _kStages = [
  _Stage('raw_material', 'Raw Material',
      Icons.inventory_2_outlined, Color(0xFF7B61FF)),
  _Stage('kappa_cutting', 'Kappa Cutting / Assembly (if applicable)',
      Icons.content_cut, Color(0xFF169a8d)),
  _Stage('die', 'Die & Paper',
      Icons.auto_fix_high_outlined, Color(0xFFFF6B6B)),
  _Stage('box_ready', 'Box Ready for Packing',
      Icons.check_box_outlined, Color(0xFFFFA500)),
  _Stage('quality_checking', 'Quality Checking',
      Icons.verified_outlined, Color(0xFF2ECC71)),
  _Stage('ready_for_dispatch', 'Ready for Dispatch',
      Icons.local_shipping_outlined, Color(0xFF8E24AA)),
];

class KappaProductionScreen extends StatefulWidget {
  final String orderId;
  const KappaProductionScreen({super.key, required this.orderId});

  @override
  State<KappaProductionScreen> createState() => _KappaProductionScreenState();
}

class _KappaProductionScreenState extends State<KappaProductionScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  Map<String, dynamic> _orderData = {};
  List<Map<String, dynamic>> _kappaProducts = [];
  List<Map<String, dynamic>> _prodData = [];
  TabController? _tabs;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _tabs?.dispose();
    for (final pd in _prodData) {
      for (final s in _kStages) {
        (pd[s.id]['remark'] as TextEditingController).dispose();
        (pd[s.id]['qty'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  // ─── Firebase fetch ───────────────────────────────────────────
 Future<void> _fetch() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {

    /// 🔵 FIRST CHECK KAPPA PRODUCTION COLLECTION
    final kappaDoc = await FirebaseFirestore.instance
        .collection('kappaProduction')
        .doc(widget.orderId)
        .get();

    if (kappaDoc.exists) {

      final data = kappaDoc.data()!;
      _kappaProducts = List<Map<String, dynamic>>.from(data['products']);

      /// order banner info ke liye
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      _orderData = orderDoc.data() ?? {};

    } else {

      /// FIRST TIME → FETCH FROM ORDERS
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      final data = doc.data()!;
      _orderData = data;

      final rawList = data['products'];
      final all = rawList is List ? rawList : [];

      _kappaProducts = all
          .where((p) => (p['productCategory'] ?? '') == 'Kappa Box')
          .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
          .toList();
    }

    /// controllers create
    _prodData = List.generate(_kappaProducts.length, (i) {

      final saved = (_kappaProducts[i]['kappaProduction'] as Map?) ?? {};
      final orderQty = _kappaProducts[i]['quantity']?.toString() ?? '';

      return {
        for (final s in _kStages)
          s.id: {
            'done': saved[s.id]?['done'] ?? false,
            'remark': TextEditingController(
              text: saved[s.id]?['remark'] ?? '',
            ),
            'qty': TextEditingController(
              text: saved[s.id]?['qty']?.toString() ??
                  (s.id == 'raw_material' ? orderQty : ''),
            ),
            'date': saved[s.id]?['savedAt'],
          },
      };
    });

    _tabs?.dispose();
    _tabs = TabController(length: _kappaProducts.length, vsync: this);

    setState(() => _loading = false);

  } catch (e) {
    setState(() {
      _error = 'Error: $e';
      _loading = false;
    });
  }
}

  // ─── Firebase save ────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = <Map<String, dynamic>>[];
      for (int i = 0; i < _kappaProducts.length; i++) {
        final prod = Map<String, dynamic>.from(_kappaProducts[i]);
        final stageMap = <String, dynamic>{};
        for (final s in _kStages) {
          final sd = _prodData[i][s.id] as Map;
          final entry = <String, dynamic>{
            'done': sd['done'] as bool,
            'remark': (sd['remark'] as TextEditingController).text.trim(),
            'qty': (sd['qty'] as TextEditingController).text.trim(),
            'savedAt': DateTime.now().toIso8601String(),
          };
          stageMap[s.id] = entry;
        }
        prod['kappaProduction'] = stageMap;
        updated.add(prod);
      }

      // merge: replace Kappa products, keep others
      final allProducts = (_orderData['products'] as List? ?? []);
      int idx = 0;
      final merged = allProducts.map((p) {
        if ((p['productCategory'] ?? '') == 'Kappa Box') return updated[idx++];
        return p;
      }).toList();

      await FirebaseFirestore.instance
    .collection('kappaProduction')
    .doc(widget.orderId)
    .set({
  'orderId': widget.orderId,
  'products': updated,
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

      _kappaProducts = updated;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Saved successfully!',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: _C.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: _C.warning,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  // ═══════════════════════ BUILD ═══════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.lightBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
            decoration: BoxDecoration(color: _C.primary)),
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
                  'Kappa Production Edit Screen',
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
      body: _loading
          ? _buildLoader()
          : _error != null
              ? _buildError()
              : _kappaProducts.isEmpty
                  ? _buildEmpty()
                  : _buildBody(),
      floatingActionButton:
          (!_loading && _error == null && _kappaProducts.isNotEmpty)
              ? FloatingActionButton.extended(
                  onPressed: _saving ? null : _save,
                  backgroundColor: _C.primary,
                  elevation: 6,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    _saving ? 'Saving...' : 'Save Production',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
    );
  }

  // ─── Loader ───────────────────────────────────────────────────
  Widget _buildLoader() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: _C.primaryGrad,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _C.primary.withOpacity(0.3), blurRadius: 20)
              ],
            ),
            child: const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          const Text('Loading Kappa data...',
              style: TextStyle(
                  fontSize: 15,
                  color: _C.primary,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  // ─── Error ────────────────────────────────────────────────────
  Widget _buildError() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 70, color: _C.warning),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white),
          ),
        ]),
      );

  // ─── Empty ────────────────────────────────────────────────────
  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.layers_outlined,
                size: 72, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          const Text('No Kappa Products Found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _C.darkText)),
          const SizedBox(height: 8),
          Text('This order has no Kappa Box category products.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ]),
      );

  // ─── Main body ────────────────────────────────────────────────
  Widget _buildBody() => Column(children: [
        _orderBanner(),
        if (_kappaProducts.length > 1) _tabBar(),
        Expanded(
          child: _kappaProducts.length == 1
              ? _productBody(0)
              : TabBarView(
                  controller: _tabs!,
                  children: List.generate(
                      _kappaProducts.length, (i) => _productBody(i)),
                ),
        ),
      ]);

  // ─── Order banner ─────────────────────────────────────────────
  Widget _orderBanner() {
    final customer = _orderData['customerName'] ?? '-';
    final company = _orderData['companyName'] ?? '';
    final priority = _orderData['priority'] ?? 'Medium';
    final sp = _orderData['salesPerson'] ?? '-';
    final delivery = (_orderData['deliveryDate'] as Timestamp?)?.toDate();
    final delivStr = delivery != null
        ? '${delivery.day}/${delivery.month}/${delivery.year}'
        : '-';

    Color pColor = _C.success;
    if (priority == 'High') pColor = _C.warning;
    if (priority == 'Medium') pColor = _C.accent;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _C.primaryGrad,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _C.primary.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.person_outline,
              color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                if (company.isNotEmpty)
                  Text(company,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.badge_outlined,
                      color: Colors.white54, size: 13),
                  const SizedBox(width: 4),
                  Text(sp,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: pColor),
                    ),
                    child: Text(priority,
                        style: TextStyle(
                            color: pColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.calendar_today,
                      color: Colors.white60, size: 12),
                  const SizedBox(width: 4),
                  Text(delivStr,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                ]),
              ]),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Text('${_kappaProducts.length}\nKappa',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
      ]),
    );
  }

  // ─── Tab bar ──────────────────────────────────────────────────
  Widget _tabBar() => Container(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 14),
        child: TabBar(
          controller: _tabs!,
          isScrollable: true,
          labelColor: _C.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _C.primary,
          indicatorWeight: 3,
          tabs: List.generate(_kappaProducts.length, (i) {
            final name =
                (_kappaProducts[i]['productName'] ?? 'Product ${i + 1}')
                    .toString();
            final done = _kStages
                .where((s) => _prodData[i][s.id]['done'] == true)
                .length;
            return Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                    name.length > 12
                        ? '${name.substring(0, 12)}…'
                        : name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: done == _kStages.length
                        ? _C.success.withOpacity(0.15)
                        : _C.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$done/${_kStages.length}',
                      style: TextStyle(
                          fontSize: 10,
                          color: done == _kStages.length
                              ? _C.success
                              : _C.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            );
          }),
        ),
      );

  // ─── Product body ─────────────────────────────────────────────
  Widget _productBody(int i) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _productDetailCard(_kappaProducts[i]),
          const SizedBox(height: 16),
          _progressCard(i),
          const SizedBox(height: 16),
          ..._kStages.map((s) => _stageCard(i, s)),
          const SizedBox(height: 20),
        ],
      );

  // ─── Product detail card ──────────────────────────────────────
  Widget _productDetailCard(Map<String, dynamic> p) {
    String sv(dynamic v) => v == null ? '' : v.toString().trim();

    Widget row(String label, String val) {
      if (val.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 115,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(val,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.darkText)),
          ),
        ]),
      );
    }

    final l = sv(p['length']);
    final h = sv(p['height']);
    final w = sv(p['width']);
    final size = [l, h, w].where((x) => x.isNotEmpty).join(' × ');

    final sections = (p['sections'] as Map<String, dynamic>?) ?? {};
    final extraSections = (p['customExtraSections'] as List?) ?? [];
    final List<String> chips = [];

    void addChip(String key, String label) {
      final v = sections[key];
      if (v != null &&
          v.toString().trim().isNotEmpty &&
          v.toString() != '0') {
        if (!chips.contains(label)) chips.add(label);
      }
    }

    addChip('trayDetail', 'Tray');
    addChip('salophinDetail', 'Salophin');
    addChip('boxCoverDetail', 'Box Cover');
    addChip('innerDetail', 'Inner');
    addChip('bottomDetail', 'Bottom');
    addChip('dieDetail', 'Die');
    addChip('otherDetail', 'Others');
    for (final ex in extraSections) {
      final t = (ex['title'] ?? '').toString().trim();
      if (t.isNotEmpty) chips.add(t);
    }

    final images = (p['images'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.cyan.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _C.primary.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              gradient: _C.primaryGrad,
              borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.layers_outlined, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text('Kappa Product Details',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),
        row('Product Name', sv(p['productName'])),
        row('Quantity', sv(p['quantity'])),
        row('Price',
            sv(p['price']).isNotEmpty ? '₹ ${sv(p['price'])}' : ''),
        row('Size (L×H×W)', size),
        row('Remarks', sv(p['remarks'])),

        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Sections:',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .map((lbl) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          gradient: _C.primaryGrad,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(lbl,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],

        if (images.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Reference Images:',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final url = images[idx].toString();
                return GestureDetector(
                  onTap: () => _openImg(url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(url,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey))),
                  ),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }

  void _openImg(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child:
                Center(child: Image.network(url, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }

  // ─── Progress card ────────────────────────────────────────────
  Widget _progressCard(int i) {
    final pd = _prodData[i];
    final done =
        _kStages.where((s) => pd[s.id]['done'] == true).length;
    final pct = done / _kStages.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Production Progress',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _C.darkText)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pct == 1
                      ? _C.success.withOpacity(0.15)
                      : _C.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pct == 1
                      ? '✅ Complete'
                      : '$done / ${_kStages.length} stages',
                  style: TextStyle(
                      color: pct == 1 ? _C.success : _C.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
                pct == 1 ? _C.success : _C.primary),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _kStages.map((s) {
              final isDone = pd[s.id]['done'] == true;
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone ? s.color : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                  color: s.color.withOpacity(0.4),
                                  blurRadius: 8)
                            ]
                          : [],
                    ),
                    child: Icon(
                        isDone ? Icons.check_rounded : s.icon,
                        size: 18,
                        color: isDone ? Colors.white : Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(s.title.split(' ').first,
                      style: TextStyle(
                          fontSize: 9,
                          color: isDone ? s.color : Colors.grey,
                          fontWeight: FontWeight.w600)),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ─── Stage card ───────────────────────────────────────────────
  Widget _stageCard(int i, _Stage s) {
    final sd = _prodData[i][s.id] as Map;
    final isDone = sd['done'] as bool;
    final ctrl = sd['remark'] as TextEditingController;
    final qtyCtrl = sd['qty'] as TextEditingController;
    final date = sd['date'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDone ? s.color : Colors.grey.shade200,
            width: isDone ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? s.color.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(children: [
        // ─── Header — tap to toggle ────────────────────────────
        GestureDetector(
          onTap: () {
            if (_locked) return;

            setState(() {
              sd['done'] = !isDone;

              if (sd['done']) {
                final currentQty =
                    (sd['qty'] as TextEditingController).text;
                final index = _kStages.indexOf(s);

                if (index + 1 < _kStages.length) {
                  final nextStage = _kStages[index + 1];
                  final nextCtrl =
                      _prodData[i][nextStage.id]['qty']
                          as TextEditingController;
                  if (nextCtrl.text.isEmpty) {
                    nextCtrl.text = currentQty;
                  }
                }

                sd['date'] = DateTime.now().toIso8601String();
              } else {
                sd['date'] = null;
              }
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: isDone
                  ? LinearGradient(colors: [
                      s.color.withOpacity(0.12),
                      s.color.withOpacity(0.04)
                    ])
                  : LinearGradient(
                      colors: [Colors.grey.shade50, Colors.grey.shade100]),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDone ? s.color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDone
                      ? [
                          BoxShadow(
                              color: s.color.withOpacity(0.4),
                              blurRadius: 8)
                        ]
                      : [],
                ),
                child: Icon(s.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDone
                                  ? s.color
                                  : Colors.grey.shade700)),
                      if (isDone)
                        Text('Completed ✓',
                            style: TextStyle(
                                fontSize: 11,
                                color: s.color,
                                fontWeight: FontWeight.w500)),
                    ]),
              ),
              // Done / Pending toggle button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isDone
                      ? LinearGradient(
                          colors: [s.color, s.color.withOpacity(0.8)])
                      : null,
                  color: isDone ? null : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDone
                      ? [
                          BoxShadow(
                              color: s.color.withOpacity(0.4),
                              blurRadius: 8)
                        ]
                      : [],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isDone ? Colors.white : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(isDone ? 'Done' : 'Pending',
                      style: TextStyle(
                          color: isDone ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
              ),
            ]),
          ),
        ),

        // ─── Body ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: ctrl,
                      enabled: !_locked,
                      decoration: InputDecoration(
                        labelText: 'Remark',
                        prefixIcon:
                            Icon(Icons.edit_note, color: s.color),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: s.color, width: 2)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      enabled: !_locked,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Qty',
                        prefixIcon:
                            Icon(Icons.numbers, color: s.color),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: s.color, width: 2)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                ],
              ),
              if (isDone && date != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: s.color),
                    const SizedBox(width: 6),
                    Text(
                      date.toString().substring(0, 16),
                      style: TextStyle(
                        fontSize: 12,
                        color: s.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}