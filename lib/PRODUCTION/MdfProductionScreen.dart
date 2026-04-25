import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

// ════════════════════════════════════════════════════════════════
//  CONSTANTS
// ════════════════════════════════════════════════════════════════
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

const List<_Stage> _kStages = [
  _Stage(
    'raw_material',
    'Raw Material',
    Icons.inventory_2_outlined,
    Color(0xFF7B61FF),
  ),
  _Stage(
    'mdf_cutting',
    'MDF Cutting/Assembly',
    Icons.content_cut,
    Color(0xFF169a8d),
  ),
  _Stage('die', 'Die & Paper', Icons.auto_fix_high_outlined, Color(0xFFFF6B6B)),
  _Stage(
    'box_ready',
    'Box Ready for Packing',
    Icons.check_box_outlined,
    Color(0xFFFFA500),
  ),
  _Stage(
    'quality_checking',
    'Quality Checking',
    Icons.verified_outlined,
    Color(0xFF2ECC71),
  ),
];

// ════════════════════════════════════════════════════════════════
//  SCREEN
// ════════════════════════════════════════════════════════════════
class MdfProductionScreen extends StatefulWidget {
  final String orderId;
  const MdfProductionScreen({super.key, required this.orderId});

  @override
  State<MdfProductionScreen> createState() => _MdfProductionScreenState();
}

