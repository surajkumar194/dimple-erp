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

  @override
  State<JobCardHistoryTab> createState() => _JobCardHistoryTabState();
}

class _JobCardHistoryTabState extends State<JobCardHistoryTab> {
  String _searchText = '';

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

  String _onlyNumber(dynamic value) {
    return RegExp(r'\d+').stringMatch(value?.toString() ?? '') ?? '0';
  }

  double _calcAmount(dynamic qty, dynamic rate) {
    final q = double.tryParse(qty?.toString() ?? '0') ?? 0;
    final r = double.tryParse(rate?.toString() ?? '0') ?? 0;
    return q * r;
  }

  pw.Widget _buildHeaderCell(String text) {
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

  pw.Widget _buildDataCell(
    String text, {
    bool center = true,
    double fontSize = 11,
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

  pw.Widget _buildProductSummary(Map<String, dynamic> product) {
    final sections = product['sections'] as Map<String, dynamic>? ?? {};
    List<String> labels = ['Product Name'];

    if (sections['trayDetail'] != null) labels.add('Tray');
    if (sections['salophinDetail'] != null) labels.add('Salophin');
    if (sections['boxCoverDetail'] != null) labels.add('Box Cover');
    if (sections['innerDetail'] != null) labels.add('Inner');
    if (sections['bottomDetail'] != null) labels.add('Bottom');
    if (sections['dieDetail'] != null) labels.add('Die');
    if (sections['otherDetail'] != null) labels.add('Other');

    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            product['name'] ?? 'Product',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...labels
              .skip(1)
              .map(
                (label) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  pw.Widget _buildProductDetails(Map<String, dynamic> product) {
    final sections = product['sections'] as Map<String, dynamic>? ?? {};
    List<String> details = [];

    if (sections['trayDetail'] != null) {
      details.add('${sections['trayDetail'] ?? ''}');
    }
    if (sections['salophinDetail'] != null) {
      details.add('${sections['salophinDetail'] ?? ''}');
    }
    if (sections['boxCoverDetail'] != null) {
      details.add('${sections['boxCoverDetail'] ?? ''}');
    }
    if (sections['innerDetail'] != null) {
      details.add('${sections['innerDetail'] ?? ''}');
    }
    if (sections['bottomDetail'] != null) {
      details.add('${sections['bottomDetail'] ?? ''}');
    }
    if (sections['dieDetail'] != null) {
      details.add('${sections['dieDetail'] ?? ''}');
    }
    if (sections['otherDetail'] != null) {
      details.add('${sections['otherDetail'] ?? ''}');
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: details
            .map(
              (detail) =>
                  pw.Text(detail, style: const pw.TextStyle(fontSize: 6)),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _buildQtyColumn(Map<String, dynamic> product) {
    final sections = product['sections'] as Map<String, dynamic>? ?? {};
    List<String> qtys = [product['quantity']?.toString() ?? '0'];

    if (sections['trayDetail'] != null) {
      qtys.add(sections['trayQty']?.toString() ?? '-');
    }
    if (sections['salophinDetail'] != null) {
      qtys.add(sections['salophinQty']?.toString() ?? '-');
    }
    if (sections['boxCoverDetail'] != null) {
      qtys.add(sections['boxCoverQty']?.toString() ?? '-');
    }
    if (sections['innerDetail'] != null) {
      qtys.add(sections['innerQty']?.toString() ?? '-');
    }
    if (sections['bottomDetail'] != null) {
      qtys.add(sections['bottomQty']?.toString() ?? '-');
    }
    if (sections['dieDetail'] != null) {
      qtys.add(sections['dieQty']?.toString() ?? '-');
    }
    if (sections['otherDetail'] != null) {
      qtys.add(sections['otherQty']?.toString() ?? '-');
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: qtys
            .map(
              (qty) => pw.Text(
                qty,
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _buildRateColumn(Map<String, dynamic> product) {
    final sections = product['sections'] as Map<String, dynamic>? ?? {};
    List<String> rates = [product['price']?.toString() ?? '0'];

    if (sections['trayDetail'] != null) {
      rates.add(sections['trayPrice']?.toString() ?? '-');
    }
    if (sections['salophinDetail'] != null) {
      rates.add(sections['salophinPrice']?.toString() ?? '-');
    }
    if (sections['boxCoverDetail'] != null) {
      rates.add(sections['boxCoverPrice']?.toString() ?? '-');
    }
    if (sections['innerDetail'] != null) {
      rates.add(sections['innerPrice']?.toString() ?? '-');
    }
    if (sections['bottomDetail'] != null) {
      rates.add(sections['bottomPrice']?.toString() ?? '-');
    }
    if (sections['dieDetail'] != null) {
      rates.add(sections['diePrice']?.toString() ?? '-');
    }
    if (sections['otherDetail'] != null) {
      rates.add(sections['otherPrice']?.toString() ?? '-');
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: rates
            .map(
              (rate) => pw.Text(
                rate,
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _buildAmountColumn(Map<String, dynamic> product) {
    final sections = product['sections'] as Map<String, dynamic>? ?? {};
    List<String> amounts = [product['amount']];

    if (sections['trayDetail'] != null) {
      final amt = _calcAmount(sections['trayQty'], sections['trayPrice']);
      amounts.add(amt > 0 ? amt.toStringAsFixed(0) : '-');
    }
    if (sections['salophinDetail'] != null) {
      final amt = _calcAmount(
        sections['salophinQty'],
        sections['salophinPrice'],
      );
      amounts.add(amt > 0 ? amt.toStringAsFixed(0) : '-');
    }
    if (sections['boxCoverDetail'] != null) {
      final amt = _calcAmount(
        sections['boxCoverQty'],
        sections['boxCoverPrice'],
      );
      amounts.add(amt > 0 ? amt.toStringAsFixed(0) : '-');
    }
    if (sections['innerDetail'] != null) {
      final amt = _calcAmount(sections['innerQty'], sections['innerPrice']);
      amounts.add(amt > 0 ? amt.toStringAsFixed(0) : '-');
    }
    if (sections['bottomDetail'] != null) {
      final amt = _calcAmount(sections['bottomQty'], sections['bottomPrice']);
      amounts.add(amt > 0 ? amt.toStringAsFixed(0) : '-');
    }
    if (sections['dieDetail'] != null) {
      final amt = _calcAmount(sections['dieQty'], sections['diePrice']);
      amounts.add(amt > 0 ? amt.toStringAsFixed(0) : '-');
    }
    if (sections['otherDetail'] != null) {
      final amt = _calcAmount(sections['otherQty'], sections['otherPrice']);
      amounts.add(amt > 0 ? amt.toStringAsFixed(0) : '-');
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: amounts
            .map(
              (amount) => pw.Text(
                amount,
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
            )
            .toList(),
      ),
    );
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
          job['orderLocation'] ??
          job['address'] ??
          'N/A';

      // Load product images
      List<Map<String, dynamic>> productsWithImages = [];
      for (var product in products) {
        final images = product['images'] as List<dynamic>? ?? [];
        List<pw.MemoryImage> pdfImages = [];

        for (var imgUrl in images) {
          try {
            final response = await http
                .get(Uri.parse(imgUrl))
                .timeout(const Duration(seconds: 5));

            if (response.statusCode == 200) {
              pdfImages.add(pw.MemoryImage(response.bodyBytes));
            }
          } catch (_) {}
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
          'amount': amount.toStringAsFixed(0),
          'remarks': product['remarks'] ?? '',
          'pdfImages': pdfImages,
          'sections': product['sections'] ?? {},
          'customExtraSections': product['customExtraSections'] ?? [],
        });
      }

      double grandTotal = 0;

      for (var product in productsWithImages) {
        grandTotal += double.tryParse(product['amount'] ?? '0') ?? 0;

        final sections = product['sections'] as Map<String, dynamic>? ?? {};

        grandTotal += _calcAmount(sections['trayQty'], sections['trayPrice']);
        grandTotal += _calcAmount(
          sections['salophinQty'],
          sections['salophinPrice'],
        );
        grandTotal += _calcAmount(
          sections['boxCoverQty'],
          sections['boxCoverPrice'],
        );
        grandTotal += _calcAmount(sections['innerQty'], sections['innerPrice']);
        grandTotal += _calcAmount(
          sections['bottomQty'],
          sections['bottomPrice'],
        );
        grandTotal += _calcAmount(sections['dieQty'], sections['diePrice']);
        grandTotal += _calcAmount(sections['otherQty'], sections['otherPrice']);
      }
      final double subTotal = grandTotal;
      final double gstAmount = subTotal * 0.05;
      final double finalTotal = subTotal + gstAmount;

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

              pw.SizedBox(height: 15),

              // ========== CUSTOMER INFO BAR ==========
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Location',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              location,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Customer Name',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              customerName,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Date',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              _formatDate(date),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              // ========== PRODUCTS TABLE ==========
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),
                  1: const pw.FlexColumnWidth(1.8),
                  2: const pw.FlexColumnWidth(4.0), // DETAILS EXPANDED
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FixedColumnWidth(40),
                  5: const pw.FixedColumnWidth(60),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.teal800,
                    ),
                    children: [
                      _buildHeaderCell('Sr.'),
                      _buildHeaderCell('SUMMARY'),
                      _buildHeaderCell('DETAILS'),
                      _buildHeaderCell('QTY'),
                      _buildHeaderCell('RATE'),
                      _buildHeaderCell('AMOUNT'),
                    ],
                  ),

                  // Data Rows - Expanded with multiple rows per product
                  ...productsWithImages.asMap().entries.expand((entry) {
                    final index = entry.key + 1;
                    final product = entry.value;
                    final List<pw.MemoryImage> imgs =
                        product['pdfImages'] as List<pw.MemoryImage>;
                    final sections =
                        product['sections'] as Map<String, dynamic>? ?? {};

                    List<pw.TableRow> rows = [];

                    // Main product row
                    rows.add(
                      pw.TableRow(
                        children: [
                          _buildDataCell(index.toString(), center: false),

                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              product['name'] ?? 'Product',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),

                          // ✅ DETAILS + IMAGES
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                if (product['remarks'] != null &&
                                    product['remarks'].toString().isNotEmpty)
                                  pw.Text(
                                    product['remarks'],
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),

                                pw.SizedBox(height: 6),

                                if (imgs.isNotEmpty)
                                  pw.Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: imgs.map((img) {
                                      return pw.Container(
                                        height: 70,
                                        width: 90,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(
                                            color: PdfColors.grey400,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: pw.Image(
                                          img,
                                          fit: pw.BoxFit.contain,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),

                          _buildDataCell(
                            _onlyNumber(product['quantity']),
                            center: true,
                          ),
                          _buildDataCell(product['price'], center: true),
                          _buildDataCell(product['amount'], center: true),
                        ],
                      ),
                    );

                    // Tray row
                    if (sections['trayDetail'] != null) {
                      rows.add(
                        pw.TableRow(
                          children: [
                            _buildDataCell(''),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Tray',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            _buildDataCell(
                              sections['trayDetail']?.toString() ?? '',
                              center: false,
                            ),
                            _buildDataCell(
                              sections['trayQty']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              sections['trayPrice']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              _calcAmount(
                                        sections['trayQty'],
                                        sections['trayPrice'],
                                      ) >
                                      0
                                  ? _calcAmount(
                                      sections['trayQty'],
                                      sections['trayPrice'],
                                    ).toStringAsFixed(0)
                                  : '-',
                              center: true,
                            ),
                            _buildDataCell(''),
                          ],
                        ),
                      );
                    }

                    // Salophin row
                    if (sections['salophinDetail'] != null) {
                      rows.add(
                        pw.TableRow(
                          children: [
                            _buildDataCell(''),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Salophin',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            _buildDataCell(
                              sections['salophinDetail']?.toString() ?? '',
                              center: false,
                            ),
                            _buildDataCell(
                              sections['salophinQty']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              sections['salophinPrice']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              _calcAmount(
                                        sections['salophinQty'],
                                        sections['salophinPrice'],
                                      ) >
                                      0
                                  ? _calcAmount(
                                      sections['salophinQty'],
                                      sections['salophinPrice'],
                                    ).toStringAsFixed(0)
                                  : '-',
                              center: true,
                            ),
                            _buildDataCell(''),
                          ],
                        ),
                      );
                    }

                    // Box Cover row
                    if (sections['boxCoverDetail'] != null) {
                      rows.add(
                        pw.TableRow(
                          children: [
                            _buildDataCell(''),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Box Cover',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            _buildDataCell(
                              sections['boxCoverDetail']?.toString() ?? '',
                              center: false,
                            ),
                            _buildDataCell(
                              sections['boxCoverQty']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              sections['boxCoverPrice']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              _calcAmount(
                                        sections['boxCoverQty'],
                                        sections['boxCoverPrice'],
                                      ) >
                                      0
                                  ? _calcAmount(
                                      sections['boxCoverQty'],
                                      sections['boxCoverPrice'],
                                    ).toStringAsFixed(0)
                                  : '-',
                              center: true,
                            ),
                            _buildDataCell(''),
                          ],
                        ),
                      );
                    }

                    // Inner row
                    if (sections['innerDetail'] != null) {
                      rows.add(
                        pw.TableRow(
                          children: [
                            _buildDataCell(''),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Inner',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            _buildDataCell(
                              sections['innerDetail']?.toString() ?? '',
                              center: false,
                            ),
                            _buildDataCell(
                              sections['innerQty']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              sections['innerPrice']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              _calcAmount(
                                        sections['innerQty'],
                                        sections['innerPrice'],
                                      ) >
                                      0
                                  ? _calcAmount(
                                      sections['innerQty'],
                                      sections['innerPrice'],
                                    ).toStringAsFixed(0)
                                  : '-',
                              center: true,
                            ),
                            _buildDataCell(''),
                          ],
                        ),
                      );
                    }

                    // Bottom row
                    if (sections['bottomDetail'] != null) {
                      rows.add(
                        pw.TableRow(
                          children: [
                            _buildDataCell(''),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Bottom',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            _buildDataCell(
                              sections['bottomDetail']?.toString() ?? '',
                              center: false,
                            ),
                            _buildDataCell(
                              sections['bottomQty']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              sections['bottomPrice']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              _calcAmount(
                                        sections['bottomQty'],
                                        sections['bottomPrice'],
                                      ) >
                                      0
                                  ? _calcAmount(
                                      sections['bottomQty'],
                                      sections['bottomPrice'],
                                    ).toStringAsFixed(0)
                                  : '-',
                              center: true,
                            ),
                            _buildDataCell(''),
                          ],
                        ),
                      );
                    }

                    // Die row
                    if (sections['dieDetail'] != null) {
                      rows.add(
                        pw.TableRow(
                          children: [
                            _buildDataCell(''),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Die',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            _buildDataCell(
                              sections['dieDetail']?.toString() ?? '',
                              center: false,
                            ),
                            _buildDataCell(
                              sections['dieQty']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              sections['diePrice']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              _calcAmount(
                                        sections['dieQty'],
                                        sections['diePrice'],
                                      ) >
                                      0
                                  ? _calcAmount(
                                      sections['dieQty'],
                                      sections['diePrice'],
                                    ).toStringAsFixed(0)
                                  : '-',
                              center: true,
                            ),
                            _buildDataCell(''),
                          ],
                        ),
                      );
                    }

                    // Other row
                    if (sections['otherDetail'] != null) {
                      rows.add(
                        pw.TableRow(
                          children: [
                            _buildDataCell(''),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Other',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            _buildDataCell(
                              sections['otherDetail']?.toString() ?? '',
                              center: false,
                            ),
                            _buildDataCell(
                              sections['otherQty']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              sections['otherPrice']?.toString() ?? '-',
                              center: true,
                            ),
                            _buildDataCell(
                              _calcAmount(
                                        sections['otherQty'],
                                        sections['otherPrice'],
                                      ) >
                                      0
                                  ? _calcAmount(
                                      sections['otherQty'],
                                      sections['otherPrice'],
                                    ).toStringAsFixed(0)
                                  : '-',
                              center: true,
                            ),
                            _buildDataCell(''),
                          ],
                        ),
                      );
                    }
                    final List extras = product['customExtraSections'] ?? [];

                    if (extras.isNotEmpty) {
                      for (var extra in extras) {
                        rows.add(
                          pw.TableRow(
                            children: [
                              _buildDataCell(''),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  extra['title'] ?? 'Extra',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildDataCell(
                                extra['detail']?.toString() ?? '',
                                center: false,
                              ),
                              _buildDataCell(extra['qty']?.toString() ?? '-'),
                              _buildDataCell(extra['price']?.toString() ?? '-'),
                              _buildDataCell(
                                _calcAmount(extra['qty'], extra['price']) > 0
                                    ? _calcAmount(
                                        extra['qty'],
                                        extra['price'],
                                      ).toStringAsFixed(0)
                                    : '-',
                              ),
                            ],
                          ),
                        );
                      }
                    }

                    return rows;
                  }).toList(),
                  // 🔹 SUB TOTAL
                  pw.TableRow(
                    children: [
                      _buildDataCell(''),
                      _buildDataCell(''),
                      _buildDataCell('SUB TOTAL', center: false),
                      _buildDataCell(''),
                      _buildDataCell(''),
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

                  // 🔹 GST 5%
                  pw.TableRow(
                    children: [
                      _buildDataCell(''),
                      _buildDataCell(''),
                      _buildDataCell('GST @ 5%', center: false),
                      _buildDataCell(''),
                      _buildDataCell(''),
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

                  // 🔹 GRAND TOTAL
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildDataCell(''),
                      _buildDataCell(''),
                      _buildDataCell(
                        'GRAND TOTAL',
                        center: false,
                        fontSize: 12,
                      ),
                      _buildDataCell(''),
                      _buildDataCell(''),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          finalTotal.toStringAsFixed(0),
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

              pw.SizedBox(height: 20),

              // Footer
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'All Rights Reserved © Dimple Packaging Pvt. Ltd.',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ];
          },
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
      child: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Job No, Customer...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
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

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final jobNo = (data['jobNo'] ?? '').toString().toLowerCase();
                  final customer =
                      (data['customerName'] ?? data['customer'] ?? '')
                          .toString()
                          .toLowerCase();
                  final status = (data['status'] ?? '')
                      .toString()
                      .toLowerCase();

                  return jobNo.contains(_searchText) ||
                      customer.contains(_searchText) ||
                      status.contains(_searchText);
                }).toList();

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
                          _searchText.isNotEmpty
                              ? 'No matching job cards found'
                              : 'No Job Cards Found',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
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
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade600,
                                              borderRadius:
                                                  BorderRadius.circular(3),
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
                            Container(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _generateAndDownloadPDF(context, data),
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Download Proforma Invoice',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
          ),
        ],
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
