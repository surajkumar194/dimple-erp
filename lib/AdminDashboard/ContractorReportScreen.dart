import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/all%20screen/historysalesorder.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// ─── Web-only import (conditional) ───────────────────────────────────────────
// Add this to pubspec.yaml:
//   universal_html: ^2.2.4
import 'package:universal_html/html.dart' as html;

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ContractorReportScreen extends StatelessWidget {
  const ContractorReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
  appBar: PreferredSize(
  preferredSize: const Size.fromHeight(110), // 👈 height बढ़ाया
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

          // 🔙 BACK BUTTON
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

          // 🔷 LOGO
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset('assets/dpl.png', height: 32),
          ),

          const SizedBox(width: 8),

          // 🔤 TITLE
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Contract Reports',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Cutting & Pasting Reports',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    ),

    // 🔥 RIGHT SIDE ICON
    // actions: [
    //   Padding(
    //     padding: const EdgeInsets.only(right: 12),
    //     child: GestureDetector(
    //       onTap: () {
    //         Navigator.push(
    //           context,
    //           MaterialPageRoute(
    //             builder: (context) => const OrderHistoryScreen(),
    //           ),
    //         );
    //       },
    //       child: Container(
    //         padding: const EdgeInsets.all(8),
    //         decoration: BoxDecoration(
    //           color: Colors.white.withOpacity(0.2),
    //           borderRadius: BorderRadius.circular(12),
    //         ),
    //         child: const Icon(
    //           Icons.history,
    //           color: Colors.white,
    //           size: 22,
    //         ),
    //       ),
    //     ),
    //   ),
    // ],

    // 🔥 IMPORTANT FIX (TabBar inside AppBar)
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(45),
      child: Container(
        alignment: Alignment.centerLeft,
        child: const TabBar(
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.cut, size: 16), text: "Cutting"),
            Tab(icon: Icon(Icons.layers, size: 16), text: "Pasting"),
          ],
        ),
      ),
    ),
  ),
),
        body: const TabBarView(
          children: [
            _ReportScreen(type: "cutting"),
            _ReportScreen(type: "pasting"),
          ],
        ),
      ),
    );
  }

  Tab _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPORT LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _ReportScreen extends StatelessWidget {
  final String type;
  const _ReportScreen({required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('constructionProduction')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A237E)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _ReportCard(data: data, type: type);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            "No reports found",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPORT CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type;

  const _ReportCard({required this.data, required this.type});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .doc(data['orderId'])
          .get(),
      builder: (context, orderSnap) {
        if (!orderSnap.hasData) {
          return const _SkeletonCard();
        }

        final orderData =
            orderSnap.data!.data() as Map<String, dynamic>? ?? {};
        final products =
            (orderData['products'] as List<dynamic>?) ?? [];

        final contractorName = type == "cutting"
            ? (data['cuttingContractor'] ?? '-')
            : (data['pastingContractor'] ?? '-');

        final price = type == "cutting"
            ? (data['cuttingPrice'] ?? '0')
            : (data['pastingPrice'] ?? '0');

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderData['customerName'] ?? 'Unknown Customer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            orderData['companyName'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Badge(label: "ID: ${data['orderId'] ?? '-'}"),
                  ],
                ),
              ),

              // ── Products Section ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.inventory_2_rounded,
                      label: "Products (${products.length})",
                    ),
                    const SizedBox(height: 8),
                    ...products.map<Widget>((p) => _ProductRow(product: p)),

                    const Divider(height: 24),

                    // ── Contractor Info ────────────────────────────────────
                    _SectionTitle(
                      icon: type == "cutting"
                          ? Icons.cut_rounded
                          : Icons.layers_rounded,
                      label:
                          type == "cutting" ? "Cutting Details" : "Pasting Details",
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.engineering,
                      label: "Contractor",
                      value: contractorName,
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.currency_rupee,
                      label: "Price",
                      value: "₹$price",
                      valueColor: const Color(0xFF2E7D32),
                    ),

                    const SizedBox(height: 14),

                    // ── Download Button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: const Text(
                          "Download PDF Report",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () async {
                          await _generatePDF(data, orderData, type, context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1A237E)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final dynamic product;
  const _ProductRow({required this.product});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Text(
              product['productName'] ?? '-',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Qty: ${product['qty'] ?? 0}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PDF GENERATOR — Web + Mobile Support
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _generatePDF(
  Map<String, dynamic> data,
  Map<String, dynamic> orderData,
  String type,
  BuildContext context,
) async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: Color(0xFF1A237E)),
    ),
  );

  try {
    final products = (orderData['products'] as List<dynamic>?) ?? [];
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('1A237E'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${type == 'cutting' ? 'Cutting' : 'Pasting'} Contractor Report",
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Generated: ${DateTime.now().toString().substring(0, 16)}",
                      style: const pw.TextStyle(
                        fontSize: 10,
                      
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Customer Info ────────────────────────────────────────────
              _pdfSection("Customer Details"),
              pw.SizedBox(height: 6),
              _pdfInfoRow("Customer Name", orderData['customerName'] ?? '-'),
              _pdfInfoRow("Company", orderData['companyName'] ?? '-'),
              _pdfInfoRow("Order ID", data['orderId'] ?? '-'),

              pw.SizedBox(height: 16),

              // ── Products ─────────────────────────────────────────────────
              _pdfSection("Products"),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColor.fromHex('E0E0E0'),
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('E8EAF6'),
                    ),
                    children: [
                      _pdfTableCell("Product Name", isHeader: true),
                      _pdfTableCell("Qty", isHeader: true),
                    ],
                  ),
                  // Table rows
                  ...products.map<pw.TableRow>((p) {
                    return pw.TableRow(
                      children: [
                        _pdfTableCell(p['productName'] ?? '-'),
                        _pdfTableCell("${p['qty'] ?? 0}"),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── Contractor Details ────────────────────────────────────────
              _pdfSection(
                  "${type == 'cutting' ? 'Cutting' : 'Pasting'} Details"),
              pw.SizedBox(height: 6),

              if (type == "cutting") ...[
                _pdfInfoRow(
                    "Cutting Contractor", data['cuttingContractor'] ?? '-'),
                _pdfInfoRow("Price", "₹${data['cuttingPrice'] ?? '0'}"),
              ] else ...[
                _pdfInfoRow(
                    "Pasting Contractor", data['pastingContractor'] ?? '-'),
                _pdfInfoRow("Price", "₹${data['pastingPrice'] ?? '0'}"),
              ],

              pw.Spacer(),

              // ── Footer ───────────────────────────────────────────────────
              pw.Divider(color: PdfColor.fromHex('E0E0E0')),
              pw.Text(
                "This is a system-generated report.",
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();
    final fileName = "${type}_report_${data['orderId']}.pdf";

    if (kIsWeb) {
      // ── WEB: Trigger browser download ─────────────────────────────────
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..download = fileName
        ..style.display = 'none';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // ── MOBILE / DESKTOP: Save to documents & open ────────────────────
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(pdfBytes);
      await OpenFile.open(file.path);
    }

    // Close loading dialog
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    // Success snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                kIsWeb ? "PDF downloaded!" : "PDF saved & opened!",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF Error: $e"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PDF HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

pw.Widget _pdfSection(String title) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: pw.BorderSide(color: PdfColor.fromHex('1A237E'), width: 3),
      ),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('1A237E'),
      ),
    ),
  );
}

pw.Widget _pdfInfoRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 130,
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Text(
          ": ",
          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 11),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: isHeader
            ? PdfColor.fromHex('1A237E')
            : PdfColors.black,
      ),
    ),
  );
}