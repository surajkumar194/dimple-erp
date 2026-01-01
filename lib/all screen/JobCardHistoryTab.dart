import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class JobCardHistoryTab extends StatelessWidget {
  const JobCardHistoryTab({super.key});

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _generateAndDownloadPDF(BuildContext context, Map<String, dynamic> job) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.teal.shade600),
                const SizedBox(height: 16),
                const Text('Generating PDF...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );

    try {
      final pdf = pw.Document();
      final List products = job['products'] ?? [];

      // LOGO LOAD KARNA
      Uint8List logoBytes;
      try {
        final data = await rootBundle.load('assets/logo.png');
        logoBytes = data.buffer.asUint8List();
      } catch (e) {
        logoBytes = Uint8List(0);
      }

      final logoImage = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

      final jobNo = job['jobNo'] ?? 'N/A';
      final date = job['date'] is Timestamp
          ? (job['date'] as Timestamp).toDate()
          : DateTime.now();
      final sections = job['sections'] as Map<String, dynamic>? ?? {};
      final extraInstruction = job['extraInstruction']?.toString() ?? '';

      // 🔥 Load product images for PDF (with limit to speed up)
      List<Map<String, dynamic>> productsWithImages = [];
      for (var product in products) {
        final images = product['images'] as List<dynamic>? ?? [];
        List<pw.MemoryImage> pdfImages = [];

        // Limit to first 3 images per product for faster loading
        final limitedImages = images.take(3).toList();
        
        for (var imageUrl in limitedImages) {
          try {
            final response = await http.get(Uri.parse(imageUrl)).timeout(
              const Duration(seconds: 5),
            );
            if (response.statusCode == 200) {
              pdfImages.add(pw.MemoryImage(response.bodyBytes));
            }
          } catch (e) {
            print('Error loading image: $e');
          }
        }

        productsWithImages.add({
          'name': product['productName'] ?? product['name'] ?? 'N/A',
          'quantity': product['quantity'] ?? 'N/A',
          'remarks': product['remarks'] ?? '',
          'pdfImages': pdfImages,
        });
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => [
            // HEADER
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 100,
                    height: 100,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(width: 100, height: 100),
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
            pw.SizedBox(height: 10),

            // TITLE
            pw.Center(
              child: pw.Text(
                'PRODUCTION JOB CARD',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // JOB CARD DETAILS
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _buildPdfRow('Job No', jobNo),
                  _buildPdfRow('Date', '${date.day}/${date.month}/${date.year}'),
                  _buildPdfRow(
                    'Customer Name',
                    job['customerName'] ?? job['customer'] ?? 'N/A',
                  ),
                  if (job['salesPerson'] != null)
                    _buildPdfRow('Sales Person', job['salesPerson']),
                  if (job['companyName']?.toString().isNotEmpty ?? false)
                    _buildPdfRow('Company Name', job['companyName']),
                  _buildPdfRow('Size', job['size'] ?? 'N/A'),
                  _buildPdfRow('Status', job['status'] ?? 'Pending'),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // 🔥 PRODUCTS TABLE WITH IMAGES
            if (productsWithImages.isNotEmpty) ...[
              pw.Text(
                'PRODUCTS DETAILS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildTableCell('S.No', isHeader: true),
                      _buildTableCell('Product Name', isHeader: true),
                      _buildTableCell('Quantity', isHeader: true),
                      _buildTableCell('Remark', isHeader: true),
                      _buildTableCell('Images', isHeader: true),
                    ],
                  ),

                  // Data Rows
                  ...productsWithImages.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final product = entry.value;
                    final imgs = product['pdfImages'] as List<pw.MemoryImage>;
                    final remark = product['remarks'] ?? '';
                    final productName = product['name']?.toString() ?? 'N/A';

                    return pw.TableRow(
                      children: [
                        _buildTableCell(index.toString()),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            productName,
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        _buildTableCell(product['quantity'].toString()),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            remark.toString().trim().isEmpty ? '-' : remark,
                            style: const pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: imgs.isNotEmpty
                              ? pw.Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: imgs.map((img) {
                                    return pw.Container(
                                      width: 40,
                                      height: 40,
                                      decoration: pw.BoxDecoration(
                                        border: pw.Border.all(color: PdfColors.grey400),
                                      ),
                                      child: pw.Image(img, fit: pw.BoxFit.cover),
                                    );
                                  }).toList(),
                                )
                              : pw.Text(
                                  'No Images',
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey600,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // PRODUCTION SECTIONS
            if (sections.isNotEmpty) ...[
              pw.Text(
                'PRODUCTION SECTIONS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                    children: [
                      _buildTableCell('Section', isHeader: true),
                      _buildTableCell('Details', isHeader: true),
                    ],
                  ),
                  ...sections.entries.map(
                    (e) => pw.TableRow(
                      children: [
                        _buildTableCell(e.key.toUpperCase()),
                        _buildTableCell(e.value?.toString() ?? '-'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // EXTRA INSTRUCTIONS
            if (extraInstruction.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EXTRA INSTRUCTIONS',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(extraInstruction),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                'This is a computer-generated Job Card.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Save PDF directly without opening
      final pdfData = await pdf.save();
      
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'JobCard_$jobNo.pdf',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('PDF Downloaded Successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog on error
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red.shade500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
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

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade50, Colors.white],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobCards')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.teal.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Job Cards...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.work_outline,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Job Cards Found',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first job card to get started',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final jobNo = data['jobNo'] ?? 'N/A';
              final status = data['status'] ?? 'Pending';
              final priority = data['priority'] ?? 'Low';
              final customer = data['customerName'] ?? data['customer'] ?? 'N/A';
              final products = data['products'] as List<dynamic>? ?? [];

              int totalQuantity = 0;
              int totalImages = 0;
              for (var product in products) {
                final qty = product['quantity'] ?? '0';
                totalQuantity += int.tryParse(qty.toString()) ?? 0;

                final images = product['images'] as List<dynamic>? ?? [];
                totalImages += images.length;
              }

              final orderDate = _formatDate(data['createdAt']);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Job Number Badge
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade400,
                                  Colors.teal.shade700,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    jobNo.length >= 3 ? jobNo.substring(3) : jobNo,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const Text(
                                    'JOB',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Job Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        jobNo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Color(0xFF169a8d),
                                        ),
                                      ),
                                    ),
                                    _buildPriorityBadge(priority),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      orderDate,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade300, height: 1),
                      const SizedBox(height: 16),

                      // Customer Info
                      _buildInfoRow(Icons.business, 'Customer', customer, Colors.blue),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.person_pin, 'Sales Person', data['salesPerson'] ?? 'N/A', Colors.purple),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.straighten, 'Size', data['size'] ?? 'N/A', Colors.orange),
                      const SizedBox(height: 16),

                      // Products Section with Images
                      if (products.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.indigo.shade50, Colors.blue.shade50],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.indigo.shade100, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2,
                                      size: 18,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Products (${products.length})',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Qty: $totalQuantity',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...products.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final product = entry.value;
                             final productName =
    (product['productName']?.toString().trim().isNotEmpty == true)
        ? product['productName']
        : (product['name']?.toString().trim().isNotEmpty == true)
            ? product['name']
            : 'N/A';
                                final productQty = (product['quantity'] != null && product['quantity'].toString().trim().isNotEmpty)
                                    ? product['quantity'].toString()
                                    : '0';
                                final productRemark = (product['remarks'] != null && product['remarks'].toString().trim().isNotEmpty)
                                    ? product['remarks'].toString()
                                    : '';
                                final productImages = product['images'] as List<dynamic>? ?? [];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.indigo.shade100),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.indigo.shade600,
                                            child: Text(
                                              '${idx + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  productName,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Quantity: $productQty',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                if (productRemark.toString().trim().isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Icon(
                                                        Icons.comment_outlined,
                                                        size: 14,
                                                        color: Colors.orange.shade700,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          productRemark,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontStyle: FontStyle.italic,
                                                            color: Colors.grey.shade800,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (productImages.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Colors.green.shade400, Colors.green.shade600],
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.image, size: 14, color: Colors.white),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${productImages.length}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (productImages.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          height: 70,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: productImages.length,
                                            itemBuilder: (context, imgIdx) {
                                              final imageUrl = productImages[imgIdx];
                                              return Container(
                                                margin: const EdgeInsets.only(right: 8),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    imageUrl,
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stack) {
                                                      return Container(
                                                        width: 70,
                                                        height: 70,
                                                        color: Colors.grey.shade300,
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      );
                                                    },
                                                    loadingBuilder: (context, child, progress) {
                                                      if (progress == null) return child;
                                                      return Container(
                                                        width: 70,
                                                        height: 70,
                                                        color: Colors.grey.shade200,
                                                        child: Center(
                                                          child: CircularProgressIndicator(
                                                            value: progress.expectedTotalBytes != null
                                                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                                                : null,
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                      );
                                                    },
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
                              }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Status Row with PDF Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (totalImages > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_library, size: 18, color: Colors.blue.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Total Images: $totalImages',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusChip(status),
                              const SizedBox(width: 8),
                              // PDF Download Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red.shade400, Colors.red.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                                  tooltip: 'Download PDF',
                                  onPressed: () => _generateAndDownloadPDF(context, data),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (priority.toLowerCase()) {
      case 'high':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.arrow_upward;
        break;
      case 'urgent':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.priority_high;
        break;
      case 'medium':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.remove;
        break;
      default:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.arrow_downward;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = Colors.green.shade500;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'in progress':
        bgColor = Colors.orange.shade500;
        textColor = Colors.white;
        icon = Icons.hourglass_bottom;
        break;
      case 'pending':
        bgColor = Colors.blue.shade500;
        textColor = Colors.white;
        icon = Icons.schedule;
        break;
      default:
        bgColor = Colors.grey.shade500;
        textColor = Colors.white;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bgColor, bgColor.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  } }