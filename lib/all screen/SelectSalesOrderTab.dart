import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/all%20screen/EditSalesOrderScreen.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

class SelectSalesOrderTab extends StatefulWidget {
  const SelectSalesOrderTab({super.key});
  @override
  State<SelectSalesOrderTab> createState() => _SelectSalesOrderTabState();
}

class _SelectSalesOrderTabState extends State<SelectSalesOrderTab> {
  String searchQuery = '';
  bool _isLoading = false;

  Future<bool> _checkIfJobCardExists(String orderId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('jobCards')
        .where('linkedOrderId', isEqualTo: orderId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Helper method to load network images for PDF
  Future<pw.ImageProvider?> _loadNetworkImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Error loading image: $e');
    }
    return null;
  }

  Future<String?> _getJobNoFromOrder(String orderId) async {
    final snap = await FirebaseFirestore.instance
        .collection('jobCards')
        .where('linkedOrderId', isEqualTo: orderId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return snap.docs.first.data()['jobNo'];
    }
    return null;
  }


  Future<void> _generateAllProductsPDF(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    final pdf = pw.Document();
    final jobNo = await _getJobNoFromOrder(orderId) ?? 'N/A'; // ✅ ADD THIS
    final notes = orderData['notes'] ?? '';
    final pageWidth = PdfPageFormat.a4.availableWidth;

    // Auto decide columns
    int columns = pageWidth > 400 ? 3 : 2;

    final imageSize = (pageWidth - ((columns - 1) * 10)) / columns;
    final products = orderData['products'] as List? ?? [];
    final orderDate =
        (orderData['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final deliveryDate =
        (orderData['deliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final customerName = orderData['customerName'] ?? '';
    final companyName = orderData['companyName'] ?? '';

    final salesPerson = orderData['salesPerson'] ?? '';

    for (int i = 0; i < products.length; i++) {
      final product = products[i];

      final dplNo = product['dplNo'] ?? '$jobNo-${i + 1}'; // ✅ CORRECT PLACE

      final sections = product['sections'] as Map<String, dynamic>? ?? {};
        final extraSections = product['customExtraSections'] as List? ?? [];

     final trayDetail = sections['trayDetail'] ?? sections['tray'] ?? '';
final salophinDetail = sections['salophinDetail'] ?? sections['salophin'] ?? '';
final boxCoverDetail = sections['boxCoverDetail'] ?? sections['boxCover'] ?? '';
final innerDetail = sections['innerDetail'] ?? sections['inner'] ?? '';
final bottomDetail = sections['bottomDetail'] ?? sections['bottom'] ?? '';
final dieDetail = sections['dieDetail'] ?? sections['die'] ?? '';

      final images = product['images'] as List? ?? [];

      // Load all images first
      List<pw.ImageProvider> loadedImages = [];
      for (final url in images) {
        if (url is String && url.isNotEmpty) {
          final img = await _loadNetworkImage(url);
          if (img != null) loadedImages.add(img);
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginTop: 1,
            marginBottom: 5,
            marginLeft: 1,
            marginRight: 1,
          ),
          build: (context) {
            return pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: <pw.Widget>[
                  pw.Text(
                    'All Rights Reserved Dimple Packaging Pvt. Ltd.',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.green),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Job No: $jobNo',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'DPL: $dplNo', // 🔥 CLEAR IDENTIFICATION
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            "Order Location: ${orderData['unit'] ?? 'N/A'}",
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'DATE - ${DateFormat('dd-MM-yyyy').format(orderDate)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey300,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'DATE OF SUPPLY',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  DateFormat('dd-MM-yyyy').format(deliveryDate),
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),

                  // Customer Name Header
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        companyName.toString().trim().isNotEmpty
                            ? '$customerName ($companyName)'
                            : customerName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 1),

                  // Product Details Table
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey600),
                    children: [
                      _buildPdfRow('Product', product['productName'] ?? ''),
                      _buildPdfRow(
                        'Category',
                        product['productCategory'] ?? '',
                      ),
                      _buildPdfRow(
                        'Dimensions (L×H×W)',
                        '${product['length'] ?? ''} × ${product['height'] ?? ''} × ${product['width'] ?? ''}',
                      ),
                      _buildPdfRow(
                        'Qnty / Remark',
                        '${product['quantity'] ?? ''}  |  ${product['remarks'] ?? ''}',
                      ),
                      _buildPdfRow('Assign Person', ''),
                       if (trayDetail.toString().trim().isNotEmpty)
      _buildPdfRow('Tray', trayDetail),

    if (salophinDetail.toString().trim().isNotEmpty)
      _buildPdfRow('Salophin', salophinDetail),

    if (boxCoverDetail.toString().trim().isNotEmpty)
      _buildPdfRow('Box Cover', boxCoverDetail),

    if (innerDetail.toString().trim().isNotEmpty)
      _buildPdfRow('Inner', innerDetail),

    if (bottomDetail.toString().trim().isNotEmpty)
      _buildPdfRow('Bottom', bottomDetail),

    if (dieDetail.toString().trim().isNotEmpty)
      _buildPdfRow('Die', dieDetail),

    // ===== CUSTOM EXTRA =====
    if (extraSections.isNotEmpty)
      ...extraSections
          .map<pw.TableRow?>((sec) {
            final detail = sec['detail'] ?? sec['details'] ?? '';
            if (detail.toString().trim().isEmpty) return null;

            return _buildPdfRow(
              sec['title'] ?? 'Extra',
              detail,
            );
          })
          .whereType<pw.TableRow>()
          .toList(),



                      _buildPdfRow('Conerned Person', salesPerson),
                    ],
                  ),
                  if (notes.toString().trim().isNotEmpty) ...[
                    pw.SizedBox(height: 1),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        //   borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Additional Notes:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 0.1),
                          pw.Text(
                            notes,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],

                  pw.SizedBox(height: 3),

                  if (loadedImages.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Product Images:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),

                          // 🔥 Images take remaining space
                          pw.Expanded(
                            child: pw.GridView(
                              crossAxisCount: loadedImages.length == 1
                                  ? 1
                                  : loadedImages.length <= 4
                                  ? 2
                                  : 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                              children: loadedImages.map((img) {
                                return pw.Image(img, fit: pw.BoxFit.contain);
                              }).toList(),
                            ),
                          ),

                          pw.SizedBox(height: 4),

                          // ✅ Footer safely at bottom
                          pw.Center(
                            child: pw.Text(
                              'All Rights Reserved Dimple Packaging Pvt. Ltd.',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  bool _hasExtraInstructions(Map<String, dynamic> sections) {
    return sections['otherDetail']?.toString().trim().isNotEmpty == true;
  }

  String _getExtraInstructions(Map<String, dynamic> sections) {
    return '${sections['otherDetail']}'
        '  |  Qty: ${sections['otherQty'] ?? ''}'
        '  |  Price: ${sections['otherPrice'] ?? ''}';
  }

  pw.TableRow _buildPdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.grey200,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  Future<void> _generateJobCardFromOrder(
    Map<String, dynamic> order,
    String orderId,
  ) async {
    final alreadyExists = await _checkIfJobCardExists(orderId);
    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Job Card already created for this Sales Order!'),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final counterRef = FirebaseFirestore.instance
          .collection('meta')
          .doc('jobCardCounter');
      String jobNo = '';
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        final last = (snap.data()?['last'] as int?) ?? 0;
        final next = last + 1;
        tx.set(counterRef, {'last': next}, SetOptions(merge: true));
        jobNo = 'DPL$next';
      });

      List products = order['products'] ?? [];
      List<Map<String, dynamic>> jobCardProducts = [];

      for (int i = 0; i < products.length; i++) {
        final product = products[i];

        jobCardProducts.add({
          'dplIndex': i + 1, // 🔥 THIS IS KEY
          'dplNo': '$jobNo-${i + 1}', // optional but recommended
          'productName': product['productName'] ?? '', // ✅ ADD THIS
          'productCategory': product['productCategory'] ?? '',
          'length': product['length'] ?? '',
          'height': product['height'] ?? '',
          'width': product['width'] ?? '',
          'quantity': product['quantity'] ?? 0,
          'price': product['price'] ?? 0,
          'remarks': product['remarks'] ?? '',
          'images': List<String>.from(product['images'] ?? []),
          'sections': product['sections'] ?? {},
          'customExtraSections': product['customExtraSections'] ?? [],
        });
      }

      List<Map<String, dynamic>> partialDispatchesData = [];
      final partialDispatches = order['partialDispatches'] as List? ?? [];
      for (var dispatch in partialDispatches) {
        partialDispatchesData.add({
          'name': dispatch['name'] ?? '',
          'quantity': dispatch['quantity'] ?? '',
          'date': dispatch['date'] ?? '',
          'timestamp': dispatch['timestamp'],
        });
      }

      await FirebaseFirestore.instance.collection('jobCards').doc(jobNo).set({
        'jobNo': jobNo,
        'date': order['orderDate'] ?? DateTime.now(),
        'priority': order['priority'] ?? 'Medium',
        'customerName': order['customerName'] ?? '',
        'salesPerson': order['salesPerson'] ?? '',
        'products': jobCardProducts,
        'partialDispatches': partialDispatchesData,
        'extraInstruction': order['notes'] ?? '',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'sales_order',
        'linkedOrderId': orderId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Job Card created successfully!')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openEditAndCreateJobCard(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditSalesOrderScreen(orderId: orderId, orderData: orderData),
      ),
    );

    final jobCardExists = await _checkIfJobCardExists(orderId);
    if (!jobCardExists && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: Colors.teal.shade600,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Create Job Card?'),
            ],
          ),
          content: const Text(
            'Would you like to create a Job Card from this updated Sales Order?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final updatedDoc = await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .get();
                if (updatedDoc.exists) {
                  await _generateJobCardFromOrder(
                    updatedDoc.data() as Map<String, dynamic>,
                    orderId,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create Job Card'),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'processing':
        return Colors.blue.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red.shade50;
      case 'medium':
        return Colors.orange.shade50;
      case 'low':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by customer or product...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.teal.shade600,
                    size: 24,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: () => setState(() => searchQuery = ''),
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
                onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.teal.shade600),
                        const SizedBox(height: 16),
                        Text(
                          'Loading orders...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var orders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final customer = (data['customerName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final productMatch =
                      (data['products'] as List?)?.any(
                        (p) => (p['productName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(searchQuery),
                      ) ??
                      false;
                  return customer.contains(searchQuery) || productMatch;
                }).toList();

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No orders found'
                              : 'No matching orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isEmpty
                              ? 'Create your first sales order'
                              : 'Try a different search term',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final doc = orders[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final products = data['products'] as List? ?? [];
                    final priority = data['priority'] ?? 'Medium';
                    final status = data['status'] ?? 'Pending';

                    return FutureBuilder<bool>(
                      future: _checkIfJobCardExists(doc.id),
                      builder: (context, snapshot) {
                        final jobCardExists = snapshot.data ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              childrenPadding: const EdgeInsets.all(20),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.shade400,
                                      Colors.teal.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.shade200,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Customer: ${data['customerName'] ?? 'Unknown'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Sales Person: ${data['salesPerson'] ?? 'Unknown'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (jobCardExists) ...[
                                    // PDF Button
                                    IconButton(
                                      icon: Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.red,
                                        size: 16.sp,
                                      ),
                                      onPressed: () =>
                                          _generateAllProductsPDF(doc.id, data),
                                      tooltip: 'Generate PDF',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    SizedBox(width: 0.2.w),
                                    // Job Card Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.shade200,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 12.sp,
                                          ),
                                          SizedBox(width: 0.2.w),
                                          Text(
                                            'Job Card',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(priority),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              priority.toLowerCase() == 'high'
                                              ? Colors.red.shade200
                                              : priority.toLowerCase() ==
                                                    'medium'
                                              ? Colors.orange.shade200
                                              : Colors.green.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.flag,
                                            size: 12,
                                            color:
                                                priority.toLowerCase() == 'high'
                                                ? Colors.red.shade600
                                                : priority.toLowerCase() ==
                                                      'medium'
                                                ? Colors.orange.shade600
                                                : Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            priority,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  priority.toLowerCase() ==
                                                      'high'
                                                  ? Colors.red.shade600
                                                  : priority.toLowerCase() ==
                                                        'medium'
                                                  ? Colors.orange.shade600
                                                  : Colors.green.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 18,
                                            color: Colors.teal.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Products:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...products.map(
                                        (p) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: Colors.teal.shade400,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: RichText(
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            '${p['productName'] ?? 'Product'}   ${p['productCategory'] ?? ''}',

                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .teal
                                                              .shade700,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            '  •  Qty: ${p['quantity'] ?? '-'}',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .deepOrange
                                                              .shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _openEditAndCreateJobCard(
                                            doc.id,
                                            data,
                                          ),
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            jobCardExists
                                                ? Icons.edit_outlined
                                                : Icons.assignment_outlined,
                                            size: 20,
                                          ),
                                    label: Text(
                                      jobCardExists
                                          ? 'Edit Order'
                                          : 'Edit & Create Job Card',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: Colors.teal.shade200,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
