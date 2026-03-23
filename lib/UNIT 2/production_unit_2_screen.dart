import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _AppColors {
  static const darkGreen = Color(0xFF0A3D1F);
  static const midGreen = Color(0xFF1B6B3A);
  static const accentGreen = Color(0xFF2E9E55);
  static const lightGreen = Color(0xFF4CAF50);
  static const bgGreen = Color(0xFFF0F7F2);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF0D2B1A);
  static const textMid = Color(0xFF3D6B52);
  static const textLight = Color(0xFF8BA899);
  static const blue = Color(0xFF1565C0);
  static const orange = Color(0xFFE65100);
  static const red = Color(0xFFC62828);
  static const purple = Color(0xFF6A1B9A);
}

class ProductionUnit2Screen extends StatelessWidget {
  const ProductionUnit2Screen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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
                        'Unit 2 — Job Cards',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage Job Cards for Unit 2',
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
            .collection('unit2JobCards')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyState();
          }

          final validDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _filterRigidBoxProducts(data['products']).isNotEmpty;
          }).toList();

          if (validDocs.isEmpty) return const _EmptyState();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            itemCount: validDocs.length,
            itemBuilder: (context, index) {
              final doc = validDocs[index];
              return _OrderCard(
                docId: doc.id,
                data: doc.data() as Map<String, dynamic>,
              );
            },
          );
        },
      ),
    );
  }
}

List<Map<String, dynamic>> _filterRigidBoxProducts(dynamic rawProducts) {
  List<Map<String, dynamic>> products = [];
  if (rawProducts is List) {
    products = rawProducts.map((e) => Map<String, dynamic>.from(e)).toList();
  } else if (rawProducts is Map) {
    products = [Map<String, dynamic>.from(rawProducts)];
  }
  return products
      .where((p) {
  final cat = (p['productCategory'] ?? '').toString().trim().toLowerCase();
  return cat.contains('rigid box');
})
      .toList();
}

