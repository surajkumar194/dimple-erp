import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConstructionProductionListScreen extends StatefulWidget {
  const ConstructionProductionListScreen({super.key});

  @override
  State<ConstructionProductionListScreen> createState() =>
      _ConstructionProductionListScreenState();
}

class _ConstructionProductionListScreenState
    extends State<ConstructionProductionListScreen> {
      Map<String, String?> _productionTypeMap = {};
  String _search = '';
  List<String> _selectedTrayContractors = [];
  String? _selectedCuttingContractor;
  String? _selectedPastingContractor;
String? _productionType; // employee or contract
  final TextEditingController _cuttingPriceController = TextEditingController();
  final TextEditingController _pastingPriceController = TextEditingController();

  String? _expandedOrderId;

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

  Future<void> _selectBoxContractors() async {
    final List<String> tempSelected = List.from(_selectedTrayContractors);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Box Contractor'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: _boxContractors.map((contractor) {
                    final isSelected = tempSelected.contains(contractor);

                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(contractor),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            tempSelected.add(contractor);
                          } else {
                            tempSelected.remove(contractor);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedTrayContractors = tempSelected;
                });
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

Widget _productionTypeSelector(String orderId) {

  String? selectedType = _productionTypeMap[orderId];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Production Type",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      const SizedBox(height: 1),
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _productionTypeMap[orderId] = "employee";
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == "employee"
                      ? _primary.withOpacity(0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primary),
                ),
                child: const Center(
                  child: Text(
                    "Employee",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _productionTypeMap[orderId] = "Contractor";
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == "Contractor"
                      ? _primary.withOpacity(0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primary),
                ),
                child: const Center(
                  child: Text(
                    "Contractor",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
  // ─── Helpers ──────────────────────────────────────────────────
  Color _pColor(String p) {
    if (p == 'High') return _warning;
    if (p == 'Medium') return _accent;
    return _success;
  }

  int _mdfCount(List products) => products.where((p) {
    final cat = (p['productCategory'] ?? '').toString().toLowerCase();
    return cat == 'mdf' || cat == 'construction';
  }).length;

  int _completedStages(List products) {
    int done = 0;
    for (final p in products) {
      final cat = (p['productCategory'] ?? '').toString().toLowerCase();
      if (cat != 'mdf' && cat != 'construction') continue;

      final box = p['box'] ?? {};
      final cutting = p['cutting'] ?? {};
      final pasting = p['pasting'] ?? {};

      if (box['done'] == true) done++;
      if (cutting['done'] == true) done++;
      if (pasting['done'] == true) done++;
    }
    return done;
  }

  int _totalStages(List products) => _mdfCount(products) * 3;

  // ─── Build Widgets ────────────────────────────────────────────
  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.currency_rupee),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

Widget _buildProductionForm(String orderId) {

  String? type = _productionTypeMap[orderId];

  // 👇 Employee case
  if (type == "employee") {
    return Column(
      children: [

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.save),
          label: const Text("Save"),
          onPressed: () async {

            await FirebaseFirestore.instance
                .collection('constructionProduction')
                .doc(orderId)
                .set({
                  "productionType": "employee",
                  "updatedAt": FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Employee Production Saved")),
            );
          },
        ),

      ],
    );
  }

  // 👇 Contractor case (poora form)
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [

      GestureDetector(
        onTap: _selectBoxContractors,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedTrayContractors.isEmpty
                      ? 'Select Box Contractor'
                      : _selectedTrayContractors.join(', '),
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),

      const SizedBox(height: 10),

      _buildDropdown(
        label: 'Cutting Contractor',
        icon: Icons.person,
        value: _selectedCuttingContractor,
        items: _cuttingContractors,
        onChanged: (v) => setState(() => _selectedCuttingContractor = v),
      ),

      const SizedBox(height: 10),

      _buildPriceField(
        controller: _cuttingPriceController,
        label: 'Cutting Price',
      ),

      const SizedBox(height: 10),

      _buildDropdown(
        label: 'Pasting Contractor',
        icon: Icons.person,
        value: _selectedPastingContractor,
        items: _pastingContractors,
        onChanged: (v) => setState(() => _selectedPastingContractor = v),
      ),

      const SizedBox(height: 10),

      _buildPriceField(
        controller: _pastingPriceController,
        label: 'Pasting Price',
      ),

      const SizedBox(height: 20),

      ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text("Save Production"),
     onPressed: () async {

  await FirebaseFirestore.instance
      .collection('constructionProduction')
      .doc(orderId)
      .set({

    "orderId": orderId,
    "productionType": _productionTypeMap[orderId],

    "boxContractor": _selectedTrayContractors,
    "cuttingContractor": _selectedCuttingContractor,
    "cuttingPrice": _cuttingPriceController.text,

    "pastingContractor": _selectedPastingContractor,
    "pastingPrice": _pastingPriceController.text,

    "updatedAt": FieldValue.serverTimestamp(),

  }, SetOptions(merge: true));

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Production Saved")),
  );
}
      ),
    ],
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

  // ─── Order Card ───────────────────────────────────────────────
  Widget _orderCard(String orderId, Map<String, dynamic> data) {
    final customer = data['customerName'] ?? '-';
    final company = data['companyName'] ?? '';
    final priority = data['priority'] ?? 'Medium';
    final sp = data['salesPerson'] ?? '-';
    final unit = data['unit'] ?? '-';
    final products = data['products'] is List ? data['products'] as List : [];
    final mdfCount = _mdfCount(products);

    final delivery = (data['deliveryDate'] as Timestamp?)?.toDate();
    final delivStr = delivery != null
        ? '${delivery.day}/${delivery.month}/${delivery.year}'
        : '-';

    final mdfNames = products
        .where(
          (p) => (p['productCategory'] ?? '').toString().toLowerCase() == 'mdf',
        )
        .map((p) => (p['productName'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();

    final isExpanded = _expandedOrderId == orderId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('constructionProduction')
          .doc(orderId)
          .get(),
   builder: (context, snap) {

  bool productionSaved = false;

  List prod = products;

  if (snap.hasData && snap.data!.exists) {
    productionSaved = true;

    final cData = snap.data!.data() as Map<String, dynamic>;
    prod = cData['products'] ?? products;
  }
        
     

        final doneStages = _completedStages(prod);
        final totalStages = _totalStages(prod);
        final pct = totalStages > 0 ? doneStages / totalStages : 0.0;

        return GestureDetector(
          onTap: () {
            setState(() {
              _expandedOrderId = isExpanded ? null : orderId;
              // Reset form fields when switching order
              if (!isExpanded) {
                _selectedTrayContractors = [];
                _selectedCuttingContractor = null;
                _selectedPastingContractor = null;
                _cuttingPriceController.clear();
                _pastingPriceController.clear();
              }
            });
          },
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
                // ── Header ──────────────────────────────────────
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
                          Icons.construction,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                          const SizedBox(height: 6),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: _primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Info Row ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _infoChip(Icons.factory_outlined, unit),
                      const SizedBox(width: 10),
                      _infoChip(Icons.calendar_today, delivStr),
                      const SizedBox(width: 10),
                      _infoChip(Icons.precision_manufacturing, '$mdfCount MDF'),
                    ],
                  ),
                ),

                if (mdfNames.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: mdfNames
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
                                  color: const Color(
                                    0xFF169a8d,
                                  ).withOpacity(0.3),
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
                  
_productionTypeSelector(orderId),
if (productionSaved)
  Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green),
        SizedBox(width: 8),
        Text(
          "Production Already Saved",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    ),
  ),
                // ── Expanded Production Form ──────────────────────
if (isExpanded && !productionSaved)                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: _buildProductionForm(orderId),
                    ),
                  ),

                // ── Open Production Button ────────────────────────
                if (!isExpanded)
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
      },
    );
  }

  // ─── Main Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: _primary),
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
                  'Contractor Production',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Manage Contractor production stages',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────────────
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

          // ── Orders List ──────────────────────────────────────
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

                final allDocs = snap.data!.docs;
                final filtered = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final products = data['products'] is List
                      ? data['products'] as List
                      : [];

                  if (_mdfCount(products) == 0) return false;
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
                            Icons.construction,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No MDF Orders Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _search.isEmpty
                              ? 'No orders have MDF products yet.'
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

  @override
  void dispose() {
    _cuttingPriceController.dispose();
    _pastingPriceController.dispose();
    super.dispose();
  }
}
