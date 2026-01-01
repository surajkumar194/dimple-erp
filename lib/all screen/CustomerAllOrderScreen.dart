import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sizer/sizer.dart'; // ✅ Add this line

class CustomerAllOrderScreen extends StatefulWidget {
  const CustomerAllOrderScreen({super.key});

  @override
  State<CustomerAllOrderScreen> createState() => _CustomerAllOrderScreenState();
}

class _CustomerAllOrderScreenState extends State<CustomerAllOrderScreen>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  String filterStatus = 'All';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generatePDF(
    BuildContext context,
    Map<String, dynamic> order,
    String orderId,
  ) async {
    final pdf = pw.Document();

    // ✅ Try loading your logo safely
    pw.MemoryImage? logoImage;
    try {
      logoImage = pw.MemoryImage(
        (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
      );
    } catch (e) {
      debugPrint("⚠️ Logo not found: $e");
    }

    // ✅ Load product images from Firebase URLs
    List products = order['products'] ?? [];

    for (var product in products) {
      List<String> urls = List<String>.from(product['images'] ?? []);
      List<pw.MemoryImage> imageList = [];

      for (String url in urls) {
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            imageList.add(pw.MemoryImage(response.bodyBytes));
          }
        } catch (e) {
          debugPrint("⚠️ Failed to load image: $e");
        }
      }
      product['pdfImages'] = imageList;
    }

    DateTime orderDate = (order['orderDate'] as Timestamp).toDate();
    DateTime deliveryDate = (order['deliveryDate'] as Timestamp).toDate();
    String status = order['status'] ?? 'Pending';
    double subtotal = 0;
    for (var product in products) {
      subtotal += (product['amount'] ?? 0);
    }

    // GST calculation (assuming 5% default or you can get from order if stored)
    double gstPercent = 5.0; // You can get this from order if stored
    double gstAmount = subtotal * gstPercent / 100;
    double totalAmount = subtotal + gstAmount;
    // ✅ Build the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ---------------- HEADER ----------------
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
            pw.Center(
              child: pw.Text(
                'SALES ORDER / Proforma Invoice',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // // ---------------- CUSTOMER INFO ----------------
            // pw.Container(
            //   padding: const pw.EdgeInsets.all(15),
            //   decoration: pw.BoxDecoration(
            //     border: pw.Border.all(color: PdfColors.grey400),
            //     borderRadius: pw.BorderRadius.circular(8),
            //   ),
            //   child: pw.Column(
            //     crossAxisAlignment: pw.CrossAxisAlignment.start,
            //     children: [
            //       pw.Text(
            //         'CUSTOMER INFORMATION',
            //         style: pw.TextStyle(
            //           fontSize: 16,
            //           fontWeight: pw.FontWeight.bold,
            //           color: PdfColors.blue700,
            //         ),
            //       ),
            //       pw.Divider(thickness: 1),
            //       _buildPdfRow('Customer Name', order['customerName'] ?? 'N/A'),
            //       if (order['companyName']?.toString().isNotEmpty ?? false)
            //         _buildPdfRow('Company Name', order['companyName']),
            //       _buildPdfRow('Phone', order['phone'] ?? 'N/A'),
            //       if (order['email']?.toString().isNotEmpty ?? false)
            //         _buildPdfRow('Email', order['email']),
            //       _buildPdfRow('Location', order['location'] ?? 'N/A'),
            //       if (order['salesPerson'] != null)
            //         _buildPdfRow('Sales Person', order['salesPerson']),
            //     ],
            //   ),
            // ),

            // pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // LEFT SIDE: CUSTOMER INFORMATION
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CUSTOMER INFORMATION',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.Divider(thickness: 1),
                          _buildPdfRow(
                            'Customer Name',
                            order['customerName'] ?? 'N/A',
                          ),
                          if (order['companyName']?.toString().isNotEmpty ??
                              false)
                            _buildPdfRow('Company Name', order['companyName']),
                          _buildPdfRow('Phone', order['phone'] ?? 'N/A'),
                          if (order['email']?.toString().isNotEmpty ?? false)
                            _buildPdfRow('Email', order['email']),
                          _buildPdfRow('Location', order['location'] ?? 'N/A'),
                          if (order['salesPerson'] != null)
                            _buildPdfRow('Sales Person', order['salesPerson']),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 20), // बीच का gap
                  // RIGHT SIDE: ORDER DETAILS
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ORDER DETAILS',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.Divider(thickness: 1),
                          pw.SizedBox(height: 10),
                          _buildPdfRow(
                            'Order Date',
                            '${orderDate.day}/${orderDate.month}/${orderDate.year}',
                          ),
                          _buildPdfRow(
                            'Dispatch Date',
                            '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}',
                          ),
                          _buildPdfRow('Status', status),
                          _buildPdfRow(
                            'Order Location',
                            order['unit'] ?? 'N/A',
                          ),
                          _buildPdfRow(
                            'Product Category',
                            order['productCategory'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),
            // ---------------- PRODUCTS ----------------
            pw.Text(
              'PRODUCT DETAILS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              columnWidths: {
             0: const pw.FixedColumnWidth(40), // S.No
  1: const pw.FlexColumnWidth(2),  // Product Name
  2: const pw.FlexColumnWidth(1),  // Quantity
  3: const pw.FlexColumnWidth(1),  // Price
  4: const pw.FlexColumnWidth(2),  // Image
  5: const pw.FlexColumnWidth(1), 

              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                  _buildTableCell('S.No', isHeader: true),
    _buildTableCell('Product Name', isHeader: true),
    _buildTableCell('Quantity', isHeader: true),
    _buildTableCell('Price', isHeader: true),
    _buildTableCell('Image', isHeader: true),
    _buildTableCell('Remarks', isHeader: true),
                  ],
                ),

                // Data Rows
                ...products.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final p = entry.value;
                  final imgs = List<pw.MemoryImage>.from(p['pdfImages'] ?? []);

                return pw.TableRow(
  children: [
    _buildTableCell(index.toString()),
    _buildTableCell(p['productName'] ?? 'N/A'),
    _buildTableCell('${p['quantity']}'),
    _buildTableCell('Rs ${p['price']}'),

    // IMAGE COLUMN
    pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: imgs.isNotEmpty
          ? pw.Wrap(
              spacing: 4,
              runSpacing: 4,
              children: imgs.map((img) {
                return pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey400,
                      width: 0.5,
                    ),
                  ),
                  child: pw.Image(img, fit: pw.BoxFit.cover),
                );
              }).toList(),
            )
          : pw.Text('—', textAlign: pw.TextAlign.center),
    ),

    // ✅ REMARKS COLUMN
    _buildTableCell(
      (p['remarks'] != null && p['remarks'].toString().isNotEmpty)
          ? p['remarks']
          : '—',
    ),
  ],
);
                }),
              ],
            ),

            pw.SizedBox(height: 15),

            // ---------------- TOTAL ----------------
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  // Subtotal
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Subtotal:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Rs ${subtotal.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  // GST
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'GST ($gstPercent%):',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Rs ${gstAmount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 1),

                  // Total Amount
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Taxable Amount:',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.Text(
                        'RS ${totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---------------- NOTES ----------------
            if ((order['notes'] ?? '').toString().isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text(
                'Notes:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                  fontSize: 17,
                ),
              ),
              pw.Text(order['notes']),
            ],

            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildPdfRow(String label, String value) {
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

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1976D2),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'All Orders',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search & Filter Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search customer or product...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF1976D2),
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', Icons.list_alt, null),
                        _buildFilterChip('Pending', Icons.pending, Colors.blue),
                        _buildFilterChip(
                          'Processing',
                          Icons.sync,
                          Colors.orange,
                        ),
                        _buildFilterChip(
                          'Completed',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildFilterChip('Cancelled', Icons.cancel, Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Orders List
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Orders will appear here once created',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var orders = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String customerName =
                      data['customerName']?.toString().toLowerCase() ?? '';
                  List products = data['products'] ?? [];
                  String status = data['status']?.toString() ?? 'Pending';

                  bool matchesSearch =
                      customerName.contains(searchQuery) ||
                      products.any(
                        (p) =>
                            p['productName']?.toString().toLowerCase().contains(
                              searchQuery,
                            ) ??
                            false,
                      );

                  bool matchesFilter =
                      filterStatus == 'All' || status == filterStatus;

                  return matchesSearch && matchesFilter;
                }).toList();

                if (orders.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No matching orders',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var order = orders[index].data() as Map<String, dynamic>;
                    String orderId = orders[index].id;
                    return FadeTransition(
                      opacity: _animationController,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Curves.easeOut,
                              ),
                            ),
                        child: _buildOrderCard(context, order, orderId),
                      ),
                    );
                  }, childCount: orders.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color? color) {
    final isSelected = filterStatus == label;
    final chipColor = color ?? const Color(0xFF1976D2);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            filterStatus = label;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? chipColor : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
    String orderId,
  ) {
    String status = order['status'] ?? 'Pending';
    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    DateTime orderDate = (order['orderDate'] as Timestamp).toDate();
    DateTime deliveryDate = (order['deliveryDate'] as Timestamp).toDate();

    List products = order['products'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(context, order, orderId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF1976D2),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['customerName'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          if (order['companyName'] != null &&
                              order['companyName'].toString().isNotEmpty)
                            Text(
                              order['companyName'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
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

                const SizedBox(height: 16),

                // Sales Person
                if (order['salesPerson'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_pin,
                          size: 16,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order['salesPerson'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),

                if (order['unit'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.factory_outlined,
                          size: 14,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order['unit'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                Container(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 16),

                // Products Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2,
                            size: 16,
                            color: Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Products (${products.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...products.take(2).map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1976D2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${p['productName']} (${p['quantity']}x)',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                '₹${(p['amount'] ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (products.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${products.length - 2} more items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.calendar_today,
                        '${orderDate.day}/${orderDate.month}/${orderDate.year}',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.local_shipping,
                        '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Total Amount
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '₹${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // PDF Button in Card
                          InkWell(
                            onTap: () => _generatePDF(context, order, orderId),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.white,
                                size: 20,
                              ),
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

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Processing':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'Processing':
        return Icons.sync;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  void _showOrderDetails(
    BuildContext context,
    Map<String, dynamic> order,
    String orderId,
  ) {
    List products = order['products'] ?? [];
    DateTime orderDate = (order['orderDate'] as Timestamp).toDate();
    DateTime deliveryDate = (order['deliveryDate'] as Timestamp).toDate();
    String status = order['status'] ?? 'Pending';
    Color statusColor = _getStatusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Information
                    _buildSectionTitle('Customer Information', Icons.person),
                    const SizedBox(height: 12),
                    _buildDetailCard([
                      _buildDetailRow2(
                        'Customer',
                        order['customerName'] ?? 'N/A',
                        Icons.person,
                      ),
                      if (order['companyName'] != null &&
                          order['companyName'].toString().isNotEmpty)
                        _buildDetailRow2(
                          'Company',
                          order['companyName'],
                          Icons.business,
                        ),
                      _buildDetailRow2(
                        'Phone',
                        order['phone'] ?? 'N/A',
                        Icons.phone,
                      ),
                      if (order['email'] != null &&
                          order['email'].toString().isNotEmpty)
                        _buildDetailRow2('Email', order['email'], Icons.email),
                      _buildDetailRow2(
                        'Location',
                        order['location'] ?? 'N/A',
                        Icons.location_on,
                      ),
                      if (order['salesPerson'] != null)
                        _buildDetailRow2(
                          'Sales Person',
                          order['salesPerson'],
                          Icons.person_pin,
                        ),

                      _buildDetailRow2(
                        'Order Location',
                        order['unit'] ?? 'N/A',
                        Icons.factory_outlined,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Products
                    _buildSectionTitle('Products', Icons.inventory_2),
                    const SizedBox(height: 12),
                    ...products.map((p) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.shopping_bag,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['productName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${p['quantity']} × ₹${p['price']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${(p['amount'] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    // Order Information
                    _buildSectionTitle('Order Information', Icons.info_outline),
                    const SizedBox(height: 12),
                    _buildDetailCard([
                      _buildDetailRow2(
                        'Order Date',
                        '${orderDate.day}/${orderDate.month}/${orderDate.year}',
                        Icons.calendar_today,
                      ),
                      _buildDetailRow2(
                        'Delivery Date',
                        '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}',
                        Icons.local_shipping,
                      ),
                      _buildDetailRow2(
                        'Priority',
                        order['priority'] ?? 'Medium',
                        Icons.flag,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Total Amount
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Including all items',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (order['notes'] != null &&
                        order['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Notes', Icons.note),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          order['notes'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    if (status != 'Completed' && status != 'Cancelled')
                      Row(
                        children: [
                          if (status == 'Pending')
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateOrderStatus(
                                  context,
                                  orderId,
                                  'Processing',
                                ),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Processing'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          if (status == 'Pending') const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateOrderStatus(
                                context,
                                orderId,
                                'Completed',
                              ),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Mark Complete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (status != 'Cancelled')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _updateOrderStatus(
                              context,
                              orderId,
                              'Cancelled',
                            ),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel Order'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Delete Order Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton.icon(
                    //     onPressed: () =>
                    //         _showDeleteConfirmation(context, orderId),
                    //     icon: const Icon(Icons.delete_forever),
                    //     label: const Text('Delete Order'),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: Colors.red[700],
                    //       side: BorderSide(color: Colors.red[700]!, width: 1.5),
                    //       padding: const EdgeInsets.symmetric(vertical: 14),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1976D2), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow2(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1976D2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(
    BuildContext context,
    String orderId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  status == 'Completed' ? Icons.check_circle : Icons.update,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text('Order status updated to $status'),
              ],
            ),
            backgroundColor: _getStatusColor(status),
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Delete Confirmation Dialog
  void _showDeleteConfirmation(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Order?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this order? This action cannot be undone.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteOrder(context, orderId);
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Delete Order Function
  Future<void> _deleteOrder(BuildContext context, String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .delete();

      if (mounted) {
        Navigator.pop(context); // Close order details sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Order deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error deleting order: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
