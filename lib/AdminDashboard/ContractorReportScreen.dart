import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ContractorPdfReportScreen extends StatefulWidget {
  const ContractorPdfReportScreen({super.key});
  @override
  State<ContractorPdfReportScreen> createState() =>
      _ContractorPdfReportScreenState();
}

class _ContractorPdfReportScreenState
    extends State<ContractorPdfReportScreen> {
  static const _primary = Color(0xFF169a8d);
  static const _darkText = Color(0xFF2C3E50);
  static const _lightBg = Color(0xFFF8F9FA);

  String _filterType = "1 Month";
  DateTimeRange? _customRange;
  String? _selectedContractor;
  bool _isGenerating = false;
  String _workType = "Both";

  List<String> _allContractors = [];
  bool _loadingContractors = true;

  Key _previewKey = UniqueKey();
  Future<_ReportData>? _previewFuture;

  @override
  void initState() {
    super.initState();
    _loadContractors();
  }

  Future<void> _loadContractors() async {
    final snap = await FirebaseFirestore.instance
        .collection('constructionProduction')
        .get();
    final Set<String> names = {};
    for (final doc in snap.docs) {
      final arr = List.from(doc.data()['productsProduction'] ?? []);
      for (final item in arr) {
        if (item == null || (item as Map).isEmpty) continue;
        final c = (item['cuttingContractor'] ?? '').toString().trim();
        final p = (item['pastingContractor'] ?? '').toString().trim();
        if (c.isNotEmpty) names.add(c);
        if (p.isNotEmpty) names.add(p);
      }
    }
    setState(() {
      _allContractors = names.toList()..sort();
      _loadingContractors = false;
      _previewFuture = _fetchReportData();
    });
  }

  void _refreshPreview() {
    setState(() {
      _previewKey = UniqueKey();
      _previewFuture = _fetchReportData();
    });
  }

  // ── Date range ─────────────────────────────────────────────────────────────
  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_filterType) {
      case "Today":
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case "1 Week":
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: today.add(const Duration(days: 1)),
        );
      case "1 Month":
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: today.add(const Duration(days: 1)),
        );
      case "Custom":
        return _customRange ??
            DateTimeRange(
              start: today.subtract(const Duration(days: 30)),
              end: today.add(const Duration(days: 1)),
            );
      default:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: today.add(const Duration(days: 1)),
        );
    }
  }

  // ── FETCH DATA ─────────────────────────────────────────────────────────────
  Future<_ReportData> _fetchReportData() async {
    final range = _getDateRange();

    final orderSnap =
        await FirebaseFirestore.instance.collection('orders').get();

    final prodSnap = await FirebaseFirestore.instance
        .collection('constructionProduction')
        .get();

    final Map<String, Map<String, dynamic>> prodMap = {};
    for (final d in prodSnap.docs) prodMap[d.id] = d.data();

    // Contractor summaries (cutting + pasting)
    final Map<String, _ContractorSummary> summaryMap = {};

    // Employee rows (for "both" and "employee" types)
    final List<_EmployeeRow> employeeRows = [];

    for (final orderDoc in orderSnap.docs) {
      final oData = orderDoc.data();
      final products =
          oData['products'] is List ? oData['products'] as List : [];

      Timestamp? ts = oData['updatedAt'] as Timestamp?;
      ts ??= oData['orderDate'] as Timestamp?;
      if (ts == null) continue;

      final date = ts.toDate();
      if (date.isBefore(range.start) || date.isAfter(range.end)) continue;

      final customerName = (oData['customerName'] ?? '-').toString();
      final orderId = orderDoc.id;
      final prodData = prodMap[orderId];
      if (prodData == null) continue;

      final arr = List.from(prodData['productsProduction'] ?? []);

      final mdfProducts = products.where((p) {
        final cat = (p['productCategory'] ?? '').toString().toLowerCase();
        return cat == 'mdf' || cat == 'construction';
      }).toList();

      for (int i = 0; i < arr.length; i++) {
        final item = arr[i];
        if (item == null || (item as Map).isEmpty) continue;

        final product = i < mdfProducts.length
            ? mdfProducts[i] as Map
            : <String, dynamic>{};
        final productName =
            (product['productName'] ?? 'Product ${i + 1}').toString();
        final totalQty =
            _parseQty(item['totalQuantity'] ?? product['quantity']);
        final productionType = (item['productionType'] ?? '').toString();

        DateTime? savedDate;
        try {
          final s = item['savedAt']?.toString() ?? '';
          if (s.isNotEmpty) savedDate = DateTime.parse(s);
        } catch (_) {}

        // ── EMPLOYEE ROWS (employee or both type) ──────────────────────────
        if (productionType == 'employee' || productionType == 'both') {
          final empQty = _parseQty(item['employeeQuantity'] ?? totalQty);
          final empRemark = (item['employeeRemark'] ?? '').toString();
          employeeRows.add(_EmployeeRow(
            srNo: 0,
            customerName: customerName,
            productName: productName,
            totalQty: totalQty,
            employeeQty: empQty,
            remark: empRemark,
            date: savedDate,
            orderId: orderId,
            productionType: productionType,
          ));
        }

        // ── CONTRACTOR ROWS (contractor or both type) ──────────────────────
        if (productionType == 'contractor' || productionType == 'both') {
          final conQty = productionType == 'both'
              ? _parseQty(item['contractorQuantity'] ?? totalQty)
              : totalQty;

          final cuttingPrice =
              double.tryParse(item['cuttingPrice']?.toString() ?? '') ?? 0;
          final pastingPrice =
              double.tryParse(item['pastingPrice']?.toString() ?? '') ?? 0;
          final cuttingContractor =
              (item['cuttingContractor'] ?? '').toString().trim().isNotEmpty
                  ? item['cuttingContractor'].toString()
                  : '-';
          final pastingContractor =
              (item['pastingContractor'] ?? '').toString().trim().isNotEmpty
                  ? item['pastingContractor'].toString()
                  : '-';

          // ── CUTTING ROW ──────────────────────────────────────────────────
          if (cuttingContractor != '-' &&
              (_workType == "Both" || _workType == "Cutting") &&
              (_selectedContractor == null ||
                  _selectedContractor!.trim().toLowerCase() ==
                      cuttingContractor.toLowerCase())) {
            final rowTotal = cuttingPrice * conQty;
            summaryMap.putIfAbsent(
              cuttingContractor,
              () => _ContractorSummary(name: cuttingContractor),
            );
            summaryMap[cuttingContractor]!.rows.add(
              _ReportRow(
                srNo: 0,
                customerName: customerName,
                productName: productName,
                qty: conQty,
                workType: "Cutting",
                pricePerUnit: cuttingPrice,
                total: rowTotal,
                date: savedDate,
                orderId: orderId,
              ),
            );
            summaryMap[cuttingContractor]!.totalCutting += rowTotal;
            summaryMap[cuttingContractor]!.totalQty += conQty;
          }

          // ── PASTING ROW ──────────────────────────────────────────────────
          if (pastingContractor != '-' &&
              (_workType == "Both" || _workType == "Pasting") &&
              (_selectedContractor == null ||
                  _selectedContractor!.trim().toLowerCase() ==
                      pastingContractor.toLowerCase())) {
            final rowTotal = pastingPrice * conQty;
            summaryMap.putIfAbsent(
              pastingContractor,
              () => _ContractorSummary(name: pastingContractor),
            );
            summaryMap[pastingContractor]!.rows.add(
              _ReportRow(
                srNo: 0,
                customerName: customerName,
                productName: productName,
                qty: conQty,
                workType: "Pasting",
                pricePerUnit: pastingPrice,
                total: rowTotal,
                date: savedDate,
                orderId: orderId,
              ),
            );
            summaryMap[pastingContractor]!.totalPasting += rowTotal;
            final alreadyCounted = (cuttingContractor == pastingContractor) &&
                (_workType == "Both");
            if (!alreadyCounted) {
              summaryMap[pastingContractor]!.totalQty += conQty;
            }
          }
        }
      }
    }

    // Re-number sr nos per contractor
    for (final s in summaryMap.values) {
      for (int r = 0; r < s.rows.length; r++) {
        s.rows[r] = s.rows[r].copyWith(srNo: r + 1);
      }
    }

    // Re-number employee rows
    for (int r = 0; r < employeeRows.length; r++) {
      employeeRows[r] = employeeRows[r].copyWith(srNo: r + 1);
    }

    double grandTotal = 0;
    int grandQty = 0;
    for (final s in summaryMap.values) {
      grandTotal += s.totalCutting + s.totalPasting;
      grandQty += s.totalQty;
    }

    final totalEmpQty = employeeRows.fold(0, (s, e) => s + e.employeeQty);

    return _ReportData(
      summaries: summaryMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
      employeeRows: employeeRows,
      grandTotal: grandTotal,
      grandQty: grandQty,
      totalEmployeeQty: totalEmpQty,
      dateRange: range,
      filterLabel: _filterType,
      workType: _workType,
    );
  }

  int _parseQty(dynamic qty) {
    if (qty is int) return qty;
    if (qty is double) return qty.toInt();
    if (qty is String) return int.tryParse(qty) ?? 0;
    return 0;
  }

  // ── PDF ACTION ─────────────────────────────────────────────────────────────
  Future<void> _generateAndDownloadPdf() async {
    setState(() => _isGenerating = true);
    try {
      final data = await _fetchReportData();
      final pdfBytes = await _buildPdf(data);
      await Printing.sharePdf(
        bytes: Uint8List.fromList(pdfBytes),
        filename:
            'contractor_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _previewPdf() async {
    setState(() => _isGenerating = true);
    try {
      final data = await _fetchReportData();
      final pdfBytes = await _buildPdf(data);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('PDF Preview'),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            body: PdfPreview(
              build: (f) => Uint8List.fromList(pdfBytes),
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── BUILD PDF ──────────────────────────────────────────────────────────────
  Future<List<int>> _buildPdf(_ReportData data) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');

    // Colors
    final primClr = PdfColor.fromHex('#169a8d');
    final darkClr = PdfColor.fromHex('#2C3E50');
    final lgrey = PdfColor.fromHex('#F4F6F8');
    final greenClr = PdfColor.fromHex('#27AE60');
    final orangeClr = PdfColor.fromHex('#E67E22');
    final blueClr = PdfColor.fromHex('#2980B9');
    final purpleClr = PdfColor.fromHex('#8E44AD');
    final hdrBg = PdfColor.fromHex('#E8F6F5');
    final empHdrBg = PdfColor.fromHex('#EBF5FB');
    final totBg = PdfColor.fromHex('#D5EDE9');
    final empTotBg = PdfColor.fromHex('#D6EAF8');

    final summaries = data.summaries;
    final empRows = data.employeeRows;

    final hasContractor = summaries.isNotEmpty;
    final hasEmployee = empRows.isNotEmpty;

    if (!hasContractor && !hasEmployee) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Text(
              'NO Data Found',
              style: pw.TextStyle(fontSize: 22, color: darkClr),
            ),
          ),
        ),
      );
      return pdf.save();
    }

    final totalCutAll = summaries.fold(0.0, (s, e) => s + e.totalCutting);
    final totalPasAll = summaries.fold(0.0, (s, e) => s + e.totalPasting);

    // ══════════════════════════════════════════════════════════════════════════
    // COVER PAGE — Contractor Summary + Employee Summary
    // ══════════════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Main header banner
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primClr,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Production Report | Contractor & Employee',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Period: ${dateFmt.format(data.dateRange.start)}    ${dateFmt.format(data.dateRange.end)}'
                    '   |   Filter: ${data.filterLabel}   |   Work: ${data.workType}',
                    style:
                        pw.TextStyle(fontSize: 9, color: PdfColors.white),
                  ),
                  pw.Text(
                    'Generated: ${dateFmt.format(DateTime.now())}',
                    style:
                        pw.TextStyle(fontSize: 9, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ── Grand stats bar
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: pw.BoxDecoration(
                color: hdrBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: primClr, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfStat('Contractors', '${summaries.length}', primClr),
                  _pdfDiv(),
                  _pdfStat('Contractor Qty', '${data.grandQty}', primClr),
                  _pdfDiv(),
                  _pdfStat(
                      'Cut Total', 'Rs. ${_fmt(totalCutAll)}', orangeClr),
                  _pdfDiv(),
                  _pdfStat(
                      'Paste Total', 'Rs. ${_fmt(totalPasAll)}', primClr),
                  _pdfDiv(),
                  _pdfStat('Contractor Grand',
                      'Rs. ${_fmt(data.grandTotal)}', greenClr),
                  _pdfDiv(),
                  _pdfStat('Employee Qty',
                      '${data.totalEmployeeQty}', blueClr),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ════════════════════════════════════════════════
            // CONTRACTOR SUMMARY TABLE
            // ════════════════════════════════════════════════
            if (hasContractor) ...[
              // Section header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: primClr,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      ' CONTRACTOR SUMMARY',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      'Total: Rs. ${_fmt(data.grandTotal)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Contractor summary table
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.0),
                  1: const pw.FixedColumnWidth(42),
                  2: const pw.FixedColumnWidth(42),
                  3: const pw.FlexColumnWidth(1.6),
                  4: const pw.FlexColumnWidth(1.8),
                  5: const pw.FlexColumnWidth(1.8),
                  6: const pw.FlexColumnWidth(1.9),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primClr),
                    children: [
                      _th('Contractor'),
                      _th('Entries'),
                      _th('Qty'),
                      _th('Avg Rate/Pc'),
                      _th('Cutting (Rs.)'),
                      _th('Pasting (Rs.)'),
                      _th('Total (Rs.)'),
                    ],
                  ),
                  ...summaries.asMap().entries.map((e) {
                    final s = e.value;
                    final tot = s.totalCutting + s.totalPasting;
                    final avgRate =
                        s.totalQty > 0 ? tot / s.totalQty : 0.0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color:
                            e.key % 2 == 0 ? PdfColors.white : lgrey,
                      ),
                      children: [
                        _td(s.name),
                        _tdCenter('${s.rows.length}'),
                        _tdCenter('${s.totalQty}'),
                        _tdRight('Rs. ${_fmt(avgRate)}'),
                        _tdRight(s.totalCutting > 0
                            ? 'Rs. ${_fmt(s.totalCutting)}'
                            : '-'),
                        _tdRight(s.totalPasting > 0
                            ? 'Rs. ${_fmt(s.totalPasting)}'
                            : '-'),
                        _tdRight('Rs. ${_fmt(tot)}',
                            bold: true, color: greenClr),
                      ],
                    );
                  }),
                  // Grand total row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: totBg),
                    children: [
                      _tdBold('GRAND TOTAL'),
                      _tdCenter(
                        '${summaries.fold(0, (s, e) => s + e.rows.length)}',
                        bold: true,
                      ),
                      _tdCenter('${data.grandQty}', bold: true),
                      _tdRight(
                        data.grandQty > 0
                            ? 'Rs. ${_fmt(data.grandTotal / data.grandQty)}'
                            : '-',
                        bold: true,
                      ),
                      _tdRight('Rs. ${_fmt(totalCutAll)}', bold: true),
                      _tdRight('Rs. ${_fmt(totalPasAll)}', bold: true),
                      _tdRight('Rs. ${_fmt(data.grandTotal)}',
                          bold: true, color: greenClr),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
            ],

            // ════════════════════════════════════════════════
            // EMPLOYEE SUMMARY TABLE (on cover page)
            // ════════════════════════════════════════════════
            if (hasEmployee) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: blueClr,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'EMPLOYEE SUMMARY',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      'Total Employee Qty: ${data.totalEmployeeQty}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Employee stats banner
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: empHdrBg,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: blueClr, width: 0.6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _pdfStat('Total Entries', '${empRows.length}', blueClr),
                    _pdfDiv(),
                    _pdfStat(
                        'Total Qty', '${data.totalEmployeeQty}', blueClr),
                    _pdfDiv(),
                    _pdfStat(
                      'Employee Only',
                      '${empRows.where((e) => e.productionType == 'employee').length}',
                      purpleClr,
                    ),
                    _pdfDiv(),
                    _pdfStat(
                      'Both Type',
                      '${empRows.where((e) => e.productionType == 'both').length}',
                      greenClr,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // ══════════════════════════════════════════════════════════════════════════
    // CONTRACTOR DETAIL PAGES (one per contractor)
    // ══════════════════════════════════════════════════════════════════════════
    for (final summary in summaries) {
      final contractorTotal = summary.totalCutting + summary.totalPasting;
      final chunks = _chunk(summary.rows, 22);

      for (int ci = 0; ci < chunks.length; ci++) {
        final chunk = chunks[ci];
        final isFirst = ci == 0;
        final isLast = ci == chunks.length - 1;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(22),
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Page header (Contractor)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: primClr,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '🔧  ${summary.name}',
                            style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            'Contractor Detail Report  |  ${data.filterLabel}'
                            '  |  Total Entries: ${summary.rows.length}',
                            style: pw.TextStyle(
                                fontSize: 9, color: PdfColors.white),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Page ${ci + 1}/${chunks.length}',
                        style: pw.TextStyle(
                            fontSize: 10, color: PdfColors.white),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Summary stats (first page only)
                if (isFirst)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: hdrBg,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: primClr, width: 0.5),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _pdfStat(
                            'Entries', '${summary.rows.length}', primClr),
                        _pdfDiv(),
                        _pdfStat(
                            'Total Qty', '${summary.totalQty}', primClr),
                        _pdfDiv(),
                        _pdfStat(
                          'Avg Rate/Pc',
                          summary.totalQty > 0
                              ? 'Rs. ${_fmt(contractorTotal / summary.totalQty)}'
                              : '-',
                          darkClr,
                        ),
                        if (summary.totalCutting > 0) ...[
                          _pdfDiv(),
                          _pdfStat('Cutting',
                              'Rs. ${_fmt(summary.totalCutting)}', orangeClr),
                        ],
                        if (summary.totalPasting > 0) ...[
                          _pdfDiv(),
                          _pdfStat('Pasting',
                              'Rs. ${_fmt(summary.totalPasting)}', primClr),
                        ],
                        _pdfDiv(),
                        _pdfStat('Grand Total',
                            'Rs. ${_fmt(contractorTotal)}', greenClr),
                      ],
                    ),
                  ),

                if (isFirst) pw.SizedBox(height: 8),

                // ── Detail table (Contractor)
                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(22),
                    1: const pw.FlexColumnWidth(2.0),
                    2: const pw.FlexColumnWidth(2.2),
                    3: const pw.FixedColumnWidth(28),
                    4: const pw.FixedColumnWidth(42),
                    5: const pw.FlexColumnWidth(1.5),
                    6: const pw.FlexColumnWidth(2.0),
                    7: const pw.FlexColumnWidth(1.8),
                    8: const pw.FlexColumnWidth(1.3),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: primClr),
                      children: [
                        _th('#'),
                        _th('Customer'),
                        _th('Product'),
                        _th('Qty'),
                        _th('Type'),
                        _th('Rate/Pc'),
                        _th('Qty × Rate'),
                        _th('Total'),
                        _th('Date'),
                      ],
                    ),
                    ...chunk.asMap().entries.map((entry) {
                      final row = entry.value;
                      final isEven = entry.key % 2 == 0;
                      final typeClr = row.workType == "Cutting"
                          ? orangeClr
                          : greenClr;
                      final typeBg = row.workType == "Cutting"
                          ? PdfColor.fromHex('#FEF0E6')
                          : PdfColor.fromHex('#E8F8EF');
                      final qtyRateLabel =
                          '${row.qty} × ${_fmt(row.pricePerUnit)}';

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isEven ? PdfColors.white : lgrey,
                        ),
                        children: [
                          _tdSC('${row.srNo}'),
                          _tdS(row.customerName),
                          _tdS(row.productName),
                          _tdSC('${row.qty}'),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 3, vertical: 3),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: typeBg,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                row.workType,
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold,
                                  color: typeClr,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ),
                          _tdSR(_fmt(row.pricePerUnit)),
                          _tdSR(qtyRateLabel,
                              color: PdfColor.fromHex('#555555')),
                          _tdSR(_fmt(row.total),
                              bold: true, color: greenClr),
                          _tdS(row.date != null
                              ? dateFmt.format(row.date!)
                              : '-'),
                        ],
                      );
                    }),
                  ],
                ),

                pw.Spacer(),

                // Final footer (last page)
                if (isLast)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: totBg,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: primClr, width: 0.8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${summary.name} — Final',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: darkClr,
                          ),
                        ),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Entries: ${summary.rows.length}  |  Qty: ${summary.totalQty}',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: darkClr),
                            ),
                            pw.Text(
                              '  |  Avg: Rs.${summary.totalQty > 0 ? _fmt(contractorTotal / summary.totalQty) : '0.00'}',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: darkClr),
                            ),
                            if (summary.totalCutting > 0)
                              pw.Text(
                                '  |  Cut: Rs.${_fmt(summary.totalCutting)}',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: orangeClr),
                              ),
                            if (summary.totalPasting > 0)
                              pw.Text(
                                '  |  Paste: Rs.${_fmt(summary.totalPasting)}',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primClr),
                              ),
                            pw.Text(
                              '  |  Total: Rs.${_fmt(contractorTotal)}',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: greenClr),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // EMPLOYEE DETAIL PAGES
    // ══════════════════════════════════════════════════════════════════════════
    if (hasEmployee) {
      final empChunks = _chunk(empRows, 25);

      for (int ci = 0; ci < empChunks.length; ci++) {
        final chunk = empChunks[ci];
        final isFirst = ci == 0;
        final isLast = ci == empChunks.length - 1;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(22),
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Page header (Employee) — BLUE color
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: blueClr,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            ' EMPLOYEE PRODUCTION DETAIL',
                            style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            'Period: ${dateFmt.format(data.dateRange.start)}    ${dateFmt.format(data.dateRange.end)}'
                            '  |  Filter: ${data.filterLabel}'
                            '  |  Total Entries: ${empRows.length}',
                            style: pw.TextStyle(
                                fontSize: 9, color: PdfColors.white),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Page ${ci + 1}/${empChunks.length}',
                        style: pw.TextStyle(
                            fontSize: 10, color: PdfColors.white),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Employee stats banner (first page only)
                if (isFirst)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: empHdrBg,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: blueClr, width: 0.5),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _pdfStat(
                            'Total Entries', '${empRows.length}', blueClr),
                        _pdfDiv(),
                        _pdfStat('Total Qty',
                            '${data.totalEmployeeQty}', blueClr),
                        _pdfDiv(),
                        _pdfStat(
                          'Employee Only',
                          '${empRows.where((e) => e.productionType == 'employee').length}',
                          purpleClr,
                        ),
                        _pdfDiv(),
                        _pdfStat(
                          'Both Type',
                          '${empRows.where((e) => e.productionType == 'both').length}',
                          greenClr,
                        ),
                      ],
                    ),
                  ),

                if (isFirst) pw.SizedBox(height: 8),

                // ── Employee detail table
                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(22),  // #
                    1: const pw.FlexColumnWidth(2.2),  // Customer
                    2: const pw.FlexColumnWidth(2.5),  // Product
                    3: const pw.FixedColumnWidth(38),  // Total Qty
                    4: const pw.FixedColumnWidth(42),  // Emp Qty
                    5: const pw.FixedColumnWidth(52),  // Type
                    6: const pw.FlexColumnWidth(2.5),  // Remark
                    7: const pw.FlexColumnWidth(1.5),  // Date
                  },
                  children: [
                    // Header row — blue background
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: blueClr),
                      children: [
                        _th('#'),
                        _th('Customer'),
                        _th('Product'),
                        _th('Total Qty'),
                        _th('Emp Qty'),
                        _th('Type'),
                        _th('Remark'),
                        _th('Date'),
                      ],
                    ),

                    // Data rows
                    ...chunk.asMap().entries.map((entry) {
                      final row = entry.value;
                      final isEven = entry.key % 2 == 0;

                      // Type badge color
                      final typeClr = row.productionType == 'both'
                          ? greenClr
                          : purpleClr;
                      final typeBg = row.productionType == 'both'
                          ? PdfColor.fromHex('#E8F8EF')
                          : PdfColor.fromHex('#F4ECF7');
                      final typeLabel = row.productionType == 'both'
                          ? 'Emp+Con'
                          : 'Employee';

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isEven ? PdfColors.white : lgrey,
                        ),
                        children: [
                          _tdSC('${row.srNo}'),
                          _tdS(row.customerName),
                          _tdS(row.productName),
                          _tdSC('${row.totalQty}'),
                          // Employee Qty — highlighted
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 3, vertical: 3),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('#EBF5FB'),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                '${row.employeeQty}',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: blueClr,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ),
                          // Production type badge
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 3, vertical: 3),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: typeBg,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                typeLabel,
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold,
                                  color: typeClr,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ),
                          _tdS(row.remark.isNotEmpty ? row.remark : '-'),
                          _tdS(row.date != null
                              ? dateFmt.format(row.date!)
                              : '-'),
                        ],
                      );
                    }),
                  ],
                ),

                pw.Spacer(),

                // Employee final footer (last page)
                if (isLast)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: empTotBg,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: blueClr, width: 0.8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Employee Production — Final Summary',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: darkClr,
                          ),
                        ),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Total Entries: ${empRows.length}',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: darkClr),
                            ),
                            pw.Text(
                              '  |  Total Employee Qty: ${data.totalEmployeeQty}',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: blueClr),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    return pdf.save();
  }

  // ── PDF helper widgets ─────────────────────────────────────────────────────
  static pw.Widget _pdfStat(String lbl, String val, PdfColor c) =>
      pw.Column(
        children: [
          pw.Text(lbl,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Text(val,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: c)),
        ],
      );

  static pw.Widget _pdfDiv() =>
      pw.Container(height: 28, width: 0.5, color: PdfColors.grey400);

  static pw.Widget _th(String t) => pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            textAlign: pw.TextAlign.center),
      );

  static pw.Widget _td(String t) => pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(t, style: const pw.TextStyle(fontSize: 9)),
      );

  static pw.Widget _tdBold(String t) => pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _tdRight(String t,
          {bool bold = false, PdfColor? color}) =>
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(t,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
            textAlign: pw.TextAlign.right),
      );

  static pw.Widget _tdCenter(String t, {bool bold = false}) =>
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal),
            textAlign: pw.TextAlign.center),
      );

  static pw.Widget _tdS(String t) => pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: pw.Text(t, style: const pw.TextStyle(fontSize: 7.5)),
      );

  static pw.Widget _tdSC(String t) => pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: pw.Text(t,
            style: const pw.TextStyle(fontSize: 7.5),
            textAlign: pw.TextAlign.center),
      );

  static pw.Widget _tdSR(String t,
          {bool bold = false, PdfColor? color}) =>
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: pw.Text(t,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
            textAlign: pw.TextAlign.right),
      );

  static String _fmt(double v) => NumberFormat('#,##,##0.00').format(v);

  static List<List<T>> _chunk<T>(List<T> list, int size) {
    if (list.isEmpty) return [[]];
    final out = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      out.add(list.sublist(
          i, i + size > list.length ? list.length : i + size));
    }
    return out;
  }

  // ── MAIN UI ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contractor Report',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              'PDF generate karein',
              style: TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ),
      ),
      body: _loadingContractors
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Date Filter ──
                  _sectionCard(
                    title: '📅 Date Filter',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _filterChips(),
                        if (_filterType == "Custom" &&
                            _customRange != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${DateFormat('dd/MM/yyyy').format(_customRange!.start)}'
                                ' – ${DateFormat('dd/MM/yyyy').format(_customRange!.end)}',
                                style: const TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Work Type ──
                  _sectionCard(
                    title: '🔧 Work Type',
                    child: Row(
                      children: ["Cutting", "Pasting", "Both"]
                          .map(
                            (t) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(t),
                                  selected: _workType == t,
                                  selectedColor:
                                      _primary.withOpacity(0.15),
                                  labelStyle: TextStyle(
                                    color: _workType == t
                                        ? _primary
                                        : Colors.grey.shade700,
                                    fontWeight: _workType == t
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (_) {
                                    setState(() => _workType = t);
                                    _refreshPreview();
                                  },
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Contractor Dropdown ──
                  _sectionCard(
                    title: '👷 Contractor Select',
                    child: DropdownButtonFormField<String>(
                      value: _selectedContractor,
                      decoration: InputDecoration(
                        hintText: 'All Contractors (default)',
                        prefixIcon: const Icon(Icons.person_search,
                            color: _primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Contractors'),
                        ),
                        ..._allContractors.map(
                          (c) => DropdownMenuItem(
                              value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedContractor = v);
                        _refreshPreview();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Live Preview ──
                  FutureBuilder<_ReportData>(
                    key: _previewKey,
                    future: _previewFuture,
                    builder: (context, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: _primary),
                        );
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text('Error: ${snap.error}',
                              style:
                                  const TextStyle(color: Colors.red)),
                        );
                      }
                      if (!snap.hasData ||
                          (snap.data!.summaries.isEmpty &&
                              snap.data!.employeeRows.isEmpty)) {
                        return _emptyState();
                      }
                      final d = snap.data!;
                      final totalCut = d.summaries
                          .fold(0.0, (s, e) => s + e.totalCutting);
                      final totalPas = d.summaries
                          .fold(0.0, (s, e) => s + e.totalPasting);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Contractor summary card
                          if (d.summaries.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF169a8d),
                                    Color(0xFF0d7c70)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    '🔧 CONTRACTOR',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _sw('Contractors',
                                          '${d.summaries.length}'),
                                      _svDiv(),
                                      _sw('Total Qty',
                                          '${d.grandQty}'),
                                      _svDiv(),
                                      _sw('Grand Total',
                                          'Rs. ${_fmt(d.grandTotal)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _sw('Cutting',
                                          'Rs. ${_fmt(totalCut)}'),
                                      _svDiv(),
                                      _sw('Pasting',
                                          'Rs. ${_fmt(totalPas)}'),
                                      _svDiv(),
                                      _sw(
                                        'Avg Rate/Pc',
                                        d.grandQty > 0
                                            ? 'Rs. ${_fmt(d.grandTotal / d.grandQty)}'
                                            : '-',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Contractor Breakdown',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _darkText),
                            ),
                            const SizedBox(height: 10),
                            ...d.summaries
                                .map((s) => _contractorPreviewCard(s)),
                          ],

                          // ── Employee summary card
                          if (d.employeeRows.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2980B9),
                                    Color(0xFF1A5276)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    '👷 EMPLOYEE',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _sw('Total Entries',
                                          '${d.employeeRows.length}'),
                                      _svDiv(),
                                      _sw('Total Qty',
                                          '${d.totalEmployeeQty}'),
                                      _svDiv(),
                                      _sw(
                                        'Both Type',
                                        '${d.employeeRows.where((e) => e.productionType == 'both').length}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Employee Entries',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _darkText),
                            ),
                            const SizedBox(height: 10),
                            ...d.employeeRows
                                .map((r) => _employeePreviewCard(r)),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.preview_rounded, color: _primary),
                label: const Text('Preview',
                    style: TextStyle(color: _primary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isGenerating ? null : _previewPdf,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: _isGenerating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(
                    _isGenerating ? 'Generating...' : 'Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isGenerating ? null : _generateAndDownloadPdf,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ["Today", "1 Week", "1 Month", "Custom"].map((f) {
            final sel = _filterType == f;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(f),
                selected: sel,
                selectedColor: _primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: sel ? _primary : Colors.grey.shade700,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (v) async {
                  setState(() => _filterType = f);
                  if (f == "Custom") {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme:
                              const ColorScheme.light(primary: _primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _customRange = picked);
                    }
                  }
                  _refreshPreview();
                },
              ),
            );
          }).toList(),
        ),
      );

  Widget _sectionCard(
          {required String title, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _darkText)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  Widget _contractorPreviewCard(_ContractorSummary s) {
    final total = s.totalCutting + s.totalPasting;
    final avgRate = s.totalQty > 0 ? total / s.totalQty : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.engineering,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _darkText)),
              ),
              Text('Rs. ${_fmt(total)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF27AE60))),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _sc(Icons.receipt_long_outlined,
                  '${s.rows.length} Entries',
                  Colors.purple.shade700,
                  Colors.purple.shade50),
              _sc(Icons.inventory_2_outlined, 'Qty: ${s.totalQty}',
                  Colors.blue.shade700, Colors.blue.shade50),
              _sc(Icons.price_change_outlined,
                  'Avg: Rs.${_fmt(avgRate)}',
                  Colors.indigo.shade700,
                  Colors.indigo.shade50),
              if (s.totalCutting > 0)
                _sc(Icons.cut, 'Cut: Rs.${_fmt(s.totalCutting)}',
                    Colors.orange.shade700, Colors.orange.shade50),
              if (s.totalPasting > 0)
                _sc(Icons.layers, 'Paste: Rs.${_fmt(s.totalPasting)}',
                    _primary, const Color(0xFFE8F6F5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _employeePreviewCard(_EmployeeRow r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Color(0xFF2980B9), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.customerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _darkText)),
                Text(r.productName,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Emp Qty: ${r.employeeQty}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2980B9),
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                r.productionType == 'both' ? 'Emp+Con' : 'Employee',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sc(IconData icon, String label, Color color, Color bg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _sw(String label, String value) => Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      );

  Widget _svDiv() =>
      Container(height: 36, width: 1, color: Colors.white24);

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox_rounded,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('NO Data Found',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkText)),
              const SizedBox(height: 8),
              Text(
                'Filter change karein ya data add karein.',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _ReportData {
  final List<_ContractorSummary> summaries;
  final List<_EmployeeRow> employeeRows;
  final double grandTotal;
  final int grandQty;
  final int totalEmployeeQty;
  final DateTimeRange dateRange;
  final String filterLabel;
  final String workType;

  _ReportData({
    required this.summaries,
    required this.employeeRows,
    required this.grandTotal,
    required this.grandQty,
    required this.totalEmployeeQty,
    required this.dateRange,
    required this.filterLabel,
    required this.workType,
  });
}

class _ContractorSummary {
  final String name;
  final List<_ReportRow> rows = [];
  double totalCutting = 0;
  double totalPasting = 0;
  int totalQty = 0;
  _ContractorSummary({required this.name});
}

class _ReportRow {
  final int srNo;
  final String customerName;
  final String productName;
  final int qty;
  final String workType;
  final double pricePerUnit;
  final double total;
  final DateTime? date;
  final String orderId;

  const _ReportRow({
    required this.srNo,
    required this.customerName,
    required this.productName,
    required this.qty,
    required this.workType,
    required this.pricePerUnit,
    required this.total,
    required this.orderId,
    this.date,
  });

  _ReportRow copyWith({int? srNo}) => _ReportRow(
        srNo: srNo ?? this.srNo,
        customerName: customerName,
        productName: productName,
        qty: qty,
        workType: workType,
        pricePerUnit: pricePerUnit,
        total: total,
        date: date,
        orderId: orderId,
      );
}

class _EmployeeRow {
  final int srNo;
  final String customerName;
  final String productName;
  final int totalQty;
  final int employeeQty;
  final String remark;
  final DateTime? date;
  final String orderId;
  final String productionType; // 'employee' or 'both'

  const _EmployeeRow({
    required this.srNo,
    required this.customerName,
    required this.productName,
    required this.totalQty,
    required this.employeeQty,
    required this.remark,
    required this.orderId,
    required this.productionType,
    this.date,
  });

  _EmployeeRow copyWith({int? srNo}) => _EmployeeRow(
        srNo: srNo ?? this.srNo,
        customerName: customerName,
        productName: productName,
        totalQty: totalQty,
        employeeQty: employeeQty,
        remark: remark,
        date: date,
        orderId: orderId,
        productionType: productionType,
      );
}