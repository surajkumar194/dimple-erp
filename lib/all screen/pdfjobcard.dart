import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class JobCardDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobCardDetailBottomSheet({super.key, required this.job});

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

  Future<void> _generateAndDownloadPDF(BuildContext context) async {
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

    // 🔥 Load product images for PDF
    List<Map<String, dynamic>> productsWithImages = [];
    for (var product in products) {
      final images = product['images'] as List<dynamic>? ?? [];
      List<pw.MemoryImage> pdfImages = [];

      for (var imageUrl in images) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
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
    // Calculate total quantity
    int totalQuantity = 0;
    for (var product in products) {
      final qty = product['quantity'] ?? '0';
      totalQuantity += int.tryParse(qty.toString()) ?? 0;
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
),                if (job['salesPerson'] != null)
                  _buildPdfRow('Sales Person', job['salesPerson']),
                if (job['companyName']?.toString().isNotEmpty ?? false)
                  _buildPdfRow('Company Name', job['companyName']),
                _buildPdfRow('Size', job['size'] ?? 'N/A'),
             //   _buildPdfRow('Total Quantity', totalQuantity.toString()),
            //    _buildPdfRow('Priority', job['priority'] ?? 'Low'),
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
              0: pw.FixedColumnWidth(40),
  1: pw.FlexColumnWidth(2.5), // Product
  2: pw.FlexColumnWidth(1.2), // Qty
  3: pw.FlexColumnWidth(1), // Remark
  4: pw.FlexColumnWidth(3),// Images
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                     _buildTableCell('S.No', isHeader: true),
    _buildTableCell('Product Name', isHeader: true),
    _buildTableCell('Quantity', isHeader: true),
    _buildTableCell('Remark', isHeader: true), // ✅
    _buildTableCell('Images', isHeader: true),
                  ],
                ),

                // Data Rows
                ...productsWithImages.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final product = entry.value;
                  final imgs = product['pdfImages'] as List<pw.MemoryImage>;
final remark = product['remarks'] ?? '';

                return pw.TableRow(
  children: [
    _buildTableCell(index.toString()),
    _buildTableCell(product['name']),
    _buildTableCell(product['quantity'].toString()),
    pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        remark.toString().trim().isEmpty ? '-' : remark,
        style: const pw.TextStyle(fontSize: 9),
      ),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: imgs.isNotEmpty
          ? pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: imgs.map((img) {
                return pw.Container(
                  width: 50,
                  height: 50,
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

    // Print / Download
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'JobCard_$jobNo.pdf',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Job Card PDF Ready!'),
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
    final date = job['date'] is Timestamp
        ? (job['date'] as Timestamp).toDate()
        : DateTime.now();
    final status = job['status'] ?? 'Pending';
    final priority = job['priority'] ?? 'Low';
    final products = job['products'] as List<dynamic>? ?? [];

    // Calculate total quantity
    int totalQuantity = 0;
    for (var product in products) {
      final qty = product['quantity'] ?? '0';
      totalQuantity += int.tryParse(qty.toString()) ?? 0;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                  child: const Icon(Icons.work, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Job Card Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Number Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.purple.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                job['jobNo'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ),
                            _buildDetailStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildSmallBadge(
                              Icons.calendar_today,
                              '${date.day}/${date.month}/${date.year}',
                              Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            _buildPriorityDetailBadge(priority),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Information Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
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
                        _infoRowStyled(
                          Icons.person,
                          'Customer',
                          job['customer'] ?? '-',
                          Colors.blue,
                        ),
                        if (job['salesPerson'] != null) ...[
                          const Divider(height: 24),
                          _infoRowStyled(
                            Icons.person_pin,
                            'Sales Person',
                            job['salesPerson'],
                            Colors.purple,
                          ),
                        ],
                        if (job['companyName']?.toString().isNotEmpty ?? false) ...[
                          const Divider(height: 24),
                          _infoRowStyled(
                            Icons.business,
                            'Company Name',
                            job['companyName'],
                            Colors.orange,
                          ),
                        ],
                        const Divider(height: 24),
                        _infoRowStyled(
                          Icons.straighten,
                          'Size',
                          job['size'] ?? '-',
                          Colors.orange,
                        ),
                        const Divider(height: 24),
                        _infoRowStyled(
                          Icons.format_list_numbered,
                          'Total Quantity',
                          totalQuantity.toString(),
                          Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔥 Products Section with Images
                  if (products.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade400,
                                Colors.purple.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Products (${products.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...products.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final product = entry.value;
final productName =
    product['productName'] ??
    product['name'] ??
    'N/A';                      final productQty = product['quantity'] ?? 'N/A';
                      final productRemark = product['remarks'] ?? '';

                      final productImages = product['images'] as List<dynamic>? ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.indigo.shade600,
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Quantity: $productQty',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (productRemark.toString().trim().isNotEmpty) ...[
  const SizedBox(height: 6),
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.comment,
        size: 16,
        color: Colors.orange.shade700,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          productRemark,
          style: TextStyle(
            fontSize: 14,
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.image,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${productImages.length}',
                                          style: const TextStyle(
                                            fontSize: 14,
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
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Product Images:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 80,
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
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) {
                                            return Container(
                                              width: 80,
                                              height: 80,
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
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  value: progress.expectedTotalBytes != null
                                                      ? progress.cumulativeBytesLoaded /
                                                          progress.expectedTotalBytes!
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
                    const SizedBox(height: 16),
                  ],

                  // Production Sections
                  if (job['sections'] != null &&
                      (job['sections'] as Map).isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.deepOrange.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Production Sections',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...(job['sections'] as Map).entries.map(
                      (e) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            e.key.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            e.value?.toString() ?? '-',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Extra Instructions
                  if (job['extraInstruction']?.toString().isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade50, Colors.orange.shade50],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade900,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Extra Instructions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  job['extraInstruction'].toString(),
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // PDF Download Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => _generateAndDownloadPDF(context),
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: const Text(
                          'Download Job Card PDF',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowStyled(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDetailBadge(String priority) {
    Color color;
    IconData icon;

    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case 'urgent':
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.remove;
        break;
      default:
        color = Colors.blue;
        icon = Icons.arrow_downward;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            'Priority: $priority',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStatusBadge(String status) {
    Color bgColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = Colors.green.shade500;
        icon = Icons.check_circle;
        break;
      case 'in progress':
        bgColor = Colors.orange.shade500;
        icon = Icons.hourglass_bottom;
        break;
      case 'pending':
        bgColor = Colors.blue.shade500;
        icon = Icons.schedule;
        break;
      default:
        bgColor = Colors.grey.shade500;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            status,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}