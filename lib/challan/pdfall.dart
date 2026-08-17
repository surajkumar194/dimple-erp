// dispatch_all_data_screen.dart
//
// Sab dispatch data Firebase se laata hai, date-range se filter karta hai,
// aur:
//   1) Har entry ka individual re-print (jaisa purani DispatchHistoryScreen me tha)
//   2) "Download All PDF" button — jo selected date-range ka POORA data
//      ek hi consolidated PDF me bana kar deta hai, jisme upar
//      "Report Generated On: dd/MM/yyyy hh:mm a" (jis waqt PDF banaya,
//      wahi date/time) likha hota hai.
//
// Packages chahiye honge pubspec.yaml me (agar already nahi hain):
//   pdf: ^3.10.8
//   printing: ^5.12.0
//   cloud_firestore: ^4.x / ^5.x  (already use ho raha hai)
//   intl: ^0.19.0                (already use ho raha hai)
//
// Import karke iss screen ko Navigator se open kar dena, jaise:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const DispatchAllDataScreen(),
//   ));

import 'dart:typed_data';

import 'package:dimple_erp/challan/DispatchFullPage.dart'; // showPdfTypeDialog(), generateChallanPDF() -> yeh aapke purane individual challan PDF wale functions hain
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DispatchAllDataScreen extends StatefulWidget {
  const DispatchAllDataScreen({super.key});

  @override
  State<DispatchAllDataScreen> createState() => _DispatchAllDataScreenState();
}

class _DispatchAllDataScreenState extends State<DispatchAllDataScreen> {
  DateTimeRange? _selectedRange;
  bool _isGeneratingPdf = false;

  // ---------------- Helpers ----------------

  String _fmt(dynamic ts) {
    if (ts == null) return 'N/A';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else {
      return 'N/A';
    }
    return DateFormat('dd/MM/yyyy  hh:mm a').format(dt);
  }

