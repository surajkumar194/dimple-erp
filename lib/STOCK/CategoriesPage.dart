import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final Stream<QuerySnapshot> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = FirebaseFirestore.instance
        .collection('products')
        .orderBy('category') 
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        toolbarHeight: 70,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: _buildCategoriesList(),
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'All Categories (from Products)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _productsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 3),
                        SizedBox(height: 16),
                        Text('Loading categories...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      _EmptyIcon(icon: Icons.category_outlined),
                      SizedBox(height: 16),
                      Text('No products found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                      SizedBox(height: 8),
                      Text('Add products first to see categories',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                      SizedBox(height: 16),
                    ],
                  ),
                );
              }

              // Unique categories + per-category count
              final Map<String, int> catCount = {};
              for (final doc in snapshot.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                String cat = (d['category'] ?? '').toString().trim();
                if (cat.isEmpty) continue;
                cat = cat.toUpperCase(); // normalize to avoid RAW/raw duplicates
                catCount.update(cat, (v) => v + 1, ifAbsent: () => 1);
              }

              final categories = catCount.keys.toList()..sort();
              if (categories.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      _EmptyIcon(icon: Icons.category_outlined),
                      SizedBox(height: 16),
                      Text('No categories yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                      SizedBox(height: 8),
                      Text('Fill category in your products to see them here',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                      SizedBox(height: 16),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: categories.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final count = catCount[cat] ?? 0;
                  return _buildCategoryTile(cat, count);
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String categoryName, int count) {
    final initial = categoryName.isNotEmpty ? categoryName[0] : '?';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              categoryName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E7FF)),
            ),
            child: Text('$count item(s)',
                style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class UOMPage extends StatefulWidget {
  const UOMPage({super.key});

  @override
  State<UOMPage> createState() => _UOMPageState();
}

class _UOMPageState extends State<UOMPage> {
  final uomCtrl = TextEditingController();
  late final Stream<QuerySnapshot> _uomStream;

  @override
  void initState() {
    super.initState();
    _uomStream = FirebaseFirestore.instance
        .collection('uom')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatDate(dynamic date) {
    DateTime? dt;
    if (date is Timestamp) {
      dt = date.toDate();
    } else if (date is DateTime) dt = date;
    else if (date is String) dt = DateTime.tryParse(date);
    if (dt == null) return 'N/A';
    return '${dt.day.toString().padLeft(2, '0')} '
        '${_month(dt.month)} '
        '${dt.year}';
  }

  String _month(int m) {
    const names = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Units of Measurement',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        toolbarHeight: 70,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48.0 : (isTablet ? 32.0 : 16.0),
            vertical: 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 32),
              _buildAddUOMForm(isDesktop, isTablet),
              const SizedBox(height: 32),
              _buildUOMList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.straighten_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Units of Measurement', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Define measurement units for your inventory', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddUOMForm(bool isDesktop, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Unit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Flex(
            direction: isDesktop || isTablet ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: isDesktop || isTablet ? 3 : 1,
                child: TextField(
                  controller: uomCtrl,
                  decoration: InputDecoration(
                    labelText: 'Unit Name',
                    hintText: 'e.g., Pieces, KG, Liters, Meters...',
                    prefixIcon: const Icon(Icons.straighten_outlined, color: Color(0xFF6B7280)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              SizedBox(width: isDesktop || isTablet ? 16 : 0, height: isDesktop || isTablet ? 0 : 16),
              Flexible(
                flex: 1,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addUOM,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Unit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUOMList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('All Units',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _uomStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 3),
                        SizedBox(height: 16),
                        Text('Loading units...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              final uoms = snapshot.data!.docs;
              if (uoms.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      _EmptyIcon(icon: Icons.straighten_outlined),
                      SizedBox(height: 16),
                      Text('No units yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                      SizedBox(height: 8),
                      Text('Add your first measurement unit to get started',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                      SizedBox(height: 16),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: uoms.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final uom = uoms[index];
                  return _buildUOMCard(uom);
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUOMCard(QueryDocumentSnapshot uom) {
    final name = (uom['name'] ?? '').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final createdAt = uom['createdAt'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text('Created: ${_formatDate(createdAt)}',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            onPressed: () => _showDeleteUOMDialog(uom.id, name),
            tooltip: 'Delete unit',
          ),
        ],
      ),
    );
  }

  void _showDeleteUOMDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Unit',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUOM(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUOM(String id) async {
    try {
      await FirebaseFirestore.instance.collection('uom').doc(id).delete();
      _showSnackBar('Unit deleted successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _addUOM() async {
    if (uomCtrl.text.trim().isEmpty) {
      _showSnackBar('Please enter a unit name', Colors.orange);
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('uom').add({
        'name': uomCtrl.text.trim(),
        'createdAt': Timestamp.now(),
      });
      uomCtrl.clear();
      _showSnackBar('Unit added successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  @override
  void dispose() {
    uomCtrl.dispose();
    super.dispose();
  }
}

class _EmptyIcon extends StatelessWidget {
  final IconData icon;
  const _EmptyIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(50)),
      child: Icon(icon, size: 48, color: const Color(0xFF9CA3AF)),
    );
  }
}
