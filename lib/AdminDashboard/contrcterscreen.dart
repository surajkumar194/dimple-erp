import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



class ConstructionProductionScreen extends StatefulWidget {
  final String orderId;
  final List products;

  const ConstructionProductionScreen({
    super.key,
    required this.orderId,
    required this.products,
  });

  @override
  State<ConstructionProductionScreen> createState() =>
      _ConstructionProductionScreenState();
}

class _ConstructionProductionScreenState
    extends State<ConstructionProductionScreen> {
  // ─── Colors ───────────────────────────────────────────────────
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

  // ─── Local state ──────────────────────────────────────────────
  Map<String, dynamic> _orderData = {};
  List<dynamic> _products = [];
  bool _loading = true;
  bool _saving = false;
@override
void initState() {
  super.initState();
  _loadData();
}
  // ─── Per-product controllers & selections ─────────────────────
  // Each index holds its own selections
  final Map<int, Map<String, dynamic>> _productState = {};

  // ─── Dropdown options ─────────────────────────────────────────
  final List<String> _boxContractors = [
    'MDF Box (HR, Bhaji Box, Wedding Box Plain)',
    'Trays',
    'Double Door Box',
    'Flap Down',
    'ARC Box',
    'One Slant',
    'Mandir Box / TV Box',
    'Plater (without handle)',
    'Doom Box',
    'File Box',
    'Two Side Tapper Box',
    'Chocunki Box',
    'Farme Box',
    'Window Box',
    'Other',
  ];

  final List<String> _cuttingContractors = [
    'Mehfos',
    'Sadiq',
    'Shoaib',
    'Other',
  ];

  final List<String> _pastingContractors = [
    'Shahnawaz',
    'Ankush',
    'Danish',
    'Karan',
    'Pappu',
    'Tohid',
    'Nandu',
    'Sadiq / Shahnawaz',
    'Azam',
    'Anil',
    'Other',
  ];


  // ─── Load from Firestore ──────────────────────────────────────
  Future<void> _loadData() async {
    try {
      final orderSnap = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!orderSnap.exists) return;
      final order = orderSnap.data()!;

      // Sirf MDF products
      final allProducts = (order['products'] as List? ?? []);

  final mdfProducts = allProducts.where((p) {
  final cat = (p['productCategory'] ?? '').toString().toLowerCase().trim();
  return cat.contains('mdf') ;
}).toList();
      debugPrint(
        '>>> Total products: ${allProducts.length}, MDF found: ${mdfProducts.length}',
      );
      for (final p in allProducts) {
        // debugPrint('>>> category: "\${p['productCategory']}"');
      }

      // Saved data load karo
      final savedSnap = await FirebaseFirestore.instance
          .collection('constructionProduction')
          .doc(widget.orderId)
          .get();

      for (int i = 0; i < mdfProducts.length; i++) {
        _productState[i] = {
          // Box contractor
          'boxContractor': null,
          'boxOther': TextEditingController(),
          'boxDone': false,
          // Cutting
          'cuttingContractor': null,
          'cuttingOther': TextEditingController(),
          'cuttingPrice': TextEditingController(),
          'cuttingDone': false,
          // Pasting
          'pastingContractor': null,
          'pastingOther': TextEditingController(),
          'pastingPrice': TextEditingController(),
          'pastingDone': false,
        };

        // Load saved values if exist
        if (savedSnap.exists) {
          final savedProducts = (savedSnap.data()!['products'] as List? ?? []);
          if (i < savedProducts.length) {
            final sp = savedProducts[i] as Map<String, dynamic>? ?? {};
            final box = sp['box'] as Map<String, dynamic>? ?? {};
            final cutting = sp['cutting'] as Map<String, dynamic>? ?? {};
            final pasting = sp['pasting'] as Map<String, dynamic>? ?? {};

            _productState[i]!['boxContractor'] = box['contractor'];
            _productState[i]!['boxOther'].text = box['otherName'] ?? '';
            _productState[i]!['boxDone'] = box['done'] ?? false;

            _productState[i]!['cuttingContractor'] = cutting['contractor'];
            _productState[i]!['cuttingOther'].text = cutting['otherName'] ?? '';
            _productState[i]!['cuttingPrice'].text =
                '${cutting['price'] ?? ''}';
            _productState[i]!['cuttingDone'] = cutting['done'] ?? false;

            _productState[i]!['pastingContractor'] = pasting['contractor'];
            _productState[i]!['pastingOther'].text = pasting['otherName'] ?? '';
            _productState[i]!['pastingPrice'].text =
                '${pasting['price'] ?? ''}';
            _productState[i]!['pastingDone'] = pasting['done'] ?? false;
          }
        }
      }

      setState(() {
        _orderData = order;
        _products = mdfProducts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // ─── Save to Firestore ────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final List<Map<String, dynamic>> productsToSave = [];

      for (int i = 0; i < _products.length; i++) {
        final ps = _productState[i]!;
        final p = Map<String, dynamic>.from(_products[i]);

        p['box'] = {
          'contractor': ps['boxContractor'] == 'Other'
              ? (ps['boxOther'] as TextEditingController).text.trim()
              : ps['boxContractor'] ?? '',
          'otherName': (ps['boxOther'] as TextEditingController).text.trim(),
          'done': ps['boxDone'],
        };
        p['cutting'] = {
          'contractor': ps['cuttingContractor'] == 'Other'
              ? (ps['cuttingOther'] as TextEditingController).text.trim()
              : ps['cuttingContractor'] ?? '',
          'otherName': (ps['cuttingOther'] as TextEditingController).text
              .trim(),
          'price':
              double.tryParse(
                (ps['cuttingPrice'] as TextEditingController).text.trim(),
              ) ??
              0,
          'done': ps['cuttingDone'],
        };
        p['pasting'] = {
          'contractor': ps['pastingContractor'] == 'Other'
              ? (ps['pastingOther'] as TextEditingController).text.trim()
              : ps['pastingContractor'] ?? '',
          'otherName': (ps['pastingOther'] as TextEditingController).text
              .trim(),
          'price':
              double.tryParse(
                (ps['pastingPrice'] as TextEditingController).text.trim(),
              ) ??
              0,
          'done': ps['pastingDone'],
        };

        productsToSave.add(p);
      }

      await FirebaseFirestore.instance
          .collection('constructionProduction')
          .doc(widget.orderId)
          .set({
            'orderId': widget.orderId,
            'customerName': _orderData['customerName'] ?? '',
            'companyName': _orderData['companyName'] ?? '',
            'priority': _orderData['priority'] ?? '',
            'deliveryDate': _orderData['deliveryDate'],
            'updatedAt': FieldValue.serverTimestamp(),
            'products': productsToSave,
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Saved successfully!'),
              ],
            ),
            backgroundColor: _success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Progress ─────────────────────────────────────────────────
  int get _totalStages => _products.length * 3; // box + cutting + pasting

  int get _doneStages {
    int done = 0;
    for (int i = 0; i < _products.length; i++) {
      final ps = _productState[i];
      if (ps == null) continue;
      if (ps['boxDone'] == true) done++;
      if (ps['cuttingDone'] == true) done++;
      if (ps['pastingDone'] == true) done++;
    }
    return done;
  }

  double get _progress => _totalStages > 0 ? _doneStages / _totalStages : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _primaryGrad),
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
              child: Image.asset('assets/dpl.png', height: 26),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Construction Production',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Text(
                  'Manage contractor stages',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      
      ),
   body: _loading
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : _products.isEmpty
        ? _buildEmpty()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(index);
            },
          ),
               
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              backgroundColor: _primary,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                _saving ? 'Saving...' : 'Save Progress',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  // ─── Summary Header ───────────────────────────────────────────
  Widget _buildSummaryHeader() {
    final customer = _orderData['customerName'] ?? '-';
    final company = _orderData['companyName'] ?? '';
    final priority = _orderData['priority'] ?? 'Medium';
    final delivery = (_orderData['deliveryDate'] as Timestamp?)?.toDate();
    final delivStr = delivery != null
        ? '${delivery.day}/${delivery.month}/${delivery.year}'
        : '-';

    Color pColor = priority == 'High'
        ? _warning
        : priority == 'Medium'
        ? _accent
        : _success;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _primaryGrad,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.precision_manufacturing,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                          fontSize: 12,
                          color: Colors.grey.shade500,
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
                  color: pColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: pColor),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: pColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _chip(Icons.calendar_today, delivStr),
              const SizedBox(width: 8),
              _chip(Icons.precision_manufacturing, '${_products.length} MDF'),
              const SizedBox(width: 8),
              _chip(Icons.checklist_rounded, '$_doneStages/$_totalStages done'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _progress == 1 ? _success : _primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _progress == 1 ? _success : _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Product Card ─────────────────────────────────────────────
  Widget _buildProductCard(int index) {
    final p = _products[index];
    final productName = p['productName'] ?? 'Product ${index + 1}';
    final qty = p['quantity'] ?? 0;
    final price = p['price'] ?? 0;
    final ps = _productState[index]!;

    int productDone = 0;
    if (ps['boxDone'] == true) productDone++;
    if (ps['cuttingDone'] == true) productDone++;
    if (ps['pastingDone'] == true) productDone++;
    final productPct = productDone / 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          // ── Product header ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary.withOpacity(0.1), _primary.withOpacity(0.04)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing,
                    color: _primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                      Text(
                        'Qty: $qty  •  ₹$price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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
                    color: productPct == 1
                        ? _success.withOpacity(0.15)
                        : _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    productPct == 1 ? '✅ Done' : '$productDone/3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: productPct == 1 ? _success : _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: productPct,
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  productPct == 1 ? _success : _primary,
                ),
              ),
            ),
          ),

          // ── 3 Sections ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // 1. Box Description
                _buildContractorSection(
                  index: index,
                  title: 'Box Description & Contractor',
                  icon: Icons.inbox_outlined,
                  color: const Color(0xFF16A085),
                  doneKey: 'boxDone',
                  child: Column(
                    children: [
                      _buildDropdown(
                        label: 'Select Box Type / Contractor',
                        icon: Icons.person_pin,
                        value: ps['boxContractor'],
                        items: _boxContractors,
                        onChanged: (v) => setState(
                          () => _productState[index]!['boxContractor'] = v,
                        ),
                      ),
                      if (ps['boxContractor'] == 'Other') ...[
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: ps['boxOther'],
                          label: 'Enter Contractor Name',
                          icon: Icons.edit,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. MDF Cutting
                _buildContractorSection(
                  index: index,
                  title: 'MDF Cutting',
                  icon: Icons.cut_outlined,
                  color: const Color(0xFF2980B9),
                  doneKey: 'cuttingDone',
                  child: Column(
                    children: [
                      _buildDropdown(
                        label: 'Select Cutting Contractor',
                        icon: Icons.person_pin,
                        value: ps['cuttingContractor'],
                        items: _cuttingContractors,
                        onChanged: (v) => setState(
                          () => _productState[index]!['cuttingContractor'] = v,
                        ),
                      ),
                      if (ps['cuttingContractor'] == 'Other') ...[
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: ps['cuttingOther'],
                          label: 'Enter Contractor Name',
                          icon: Icons.edit,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _buildPriceField(
                        controller: ps['cuttingPrice'],
                        label: 'Cutting Price (₹)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. MDF Pasting
                _buildContractorSection(
                  index: index,
                  title: 'MDF Pasting',
                  icon: Icons.layers_outlined,
                  color: const Color(0xFF8E44AD),
                  doneKey: 'pastingDone',
                  child: Column(
                    children: [
                      _buildDropdown(
                        label: 'Select Pasting Contractor',
                        icon: Icons.person_pin,
                        value: ps['pastingContractor'],
                        items: _pastingContractors,
                        onChanged: (v) => setState(
                          () => _productState[index]!['pastingContractor'] = v,
                        ),
                      ),
                      if (ps['pastingContractor'] == 'Other') ...[
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: ps['pastingOther'],
                          label: 'Enter Contractor Name',
                          icon: Icons.edit,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _buildPriceField(
                        controller: ps['pastingPrice'],
                        label: 'Pasting Price (₹)',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Contractor Section with Done toggle ──────────────────────
  Widget _buildContractorSection({
    required int index,
    required String title,
    required IconData icon,
    required Color color,
    required String doneKey,
    required Widget child,
  }) {
    final done = _productState[index]![doneKey] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? color.withOpacity(0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? color.withOpacity(0.3) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Section title + done toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: done ? color.withOpacity(0.15) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: done ? color : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: done ? color : _darkText,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              // Done checkbox
              GestureDetector(
                onTap: () =>
                    setState(() => _productState[index]![doneKey] = !done),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: done ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: done ? color : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
      items: items
          .map(
            (name) => DropdownMenuItem<String>(value: name, child: Text(name)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.currency_rupee, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
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
              Icons.precision_manufacturing,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No MDF Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkText,
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
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
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

  @override
  void dispose() {
    for (final ps in _productState.values) {
      (ps['boxOther'] as TextEditingController).dispose();
      (ps['cuttingOther'] as TextEditingController).dispose();
      (ps['cuttingPrice'] as TextEditingController).dispose();
      (ps['pastingOther'] as TextEditingController).dispose();
      (ps['pastingPrice'] as TextEditingController).dispose();
    }
    super.dispose();
  }
}
