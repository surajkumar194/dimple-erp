// pubspec.yaml dependencies add karein:
// pdf: ^3.10.4
// printing: ^5.11.0
// path_provider: ^2.1.1
// intl: ^0.18.0
// cloud_firestore: latest

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class ViewProductionScreen extends StatelessWidget {
  const ViewProductionScreen({super.key});

  static Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 90) return Colors.green;
    if (efficiency >= 70) return Colors.orange;
    return Colors.red;
  }

  static Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: iconColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // PDF Generate karne ka main function with logo
  static Future<void> _generatePDF(
      BuildContext context, Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // LOGO LOAD KARNA
    pw.ImageProvider? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/logo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      print('Logo load error: $e');
      logoImage = null;
    }

    final efficiency = (data['efficiency'] ?? 0.0).toDouble();
    final timestamp = data['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // HEADER with Logo
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
                pw.Container(
                  width: 100,
                  height: 100,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'DPL',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                  ),
                ),
              pw.SizedBox(width: 15),
              pw.Expanded(
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
                      'West, Bhattian Ludhiana, Punjab - 141008\n'
                      'Contact No.: 9872518000, 7888896774',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'GST No.: 03AADCD5371K1ZP     PAN No.: AADCD5371K',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        pw.SizedBox(height: 10),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 10),
          // Title
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.teal200, width: 1.5),
              ),
              child: pw.Text(
                'PRODUCTION RECORD REPORT',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 25),

          // Machine and Operator Details
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              children: [
                _buildPDFRow(
                    'Machine Name:', data['machine'] ?? 'Unknown', true),
                pw.SizedBox(height: 12),
                _buildPDFRow(
                    'Operator:', data['operator'] ?? 'Unknown', false),
                pw.SizedBox(height: 12),
                _buildPDFRow('Shift:', data['shift'] ?? 'N/A', false),
                pw.SizedBox(height: 12),
                _buildPDFRow(
                  'Date & Time:',
                  dateTime != null
                      ? DateFormat('dd MMM yyyy • hh:mm a').format(dateTime)
                      : 'Not available',
                  false,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // Production Details Table
          pw.Text(
            'Production Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey300),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1.5),
              },
              children: [
                _buildPDFTableRow(
                    'Planned Quantity', '${data['plannedQty'] ?? 0} pcs', true),
                _buildPDFTableRow(
                    'Actual Quantity', '${data['actualQty'] ?? 0} pcs', false),
                _buildPDFTableRow(
                    'Rejection', '${data['rejection'] ?? 0} pcs', false),
                _buildPDFTableRow(
                    'Good Quantity', '${data['goodQty'] ?? 0} pcs', false),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // Timing Details Side by Side
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.blue200, width: 1.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'START TIME',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        data['startTime'] ?? '-',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.purple200, width: 1.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'END TIME',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        data['endTime'] ?? '-',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.purple900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // Efficiency Badge - Big & Beautiful
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 50),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [
                    _getPDFEfficiencyColor(efficiency),
                    _getPDFEfficiencyColor(efficiency).shade(0.3),
                  ],
                ),
                borderRadius: pw.BorderRadius.circular(12),
                boxShadow: [
                  pw.BoxShadow(
                    color: PdfColors.grey400,
                    offset: const PdfPoint(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'EFFICIENCY',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${efficiency.toStringAsFixed(1)}%',
                    style: pw.TextStyle(
                      fontSize: 38,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 30),

          // Footer with timestamp
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 1),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Powered by Dimple Packaging Pvt Ltd',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // PDF ko show aur download karein
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Production_${data['machine']}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  static pw.TableRow _buildPDFTableRow(
      String label, String value, bool isHeader) {
    return pw.TableRow(
      decoration:
          isHeader ? pw.BoxDecoration(color: PdfColors.teal50) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(14),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight:
                  isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.grey800,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(14),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal900,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPDFRow(String label, String value, bool isBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  static PdfColor _getPDFEfficiencyColor(double efficiency) {
    if (efficiency >= 90) return PdfColors.green700;
    if (efficiency >= 70) return PdfColors.orange700;
    return PdfColors.red700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Production Records",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00796B), Color(0xFF009688)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.insert_chart, size: 18),
                    SizedBox(width: 6),
                    Text('Reports', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('machine_production')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 90, color: Colors.red.shade300),
                  const SizedBox(height: 20),
                  Text(
                    "Error loading data",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please check your connection",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: Color(0xFF00796B), strokeWidth: 3),
                  const SizedBox(height: 20),
                  Text(
                    "Loading records...",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600),
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
                    child: Icon(Icons.inventory_2_outlined,
                        size: 80, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No Production Records Yet",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Start adding entries from the Add Entry screen",
                    style:
                        TextStyle(fontSize: 15, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final efficiency = (data['efficiency'] ?? 0.0).toDouble();
              final timestamp = data['timestamp'] as Timestamp?;
              final dateTime = timestamp?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  collapsedBackgroundColor: Colors.white,
                  backgroundColor: Colors.white,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00796B), Color(0xFF009688)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00796B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (data['machine'] as String?)?.isNotEmpty == true
                            ? data['machine'][0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    data['machine'] ?? 'Unknown Machine',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      letterSpacing: 0.3,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            data['operator'] ?? 'Unknown',
                            style: TextStyle(
                                fontSize: 14.5,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade50,
                                  Colors.teal.shade100
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              data['shift'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.teal.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 15, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            dateTime != null
                                ? DateFormat('dd MMM yyyy • hh:mm a')
                                    .format(dateTime)
                                : 'Date not available',
                            style: TextStyle(
                                fontSize: 13.5, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getEfficiencyColor(efficiency).withOpacity(0.2),
                              _getEfficiencyColor(efficiency).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getEfficiencyColor(efficiency)
                                .withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          "${efficiency.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _getEfficiencyColor(efficiency),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // PDF Download Button with Style
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade200,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.picture_as_pdf,
                              color: Colors.white, size: 24),
                          onPressed: () => _generatePDF(context, data),
                          tooltip: 'Download PDF',
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade50,
                            Colors.grey.shade100
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.donut_small_rounded,
                            label: "Planned Quantity",
                            value: "${data['plannedQty'] ?? 0} pcs",
                            iconColor: Colors.blue.shade700,
                          ),
                          _buildDetailRow(
                            icon: Icons.check_circle_rounded,
                            label: "Actual Quantity",
                            value: "${data['actualQty'] ?? 0} pcs",
                            iconColor: Colors.green.shade700,
                          ),
                          _buildDetailRow(
                            icon: Icons.cancel_rounded,
                            label: "Rejection",
                            value: "${data['rejection'] ?? 0} pcs",
                            iconColor: Colors.red.shade700,
                          ),
                          _buildDetailRow(
                            icon: Icons.check_box_rounded,
                            label: "Good Quantity",
                            value: "${data['goodQty'] ?? 0} pcs",
                            iconColor: Colors.teal.shade700,
                          ),
                          Divider(
                              height: 35,
                              thickness: 1.5,
                              color: Colors.grey.shade400),
                          _buildDetailRow(
                            icon: Icons.speed_rounded,
                            label: "Efficiency",
                            value: "${efficiency.toStringAsFixed(1)}%",
                            iconColor: _getEfficiencyColor(efficiency),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  icon: Icons.play_circle_rounded,
                                  label: "Start",
                                  value: data['startTime'] ?? '-',
                                  iconColor: const Color(0xFF00796B),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildDetailRow(
                                  icon: Icons.stop_circle_rounded,
                                  label: "End",
                                  value: data['endTime'] ?? '-',
                                  iconColor: const Color(0xFF6A1B9A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}