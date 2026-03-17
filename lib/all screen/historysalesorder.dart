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
  void _showTermsSelectionDialog(Map<String, dynamic> data) {
    bool payment = true;
    bool freight = true;
    bool packing = true;
    bool gst = true;
    bool advance50 = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
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
                      '50% advance for start working rest payment before delivery',
                    ),
                  ),
                  CheckboxListTile(
                    value: payment,
                    onChanged: (v) => setState(() => payment = v ?? true),
                    title: const Text('All payments within 15 days'),
                  ),
                  CheckboxListTile(
                    value: freight,
                    onChanged: (v) => setState(() => freight = v ?? true),
                    title: const Text('Freight charges extra'),
                  ),
                  CheckboxListTile(
                    value: packing,
                    onChanged: (v) => setState(() => packing = v ?? true),
                    title: const Text('Packing charges extra'),
                  ),
                  CheckboxListTile(
                    value: gst,
                    onChanged: (v) => setState(() => gst = v ?? true),
                    title: const Text('GST extra as per invoice'),
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
                      termsOptions: {
                        'payment': payment,
                        'advance50': advance50,

                        'freight': freight,
                        'packing': packing,
                        'gst': gst,
                      },
                    );
                  },
                  child: const Text('Generate PDF'),
                ),
              ],
            );
          },
        );
      },
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
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
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
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
                    children: _statusOptions.asMap().entries.map((entry) {
                      final status = entry.value;
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
                          onSelected: (selected) {
                            setState(() {
                              _statusFilter = status;
                            });
                          },
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
                // Loading
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading orders',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Empty collection
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade100,
                                Colors.purple.shade100,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inbox_rounded,
                            size: 80,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start creating orders to see them here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter
                final orders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (_statusFilter != 'All' &&
                      data['status'] != _statusFilter) {
                    return false;
                  }

                  if (_searchQuery.isNotEmpty) {
                    final orderNo = (data['salesOrderNo'] ?? '')
                        .toString()
                        .toLowerCase();
                    final customerName = (data['customerName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final companyName = (data['companyName'] ?? '')
                        .toString()
                        .toLowerCase();

                    return orderNo.contains(_searchQuery) ||
                        customerName.contains(_searchQuery) ||
                        companyName.contains(_searchQuery);
                  }

                  return true;
                }).toList();

                // No match after filter
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade100,
                                Colors.red.shade100,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: Colors.orange.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No matching orders',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // List
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

  Widget _buildOrderCard(String docId, Map<String, dynamic> data, int index) {
    final orderNo = data['salesOrderNo'] ?? 'N/A';
    final customerName = data['customerName'] ?? 'N/A';
    final totalAmount = (data['grandTotal'] ?? 0).toDouble();
    final status = data['status'] ?? 'Pending';
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [gradient[0].withOpacity(0.03), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // ── Card Header ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
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
                              offset: const Offset(0, 4),
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

                // ── Card Body ───────────────────────────────────────────
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
                              value: '₹${totalAmount.toStringAsFixed(0)}',
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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

  // -----------------------------------------------------------------------
  // ACTION BUTTON
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // DOWNLOAD OPTIONS BOTTOM SHEET
  // -----------------------------------------------------------------------
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
            // PDF option
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
                'Download as PDF',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: const Text('Professional PDF with images'),
              onTap: () {
                Navigator.pop(ctx);
                _showTermsSelectionDialog(data);
              },
            ),
            // const SizedBox(height: 8),
            // // JPG option
            // ListTile(
            //   leading: Container(
            //     padding: const EdgeInsets.all(12),
            //     decoration: BoxDecoration(
            //       gradient: LinearGradient(
            //         colors: [Colors.green.shade400, Colors.green.shade700],
            //       ),
            //       borderRadius: BorderRadius.circular(14),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.green.shade200,
            //           blurRadius: 8,
            //           offset: const Offset(0, 4),
            //         ),
            //       ],
            //     ),
            //     child: const Icon(
            //       Icons.image_rounded,
            //       color: Colors.white,
            //       size: 26,
            //     ),
            //   ),
            //   title: const Text(
            //     'Download as JPG',
            //     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            //   ),
            //   subtitle: const Text('High-quality image file'),
            //   onTap: () async {
            //     Navigator.pop(ctx);
            //     await _generateJPG(data);
            //   },
            // ),
            // const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // ORDER DETAILS BOTTOM SHEET
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // DETAIL SECTION (Customer / Order info cards)
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // PRODUCTS SECTION
  // -----------------------------------------------------------------------
  Widget _buildProductsSection(Map<String, dynamic> data) {
List products = [];

final rawProducts = data['products'];

if (rawProducts is List) {
  products = rawProducts;
} else if (rawProducts is Map) {
  products = [rawProducts];
}
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
          // Header
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
          // Product list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: products.map((product) {
final images = product['images'] is List ? product['images'] : [];
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
                      // Code + Name row
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
                      // Category + Quantity
                      Row(
                        children: [
                          Expanded(
                            child: _buildProductDetail(
                              'Category',
                              product['productCategory'] ?? 'N/A',
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
                      // Price + Amount
                      Row(
                        children: [
                          Expanded(
                            child: _buildProductDetail(
                              'Price/Unit',
                              '₹${product['price'] ?? 0}',
                              Icons.currency_rupee_rounded,
                            ),
                          ),
                          Expanded(
                            child: _buildProductDetail(
                              'Amount',
                              '₹${(product['amount'] ?? 0).toStringAsFixed()}',
                              Icons.account_balance_wallet_rounded,
                            ),
                          ),
                        ],
                      ),
                      // Remarks
                      if (product['remarks'] != null &&
                          product['remarks'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Images
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
                                children: images.map((imageUrl) {
                                  return GestureDetector(
                                    onTap: () => _showImagePreview(imageUrl),
                                    child: Hero(
                                      tag: imageUrl,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade300,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.shade200,
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                  strokeWidth: 2,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                  );
                                                },
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

  // -----------------------------------------------------------------------
  // IMAGE PREVIEW DIALOG
  // -----------------------------------------------------------------------
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          padding: const EdgeInsets.all(50),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          ),
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
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // PRODUCT DETAIL ROW (inside product card)
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // PAYMENT SECTION
  // -----------------------------------------------------------------------
  Widget _buildPaymentSection(Map<String, dynamic> data) {
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
                  'Subtotal',
                  '₹${(data['totalAmount'] ?? 0).toStringAsFixed(0)}',
                ),
                _buildPaymentRow(
                  'GST (${data['gstPercent'] ?? 0}%)',
                  '₹${(data['gstAmount'] ?? 0).toStringAsFixed(0)}',
                ),
                if ((data['deliveryCharges'] ?? 0) > 0)
                  _buildPaymentRow(
                    'Delivery Charges',
                    '₹${(data['deliveryCharges'] ?? 0).toStringAsFixed(0)}',
                  ),
                if ((data['advanceAmount'] ?? 0) > 0)
                  _buildPaymentRow(
                    'Advance Paid',
                    '-₹${(data['advanceAmount'] ?? 0).toStringAsFixed(0)}',
                    isNegative: true,
                  ),
                const Divider(thickness: 2, height: 24),
                // Grand total badge
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
                        '₹${(data['grandTotal'] ?? 0).toStringAsFixed(0)}',
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red.shade600 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // DETAIL ROW (label : value)
  // -----------------------------------------------------------------------
  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
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
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // NAVIGATE → EditOrderScreen
  // -----------------------------------------------------------------------
  void _editOrder(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditOrderScreen(orderId: docId, orderData: data),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // PDF GENERATION
  // -----------------------------------------------------------------------
  Future<void> _generatePDF(
    Map<String, dynamic> data, {
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

      // Load logo
      pw.ImageProvider? logoImage;
      try {
        final ByteData logoData = await rootBundle.load('assets/dpl.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Logo not found: $e');
      }

      // Download ALL product images with timeout
List products = [];

final rawProducts = data['products'];

if (rawProducts is List) {
  products = rawProducts;
} else if (rawProducts is Map) {
  products = [rawProducts];
}
      final List<Map<String, dynamic>> productsWithImages = [];

      for (var product in products) {
final images = product['images'] is List ? product['images'] : [];
        final List<pw.MemoryImage> pdfImages = [];

        for (var imgUrl in images) {
          try {
            final response = await http
                .get(Uri.parse(imgUrl))
                .timeout(const Duration(seconds: 3));
            if (response.statusCode == 200) {
              pdfImages.add(pw.MemoryImage(response.bodyBytes));
            }
          } catch (_) {
            // skip
          }
        }

        final double qty =
            double.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

        final double rate =
            double.tryParse(product['price']?.toString() ?? '0') ?? 0;
        final double amount = qty * rate;

        productsWithImages.add({
          'productName': product['productName'] ?? 'N/A',
          'productCategory': product['productCategory'] ?? '',
          'quantity': qty.toStringAsFixed(0),
          'price': rate.toStringAsFixed(2),
          'amount': amount.toStringAsFixed(0),
          'remarks': product['remarks'] ?? '',
          'pdfImages': pdfImages,
        });
      }

      // Pre-calc totals
      double subTotal = 0;
      for (var p in productsWithImages) {
        subTotal += double.parse(p['amount']);
      }
      final double gstPercent =
          double.tryParse(data['gstPercent']?.toString() ?? '0') ?? 0;
      final double gstAmount = subTotal * (gstPercent / 100);
      final double deliveryCharges =
          double.tryParse(data['deliveryCharges']?.toString() ?? '0') ?? 0;
      final double advanceAmount =
          double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0;
      final double grandTotal =
          subTotal + gstAmount + deliveryCharges - advanceAmount;

      // Date helpers
      String orderDateStr = 'N/A';
      if (data['orderDate'] != null && data['orderDate'] is Timestamp) {
        orderDateStr = DateFormat(
          'dd-MM-yyyy',
        ).format((data['orderDate'] as Timestamp).toDate());
      }
      String dispatchDateStr = 'N/A';
      if (data['deliveryDate'] != null && data['deliveryDate'] is Timestamp) {
        dispatchDateStr = DateFormat(
          'dd-MM-yyyy',
        ).format((data['deliveryDate'] as Timestamp).toDate());
      }
      List<String> termsLines = [];
      if (termsOptions['advance50'] == true) {
        termsLines.add(
          '50% advance for start working, rest payment before delivery.',
        );
      }

      if (termsOptions['payment'] == true) {
        termsLines.add(
          'All payments will be cleared within 15 days of delivery.',
        );
      }
      if (termsOptions['freight'] == true) {
        termsLines.add('Freight charges will be extra.');
      }
      if (termsOptions['packing'] == true) {
        termsLines.add('Packing charges will be extra.');
      }
      if (termsOptions['gst'] == true) {
        termsLines.add('GST will be charged extra as per invoice.');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // ── Logo + Company Header (no outer border box) ──────────
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
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Grand Trunk Rd, near Navdeep Resorts, adjoining Sidak Resorts,\n'
                        'West, Bhattian Ludhiana, Punjab - 141008\nContact No.: 9872518000, 7888696774',
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
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),

              // ── Centered "SALES ORDER" title ──────────────────────────
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
              pw.SizedBox(height: 6),
              pw.Text(
                'Sales Order: ${data['salesOrderNo'] ?? 'N/A'}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // ── Single bordered container — Customer + Order side by side ──
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Customer column
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
                    // Order details column
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
                          //  _pdfInfoRow('Dispatch Date', dispatchDateStr),
                          _pdfInfoRow('Status', data['status'] ?? 'Pending'),
                          _pdfInfoRow('Order Location', data['unit'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // ── Products Table ────────────────────────────────────────
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),
                  1: const pw.FlexColumnWidth(1.8),
                  2: const pw.FlexColumnWidth(4.0),
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FixedColumnWidth(40),
                  5: const pw.FixedColumnWidth(60),
                },
                children: [
                  // Header row — teal800
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.teal800,
                    ),
                    children: [
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
                    final product = entry.value;
                    final List<pw.MemoryImage> imgs =
                        product['pdfImages'] as List<pw.MemoryImage>;

                    return pw.TableRow(
                      children: [
                        // Sr.
                        _pdfTableCell('${idx + 1}'),
                        // SUMMARY — product name only
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            product['productName'],
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        // DETAILS — images grid + remarks in red
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              if (imgs.isNotEmpty) buildImageGrid(imgs),
                              if (imgs.isNotEmpty) pw.SizedBox(height: 2),
                              if (product['remarks'].toString().isNotEmpty)
                                pw.Text(
                                  product['remarks'],
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.red800,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // QTY
                        _pdfTableCell(product['quantity']),
                        // RATE
                        _pdfTableCell(product['price']),
                        // AMOUNT
                        _pdfTableCell(product['amount']),
                      ],
                    );
                  }),
                  // SUB TOTAL
                  pw.TableRow(
                    children: [
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      _pdfTableCell('SUB TOTAL', isBold: true),
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          subTotal.toStringAsFixed(0),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  // GST
                  pw.TableRow(
                    children: [
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      _pdfTableCell(
                        'GST @ ${gstPercent.toStringAsFixed(0)}%',
                        isBold: true,
                      ),
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          gstAmount.toStringAsFixed(0),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  // Delivery (conditional)
                  if (deliveryCharges > 0)
                    pw.TableRow(
                      children: [
                        _pdfTableCell(''),
                        _pdfTableCell(''),
                        _pdfTableCell('DELIVERY', isBold: true),
                        _pdfTableCell(''),
                        _pdfTableCell(''),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            deliveryCharges.toStringAsFixed(0),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  // Advance (conditional)
                  if (advanceAmount > 0)
                    pw.TableRow(
                      children: [
                        _pdfTableCell(''),
                        _pdfTableCell(''),
                        _pdfTableCell('ADVANCE', isBold: true),
                        _pdfTableCell(''),
                        _pdfTableCell(''),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '-${advanceAmount.toStringAsFixed(0)}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  // GRAND TOTAL — grey300 bg
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      _pdfTableCell('GRAND TOTAL', isBold: true, fontSize: 12),
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          grandTotal.toStringAsFixed(0),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 1),
              pw.Divider(thickness: 1, color: PdfColors.black),

              // ── Footer text (yellow700, centered) ─────────────────────
              pw.Center(
                child: pw.Text(
                  'All Rights Reserved © Dimple Packaging Pvt. Ltd.',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.yellow700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              if (termsLines.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  margin: const pw.EdgeInsets.only(top: 12),
                  padding: const pw.EdgeInsets.all(14),
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
                      pw.SizedBox(height: 6),
                      pw.Text(
                        termsLines.join('\n'),
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
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
        onLayout: (format) async => pdf.save(),
        name: 'SalesOrder_${data['salesOrderNo']}.pdf',
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

  // -----------------------------------------------------------------------
  // JPG GENERATION (shares PDF as fallback via share sheet)
  // -----------------------------------------------------------------------
  Future<void> _generateJPG(Map<String, dynamic> data) async {
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
                    Text('Generating JPG...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final pdf = pw.Document();

      pw.ImageProvider? logoImage;
      try {
        final ByteData logoData = await rootBundle.load('assets/dpl.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Logo not found: $e');
      }

      // Download ALL product images with timeout
List products = [];

final rawProducts = data['products'];

if (rawProducts is List) {
  products = rawProducts;
} else if (rawProducts is Map) {
  products = [rawProducts];
}
      final List<Map<String, dynamic>> productsWithImages = [];

      for (var product in products) {
final images = product['images'] is List ? product['images'] : [];
        final List<pw.MemoryImage> pdfImages = [];

        for (var imgUrl in images) {
          try {
            final response = await http
                .get(Uri.parse(imgUrl))
                .timeout(const Duration(seconds: 3));
            if (response.statusCode == 200) {
              pdfImages.add(pw.MemoryImage(response.bodyBytes));
            }
          } catch (_) {
            // skip
          }
        }

        final double qty =
            double.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

        final double rate =
            double.tryParse(product['price']?.toString() ?? '0') ?? 0;
        final double amount = qty * rate;

        productsWithImages.add({
          'productName': product['productName'] ?? 'N/A',
          'productCategory': product['productCategory'] ?? '',
          'quantity': qty.toStringAsFixed(0),
          'price': rate.toStringAsFixed(2),
          'amount': amount.toStringAsFixed(0),
          'remarks': product['remarks'] ?? '',
          'pdfImages': pdfImages,
        });
      }

      // Pre-calc totals
      double subTotal = 0;
      for (var p in productsWithImages) {
        subTotal += double.parse(p['amount']);
      }
      final double gstPercent =
          double.tryParse(data['gstPercent']?.toString() ?? '0') ?? 0;
      final double gstAmount = subTotal * (gstPercent / 100);
      final double deliveryCharges =
          double.tryParse(data['deliveryCharges']?.toString() ?? '0') ?? 0;
      final double advanceAmount =
          double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0;
      final double grandTotal =
          subTotal + gstAmount + deliveryCharges - advanceAmount;

      // Date helpers
      String orderDateStr = 'N/A';
      if (data['orderDate'] != null && data['orderDate'] is Timestamp) {
        orderDateStr = DateFormat(
          'dd-MM-yyyy',
        ).format((data['orderDate'] as Timestamp).toDate());
      }
      String dispatchDateStr = 'N/A';
      if (data['deliveryDate'] != null && data['deliveryDate'] is Timestamp) {
        dispatchDateStr = DateFormat(
          'dd-MM-yyyy',
        ).format((data['deliveryDate'] as Timestamp).toDate());
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // ── Logo + Company Header ─────────────────────────────────
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
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Grand Trunk Rd, near Navdeep Resorts, adjoining Sidak Resorts,\n'
                        'West, Bhattian Ludhiana, Punjab - 141008\nContact No.: 9872518000, 7888696774',
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
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),

              // ── Centered title ────────────────────────────────────────
              pw.Center(
                child: pw.Text(
                  'SALES ORDER',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Sales Order: ${data['salesOrderNo'] ?? 'N/A'}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // ── Single bordered info container ─────────────────────────
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
                          _pdfInfoRow('Dispatch Date', dispatchDateStr),
                          _pdfInfoRow('Status', data['status'] ?? 'Pending'),
                          _pdfInfoRow('Order Location', data['unit'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // ── Products Table ──────────────────────────────────────────
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),
                  1: const pw.FlexColumnWidth(1.8),
                  2: const pw.FlexColumnWidth(4.0),
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FixedColumnWidth(40),
                  5: const pw.FixedColumnWidth(60),
                },
                children: [
                  // Header — teal800
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.teal800,
                    ),
                    children: [
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
                    final product = entry.value;
                    final List<pw.MemoryImage> imgs =
                        product['pdfImages'] as List<pw.MemoryImage>;

                    return pw.TableRow(
                      children: [
                        _pdfTableCell('${idx + 1}'),
                        // SUMMARY
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            product['productName'],
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        // DETAILS — images + remarks
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (imgs.isNotEmpty) buildImageGrid(imgs),
                              if (imgs.isNotEmpty) pw.SizedBox(height: 6),
                              if (product['remarks'].toString().isNotEmpty)
                                pw.Text(
                                  product['remarks'],
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.red800,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _pdfTableCell(product['quantity']),
                        _pdfTableCell(product['price']),
                        _pdfTableCell(product['amount']),
                      ],
                    );
                  }),
                  // SUB TOTAL
                  pw.TableRow(
                    children: [
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      _pdfTableCell('SUB TOTAL', isBold: true),
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          subTotal.toStringAsFixed(0),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  // GST
                  pw.TableRow(
                    children: [
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      _pdfTableCell(
                        'GST @ ${gstPercent.toStringAsFixed(0)}%',
                        isBold: true,
                      ),
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          gstAmount.toStringAsFixed(0),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  // Delivery
                  if (deliveryCharges > 0)
                    pw.TableRow(
                      children: [
                        _pdfTableCell(''),
                        _pdfTableCell(''),
                        _pdfTableCell('DELIVERY', isBold: true),
                        _pdfTableCell(''),
                        _pdfTableCell(''),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            deliveryCharges.toStringAsFixed(0),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  // Advance
                  if (advanceAmount > 0)
                    pw.TableRow(
                      children: [
                        _pdfTableCell(''),
                        _pdfTableCell(''),
                        _pdfTableCell('ADVANCE', isBold: true),
                        _pdfTableCell(''),
                        _pdfTableCell(''),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '-${advanceAmount.toStringAsFixed(0)}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  // GRAND TOTAL
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      _pdfTableCell('GRAND TOTAL', isBold: true, fontSize: 12),
                      _pdfTableCell(''),
                      _pdfTableCell(''),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          grandTotal.toStringAsFixed(0),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 1),
              pw.Divider(thickness: 1, color: PdfColors.black),

              // ── Footer ────────────────────────────────────────────────
              pw.Center(
                child: pw.Text(
                  'All Rights Reserved © Dimple Packaging Pvt. Ltd.\n'
                  'G.S.T., Packing & Freight Will Be Extra',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.yellow700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ];
          },
        ),
      );

      final pdfData = await pdf.save();

      if (mounted) Navigator.pop(context);

      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'SalesOrder_${data['salesOrderNo']}.pdf',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating JPG: $e')));
      }
    }
  }

  // -----------------------------------------------------------------------
  // PDF HELPER WIDGETS
  // -----------------------------------------------------------------------
  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
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
    bool center = true,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: 3,
      ),
    );
  }

  // -----------------------------------------------------------------------
  // DISPOSE
  // -----------------------------------------------------------------------
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ==========================================================================
// EDIT ORDER SCREEN
// ==========================================================================
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

  double _gstPercent = 5.0;
  final List<double> _gstOptions = [5.0, 12.0, 18.0];
  late DateTime _selectedDate;
  late String _selectedPriority;
  String? _selectedSalesPerson;
  String? _customSalesPerson;
  String? _selectedUnit;
  String? _selectedStatus;
  double _advanceAmount = 0.0;
  double _deliveryCharges = 0.0;

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
  final List<String> _productCategories = ['MDF', 'Kappa Box', 'Packaging', 'Rigid Box (unit 2)', 'Others'];
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
  // -----------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProductsFromOrder();
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

    _gstPercent = (data['gstPercent'] ?? 5.0).toDouble();
    _selectedDate =
        (data['deliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    _selectedPriority = data['priority'] ?? 'Medium';
final savedSales = data['salesPerson'];

if (_salesPersons.contains(savedSales)) {
  _selectedSalesPerson = savedSales;
} else {
  _selectedSalesPerson = 'Others';
  _customSalesPerson = savedSales;
}    _selectedUnit = data['unit'];
    _selectedStatus = data['status'] ?? 'Pending';
    _advanceAmount = (data['advanceAmount'] ?? 0).toDouble();
    _deliveryCharges = (data['deliveryCharges'] ?? 0).toDouble();
  }

void _loadProductsFromOrder() {
  final rawProducts = widget.orderData['products'];

  List productsList = [];

  if (rawProducts is List) {
    productsList = rawProducts;
  } else if (rawProducts is Map) {
    productsList = [rawProducts];
  }

  _products = productsList.map((p) {
    return {
      'code': p['productCode'] ?? p['code'] ?? 'A',
      'category': p['productCategory'] ?? p['category'] ?? 'MDF',

      'name': TextEditingController(
        text: p['productName'] ?? p['name'] ?? '',
      ),

      'quantity': TextEditingController(
        text: '${p['quantity'] ?? p['qty'] ?? 0}',
      ),

      'price': TextEditingController(
        text: '${p['price'] ?? p['rate'] ?? 0}',
      ),

      'remarks': TextEditingController(
        text: p['remarks'] ?? '',
      ),

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
      'name': TextEditingController(),
      'quantity': TextEditingController(),
      'price': TextEditingController(),
      'remarks': TextEditingController(),
      'images': <XFile>[],
      'fetchedImages': <String>[],
    });
  }
}



  // ── Computed totals ──────────────────────────────────────────────────
  double get _subTotal {
    double total = 0;
    for (var item in _products) {
      final qty = double.tryParse(item['quantity']!.text) ?? 0;
      final price = double.tryParse(item['price']!.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  double get _gstAmount => _subTotal * _gstPercent / 100;
  double get _grossTotal => _subTotal + _gstAmount + _deliveryCharges;
  double get _finalTotal =>
      (_grossTotal - _advanceAmount).clamp(0, double.infinity);

  // -----------------------------------------------------------------------
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
      debugPrint("❌ Image upload failed: $e");
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

        final double qty = double.tryParse(item['quantity']!.text) ?? 0;

        final double price = double.tryParse(item['price']!.text) ?? 0;

        final double amount = qty * price;

        productList.add({
          'productCode': item['code'],
          'productCategory': item['category'],
          'productName': item['name']!.text,
          'quantity': qty,
          'price': price,
          'amount': amount,
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
            'salesPerson': _selectedSalesPerson == 'Others'
                ? _customSalesPerson
                : _selectedSalesPerson,
            'products': productList,
            'advanceAmount': _advanceAmount,
            'deliveryCharges': _deliveryCharges,
            'taxableAmount': _subTotal,
            'totalAmount': _subTotal,
            'gstAmount': _gstAmount,
            'grandTotal': _finalTotal,
            'gstPercent': _gstPercent,
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
    final code = generateProductCode(_products.length);

    _products.add({
      'code': code,
      'category': 'MDF',
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

    // reindex codes
    for (int i = 0; i < _products.length; i++) {
      _products[i]['code'] = generateProductCode(i);
    }
  });
}
  Future<void> _pickProductImages(int index) async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) {
      setState(() {
        _products[index]['images'].addAll(files);
      });
    }
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
            // ── Customer Info ───────────────────────────────────────────
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

            // ── Order Details ───────────────────────────────────────────
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

            // ── Products ────────────────────────────────────────────────
            _buildSection('Products', Icons.inventory, [
              ..._products.asMap().entries.map((entry) {
                return _buildProductCard(entry.key, entry.value);
              }),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Payment ─────────────────────────────────────────────────
            _buildSection('Payment Details', Icons.payment, [
              Row(
                children: [
                  const Text('GST: '),
                  DropdownButton<double>(
                    value: _gstPercent,
                    items: _gstOptions
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text('${g.toInt()}%'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _gstPercent = v!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _deliveryCharges.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) =>
                    setState(() => _deliveryCharges = double.tryParse(v) ?? 0),
                decoration: const InputDecoration(
                  labelText: 'Delivery Charges',
                  prefixIcon: Icon(Icons.local_shipping),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _advanceAmount.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) =>
                    setState(() => _advanceAmount = double.tryParse(v) ?? 0),
                decoration: const InputDecoration(
                  labelText: 'Advance Amount',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Summary box
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
                          '₹${_subTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GST (${_gstPercent.toInt()}%):'),
                        Text('₹${_gstAmount.toStringAsFixed(0)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery:'),
                        Text('₹${_deliveryCharges.toStringAsFixed(0)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Advance:'),
                        Text('-₹${_advanceAmount.toStringAsFixed(0)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '₹${_finalTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // ── Submit button ───────────────────────────────────────────
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

  // -----------------------------------------------------------------------
  // SECTION WRAPPER
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // TEXT FIELD HELPER
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // PRODUCT CARD
  // -----------------------------------------------------------------------
  Widget _buildProductCard(int index, Map<String, dynamic> product) {
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
              onChanged: (v) => setState(() => product['category'] = v),
            ),
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
            // Image previews
            if ((product['fetchedImages'] as List).isNotEmpty ||
                (product['images'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Already-uploaded images
                  ...(product['fetchedImages'] as List<String>).map((url) {
                    return Stack(
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
                            onPressed: () {
                              setState(() {
                                (product['fetchedImages'] as List).remove(url);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                  // Newly picked images
                  ...(product['images'] as List<XFile>).map((file) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black,
                              builder: (ctx) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: InteractiveViewer(
                                        minScale: 0.5,
                                        maxScale: 4.0,
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
                            );
                          },
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
                            onPressed: () {
                              setState(() {
                                (product['images'] as List).remove(file);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Line total
            Align(
              alignment: Alignment.centerRight,
              child: Builder(
                builder: (context) {
                  final qty = double.tryParse(product['quantity']!.text) ?? 0;
                  final price = double.tryParse(product['price']!.text) ?? 0;
                  final total = qty * price;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: ₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  // -----------------------------------------------------------------------
  // DISPOSE
  // -----------------------------------------------------------------------
  @override
  void dispose() {
    _customerNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _gstNumberController.dispose();
    for (var product in _products) {
      product['name']!.dispose();
      product['quantity']!.dispose();
      product['price']!.dispose();
      product['remarks']!.dispose();
    }
    super.dispose();
  }
}

// ==========================================================================
// TOP-LEVEL PDF HELPER — IMAGE GRID (matches JobCardHistoryTab exactly)
// ==========================================================================
pw.Widget buildImageGrid(List<pw.MemoryImage> images) {
  if (images.isEmpty) return pw.SizedBox();

  const double fixedHeight = 90;

  int columns;
  if (images.length == 1) {
    columns = 1;
  } else if (images.length == 2) {
    columns = 2;
  } else {
    columns = 3;
  }

  return pw.SizedBox(
    height: fixedHeight,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: List.generate(columns, (index) {
        if (index >= images.length) {
          return pw.Expanded(child: pw.SizedBox());
        }

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
