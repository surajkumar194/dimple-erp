import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

String _hsnForCategory(String? category) {
  if (category == 'MDF') return '44111200';
  if (category == 'Laddu Paper') return '48062000';
  return '48192090';
}

double _gstPctForCategory(String? category) {
  if (category == 'MDF') return 18.0;
  if (category == 'Laddu Paper') return 18.0;
  return 5.0;
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Processing',
    'Completed',
    'Cancelled',
  ];

  void _showTermsSelectionDialog(
    Map<String, dynamic> data, {
    required bool withHsn,
  }) {
    bool payment = true;
    bool freight = true;
    bool packing = true;
    bool gst = true;
    bool balancePayment = true;
    bool advance50 = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Terms & Conditions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: advance50,
                onChanged: (v) => setState(() => advance50 = v ?? true),
                title: const Text(
                  '50% advance payment is required to commence production',
                ),
              ),

               CheckboxListTile(
                value: balancePayment,
                onChanged: (v) => setState(() => balancePayment = v ?? true),
                title: const Text(
                  'Balance payment must be paid before dispatch.',
                ),
              ),
              CheckboxListTile(
                value: payment,
                onChanged: (v) => setState(() => payment = v ?? true),
                title: const Text('Goods will be dispatched only after receipt of full payment.'),
              ),
              CheckboxListTile(
                value: freight,
                onChanged: (v) => setState(() => freight = v ?? true),
                title: const Text('Freight charges are extra'),
              ),
              CheckboxListTile(
                value: packing,
                onChanged: (v) => setState(() => packing = v ?? true),
                title: const Text('Packing charges are extra'),
              ),
              CheckboxListTile(
                value: gst,
                onChanged: (v) => setState(() => gst = v ?? true),
                title: const Text('GST will be charged as per applicable rates (MDF Products - 18%; Cardboard Boxes - 5%).'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _generatePDF(
                  data,
                  withHsn: withHsn,
                  termsOptions: {
                    'payment': payment,
                    'advance50': advance50,
                    'freight': freight,
                    'packing': packing,
                    'gst': gst,
                    'balancePayment': balancePayment,
                  },
                );
              },
              child: const Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade600,
                Colors.blue.shade600,
                Colors.cyan.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history_rounded, size: 26),
            ),
            const SizedBox(width: 12),
            const Text(
              'Order History',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search + filter bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search orders, customers...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.blue.shade600,
                          size: 26,
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              }),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((status) {
                      final isSelected = _statusFilter == status;
                      Color chipColor;
                      switch (status) {
                        case 'Pending':
                          chipColor = Colors.orange;
                          break;
                        case 'Processing':
                          chipColor = Colors.blue;
                          break;
                        case 'Completed':
                          chipColor = Colors.green;
                          break;
                        case 'Cancelled':
                          chipColor = Colors.red;
                          break;
                        default:
                          chipColor = Colors.purple;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: FilterChip(
                          label: Text(
                            status,
                            style: TextStyle(
                              color: isSelected ? Colors.white : chipColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _statusFilter = status),
                          avatar: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                          backgroundColor: chipColor.withOpacity(0.1),
                          selectedColor: chipColor,
                          side: BorderSide(
                            color: isSelected
                                ? chipColor
                                : chipColor.withOpacity(0.3),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          elevation: isSelected ? 4 : 0,
                          shadowColor: chipColor.withOpacity(0.5),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                          strokeWidth: 4,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading orders...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red.shade300,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState(
                    'No orders found',
                    'Start creating orders to see them here',
                    Icons.inbox_rounded,
                    Colors.blue,
                  );
                }

                final orders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_statusFilter != 'All' && data['status'] != _statusFilter)
                    return false;
                  if (_searchQuery.isNotEmpty) {
                    final orderNo = (data['salesOrderNo'] ?? '')
                        .toString()
                        .toLowerCase();
                    final customer = (data['customerName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final company = (data['companyName'] ?? '')
                        .toString()
                        .toLowerCase();
                    return orderNo.contains(_searchQuery) ||
                        customer.contains(_searchQuery) ||
                        company.contains(_searchQuery);
                  }
                  return true;
                }).toList();

                if (orders.isEmpty) {
                  return _emptyState(
                    'No matching orders',
                    'Try adjusting your filters',
                    Icons.search_off_rounded,
                    Colors.orange,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildOrderCard(doc.id, data, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Order Card ────────────────────────────────────────────────────────────
  Widget _buildOrderCard(String docId, Map<String, dynamic> data, int index) {
    final orderNo = data['salesOrderNo'] ?? 'N/A';
    final customerName = data['customerName'] ?? 'N/A';
    final totalAmount = (data['grandTotal'] ?? 0).toDouble();
    final status = data['status'] ?? 'Pending';
    final dispatchType = data['dispatchType'] ?? '';
    final orderDate = (data['orderDate'] as Timestamp?)?.toDate();

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Processing':
        statusColor = Colors.blue;
        statusIcon = Icons.autorenew_rounded;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_rounded;
    }

    final gradients = [
      [Colors.purple.shade400, Colors.purple.shade700],
      [Colors.blue.shade400, Colors.blue.shade700],
      [Colors.green.shade400, Colors.green.shade700],
      [Colors.orange.shade400, Colors.orange.shade700],
      [Colors.pink.shade400, Colors.pink.shade700],
      [Colors.teal.shade400, Colors.teal.shade700],
    ];
    final gradient = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, gradient[0].withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gradient[0].withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(docId, data),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderNo,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customerName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.currency_rupee_rounded,
                            label: 'Total Amount',
                            value: 'Rs${totalAmount.toStringAsFixed(0)}',
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.calendar_today_rounded,
                            label: 'Order Date',
                            value: orderDate != null
                                ? DateFormat('dd MMM yyyy').format(orderDate)
                                : 'N/A',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.local_shipping,
                            label: 'Dispatch',
                            value: dispatchType.isEmpty ? 'N/A' : dispatchType,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            onPressed: () => _editOrder(docId, data),
                            icon: Icons.edit_rounded,
                            label: 'Edit Order',
                            gradient: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            onPressed: () => _showDownloadOptions(data),
                            icon: Icons.download_rounded,
                            label: 'Download',
                            gradient: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ── Download Options ──────────────────────────────────────────────────────
  void _showDownloadOptions(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF5F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Download Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade700],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              title: const Text(
                'Download PDF (Standard)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: const Text(
                'PDF with images, GST breakdown — no HSN codes',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showTermsSelectionDialog(data, withHsn: false);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              title: const Text(
                'Download PDF (With HSN Codes)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: const Text(
                'MDF: 44111200 | Laddu Paper: 48062000 | Others: 48192090',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showTermsSelectionDialog(data, withHsn: true);
              },
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ── Order Detail Bottom Sheet ─────────────────────────────────────────────
  void _showOrderDetails(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.purple.shade300],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.purple.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection(
                      'Customer Information',
                      Icons.person_rounded,
                      Colors.purple,
                      [
                        _buildDetailRow(
                          'Customer Name',
                          data['customerName'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Company Name',
                          data['companyName'] ?? 'N/A',
                        ),
                        _buildDetailRow('Phone', data['phone'] ?? 'N/A'),
                        _buildDetailRow('Email', data['email'] ?? 'N/A'),
                        _buildDetailRow('Location', data['location'] ?? 'N/A'),
                        _buildDetailRow(
                          'GST Number',
                          data['customerGstNumber'] ?? 'N/A',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      'Order Information',
                      Icons.shopping_cart_rounded,
                      Colors.blue,
                      [
                        _buildDetailRow(
                          'Order Number',
                          data['salesOrderNo'] ?? 'N/A',
                        ),
                        _buildDetailRow('Unit', data['unit'] ?? 'N/A'),
                        _buildDetailRow(
                          'Sales Person',
                          data['salesPerson'] ?? 'N/A',
                        ),
                        _buildDetailRow('Status', data['status'] ?? 'N/A'),
                        _buildDetailRow('Priority', data['priority'] ?? 'N/A'),
                        _buildDetailRow(
                          'Dispatch Type',
                          data['dispatchType'] ?? 'N/A',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProductsSection(data),
                    const SizedBox(height: 20),
                    _buildPaymentSection(data),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(Map<String, dynamic> data) {
    final rawProducts = data['products'];
    List products = rawProducts is List
        ? rawProducts
        : (rawProducts is Map ? [rawProducts] : []);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.green.shade50.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${products.length} Items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: products.map((product) {
                final images = product['images'] is List
                    ? product['images'] as List
                    : [];
                final category =
                    product['productCategory'] ?? product['category'] ?? '';
                final gstPct =
                    (product['gstPercent'] ?? _gstPctForCategory(category))
                        .toDouble();
                final qty =
                    (double.tryParse(product['quantity']?.toString() ?? '0') ??
                    0);
                final price =
                    (double.tryParse(product['price']?.toString() ?? '0') ?? 0);
                final subAmt = qty * price;
                final gstAmt = (product['gstAmount'] != null)
                    ? (product['gstAmount'] as num).toDouble()
                    : subAmt * gstPct / 100;
                final totalAmt = subAmt + gstAmt;
                final isMdf = category == 'MDF';
                final isLadduPaper = category == 'Laddu Paper';
                final isHighGst = isMdf || isLadduPaper;
                final hsnCode =
                    product['hsnCode']?.toString().isNotEmpty == true
                    ? product['hsnCode']
                    : _hsnForCategory(category);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade100.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product['productCode'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product['productName'] ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProductDetail(
                              'Category',
                              category,
                              Icons.category_rounded,
                            ),
                          ),
                          Expanded(
                            child: _buildProductDetail(
                              'Quantity',
                              '${product['quantity'] ?? 0}',
                              Icons.numbers_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProductDetail(
                              'Price/Unit',
                              'Rs${product['price'] ?? 0}',
                              Icons.currency_rupee_rounded,
                            ),
                          ),
                          Expanded(
                            child: _buildProductDetail(
                              'Subtotal',
                              'Rs${subAmt.toStringAsFixed(0)}',
                              Icons.calculate_rounded,
                            ),
                          ),
                        ],
                      ),

                      // ── UPDATED: HSN code shown in detail view ────────
                      if (hsnCode != null && hsnCode.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isHighGst
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isHighGst
                                  ? Colors.orange.shade200
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                size: 14,
                                color: isHighGst
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'HSN: $hsnCode',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isHighGst
                                      ? Colors.orange.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isHighGst
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isHighGst
                                ? Colors.orange.shade200
                                : Colors.blue.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.percent_rounded,
                                      size: 14,
                                      color: isHighGst
                                          ? Colors.orange.shade700
                                          : Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'GST @ ${gstPct.toInt()}%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isHighGst
                                            ? Colors.orange.shade700
                                            : Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '+ Rs${gstAmt.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isHighGst
                                        ? Colors.orange.shade700
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Product Total (with GST)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rs${totalAmt.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (product['remarks'] != null &&
                          product['remarks'].toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.note_rounded,
                                size: 18,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  product['remarks'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (images.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.image_rounded,
                                    size: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Product Images (${images.length})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: images
                                    .map(
                                      (imageUrl) => GestureDetector(
                                        onTap: () => _showImagePreview(
                                          imageUrl.toString(),
                                        ),
                                        child: Hero(
                                          tag: imageUrl,
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.blue.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrl.toString(),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: imageUrl,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetail(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(Map<String, dynamic> data) {
    final rawProducts = data['products'];
    List products = rawProducts is List
        ? rawProducts
        : (rawProducts is Map ? [rawProducts] : []);

    double subTotal = 0;
    double totalGst = 0;

    for (var p in products) {
      final category = p['productCategory'] ?? p['category'] ?? '';
      final qty = double.tryParse(p['quantity']?.toString() ?? '0') ?? 0;
      final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0;
      final sub = qty * price;
      subTotal += sub;

      final gstPct = (p['gstPercent'] ?? _gstPctForCategory(category))
          .toDouble();
      final gstAmt = (p['gstAmount'] != null)
          ? (p['gstAmount'] as num).toDouble()
          : sub * gstPct / 100;
      totalGst += gstAmt;
    }

    final delivery = (data['deliveryCharges'] ?? 0).toDouble();
    final advance = (data['advanceAmount'] ?? 0).toDouble();
    final grandTotal =
        (data['grandTotal'] ?? (subTotal + totalGst + delivery - advance))
            .toDouble();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                Icon(Icons.payment_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Payment Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Column(
              children: [
                _buildPaymentRow(
                  'Subtotal (before GST)',
                  'Rs${subTotal.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 4),
                ...products.map((p) {
                  final category = p['productCategory'] ?? p['category'] ?? '';
                  final qty =
                      double.tryParse(p['quantity']?.toString() ?? '0') ?? 0;
                  final price =
                      double.tryParse(p['price']?.toString() ?? '0') ?? 0;
                  final sub = qty * price;
                  final gstPct =
                      (p['gstPercent'] ?? _gstPctForCategory(category))
                          .toDouble();
                  final gstAmt = (p['gstAmount'] != null)
                      ? (p['gstAmount'] as num).toDouble()
                      : sub * gstPct / 100;
                  final code = p['productCode'] ?? '';
                  return _buildPaymentRow(
                    'GST ${gstPct.toInt()}% – $code ($category)',
                    'Rs${gstAmt.toStringAsFixed(0)}',
                    isGst: true,
                  );
                }),
                _buildPaymentRow(
                  'Total GST',
                  'Rs${totalGst.toStringAsFixed(0)}',
                  isBold: true,
                ),
                if (delivery > 0)
                  _buildPaymentRow(
                    'Delivery Charges',
                    'Rs${delivery.toStringAsFixed(0)}',
                  ),
                if (advance > 0)
                  _buildPaymentRow(
                    'Advance Paid',
                    '-Rs${advance.toStringAsFixed(0)}',
                    isNegative: true,
                  ),
                const Divider(thickness: 2, height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'GRAND TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rs${grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                        ),
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

  Widget _buildPaymentRow(
    String label,
    String value, {
    bool isNegative = false,
    bool isBold = false,
    bool isGst = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isGst ? 12 : 14,
                color: isGst ? Colors.grey.shade600 : Colors.grey.shade700,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isGst ? 12 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isNegative
                  ? Colors.red.shade600
                  : (isGst ? Colors.grey.shade700 : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _editOrder(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditOrderScreen(orderId: docId, orderData: data),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PDF GENERATION
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generatePDF(
    Map<String, dynamic> data, {
    required bool withHsn,
    required Map<String, bool> termsOptions,
  }) async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating PDF...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final pdf = pw.Document();
final ByteData qrData = await rootBundle.load(
  'assets/qr.jpeg',
);

final qrImage = pw.MemoryImage(
  qrData.buffer.asUint8List(),
);
      // Logo
      pw.ImageProvider? logoImage;
      try {
        final ByteData logoData = await rootBundle.load('assets/dpl.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Logo not found: $e');
      }

      // Products
      final rawProducts = data['products'];
      List products = rawProducts is List
          ? rawProducts
          : (rawProducts is Map ? [rawProducts] : []);

      final List<Map<String, dynamic>> productsWithImages = [];

      for (var product in products) {
        final images = product['images'] is List ? product['images'] : [];
        final List<pw.MemoryImage> pdfImages = [];
        for (var imgUrl in images) {
          try {
            final response = await http
                .get(Uri.parse(imgUrl))
                .timeout(const Duration(seconds: 5));
            if (response.statusCode == 200)
              pdfImages.add(pw.MemoryImage(response.bodyBytes));
          } catch (_) {}
        }

        final double qty =
            double.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
        final double price =
            double.tryParse(product['price']?.toString() ?? '0') ?? 0;
        final double subAmount = qty * price;
        final String category =
            product['productCategory'] ?? product['category'] ?? '';
        final double gstPct =
            (product['gstPercent'] ?? _gstPctForCategory(category)).toDouble();
        final double gstAmt = (product['gstAmount'] != null)
            ? (product['gstAmount'] as num).toDouble()
            : subAmount * gstPct / 100;
        final double totalAmt = subAmount + gstAmt;

        // ── UPDATED: Use saved hsnCode if present, else derive from category
        final String hsnCode =
            (product['hsnCode']?.toString().isNotEmpty == true)
            ? product['hsnCode'].toString()
            : _hsnForCategory(category);

        productsWithImages.add({
          'productName': product['productName'] ?? 'N/A',
          'productCategory': category,
          'productCode': product['productCode'] ?? '',
          'quantity': qty.toStringAsFixed(0),
          'price': price.toStringAsFixed(2),
          'subAmount': subAmount,
          'gstPercent': gstPct,
          'gstAmount': gstAmt,
          'amount': totalAmt,
          'remarks': product['remarks'] ?? '',
          'pdfImages': pdfImages,
          'hsnCode': hsnCode,
        });
      }

      // Grand totals
      double subTotal = productsWithImages.fold(
        0.0,
        (s, p) => s + (p['subAmount'] as double),
      );
      double totalGst = productsWithImages.fold(
        0.0,
        (s, p) => s + (p['gstAmount'] as double),
      );
      double deliveryCharges =
          double.tryParse(data['deliveryCharges']?.toString() ?? '0') ?? 0;
      double advanceAmount =
          double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0;
      double grandTotal = subTotal + totalGst + deliveryCharges - advanceAmount;

      // Order date
      String orderDateStr = 'N/A';
      if (data['orderDate'] != null && data['orderDate'] is Timestamp) {
        orderDateStr = DateFormat(
          'dd-MM-yyyy',
        ).format((data['orderDate'] as Timestamp).toDate());
      }

      // Terms
      List<String> termsLines = [];
      if (termsOptions['advance50'] == true)
        termsLines.add(
          '50% advance payment is required to commence production',
        );
         if (termsOptions['balancePayment'] == true)
        termsLines.add(
          'Balance payment must be paid before dispatch.',
        );
    
      if (termsOptions['payment'] == true)
        termsLines.add(
          'Goods will be dispatched only after receipt of full payment.',
        );
      if (termsOptions['freight'] == true)
        termsLines.add('Freight charges are extra.');
      if (termsOptions['packing'] == true)
        termsLines.add('Packing charges are extra.');
      if (termsOptions['gst'] == true)
        termsLines.add('GST will be charged as per applicable rates (MDF Products - 18%; Cardboard Boxes - 5%).');
//GSTextra as per invoice — MDF @18% & Cards/Boards @5%.
//GST will be charged extra as per invoice.
      // ── GST groups ────────────────────────────────────────────────────
      final Map<double, Map<String, double>> gstGroups = {};
      for (final p in productsWithImages) {
        final pct = p['gstPercent'] as double;
        final sub = p['subAmount'] as double;
        final gst = p['gstAmount'] as double;
        gstGroups[pct] ??= {'taxable': 0.0, 'gstAmt': 0.0};
        gstGroups[pct]!['taxable'] = gstGroups[pct]!['taxable']! + sub;
        gstGroups[pct]!['gstAmt'] = gstGroups[pct]!['gstAmt']! + gst;
      }
      final sortedPcts = gstGroups.keys.toList()..sort();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
       pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.Image(logoImage),
                    ),
                  pw.SizedBox(width: 15),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DIMPLE PACKAGING PVT. LTD.',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Grand Trunk Rd, Near Navdeep Resorts, Adjoining Sidak Resorts,\n'
                        'West, Bhattian Ludhiana, Punjab - 141008\n'
                        'Contact No.: 9872518000, 7888696774',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'GST No.: 03AADCD5371K1ZP     PAN No.: AADCD5371K',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1),
              pw.Center(
                child: pw.Text(
                  'Estimate Order',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Sales Order: ${data['salesOrderNo'] ?? 'N/A'}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 7),

              // ── Customer + Order info ──────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CUSTOMER INFORMATION',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.Divider(),
                          _pdfInfoRow(
                            'Customer',
                            data['customerName'] ?? 'N/A',
                          ),
                          _pdfInfoRow('Phone', data['phone'] ?? 'N/A'),
                          _pdfInfoRow('Location', data['location'] ?? 'N/A'),
                          _pdfInfoRow(
                            'Sales Person',
                            data['salesPerson'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ORDER DETAILS',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.Divider(),
                          _pdfInfoRow('Order Date', orderDateStr),
                          _pdfInfoRow('Status', data['status'] ?? 'Pending'),
                          _pdfInfoRow(
                            'Dispatch Type',
                            data['dispatchType'] ?? 'N/A',
                          ),
                          _pdfInfoRow('Order Location', data['unit'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // ── Products table ─────────────────────────────────────────
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: withHsn
                    ? {
                        0: const pw.FixedColumnWidth(25),
                        1: const pw.FixedColumnWidth(55),
                        2: const pw.FlexColumnWidth(1.8),
                        3: const pw.FlexColumnWidth(3.5),
                        4: const pw.FixedColumnWidth(38),
                        5: const pw.FixedColumnWidth(45),
                        6: const pw.FixedColumnWidth(55),
                      }
                    : {
                        0: const pw.FixedColumnWidth(25),
                        1: const pw.FlexColumnWidth(1.8),
                        2: const pw.FlexColumnWidth(4.0),
                        3: const pw.FixedColumnWidth(40),
                        4: const pw.FixedColumnWidth(40),
                        5: const pw.FixedColumnWidth(60),
                      },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.teal800,
                    ),
                    children: withHsn
                        ? [
                            _pdfTableHeader('Sr.'),
                            _pdfTableHeader('HSN Code'),
                            _pdfTableHeader('SUMMARY'),
                            _pdfTableHeader('DETAILS'),
                            _pdfTableHeader('QTY'),
                            _pdfTableHeader('RATE'),
                            _pdfTableHeader('AMOUNT'),
                          ]
                        : [
                            _pdfTableHeader('Sr.'),
                            _pdfTableHeader('SUMMARY'),
                            _pdfTableHeader('DETAILS'),
                            _pdfTableHeader('QTY'),
                            _pdfTableHeader('RATE'),
                            _pdfTableHeader('AMOUNT'),
                          ],
                  ),
                  // Product rows
                  ...productsWithImages.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    final List<pw.MemoryImage> imgs =
                        p['pdfImages'] as List<pw.MemoryImage>;

                    final detailsCol = pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          if (imgs.isNotEmpty) buildImageGrid(imgs),
                          if (imgs.isNotEmpty) pw.SizedBox(height: 2),
                          if (p['remarks'].toString().isNotEmpty)
                            pw.Text(
                              p['remarks'],
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.red800,
                              ),
                            ),
                        ],
                      ),
                    );

                    return pw.TableRow(
                      children: withHsn
                          ? [
                              _pdfTableCell('${idx + 1}'),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      p['hsnCode'],
                                      style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                    pw.Text(
                                      'GST ${(p['gstPercent'] as double).toInt()}%',
                                      style: const pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.grey700,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  p['productName'],
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              detailsCol,
                              _pdfTableCell(p['quantity']),
                              _pdfTableCell(p['price']),
                              _pdfTableCell(
                                (p['subAmount'] as double).toStringAsFixed(0),
                              ),
                            ]
                          : [
                              _pdfTableCell('${idx + 1}'),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  p['productName'],
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              detailsCol,
                              _pdfTableCell(p['quantity']),
                              _pdfTableCell(p['price']),
                              _pdfTableCell(
                                (p['subAmount'] as double).toStringAsFixed(0),
                              ),
                            ],
                    );
                  }),
                  // Subtotal row
                  pw.TableRow(
                    children: withHsn
                        ? [
                            _pdfTableCell(''),
                            _pdfTableCell(''),
                            _pdfTableCell(''),
                            _pdfTableCell('SUBTOTAL', isBold: true),
                            _pdfTableCell(''),
                            _pdfTableCell(''),
                            _pdfTableCell(
                              subTotal.toStringAsFixed(0),
                              isBold: true,
                            ),
                          ]
                        : [
                            _pdfTableCell(''),
                            _pdfTableCell(''),
                            _pdfTableCell('SUBTOTAL', isBold: true),
                            _pdfTableCell(''),
                            _pdfTableCell(''),
                            _pdfTableCell(
                              subTotal.toStringAsFixed(0),
                              isBold: true,
                            ),
                          ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // ── GST Breakdown table ────────────────────────────────────
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      color: PdfColors.blueGrey800,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'Tax Rate',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'Taxable Amt.',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'CGST Amt.',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'SGST Amt.',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'Total Tax',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    ...() {
                      double sumTaxable = 0,
                          sumCgst = 0,
                          sumSgst = 0,
                          sumTotal = 0;
                      final List<pw.Widget> rows = [];

                      for (int i = 0; i < sortedPcts.length; i++) {
                        final pct = sortedPcts[i];
                        final taxable = gstGroups[pct]!['taxable']!;
                        final totalGstForGroup = gstGroups[pct]!['gstAmt']!;
                        final cgst = totalGstForGroup / 2;
                        final sgst = totalGstForGroup / 2;

                        sumTaxable += taxable;
                        sumCgst += cgst;
                        sumSgst += sgst;
                        sumTotal += totalGstForGroup;

                        final bg = i % 2 == 0
                            ? PdfColors.white
                            : PdfColors.grey100;

                        rows.add(
                          pw.Container(
                            color: bg,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text(
                                    '${pct.toInt()} %',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.blueGrey800,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    taxable.toStringAsFixed(2),
                                    style: const pw.TextStyle(fontSize: 9),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    cgst.toStringAsFixed(2),
                                    style: const pw.TextStyle(fontSize: 9),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    sgst.toStringAsFixed(2),
                                    style: const pw.TextStyle(fontSize: 9),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    totalGstForGroup.toStringAsFixed(2),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.orange900,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (i == sortedPcts.length - 1) {
                          rows.add(
                            pw.Container(
                              color: PdfColors.grey200,
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: pw.Row(
                                children: [
                                  pw.Expanded(
                                    flex: 2,
                                    child: pw.Text(
                                      'Total',
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 3,
                                    child: pw.Text(
                                      sumTaxable.toStringAsFixed(2),
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 3,
                                    child: pw.Text(
                                      sumCgst.toStringAsFixed(2),
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 3,
                                    child: pw.Text(
                                      sumSgst.toStringAsFixed(2),
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 3,
                                    child: pw.Text(
                                      sumTotal.toStringAsFixed(2),
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.orange900,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                      return rows;
                    }(),

                    if (deliveryCharges > 0)
                      pw.Container(
                        color: PdfColors.white,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 8,
                              child: pw.Text(
                                'Delivery Charges',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Expanded(
                              flex: 6,
                              child: pw.Text(
                                'Rs${deliveryCharges.toStringAsFixed(0)}',
                                style: const pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (advanceAmount > 0)
                      pw.Container(
                        color: PdfColors.white,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 8,
                              child: pw.Text(
                                'Advance Paid',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Expanded(
                              flex: 6,
                              child: pw.Text(
                                '-Rs${advanceAmount.toStringAsFixed(0)}',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.red,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                    pw.Container(
                      color: PdfColors.green100,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 8,
                            child: pw.Text(
                              'GRAND TOTAL',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green900,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 6,
                            child: pw.Text(
                              'Rs${grandTotal.toStringAsFixed(0)}',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green900,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 2),

              pw.Center(
                child: pw.Text(
                  'All Rights Reserved © Dimple Packaging Pvt. Ltd.',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              if (termsLines.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                 // margin: const pw.EdgeInsets.only(top: 1),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey700),
                    borderRadius: pw.BorderRadius.circular(10),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Terms & Conditions',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                        ),
                      ),
                   pw.SizedBox(height: 1),

// ── Bank Details Section ─────────────────────
pw.Container(
  padding: const pw.EdgeInsets.all(6),
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: PdfColors.grey400),
    borderRadius: pw.BorderRadius.circular(8),
  ),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [

      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            pw.Text(
              'Bank Details',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),

            pw.SizedBox(height: 1),

            _pdfInfoRow(
              'Account Title',
              'DIMPLE PACKAGING PRIVATE LIMITED',
            ),

            _pdfInfoRow(
              'Account Number',
              '924030018463563',
            ),

            _pdfInfoRow(
              'IFSC',
              'UTIB0000042',
            ),

            _pdfInfoRow(
              'Bank',
              'Axis Bank Ltd., Mall Road, Ludhiana',
            ),

            _pdfInfoRow(
              'SWIFT',
              'AXISINBB042',
            ),
          ],
        ),
      ),

      pw.SizedBox(width: 10),

      pw.Container(
        width: 90,
        height: 80,
        child: pw.Image(qrImage),
      ),
    ],
  ),
),
                      pw.Text(
                        termsLines.join('\n'),
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                          fontSize: 11,
                          lineSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
            ];
          },
        ),
      );

      if (mounted) Navigator.pop(context);

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: withHsn
            ? 'SalesOrder_${data['salesOrderNo']}_WithHSN.pdf'
            : 'SalesOrder_${data['salesOrderNo']}.pdf',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width:70,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 8 ),
            ),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 8))),
        ],
      ),
    );
  }

  pw.Widget _pdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  pw.Widget _pdfTableCell(
    String text, {
    bool isBold = false,
    double fontSize = 11,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
        maxLines: 3,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// =============================================================================
// EDIT ORDER SCREEN
// =============================================================================
class EditOrderScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  const EditOrderScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });
  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _gstNumberController;

  late DateTime _selectedDate;
  late String _selectedPriority;
  String? _selectedSalesPerson;
  String? _customSalesPerson;
  String? _selectedUnit;
  String? _selectedStatus;
  double _advanceAmount = 0.0;
  double _deliveryCharges = 0.0;
  String? _dispatchType;

  final List<String> _statusOptions = [
    'Pending',
    'Processing',
    'Completed',
    'Cancelled',
  ];
  final List<String> _units = [
    'Unit 1',
    'Unit 2',
    'Meena Bazar',
    'College Road',
  ];

  // ─── UPDATED: Added Laddu Paper ───────────────────────────────────────────
  final List<String> _productCategories = [
    'MDF',
    'Kappa Box (Gora)',
    'Packaging',
    'Shagun Envelopes',
    'Rigid Box (unit 2 Hussainpura)',
    'Laddu Paper',
    'Others',
  ];

  final List<String> _salesPersons = [
    "Abhijit Sinha",
    "Komal Sir",
    "Ajay Talwar",
    "Amarjit Singh",
    "Ashish",
    "Harjap ji",
    "Gunnet Singh",
    "Hardeep Singh",
    "Jagdish Suri",
    "Karan",
    "Krishna Arora",
    "Kuldeep Singh",
    "Neeraj Batta",
    "Prabhu Dayal",
    "Rajiv Markanda",
    "Raju",
    "Sanjeev Jain",
    "Sumeet narula",
    "Sunny Kalra",
    "Others",
  ];
  final List<String> _dispatchOptions = ['Transport', 'Vehicle'];

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  String generateProductCode(int index) {
    String code = '';
    int num = index;
    do {
      code = String.fromCharCode(65 + (num % 26)) + code;
      num = (num ~/ 26) - 1;
    } while (num >= 0);
    return code;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProductsFromOrder();
    _dispatchType = widget.orderData['dispatchType'];
  }

  void _initializeControllers() {
    final data = widget.orderData;
    _customerNameController = TextEditingController(
      text: data['customerName'] ?? '',
    );
    _companyNameController = TextEditingController(
      text: data['companyName'] ?? '',
    );
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _locationController = TextEditingController(text: data['location'] ?? '');
    _notesController = TextEditingController(text: data['notes'] ?? '');
    _gstNumberController = TextEditingController(
      text: data['customerGstNumber'] ?? '',
    );
    _selectedDate =
        (data['deliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    _selectedPriority = data['priority'] ?? 'Medium';
    final savedSales = data['salesPerson'];
    if (_salesPersons.contains(savedSales)) {
      _selectedSalesPerson = savedSales;
    } else {
      _selectedSalesPerson = 'Others';
      _customSalesPerson = savedSales;
    }
    _selectedUnit = data['unit'];
    _selectedStatus = data['status'] ?? 'Pending';
    _advanceAmount = (data['advanceAmount'] ?? 0).toDouble();
    _deliveryCharges = (data['deliveryCharges'] ?? 0).toDouble();
  }

  void _loadProductsFromOrder() {
    final rawProducts = widget.orderData['products'];
    List productsList = rawProducts is List
        ? rawProducts
        : (rawProducts is Map ? [rawProducts] : []);

    _products = productsList.map((p) {
      final category = p['productCategory'] ?? p['category'] ?? 'MDF';
      final savedGst = p['gstPercent'];
      final gstPct = savedGst != null
          ? (savedGst as num).toDouble()
          : _gstPctForCategory(category);
      return {
        'code': p['productCode'] ?? p['code'] ?? 'A',
        'category': category,
        'gstPercent': gstPct,
        // ── UPDATED: Load saved hsnCode ───────────────────────────────
        'hsnCode': p['hsnCode']?.toString() ?? '',
        'name': TextEditingController(
          text: p['productName'] ?? p['name'] ?? '',
        ),
        'quantity': TextEditingController(text: '${p['quantity'] ?? 0}'),
        'price': TextEditingController(text: '${p['price'] ?? 0}'),
        'remarks': TextEditingController(text: p['remarks'] ?? ''),
        'images': <XFile>[],
        'fetchedImages': p['images'] is List
            ? List<String>.from(p['images'])
            : <String>[],
      };
    }).toList();

    if (_products.isEmpty) {
      _products.add({
        'code': 'A',
        'category': 'MDF',
        'gstPercent': 18.0,
        'hsnCode': '',
        'name': TextEditingController(),
        'quantity': TextEditingController(),
        'price': TextEditingController(),
        'remarks': TextEditingController(),
        'images': <XFile>[],
        'fetchedImages': <String>[],
      });
    }
  }

  double _productSubTotal(Map<String, dynamic> item) {
    final qty = double.tryParse(item['quantity']!.text) ?? 0;
    final price = double.tryParse(item['price']!.text) ?? 0;
    return qty * price;
  }

  double _productGstAmt(Map<String, dynamic> item) {
    final gstPct =
        item['gstPercent'] as double? ?? _gstPctForCategory(item['category']);
    return _productSubTotal(item) * gstPct / 100;
  }

  double get _subTotal =>
      _products.fold(0.0, (s, item) => s + _productSubTotal(item));
  double get _totalGst =>
      _products.fold(0.0, (s, item) => s + _productGstAmt(item));
  double get _grossTotal => _subTotal + _totalGst + _deliveryCharges;
  double get _finalTotal =>
      (_grossTotal - _advanceAmount).clamp(0, double.infinity);

  Future<String?> _uploadImageToStorage(
    XFile imageFile,
    String productName,
  ) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'order_products/$productName/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(imageFile.path));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> productList = [];
      for (var item in _products) {
        final List<String> imageUrls = List<String>.from(
          item['fetchedImages'] ?? [],
        );
        for (var img in item['images']) {
          final url = await _uploadImageToStorage(img, item['name']!.text);
          if (url != null) imageUrls.add(url);
        }
        final qty = double.tryParse(item['quantity']!.text) ?? 0;
        final price = double.tryParse(item['price']!.text) ?? 0;
        final gstPct = item['gstPercent'] as double;
        final subAmount = qty * price;
        final gstAmt = subAmount * gstPct / 100;

        // ── UPDATED: Save hsnCode on update ───────────────────────────
        productList.add({
          'productCode': item['code'],
          'productCategory': item['category'],
          'productName': item['name']!.text,
          'hsnCode': item['hsnCode'] ?? '',
          'quantity': qty,
          'price': price,
          'subAmount': subAmount,
          'gstPercent': gstPct,
          'gstAmount': gstAmt,
          'amount': subAmount + gstAmt,
          'remarks': item['remarks']!.text,
          'images': imageUrls,
        });
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'customerName': _customerNameController.text,
            'companyName': _companyNameController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'customerGstNumber': _gstNumberController.text,
            'location': _locationController.text,
            'unit': _selectedUnit,
            'dispatchType': _dispatchType,
            'salesPerson': _selectedSalesPerson == 'Others'
                ? _customSalesPerson
                : _selectedSalesPerson,
            'products': productList,
            'advanceAmount': _advanceAmount,
            'deliveryCharges': _deliveryCharges,
            'subTotal': _subTotal,
            'totalGstAmount': _totalGst,
            'grossTotal': _grossTotal,
            'grandTotal': _finalTotal,
            'deliveryDate': _selectedDate,
            'priority': _selectedPriority,
            'notes': _notesController.text,
            'status': _selectedStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order updated successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addProduct() {
    setState(() {
      _products.add({
        'code': generateProductCode(_products.length),
        'category': 'MDF',
        'gstPercent': 18.0,
        'hsnCode': '',
        'name': TextEditingController(),
        'quantity': TextEditingController(),
        'price': TextEditingController(),
        'remarks': TextEditingController(),
        'images': <XFile>[],
        'fetchedImages': <String>[],
      });
    });
  }

  void _removeProduct(int index) {
    if (_products.length <= 1) return;
    _products[index]['name'].dispose();
    _products[index]['quantity'].dispose();
    _products[index]['price'].dispose();
    _products[index]['remarks'].dispose();
    setState(() {
      _products.removeAt(index);
      for (int i = 0; i < _products.length; i++)
        _products[i]['code'] = generateProductCode(i);
    });
  }

  Future<void> _pickProductImages(int index) async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty)
      setState(() => _products[index]['images'].addAll(files));
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: Text('Edit Order - ${widget.orderData['salesOrderNo']}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Customer Information', Icons.person, [
              _buildTextField(
                _customerNameController,
                'Customer Name',
                Icons.person,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _companyNameController,
                'Company Name',
                Icons.business,
              ),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, 'Phone', Icons.phone),
              const SizedBox(height: 12),
              _buildTextField(_emailController, 'Email', Icons.email),
              const SizedBox(height: 12),
              _buildTextField(
                _locationController,
                'Location',
                Icons.location_on,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _gstNumberController,
                'GST Number',
                Icons.receipt,
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Order Details', Icons.receipt_long, [
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: _units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedUnit = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _salesPersons.contains(_selectedSalesPerson)
                    ? _selectedSalesPerson
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Sales Person',
                  border: OutlineInputBorder(),
                ),
                items: _salesPersons
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSalesPerson = v),
              ),
              const SizedBox(height: 12),
              if (_selectedSalesPerson == 'Others')
                TextFormField(
                  initialValue: _customSalesPerson ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Enter Sales Person Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _customSalesPerson = v,
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['Low', 'Medium', 'High', 'Urgent']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPriority = v!),
              ),
            ]),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _dispatchOptions.contains(_dispatchType)
                  ? _dispatchType
                  : null,
              decoration: InputDecoration(
                labelText: 'Dispatch Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _dispatchOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _dispatchType = val),
            ),
            const SizedBox(height: 16),
            _buildSection('Products', Icons.inventory, [
              ..._products.asMap().entries.map(
                (e) => _buildProductCard(e.key, e.value),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Payment Summary', Icons.payment, [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text(
                          'Rs${_subTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total GST:'),
                        Text(
                          'Rs${_totalGst.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Rs${_finalTotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Update Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ── UPDATED: Product card with Laddu Paper + Others HSN/GST support ────────
  Widget _buildProductCard(int index, Map<String, dynamic> product) {
    final gstPct =
        product['gstPercent'] as double? ??
        _gstPctForCategory(product['category']);
    final category = product['category'] as String? ?? '';
    final isLadduPaper = category == 'Laddu Paper';
    final isOthers = category == 'Others';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Product ${index + 1} (${product['code']})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_products.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeProduct(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: product['category'],
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _productCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() {
                product['category'] = v;
                product['gstPercent'] = _gstPctForCategory(v);
                // Auto-set HSN for known categories
                if (v != 'Others') {
                  product['hsnCode'] = v == 'Laddu Paper' ? '48062000' : '';
                }
              }),
            ),

            // ── Laddu Paper: fixed info banner ─────────────────────────
            if (isLadduPaper) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HSN Code: 48062000',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'GST: 18% — Fixed for Laddu Paper',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // ── Others: custom HSN + GST selector ─────────────────────
            if (isOthers) ...[
              const SizedBox(height: 10),
              TextFormField(
                initialValue: product['hsnCode'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'HSN Code (Optional)',
                  hintText: 'e.g. 48062000',
                  prefixIcon: Icon(Icons.tag_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) =>
                    setState(() => product['hsnCode'] = val.trim()),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select GST Rate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [5.0, 18.0].map((pct) {
                        final isActive = gstPct == pct;
                        final btnColor = pct == 18.0
                            ? Colors.orange.shade600
                            : Colors.blue.shade600;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => product['gstPercent'] = pct),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? LinearGradient(
                                        colors: [
                                          btnColor.withOpacity(0.85),
                                          btnColor,
                                        ],
                                      )
                                    : null,
                                color: isActive ? null : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.transparent
                                      : btnColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${pct.toInt()}%',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : btnColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            _buildTextField(
              product['name'],
              'Product Name',
              Icons.shopping_bag,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    product['quantity'],
                    'Quantity',
                    Icons.numbers,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    product['price'],
                    'Price',
                    Icons.currency_rupee,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(product['remarks'], 'Remarks', Icons.comment),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickProductImages(index),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
            if ((product['fetchedImages'] as List).isNotEmpty ||
                (product['images'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...(product['fetchedImages'] as List<String>).map(
                    (url) => Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showFullScreenImage(url),
                          child: Image.network(
                            url,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => (product['fetchedImages'] as List).remove(
                                url,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...(product['images'] as List<XFile>).map(
                    (file) => Stack(
                      children: [
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            barrierColor: Colors.black,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      child: kIsWeb
                                          ? Image.network(file.path)
                                          : Image.file(File(file.path)),
                                    ),
                                  ),
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          child: kIsWeb
                              ? Image.network(
                                  file.path,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(file.path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => (product['images'] as List).remove(file),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Builder(
                builder: (context) {
                  final qty = double.tryParse(product['quantity']!.text) ?? 0;
                  final price = double.tryParse(product['price']!.text) ?? 0;
                  final sub = qty * price;
                  final gst = sub * gstPct / 100;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sub: Rs${sub.toStringAsFixed(0)} + GST ${gstPct.toInt()}%: Rs${gst.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Total: Rs${(sub + gst).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _gstNumberController.dispose();
    for (var p in _products) {
      p['name']!.dispose();
      p['quantity']!.dispose();
      p['price']!.dispose();
      p['remarks']!.dispose();
    }
    super.dispose();
  }
}

pw.Widget buildImageGrid(List<pw.MemoryImage> images) {
  if (images.isEmpty) return pw.SizedBox();
  const double fixedHeight = 90;
  final int columns = images.length == 1 ? 1 : (images.length == 2 ? 2 : 3);
  return pw.SizedBox(
    height: fixedHeight,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: List.generate(columns, (index) {
        if (index >= images.length) return pw.Expanded(child: pw.SizedBox());
        return pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Image(images[index], fit: pw.BoxFit.contain),
          ),
        );
      }),
    ),
  );
}