String _formatDate(dynamic ts) {
  if (ts is Timestamp) {
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
  return 'N/A';
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _AppColors.midGreen.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: _AppColors.midGreen,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Orders...',
            style: TextStyle(
              color: _AppColors.textMid,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _AppColors.midGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: _AppColors.midGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Orders Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unit 2 mein koi Rigid Box order nahi hai abhi.',
            style: TextStyle(fontSize: 14, color: _AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _OrderCard({required this.docId, required this.data});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _customerExpanded = false;

  List<Map<String, dynamic>> _extractProducts() =>
      _filterRigidBoxProducts(widget.data['products']);

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final status = data['productionStatus'] ?? 'Pending';
    final products = _extractProducts();
    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _AppColors.midGreen.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(data, status, products.length),
          _buildCustomerSection(data),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFEEF2EE),
          ),
          _buildProductsSection(products),
        ],
      ),
    );
  }

  // ─────────────────── HEADER ───────────────────
  Widget _buildHeader(Map<String, dynamic> data, String status, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _AppColors.darkGreen,
            _AppColors.midGreen,
            _AppColors.accentGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.domain, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['companyName'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data['customerName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderChip(
                icon: Icons.local_shipping_outlined,
                text: _formatDate(data['deliveryDate']),
              ),
              const SizedBox(width: 8),
              _HeaderChip(
                icon: Icons.inventory_2_outlined,
                text: '$count Items',
              ),
              const SizedBox(width: 8),
              _PriorityChip(priority: data['priority']?.toString() ?? 'Normal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(Map<String, dynamic> data) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: const Color(0xFFF8FBF8),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _customerExpanded = !_customerExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _AppColors.midGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_pin_outlined,
                      size: 16,
                      color: _AppColors.midGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Customer Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  _MiniPill(
                    icon: Icons.phone,
                    text: data['phone']?.toString() ?? 'N/A',
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _customerExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: _AppColors.midGreen,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _customerExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DetailTile(
                          icon: Icons.phone_in_talk_outlined,
                          label: 'Phone',
                          value: data['phone']?.toString() ?? 'N/A',
                          color: _AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailTile(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: data['location']?.toString() ?? 'N/A',
                          color: _AppColors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Order Date',
                          value: _formatDate(data['orderDate']),
                          color: _AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DetailTile(
                          icon: Icons.local_shipping_outlined,
                          label: 'Delivery',
                          value: _formatDate(data['deliveryDate']),
                          color: _AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(List<Map<String, dynamic>> products) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _AppColors.midGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Rigid Box Products',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              _UnitBadge(),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.darkGreen, _AppColors.accentGreen],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${products.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...products.asMap().entries.map(
            (entry) => _ProductTile(
              product: entry.value,
              index: entry.key,
              docId: widget.docId,
              orderData: widget.data,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final int index;
  final String docId;
  final Map<String, dynamic> orderData;

  const _ProductTile({
    required this.product,
    required this.index,
    required this.docId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final sections = product['sections'] as Map<String, dynamic>? ?? {};
    final extras = product['customExtraSections'] as List? ?? [];
    final productName = product['productName'] ?? 'Product ${index + 1}';
    final quantity = product['quantity'] ?? 0;
    final length = product['length']?.toString() ?? '';
    final height = product['height']?.toString() ?? '';
    final width = product['width']?.toString() ?? '';
    final hasDimensions =
        length.isNotEmpty || height.isNotEmpty || width.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.darkGreen, _AppColors.accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _AppColors.textDark,
                      ),
                    ),
                    if (hasDimensions)
                      Row(
                        children: [
                          const Icon(
                            Icons.straighten_outlined,
                            size: 11,
                            color: _AppColors.textLight,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$length × $height × $width',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _AppColors.darkGreen.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _AppColors.midGreen.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  'Qty: $quantity',
                  style: const TextStyle(
                    color: _AppColors.darkGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),
            _ProductDetailsGrid(product: product),
            if (sections.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionBlock(
                title: 'Packaging Sections',
                color: _AppColors.blue,
                icon: Icons.layers_outlined,
                children: sections.entries
                    .map(
                      (e) => _InfoRow(label: e.key, value: e.value.toString()),
                    )
                    .toList(),
              ),
            ],
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 10),
              _SectionBlock(
                title: 'Extra Sections',
                color: _AppColors.orange,
                icon: Icons.add_box_outlined,
                children: extras
                    .map(
                      (e) => _InfoRow(
                        label: e['title'] ?? '',
                        value: 'Qty: ${e['qty']}  |  ₹${e['price']}',
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            // ✅ Job Card Stream — checks by orderId field
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('unit2JobCards')
                  .where('orderId', isEqualTo: docId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 44,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _AppColors.midGreen,
                      ),
                    ),
                  );
                }
                final exists =
                    snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                if (exists) {
                  final jobData =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  return _JobCardCreatedBadge(
                    jobCardData: jobData,
                    docId: snapshot.data!.docs.first.id,
                  );
                }
                return _CreateJobCardButton(
                  orderId: docId,
                  orderData: orderData,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailsGrid extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductDetailsGrid({required this.product});

  @override
  Widget build(BuildContext context) {
    final category = product['productCategory']?.toString() ?? '';
    final remarks = product['remarks']?.toString() ?? '';
    final length = product['length']?.toString() ?? '';
    final height = product['height']?.toString() ?? '';
    final width = product['width']?.toString() ?? '';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (category.isNotEmpty)
          _DetailPill(
            label: 'Category',
            value: category,
            icon: Icons.category_outlined,
          ),
        if (length.isNotEmpty)
          _DetailPill(
            label: 'L×H×W',
            value: '$length×$height×$width',
            icon: Icons.straighten_outlined,
          ),
        if (remarks.isNotEmpty)
          _DetailPill(
            label: 'Remarks',
            value: remarks,
            icon: Icons.notes_outlined,
          ),
      ],
    );
  }
}

class _JobCardCreatedBadge extends StatelessWidget {
  final Map<String, dynamic> jobCardData;
  final String docId;

  const _JobCardCreatedBadge({required this.jobCardData, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32).withOpacity(0.08),
            const Color(0xFF4CAF50).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Card Created',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  jobCardData['jobCardNumber'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: _AppColors.darkGreen,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: _AppColors.textLight,
          ),
        ],
      ),
    );
  }
}

class _CreateJobCardButton extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const _CreateJobCardButton({required this.orderId, required this.orderData});

  @override
  State<_CreateJobCardButton> createState() => _CreateJobCardButtonState();
}

class _CreateJobCardButtonState extends State<_CreateJobCardButton> {
  // ✅ Guard: double tap / double submission block
  bool _isSubmitting = false;
  String selectedTray = 'SBS';
  void _openJobCardForm(BuildContext context) {
    final sizeController = TextEditingController();

    final topSizeController = TextEditingController();
    final traySizeController = TextEditingController();
    final bottomSizeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ✅ isDismissible false while submitting handled inside
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
            top: 30,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _AppColors.midGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_add,
                        color: _AppColors.midGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Job Card',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Unit 2 — Rigid Box',
                          style: TextStyle(
                            fontSize: 12,
                            color: _AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                _FormSection(
                  title: 'Size',
                  icon: Icons.swap_horizontal_circle_sharp,
                  color: const Color.fromARGB(255, 233, 31, 13),
                  sizeController: sizeController,
                ),
                const SizedBox(height: 2),

                _FormSection(
                  title: 'Top Part',
                  icon: Icons.vertical_align_top_rounded,
                  color: _AppColors.blue,
                  sizeController: topSizeController,
                 inputFormatters: [],
keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 2),
                _FormSection(
                  title: 'Bottom Part',
                  icon: Icons.vertical_align_bottom_rounded,
                  color: _AppColors.orange,
                  sizeController: bottomSizeController,
                  inputFormatters: [],
keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 2),

                _TrayDropdown(
                  selectedTray: selectedTray,
                  onChanged: (val) {
                    setState(() {
                      selectedTray = val!;
                    });
                  },
                ),

                const SizedBox(height: 2),

                // ✅ Submit Button — uses StatefulBuilder to show loading state
                StatefulBuilder(
                  builder: (ctx, setLocalState) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // ✅ null when submitting — disables button
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (sizeController.text.trim().isEmpty ||
                                    topSizeController.text.trim().isEmpty ||
                                    bottomSizeController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    _snackBar(
                                      '⚠️ All fields are required!',
                                      Colors.red.shade700,
                                    ),
                                  );
                                  return;
                                }
                                setLocalState(() {});
                                await _createJobCard(
                                  context,
                                  sheetContext: sheetContext,
                                  Size: sizeController.text.trim(),
                                  topSize: topSizeController.text.trim(),

                                  traySize: selectedTray,

                                  bottomSize: bottomSizeController.text.trim(),
                                );
                                setLocalState(() {});
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubmitting
                              ? Colors.grey
                              : _AppColors.midGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_turned_in_outlined,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Generate Job Card',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ FIXED _createJobCard
  Future<void> _createJobCard(
    BuildContext context, {
    required BuildContext sheetContext,
    required String Size,
    required String topSize,
    required String traySize,
    required String bottomSize,
  }) async {
    if (_isSubmitting) return;
    if (mounted) setState(() => _isSubmitting = true);

    try {
      final jobCardRef = FirebaseFirestore.instance.collection('unit2JobCards');

      // ✅ 1️⃣ Check existing job card
      final existing = await jobCardRef
          .where('orderId', isEqualTo: widget.orderId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('⚠️ Job Card already exists for this order', Colors.orange),
        );
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }

      // ✅ 2️⃣ Get last job card number
      final snapshot = await jobCardRef
          .orderBy('jobCardNumber', descending: true)
          .limit(1)
          .get();

      int lastNumber = 0;

      if (snapshot.docs.isNotEmpty) {
        final lastCode =
            snapshot.docs.first.data()['jobCardNumber'] ?? 'DPL-HSP-00';
        lastNumber = int.tryParse(lastCode.split('-').last) ?? 0;
      }

      lastNumber++;

      final jobCardNumber = 'DPL-HSP-${lastNumber.toString().padLeft(2, '0')}';

      // ✅ 3️⃣ Filter products
      final rigidBoxProducts = _filterRigidBoxProducts(
        widget.orderData['products'],
      );

      // ✅ 4️⃣ Create job card
      await jobCardRef.doc(widget.orderId).set({
        'jobCardNumber': jobCardNumber,
        'orderId': widget.orderId,
        'customerName': widget.orderData['customerName'] ?? '',
        'companyName': widget.orderData['companyName'] ?? '',
        'salesPerson': widget.orderData['salesPerson'] ?? '',
        'dispatchDate': widget.orderData['deliveryDate'],
        'productionUnit': 'Unit 2',
        'createdDate': Timestamp.now(),
        'status': 'Pending',
        'products': rigidBoxProducts,
        'parts': {
          'size': {'size': Size},
          'topPart': {'size': topSize},
          'bottomPart': {'size': bottomSize},
          'tray': {'size': traySize},
        },
        'inventoryUsed': {},
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Close sheet
      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }

      // ✅ Success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('✅ Job Card Created: $jobCardNumber', _AppColors.midGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_snackBar('❌ Error: ${e.toString()}', Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  SnackBar _snackBar(String msg, Color color) => SnackBar(
    content: Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        // ✅ Disable while submitting
        onPressed: _isSubmitting ? null : () => _openJobCardForm(context),
        icon: const Icon(Icons.assignment_add, size: 20),
        label: const Text(
          'Create Job Card',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _TrayDropdown extends StatelessWidget {
  final String selectedTray;
  final Function(String?) onChanged;

  const _TrayDropdown({required this.selectedTray, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AppColors.purple.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _AppColors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_rows_outlined,
                  size: 16,
                  color: _AppColors.purple,
                ),
              ),
              const SizedBox(width: 8),

              const Text(
                "Tray",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _AppColors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: selectedTray,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: const [
              DropdownMenuItem(value: "SBS", child: Text("SBS")),
              DropdownMenuItem(value: "Golden", child: Text("Golden")),
              DropdownMenuItem(value: "Plastic", child: Text("Plastic")),
              DropdownMenuItem(value: "N/A", child: Text("N/A")),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  FORM SECTION WIDGET
// ══════════════════════════════════════════════════
class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final TextEditingController sizeController;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.sizeController,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),

              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

         _StyledTextField(
  controller: sizeController,
  label: 'Size (L×H×W)',
  icon: Icons.straighten_outlined,
  color: color,
  keyboardType: keyboardType,
  inputFormatters: inputFormatters,
),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters, // ✅ IMPORTANT
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _AppColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
        prefixIcon: Icon(icon, size: 16, color: color.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  SMALL WIDGETS
// ══════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'Completed':
        return const Color(0xFF2E7D32);
      case 'In Progress':
        return _AppColors.orange;
      default:
        return _AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;

  const _PriorityChip({required this.priority});

  Color get _color {
    final p = priority.toLowerCase();
    if (p.contains('high') || p.contains('urgent')) return _AppColors.red;
    if (p.contains('medium')) return _AppColors.orange;
    return _AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _AppColors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.blue.withOpacity(0.35)),
      ),
      child: const Text(
        'Unit 2',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _AppColors.blue,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _AppColors.midGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _AppColors.midGreen),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: _AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _AppColors.bgGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E8DA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _AppColors.midGreen),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: _AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: _AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<Widget> children;

  const _SectionBlock({
    required this.title,
    required this.color,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