class _MdfProductionScreenState extends State<MdfProductionScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  Map<String, dynamic> _orderData = {};
  List<Map<String, dynamic>> _mdfProducts = [];
  List<Map<String, dynamic>> _prodData = [];
  TabController? _tabs;

  bool _firestoreLocked = false;

  bool get _isFullyLocked => _firestoreLocked && _allDone();

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
      _firestoreLocked = false;
    });

    try {
      final mdfDoc = await FirebaseFirestore.instance
          .collection('mdfProduction')
          .doc(widget.orderId)
          .get();

      if (mdfDoc.exists) {
        final data = mdfDoc.data()!;
        _firestoreLocked = data['locked'] ?? false;
        _mdfProducts = List<Map<String, dynamic>>.from(data['products']);
        _orderData = {};
      } else {
        _firestoreLocked = false;
        final doc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .get();
        final data = doc.data()!;
        _orderData = data;
        final rawList = data['products'];
        final all = rawList is List ? rawList : [];
        _mdfProducts = all
            .where((p) => (p['productCategory'] ?? '') == 'MDF')
            .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
            .toList();
      }

      _prodData = List.generate(_mdfProducts.length, (i) {
        final saved = (_mdfProducts[i]['mdfProduction'] as Map?) ?? {};
        final orderQty = _mdfProducts[i]['quantity']?.toString() ?? '';
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

      if (_firestoreLocked && !_checkAllDoneFromProdData()) {
        _firestoreLocked = false;
        await FirebaseFirestore.instance
            .collection('mdfProduction')
            .doc(widget.orderId)
            .update({'locked': false});
      }

      _tabs?.dispose();
      _tabs = TabController(length: _mdfProducts.length, vsync: this);
      _tabs!.addListener(() {
        if (mounted) setState(() {});
      });

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  bool _checkAllDoneFromProdData() {
    if (_prodData.isEmpty) return false;
    for (int i = 0; i < _prodData.length; i++) {
      for (var s in _kStages) {
        if (_prodData[i][s.id]['done'] != true) return false;
      }
    }
    return true;
  }

  bool _allDone() {
    if (_prodData.isEmpty) return false;
    for (int i = 0; i < _prodData.length; i++) {
      for (var s in _kStages) {
        if (_prodData[i][s.id]['done'] != true) return false;
      }
    }
    return true;
  }

  // ✅ NEW: Check if a single product's all stages are done
  bool _allDoneForProduct(int i) {
    if (_prodData.isEmpty || i >= _prodData.length) return false;
    for (var s in _kStages) {
      if (_prodData[i][s.id]['done'] != true) return false;
    }
    return true;
  }

  // ─── Auto-save on stage toggle ────────────────────────────────
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = <Map<String, dynamic>>[];
      for (int i = 0; i < _mdfProducts.length; i++) {
        final prod = Map<String, dynamic>.from(_mdfProducts[i]);
        final stageMap = <String, dynamic>{};
        for (final s in _kStages) {
          final sd = _prodData[i][s.id] as Map;
          stageMap[s.id] = {
            'done': sd['done'] as bool,
            'remark': (sd['remark'] as TextEditingController).text.trim(),
            'qty': (sd['qty'] as TextEditingController).text.trim(),
            'savedAt': DateTime.now().toIso8601String(),
          };
        }
        prod['mdfProduction'] = stageMap;
        updated.add(prod);
      }

      await FirebaseFirestore.instance
          .collection('mdfProduction')
          .doc(widget.orderId)
          .set({
            'orderId': widget.orderId,
            'products': updated,
            'locked': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _mdfProducts = updated;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: _C.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  // ─── Final save: COMMON or DISPATCH (per product) ────────────
  Future<void> _finalSave(String type, int productIndex) async {
    setState(() => _saving = true);
    try {
      final updated = <Map<String, dynamic>>[];
      for (int i = 0; i < _mdfProducts.length; i++) {
        final prod = Map<String, dynamic>.from(_mdfProducts[i]);
        final stageMap = <String, dynamic>{};
        for (final s in _kStages) {
          final sd = _prodData[i][s.id] as Map;
          stageMap[s.id] = {
            'done': sd['done'],
            'remark': (sd['remark'] as TextEditingController).text,
            'qty': (sd['qty'] as TextEditingController).text,
            'savedAt': DateTime.now().toIso8601String(),
          };
        }
        // ✅ Mark finalStatus per product
        if (i == productIndex) {
          prod['finalStatus'] = type;
          prod['statusSentAt'] = DateTime.now().toIso8601String();
        }
        prod['mdfProduction'] = stageMap;
        updated.add(prod);
      }

      // ✅ Lock only if ALL products done AND all have finalStatus
      final shouldLock = _allDone() &&
          updated.every((p) => p['finalStatus'] != null);

      await FirebaseFirestore.instance
          .collection('mdfProduction')
          .doc(widget.orderId)
          .set({
            'orderId': widget.orderId,
            'products': updated,
            'locked': shouldLock,
            'updatedAt': FieldValue.serverTimestamp(),
            if (shouldLock) 'completedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _mdfProducts = updated;
      if (shouldLock) {
        setState(() => _firestoreLocked = true);
      }

      if (mounted) {
        final productName =
            (_mdfProducts[productIndex]['productName'] ?? 'Product')
                .toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type == 'COMMON'
                        ? '✅ "$productName" moved to Common Orders'
                        : '🚚 "$productName" sent to Dispatch',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: type == 'COMMON' ? Colors.blue : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _C.warning),
        );
      }
    }
    setState(() => _saving = false);
  }

  // ════════════════════════ BUILD ═══════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.lightBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: _C.primary),
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
                  'MDF Production Edit',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  'Manage MDF production stages',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _fetch,
            ),
        ],
      ),
      body: _loading
          ? _buildLoader()
          : _error != null
          ? _buildError()
          : _mdfProducts.isEmpty
          ? _buildEmpty()
          : _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────
  Widget? _buildBottomBar() {
    if (_loading) return null;

    // ✅ Current tab index
    final currentIndex = (_tabs?.index ?? 0).clamp(0, _mdfProducts.isEmpty ? 0 : _mdfProducts.length - 1);

    // ✅ Check if current product is done
    final currentProductDone = _mdfProducts.isEmpty ? false : _allDoneForProduct(currentIndex);

    // ✅ Check if current product already has a finalStatus (sent)
    final alreadySent = _mdfProducts.isEmpty
        ? false
        : (_mdfProducts[currentIndex]['finalStatus'] != null);

    final canAct = currentProductDone && !_saving && !alreadySent && !_isFullyLocked;

    String commonLabel = 'COMMON';
    String dispatchLabel = 'DISPATCH';
    String commonSub = 'Mark as Common Order';
    String dispatchSub = 'Send to Dispatch';

    if (alreadySent) {
      final status = _mdfProducts[currentIndex]['finalStatus'] ?? '';
      commonLabel = status == 'COMMON' ? '✓ COMMON' : 'COMMON';
      dispatchLabel = status == 'DISPATCH' ? '✓ DISPATCH' : 'DISPATCH';
      commonSub = status == 'COMMON' ? 'Already sent' : 'Mark as Common Order';
      dispatchSub = status == 'DISPATCH' ? 'Already sent' : 'Send to Dispatch';
    } else if (_isFullyLocked) {
      commonLabel = '✓ DONE';
      dispatchLabel = '✓ DONE';
      commonSub = 'Locked';
      dispatchSub = 'Locked';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: commonLabel,
              sublabel: commonSub,
              icon: Icons.category_outlined,
              color: Colors.blue.shade600,
              enabled: canAct,
              loading: _saving,
              onTap: () => _showConfirmDialog('COMMON', currentIndex),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: dispatchLabel,
              sublabel: dispatchSub,
              icon: Icons.local_shipping_outlined,
              color: Colors.green.shade600,
              enabled: canAct,
              loading: _saving,
              onTap: () => _showConfirmDialog('DISPATCH', currentIndex),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Confirm dialog ───────────────────────────────────────────
  void _showConfirmDialog(String type, int productIndex) {
    final isCommon = type == 'COMMON';
    final productName =
        (_mdfProducts[productIndex]['productName'] ?? 'Product').toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isCommon ? Colors.blue : Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCommon
                    ? Icons.category_outlined
                    : Icons.local_shipping_outlined,
                color: isCommon ? Colors.blue : Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isCommon ? 'COMMON ORDER' : 'Send to DISPATCH?',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📦 $productName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _C.primary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isCommon
                  ? 'This product will be moved to the Common Orders list. This action cannot be undone.'
                  : 'This product will be moved to the Dispatch queue. This action cannot be undone.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finalSave(type, productIndex);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCommon ? Colors.blue : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Confirm $type'),
          ),
        ],
      ),
    );
  }

  // ─── Loader ───────────────────────────────────────────────────
  Widget _buildLoader() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: _C.primaryGrad,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _C.primary.withOpacity(0.3), blurRadius: 20),
            ],
          ),
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Loading MDF data...',
          style: TextStyle(
            fontSize: 15,
            color: _C.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 70, color: _C.warning),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _fetch,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
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
            Icons.inventory_2_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No MDF Products Found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _C.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This order has no MDF category products.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    ),
  );

  Widget _buildBody() => Column(
    children: [
      _orderBanner(),
      if (_mdfProducts.length > 1) _tabBar(),
      Expanded(
        child: _mdfProducts.length == 1
            ? _productBody(0)
            : TabBarView(
                controller: _tabs!,
                children: List.generate(
                  _mdfProducts.length,
                  (i) => _productBody(i),
                ),
              ),
      ),
    ],
  );

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
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 28,
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (company.isNotEmpty)
                  Text(
                    company,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: Colors.white54,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sp,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: pColor),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: pColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white60,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      delivStr,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_mdfProducts.length}\nMDF',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      tabs: List.generate(_mdfProducts.length, (i) {
        final name = (_mdfProducts[i]['productName'] ?? 'Product ${i + 1}')
            .toString();
        final done = _kStages
            .where((s) => _prodData[i][s.id]['done'] == true)
            .length;
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.length > 12 ? '${name.substring(0, 12)}…' : name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: done == _kStages.length
                      ? _C.success.withOpacity(0.15)
                      : _C.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$done/${_kStages.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: done == _kStages.length ? _C.success : _C.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ),
  );

  Widget _productBody(int i) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
    children: [
      _productDetailCard(_mdfProducts[i]),
      const SizedBox(height: 16),
      _progressCard(i),
      const SizedBox(height: 16),
      ..._kStages.map((s) => _stageCard(i, s)),
      const SizedBox(height: 20),
    ],
  );

  Widget _productDetailCard(Map<String, dynamic> p) {
    String sv(dynamic v) => v == null ? '' : v.toString().trim();
    Widget row(String label, String val) {
      if (val.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 115,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                val,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.darkText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sections = (p['sections'] as Map<String, dynamic>?) ?? {};
    final extraSections = (p['customExtraSections'] as List?) ?? [];
    final List<String> chips = [];
    void addChip(String key, String label) {
      final v = sections[key];
      if (v != null && v.toString().trim().isNotEmpty && v.toString() != '0') {
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
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.primary.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: _C.primaryGrad,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'MDF Product Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          const Divider(height: 1),
          const SizedBox(height: 5),
          row('Product Name', sv(p['productName'])),
          row('Quantity', sv(p['quantity'])),
          row('Remarks', sv(p['remarks'])),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 5),
            const Text(
              'Sections:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips
                  .map(
                    (lbl) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: _C.primaryGrad,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lbl,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 5),
            const Text(
              'Reference Images:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
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
                      child: Image.network(
                        url,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
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
            child: Center(child: Image.network(url, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }

  Widget _progressCard(int i) {
    final pd = _prodData[i];
    final done = _kStages.where((s) => pd[s.id]['done'] == true).length;
    final pct = done / _kStages.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Production Progress',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _C.darkText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pct == 1
                      ? _C.success.withOpacity(0.15)
                      : _C.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pct == 1 ? '✅ Complete' : '$done / ${_kStages.length} stages',
                  style: TextStyle(
                    color: pct == 1 ? _C.success : _C.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct == 1 ? _C.success : _C.primary,
              ),
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
                  child: Column(
                    children: [
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
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isDone ? Icons.check_rounded : s.icon,
                          size: 18,
                          color: isDone ? Colors.white : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        s.title.split(' ').first,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDone ? s.color : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageCard(int i, _Stage s) {
    final sd = _prodData[i][s.id] as Map;
    final isDone = sd['done'] as bool;
    final ctrl = sd['remark'] as TextEditingController;
    final qtyCtrl = sd['qty'] as TextEditingController;

    final isLocked = _isFullyLocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? s.color : Colors.grey.shade200,
          width: isDone ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? s.color.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (isLocked) return;
              setState(() {
                sd['done'] = !isDone;
                if (sd['done']) {
                  final currentQty =
                      (sd['qty'] as TextEditingController).text;
                  final index = _kStages.indexOf(s);
                  if (index + 1 < _kStages.length) {
                    final nextCtrl =
                        _prodData[i][_kStages[index + 1].id]['qty']
                            as TextEditingController;
                    if (nextCtrl.text.isEmpty) nextCtrl.text = currentQty;
                  }
                  sd['date'] = DateTime.now().toIso8601String();
                } else {
                  sd['date'] = null;
                }
              });
              _save();

              // ✅ NEW: Auto switch to next incomplete product tab
              if (_allDoneForProduct(i) && _tabs != null && _mdfProducts.length > 1) {
                for (int next = i + 1; next < _mdfProducts.length; next++) {
                  if (!_allDoneForProduct(next)) {
                    final productName =
                        (_mdfProducts[next]['productName'] ?? 'Product ${next + 1}')
                            .toString();
                    Future.delayed(const Duration(milliseconds: 400), () {
                      if (mounted) {
                        _tabs!.animateTo(next);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '✅ Product ${i + 1} done! Now: $productName',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: _C.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    });
                    break;
                  }
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: isDone
                    ? LinearGradient(
                        colors: [
                          s.color.withOpacity(0.12),
                          s.color.withOpacity(0.04),
                        ],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade50, Colors.grey.shade100],
                      ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
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
                                blurRadius: 8,
                              ),
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
                        Text(
                          s.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDone ? s.color : Colors.grey.shade700,
                          ),
                        ),
                        if (isDone)
                          Text(
                            'Completed ✓',
                            style: TextStyle(
                              fontSize: 11,
                              color: s.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isDone
                          ? LinearGradient(
                              colors: [s.color, s.color.withOpacity(0.8)],
                            )
                          : null,
                      color: isDone ? null : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                color: s.color.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isDone ? Colors.white : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDone ? 'Done' : 'Pending',
                          style: TextStyle(
                            color: isDone ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                        enabled: !isLocked,
                        decoration: InputDecoration(
                          labelText: 'Remark',
                          prefixIcon: Icon(Icons.edit_note, color: s.color),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: s.color, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        enabled: !isLocked,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          prefixIcon: Icon(Icons.numbers, color: s.color),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: s.color, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isDone && sd['date'] != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: s.color),
                      const SizedBox(width: 6),
                      Text(
                        sd['date'].toString().substring(0, 16),
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
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  REUSABLE ACTION BUTTON WIDGET
// ════════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: enabled ? color : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}