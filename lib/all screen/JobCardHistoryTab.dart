import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sizer/sizer.dart';

class JobCardHistoryTab extends StatefulWidget {
  const JobCardHistoryTab({super.key});

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _buildSizeCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 8 : 7,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  @override
  State<JobCardHistoryTab> createState() => _JobCardHistoryTabState();
}

class _JobCardHistoryTabState extends State<JobCardHistoryTab> {
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
      return DateFormat('dd-MM-yyyy').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _generateAndDownloadPDF(
    BuildContext context,
    Map<String, dynamic> job,
  ) async {
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
                const Text(
                  'Generating Proforma Invoice...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final pdf = pw.Document();
      final List products = job['products'] ?? [];

      // Load company logo
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
      final customerName = job['customerName'] ?? job['customer'] ?? 'N/A';
      final location =
          job['location'] ??
          job['jobLocation'] ??
          job['unit'] ??
          job['orderLocation'] ??
          job['address'] ??
          'N/A';

      // Load product images
      List<Map<String, dynamic>> productsWithImages = [];
      for (var product in products) {
        final images = product['images'] as List<dynamic>? ?? [];
        pw.MemoryImage? firstImage;

        if (images.isNotEmpty) {
          try {
            final response = await http
                .get(Uri.parse(images[0]))
                .timeout(const Duration(seconds: 5));
            if (response.statusCode == 200) {
              firstImage = pw.MemoryImage(response.bodyBytes);
            }
          } catch (e) {
            print('Error loading image: $e');
          }
        }

        // Extract size from product or job
        final size = product['size'] ?? job['size'] ?? '';
        List<String> dimensions = ['', '', ''];

        if (size.toString().isNotEmpty) {
          // Try to parse size like "250.5mm x 175mm x 46mm"
          final sizeStr = size.toString().toLowerCase();
          final parts = sizeStr.split('x').map((e) => e.trim()).toList();

          if (parts.length >= 3) {
            dimensions[0] = parts[0].replaceAll('mm', '').trim() + 'mm';
            dimensions[1] = parts[1].replaceAll('mm', '').trim() + 'mm';
            dimensions[2] = parts[2].replaceAll('mm', '').trim() + 'mm';
          }
        }
final int qty =
    int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

final double rate =
    double.tryParse(product['price']?.toString() ?? '0') ?? 0;

final double amount = qty * rate;

        productsWithImages.add({
          'name': product['productName'] ?? product['name'] ?? 'N/A',
          'quantity': product['quantity']?.toString() ?? '0',
          'price': product['price']?.toString() ?? '0',
  'amount': amount.toStringAsFixed(2), // ✅ AUTO
          'remarks': product['remarks'] ?? '',
          'pdfImage': firstImage,
          'length': dimensions[0],
          'width': dimensions[1],
          'height': dimensions[2],
        });
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) => [
            // ========== HEADER ==========
            pw.Container(
              decoration: pw.BoxDecoration(
                //border: pw.Border.all(color: PdfColors.black, width: 2),
              ),
              child: pw.Column(
                children: [
                  // Title Bar
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    // color: PdfColors.grey300,
                    child: pw.Center(
                      child: pw.Text(
                        'Proforma Invoice',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Company Details Row
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 80,
                          height: 80,
                          child: pw.Image(logoImage),
                        ),
                      pw.SizedBox(width: 10),

                      // Company Info
                      pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Column(
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
                                'West, Bhattian Ludhiana, Punjab - 141008, Contact No.: 9872518000, 7888696774',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'GST No.: 03AADCD5371K1ZP     PAN No.: AADCD5371K',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 15),

            // ========== CUSTOMER INFO BAR ==========
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Row(
                children: [
                  // Summary Column
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(color: PdfColors.black),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          location,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Customer Name
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(color: PdfColors.black),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          customerName,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Date
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(
                        child: pw.Text(
                          'DATE: ${_formatDate(date)}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 15),

            // ========== PRODUCTS TABLE ==========
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: {
                0: const pw.FixedColumnWidth(35), // Sr. No.
                1: const pw.FlexColumnWidth(2), // Summary (Product Name)
                2: const pw.FlexColumnWidth(3.5), // Image + Size
                3: const pw.FlexColumnWidth(1), // Qty
                4: const pw.FlexColumnWidth(1), // Rate
                5: const pw.FlexColumnWidth(1), // Amount
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    JobCardHistoryTab._buildTableHeader('Sr. No.'),
                    JobCardHistoryTab._buildTableHeader('SUMMARY'),
                    JobCardHistoryTab._buildTableHeader('IMAGE'),
                    JobCardHistoryTab._buildTableHeader('QNTY.'),
                    JobCardHistoryTab._buildTableHeader('RATE'),
                    JobCardHistoryTab._buildTableHeader('AMOUNT'),
                  ],
                ),

                // Data Rows
                ...productsWithImages.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final product = entry.value;
                  final img = product['pdfImage'] as pw.MemoryImage?;

                  return pw.TableRow(
                    children: [
                      // Serial Number
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            index.toString(),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Product Name
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            product['name'],
                            style: pw.TextStyle(
                              fontSize: 13.sp,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),

                      // Image + Size Table
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          children: [
                            // Product Image
                            if (img != null)
                              pw.Container(
                                width: 100,
                                height: 100,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(
                                    color: PdfColors.grey400,
                                  ),
                                ),
                                child: pw.Image(img, fit: pw.BoxFit.cover),
                              )
                            else
                              pw.Container(
                                width: 80,
                                height: 80,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(
                                    color: PdfColors.grey400,
                                  ),
                                  color: PdfColors.grey200,
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    'No Image',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                                ),
                              ),

                            pw.SizedBox(height: 6),

                            // Size Table (L, W, H)
                            // pw.Table(
                            //   border: pw.TableBorder.all(
                            //     color: PdfColors.black,
                            //     width: 0.5,
                            //   ),
                            //   columnWidths: {
                            //     0: const pw.FlexColumnWidth(1),
                            //     1: const pw.FlexColumnWidth(1),
                            //     2: const pw.FlexColumnWidth(1),
                            //   },
                            //   children: [
                            //     // L W H Header
                            //     pw.TableRow(
                            //       decoration: const pw.BoxDecoration(
                            //         color: PdfColors.grey200,
                            //       ),
                            //       children: [
                            //         JobCardHistoryTab._buildSizeCell(
                            //           'L',
                            //           isHeader: true,
                            //         ),
                            //         JobCardHistoryTab._buildSizeCell(
                            //           'W',
                            //           isHeader: true,
                            //         ),
                            //         JobCardHistoryTab._buildSizeCell(
                            //           'H',
                            //           isHeader: true,
                            //         ),
                            //       ],
                            //     ),
                            //     // Size Values
                            //     pw.TableRow(
                            //       children: [
                            //         JobCardHistoryTab._buildSizeCell(
                            //           product['length'] ?? '-',
                            //         ),
                            //         JobCardHistoryTab._buildSizeCell(
                            //           product['width'] ?? '-',
                            //         ),
                            //         JobCardHistoryTab._buildSizeCell(
                            //           product['height'] ?? '-',
                            //         ),
                            //       ],
                            //     ),
                            //   ],
                            // ),

                            // Remarks if any
                            // if (product['remarks']
                            //     .toString()
                            //     .trim()
                            //     .isNotEmpty) ...[
                            //   pw.SizedBox(height: 4),
                            //   pw.Text(
                            //     product['remarks'],
                            //     style: const pw.TextStyle(fontSize: 7),
                            //     textAlign: pw.TextAlign.center,
                            //   ),
                            // ],
                          ],
                        ),
                      ),

                      // Quantity
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            product['quantity'],
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                      ),

                      // Rate
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            product['price'],
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                      ),

                      // Amount
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            product['amount'],
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 30),

            // Footer
            pw.Divider(thickness: 1),
            pw.Center(
              child: pw.Text(
                'Dimple packaging pvt ltd Proforma Invoice.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        ),
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Save PDF
      final pdfData = await pdf.save();

      await Printing.sharePdf(
        bytes: pdfData,
        filename:
            'ProformaInvoice_${customerName.replaceAll(' ', '_')}_$jobNo.pdf',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Proforma Invoice Downloaded Successfully!'),
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
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.work_outline,
                      size: 80,
                      color: Colors.teal.shade300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Job Cards Found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first job card to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
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
              final customer =
                  data['customerName'] ?? data['customer'] ?? 'N/A';
              final products = data['products'] as List<dynamic>? ?? [];

              int totalQuantity = 0;
              for (var product in products) {
                final qty = product['quantity'] ?? '0';
                totalQuantity += int.tryParse(qty.toString()) ?? 0;
              }

              final orderDate = _formatDate(data['createdAt']);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
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
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row with Job No and Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade600,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      jobNo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        color: Color(0xFF169a8d),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Customer: $customer',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildStatusChip(status),
                              const SizedBox(height: 10),
                              _buildPriorityChip(priority),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      Container(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),

                      const SizedBox(height: 16),

                      // Details Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailBox(
                              icon: Icons.calendar_today,
                              label: 'Date',
                              value: orderDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBox(
                              icon: Icons.inventory_2,
                              label: 'Products',
                              value: '${products.length}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBox(
                              icon: Icons.production_quantity_limits,
                              label: 'Quantity',
                              value: '$totalQuantity',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // PDF Download Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _generateAndDownloadPDF(context, data),
                          icon: const Icon(Icons.picture_as_pdf, size: 20),
                          label: const Text(
                            'Download Proforma Invoice',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildDetailBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.teal.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        borderColor = Colors.green.shade300;
        icon = Icons.check_circle;
        break;
      case 'in progress':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        borderColor = Colors.orange.shade300;
        icon = Icons.hourglass_bottom;
        break;
      case 'pending':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        borderColor = Colors.blue.shade300;
        icon = Icons.schedule;
        break;
      default:
        bgColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        borderColor = Colors.grey.shade300;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
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
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (priority.toLowerCase()) {
      case 'high':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        borderColor = Colors.red.shade300;
        break;
      case 'medium':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade700;
        borderColor = Colors.amber.shade300;
        break;
      case 'low':
      default:
        bgColor = Colors.cyan.shade50;
        textColor = Colors.cyan.shade700;
        borderColor = Colors.cyan.shade300;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        '● $priority',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}