  String get _rangeLabel {
    if (_selectedRange == null) return 'All Dates';
    final f = DateFormat('dd/MM/yyyy');
    return '${f.format(_selectedRange!.start)} - ${f.format(_selectedRange!.end)}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _selectedRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day),
          ),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // End date ko din ke aakhri second tak extend kar dete hain
        // taaki us din ka pura data cover ho jaaye.
        _selectedRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        );
      });
    }
  }

  void _clearRange() {
    setState(() => _selectedRange = null);
  }

  // Firestore query — agar date range selected hai to us hisaab se filter,
  // warna sab data (createdAt descending).
  Stream<QuerySnapshot> _buildStream() {
    Query query = FirebaseFirestore.instance
        .collection('dispatchSales')
        .orderBy('createdAt', descending: true);

    if (_selectedRange != null) {
      query = query
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedRange!.start),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(_selectedRange!.end),
          );
    }
    return query.snapshots();
  }

  // ---------------- Consolidated PDF (saara filtered data ek PDF me) ----------------

  Future<void> _downloadAllPdf(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iss date range me koi data nahi hai.')),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);
    try {
      final Uint8List bytes = await _buildConsolidatedPdf(docs);
      final fileName =
          'Dispatch_Report_${DateFormat('ddMMyyyy_HHmmss').format(DateTime.now())}.pdf';

      await Printing.sharePdf(bytes: bytes, filename: fileName);
      // Agar seedha device me save/print karna ho to isके बदले yeh use karein:
      // await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF banane me error: $e')));
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<Uint8List> _buildConsolidatedPdf(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final pdf = pw.Document();

    // Jis exact waqt PDF generate ho raha hai, wahi timestamp — yehi
    // "print date" hai jo aapne bola tha.
    final String generatedOn = DateFormat(
      'dd/MM/yyyy  hh:mm a',
    ).format(DateTime.now());

    // ---- Totals ----
    int grandQty = 0;
    int grandPackets = 0;
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      grandQty += _toInt(data['totalQty']);
      grandPackets += _toInt(data['totalPackets']);
    }

    const headerColor = PdfColor.fromInt(0xFF1A237E);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dispatch Report',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: headerColor,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} / ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            // ---- yeh wahi "jis din PDF bana" wala text hai ----
            pw.Text(
              'Report Generated On: $generatedOn',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Text(
              'Date Range: $_rangeLabel',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Divider(color: PdfColors.grey400),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.Text(
              'Generated on $generatedOn  |  Dimple ERP',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
        build: (context) => [
          // ---- Summary box ----
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Challans: ${docs.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Total Qty: $grandQty',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Total Packets: $grandPackets',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // ---- Har challan ka block ----
          for (final doc in docs) ..._buildChallanBlock(doc),
        ],
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildChallanBlock(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final challNo = (data['challNo'] ?? 'N/A').toString();
    final createdAt = _fmt(data['createdAt']);
    final customerName = (data['customerName'] ?? '').toString();
    final driverName = (data['driverName'] ?? '').toString();
    final totalQty = _toInt(data['totalQty']);
    final totalPackets = _toInt(data['totalPackets']);
    final List items = data['items'] ?? [];

    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Challan: $challNo',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1A237E),
                  ),
                ),
                pw.Text(
                  createdAt,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            if (customerName.isNotEmpty)
              pw.Text(
                'Customer: $customerName',
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (driverName.isNotEmpty)
              pw.Text(
                'Driver: $driverName',
                style: const pw.TextStyle(fontSize: 10),
              ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Item', bold: true),
                    _cell('Qty', bold: true),
                    _cell('Pkt', bold: true),
                    _cell('Remarks', bold: true),
                  ],
                ),
                for (final item in items)
                  pw.TableRow(
                    children: [
                      _cell((item['productName'] ?? '').toString()),
                      _cell(_toInt(item['quantity']).toString()),
                      _cell(_toInt(item['packets']).toString()),
                      _cell(
                        item['isManuallyAdded'] == true
                            ? 'EXTRA'
                            : item['isOverDispatched'] == true
                            ? 'OVER'
                            : '-',
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Qty: $totalQty   |   Total Packets: $totalPackets',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A148C),
                  Color(0xFF7B1FA2),
                  Color(0xFF0D47A1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
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
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'All Dispatch Data',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ---- Date filter row ----
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.date_range_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _rangeLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_selectedRange != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _clearRange,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Iss date range me koi data nahi mila.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${docs.length} challans found',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) => _buildCard(docs[i]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: _buildStream(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          return FloatingActionButton.extended(
            onPressed: _isGeneratingPdf ? null : () => _downloadAllPdf(docs),
            backgroundColor: const Color(0xFF1B5E20),
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            label: Text(
              _isGeneratingPdf ? 'Generating...' : 'Download All PDF',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final challNo = data['challNo'] ?? 'N/A';
    final createdAt = _fmt(data['createdAt']);
    final customerName = data['customerName'] ?? '';
    final totalQty = data['totalQty'] ?? 0;
    final totalPackets = data['totalPackets'] ?? 0;
    final driverName = data['driverName'] ?? '';
    final List items = data['items'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              Text(
                createdAt,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (customerName.toString().isNotEmpty)
            Text(
              customerName.toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(Icons.numbers_rounded, 'Qty: $totalQty', Colors.blue),
              _chip(
                Icons.inventory_2_rounded,
                'Packets: $totalPackets',
                Colors.orange,
              ),
              if (driverName.toString().isNotEmpty)
                _chip(
                  Icons.drive_eta_rounded,
                  driverName.toString(),
                  Colors.teal,
                ),
              _chip(
                Icons.category_rounded,
                '${items.length} Items',
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final bool? withRate = await showPdfTypeDialog(context);
              if (withRate == null) return;
              await generateChallanPDF(data, showRate: withRate);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Re-Print This Challan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  Widget _chip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
