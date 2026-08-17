import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:ui' as ui;

String _hsnForCategory(String? category) {
  if (category == 'MDF') return '44111200';
  if (category == 'Laddu Paper') return '48062000';
  return '48192090';
}

double _gstPctForCategory(String? category) {
  if (category == 'MDF') return 18.0;
  if (category == 'Laddu Paper') return 18.0;
  return 5.0;
}

class JobCardHistoryTab extends StatefulWidget {
  const JobCardHistoryTab({super.key});
  @override
  State<JobCardHistoryTab> createState() => _JobCardHistoryTabState();
}

class _JobCardHistoryTabState extends State<JobCardHistoryTab>
    with SingleTickerProviderStateMixin {
  String _searchText = '';
  DateTimeRange? _selectedDateRange;
  String _selectedDateFilter = 'All';
  String _selectedUnit = 'All';
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

  void _showDownloadOptionsDialog(
    BuildContext context,
    Map<String, dynamic> job,
  ) {
    final List products = job['products'] ?? [];

    // detect which sections exist
    bool hasTray = false, hasSalophin = false, hasBoxCover = false;
    bool hasInner = false, hasBottom = false, hasDie = false;
    bool hasOther = false, hasExtra = false;

    for (var product in products) {
      final sections = product['sections'] as Map<String, dynamic>? ?? {};
      if ((sections['trayDetail'] ?? '').toString().isNotEmpty) hasTray = true;
      if ((sections['salophinDetail'] ?? '').toString().isNotEmpty)
        hasSalophin = true;
      if ((sections['boxCoverDetail'] ?? '').toString().isNotEmpty)
        hasBoxCover = true;
      if ((sections['innerDetail'] ?? '').toString().isNotEmpty)
        hasInner = true;
      if ((sections['bottomDetail'] ?? '').toString().isNotEmpty)
        hasBottom = true;
      if ((sections['dieDetail'] ?? '').toString().isNotEmpty) hasDie = true;
      if ((sections['otherDetail'] ?? '').toString().isNotEmpty)
        hasOther = true;
      if ((product['customExtraSections'] as List? ?? []).isNotEmpty)
        hasExtra = true;
    }

    // section checkboxes
    bool includeTray = hasTray;
    bool includeSalophin = hasSalophin;
    bool includeBoxCover = hasBoxCover;
    bool includeInner = hasInner;
    bool includeBottom = hasBottom;
    bool includeDie = hasDie;
    bool includeOther = hasOther;
    bool includeExtra = hasExtra;

    // terms checkboxes
    bool include50Advance = false;
    bool includeBalance = false;
    bool includePaymentTerms = true;
    bool includeFreightTerms = true;
    bool includePackingTerms = true;
    bool includeGSTTerms = true;


    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 20,
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.purple.shade50.withOpacity(0.3),
                      Colors.blue.shade50.withOpacity(0.3),
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.blue.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.cloud_download_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (b) => LinearGradient(
                                    colors: [
                                      Colors.purple.shade700,
                                      Colors.blue.shade700,
                                    ],
                                  ).createShader(b),
                                  child: const Text(
                                    'Download Options',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Choose sections to include',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (hasTray ||
                          hasSalophin ||
                          hasBoxCover ||
                          hasInner ||
                          hasBottom ||
                          hasDie ||
                          hasOther ||
                          hasExtra) ...[
                        _buildDialogSectionBox(
                          title: 'Product Sections',
                          color: Colors.purple,
                          children: [
                            if (hasTray)
                              _buildCheckboxTile(
                                'Tray',
                                includeTray,
                                (v) => setDialogState(
                                  () => includeTray = v ?? true,
                                ),
                              ),
                            if (hasSalophin)
                              _buildCheckboxTile(
                                'Salophin',
                                includeSalophin,
                                (v) => setDialogState(
                                  () => includeSalophin = v ?? true,
                                ),
                              ),
                            if (hasBoxCover)
                              _buildCheckboxTile(
                                'Box Cover',
                                includeBoxCover,
                                (v) => setDialogState(
                                  () => includeBoxCover = v ?? true,
                                ),
                              ),
                            if (hasInner)
                              _buildCheckboxTile(
                                'Inner',
                                includeInner,
                                (v) => setDialogState(
                                  () => includeInner = v ?? true,
                                ),
                              ),
                            if (hasBottom)
                              _buildCheckboxTile(
                                'Bottom',
                                includeBottom,
                                (v) => setDialogState(
                                  () => includeBottom = v ?? true,
                                ),
                              ),
                            if (hasDie)
                              _buildCheckboxTile(
                                'Die',
                                includeDie,
                                (v) => setDialogState(
                                  () => includeDie = v ?? true,
                                ),
                              ),
                            if (hasOther)
                              _buildCheckboxTile(
                                'Other',
                                includeOther,
                                (v) => setDialogState(
                                  () => includeOther = v ?? true,
                                ),
                              ),
                            if (hasExtra)
                              _buildCheckboxTile(
                                'Extra Sections',
                                includeExtra,
                                (v) => setDialogState(
                                  () => includeExtra = v ?? true,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildDialogSectionBox(
                        title: 'Terms & Conditions',
                        color: Colors.blue,
                        children: [
                          _buildCheckboxTile(
                            '50% advance payment is required to commence production',
                            include50Advance,
                            (v) => setDialogState(
                              () => include50Advance = v ?? false,
                            ),
                          ),
                          _buildCheckboxTile('Balance payment must be paid before dispatch.', includeBalance,
                           (v) => setDialogState(() => includeBalance = v ?? false)),
                          _buildCheckboxTile(
                            'Goods will be dispatched only after receipt of full payment.',
                            includePaymentTerms,
                            (v) => setDialogState(
                              () => includePaymentTerms = v ?? true,
                            ),
                          ),
                          _buildCheckboxTile(
                            'Freight charges are extra.',
                            includeFreightTerms,
                            (v) => setDialogState(
                              () => includeFreightTerms = v ?? true,
                            ),
                          ),
                          _buildCheckboxTile(
                            'Packing charges are extra.',
                            includePackingTerms,
                            (v) => setDialogState(
                              () => includePackingTerms = v ?? true,
                            ),
                          ),
                          _buildCheckboxTile(
                            'GST will be charged as per applicable rates (MDF Products - 18%; Cardboard Boxes - 5%).',
                            includeGSTTerms,
                            (v) => setDialogState(
                              () => includeGSTTerms = v ?? true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── PDF Standard ────────────────────────────────────
                      _buildDownloadButton(
                        label: 'Download PDF (Standard)',
                        subtitle: 'Images, GST breakdown — no HSN codes',
                        icon: Icons.picture_as_pdf_rounded,
                        colors: [Colors.red.shade500, Colors.red.shade700],
                        onTap: () {
                          Navigator.pop(context);
                          _generateAndDownloadPDF(
                            context,
                            job,
                            withHsn: false,
                            sectionOptions: _buildSectionOptions(
                              includeTray: includeTray,
                              includeSalophin: includeSalophin,
                              includeBoxCover: includeBoxCover,
                              includeInner: includeInner,
                              includeBottom: includeBottom,
                              includeDie: includeDie,
                              includeOther: includeOther,
                              includeExtra: includeExtra,
                              include50Advance: include50Advance,
                              includeBalance: includeBalance,
                              includePaymentTerms: includePaymentTerms,
                              includeFreightTerms: includeFreightTerms,
                              includePackingTerms: includePackingTerms,
                              includeGSTTerms: includeGSTTerms,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // ── PDF With HSN ────────────────────────────────────
                      _buildDownloadButton(
                        label: 'Download PDF (With HSN Codes)',
                        subtitle:
                            'MDF: 44111200 | Laddu Paper: 48062000 | Others: 48192090',
                        icon: Icons.receipt_long_rounded,
                        colors: [
                          Colors.indigo.shade500,
                          Colors.indigo.shade700,
                        ],
                        onTap: () {
                          Navigator.pop(context);
                          _generateAndDownloadPDF(
                            context,
                            job,
                            withHsn: true,
                            sectionOptions: _buildSectionOptions(
                              includeTray: includeTray,
                              includeSalophin: includeSalophin,
                              includeBoxCover: includeBoxCover,
                              includeInner: includeInner,
                              includeBottom: includeBottom,
                              includeDie: includeDie,
                              includeOther: includeOther,
                              includeExtra: includeExtra,
                              include50Advance: include50Advance,
                              includeBalance: includeBalance,
                              includePaymentTerms: includePaymentTerms,
                              includeFreightTerms: includeFreightTerms,
                              includePackingTerms: includePackingTerms,
                              includeGSTTerms: includeGSTTerms,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // ── JPG ─────────────────────────────────────────────
                      _buildDownloadButton(
                        label: 'Download JPG',
                        subtitle: 'Each page saved as separate image',
                        icon: Icons.image_rounded,
                        colors: [Colors.blue.shade500, Colors.blue.shade700],
                        onTap: () {
                          Navigator.pop(context);
                          _generateAndDownloadJPG(
                            context,
                            job,
                            sectionOptions: _buildSectionOptions(
                              includeTray: includeTray,
                              includeSalophin: includeSalophin,
                              includeBoxCover: includeBoxCover,
                              includeInner: includeInner,
                              includeBottom: includeBottom,
                              includeDie: includeDie,
                              includeOther: includeOther,
                              includeExtra: includeExtra,
                              include50Advance: include50Advance,
                              includeBalance: includeBalance,
                              includePaymentTerms: includePaymentTerms,
                              includeFreightTerms: includeFreightTerms,
                              includePackingTerms: includePackingTerms,
                              includeGSTTerms: includeGSTTerms,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Cancel ──────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, bool> _buildSectionOptions({
    required bool includeTray,
    required bool includeSalophin,
    required bool includeBoxCover,
    required bool includeInner,
    required bool includeBottom,
    required bool includeDie,
    required bool includeOther,
    required bool includeExtra,
    required bool include50Advance,
    required bool includeBalance,
    required bool includePaymentTerms,
    required bool includeFreightTerms,
    required bool includePackingTerms,
    required bool includeGSTTerms,
  }) {
    return {
      'tray': includeTray,
      'salophin': includeSalophin,
      'boxCover': includeBoxCover,
      'inner': includeInner,
      'bottom': includeBottom,
      'die': includeDie,
      'other': includeOther,
      'extra': includeExtra,
      'advance50': include50Advance,
      'balancePayment': includeBalance,
      'paymentTerms': includePaymentTerms,
      'freightTerms': includeFreightTerms,
      'packingTerms': includePackingTerms,
      'gstTerms': includeGSTTerms,
    };
  }

  // ── Helper: dialog section box ─────────────────────────────────────────────
  Widget _buildDialogSectionBox({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── Helper: checkbox tile ──────────────────────────────────────────────────
  Widget _buildCheckboxTile(
    String title,
    bool value,
    Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      activeColor: Colors.purple.shade600,
      checkColor: Colors.white,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  // ── Helper: download button ────────────────────────────────────────────────
  Widget _buildDownloadButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════
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

  // ══════════════════════════════════════════════════════════════════════════
  // PDF GENERATION — with withHsn flag
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateAndDownloadPDF(
    BuildContext buttonContext,
    Map<String, dynamic> job, {
    required bool withHsn,
    required Map<String, bool> sectionOptions,
  }) async {
    BuildContext? loadingContext;
    showDialog(
      context: buttonContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        loadingContext = ctx;
        return WillPopScope(
          onWillPop: () async => false,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
    try {
      final pdfData = await _generatePDFData(
        job,
        withHsn: withHsn,
        sectionOptions: sectionOptions,
      );
      final jobNo = job['jobCardNumber'] ?? job['jobNo'] ?? 'N/A';
      await Printing.layoutPdf(
        onLayout: (_) async => pdfData,
        name: withHsn
            ? 'SalesOrder_${jobNo}_WithHSN.pdf'
            : 'SalesOrder_$jobNo.pdf',
      );
      if (buttonContext.mounted) {
        ScaffoldMessenger.of(buttonContext).showSnackBar(
          SnackBar(
            content: const Text('PDF Saved Successfully!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (buttonContext.mounted) {
        ScaffoldMessenger.of(buttonContext).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      if (loadingContext != null && loadingContext!.mounted) {
        Navigator.of(loadingContext!).pop();
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PDF DATA BUILDER — A to Z matching OrderHistoryScreen PDF
  // ══════════════════════════════════════════════════════════════════════════
  Future<Uint8List> _generatePDFData(
    Map<String, dynamic> job, {
    required bool withHsn,
    required Map<String, bool> sectionOptions,
  }) async {
    final pdf = pw.Document();
    final ByteData qrData = await rootBundle.load(
  'assets/qr.jpeg',
);

final qrImage = pw.MemoryImage(
  qrData.buffer.asUint8List(),
);
    final List products = job['products'] ?? [];

    // ── Logo ──────────────────────────────────────────────────────────────
    pw.ImageProvider? logoImage;
    try {
      final data = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/dpl.png');
        logoImage = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {}
    }

    // ── Dates ─────────────────────────────────────────────────────────────
    DateTime orderDate;
    if (job['orderDate'] is Timestamp) {
      orderDate = (job['orderDate'] as Timestamp).toDate();
    } else if (job['date'] is Timestamp) {
      orderDate = (job['date'] as Timestamp).toDate();
    } else if (job['createdAt'] is Timestamp) {
      orderDate = (job['createdAt'] as Timestamp).toDate();
    } else {
      orderDate = DateTime.now();
    }
    final String orderDateStr = DateFormat('dd-MM-yyyy').format(orderDate);

    final String customerName = job['customerName'] ?? job['customer'] ?? 'N/A';
    final String companyName =
        job['companyName'] ?? job['company'] ?? job['firmName'] ?? '';

    // ── Load product images ───────────────────────────────────────────────
    final List<Map<String, dynamic>> productsWithImages = [];

    for (var product in products) {
      final images = product['images'] as List<dynamic>? ?? [];
      final List<pw.MemoryImage> pdfImages = [];
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

      final String category =
          product['productCategory'] ?? product['category'] ?? '';
      final double gstPct =
          (product['gstPercent'] ?? _gstPctForCategory(category)).toDouble();
      final double qty =
          double.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
      final double price =
          double.tryParse(product['price']?.toString() ?? '0') ?? 0;
      final double subAmount = qty * price;
      final double gstAmt = (product['gstAmount'] != null)
          ? (product['gstAmount'] as num).toDouble()
          : subAmount * gstPct / 100;

      // sections sub-totals (from section prices)
      final sections = product['sections'] as Map<String, dynamic>? ?? {};
      double sectionSubAmt = 0;
      if (sectionOptions['tray'] == true)
        sectionSubAmt += _calcAmount(
          sections['trayQty'],
          sections['trayPrice'],
        );
      if (sectionOptions['salophin'] == true)
        sectionSubAmt += _calcAmount(
          sections['salophinQty'],
          sections['salophinPrice'],
        );
      if (sectionOptions['boxCover'] == true)
        sectionSubAmt += _calcAmount(
          sections['boxCoverQty'],
          sections['boxCoverPrice'],
        );
      if (sectionOptions['inner'] == true)
        sectionSubAmt += _calcAmount(
          sections['innerQty'],
          sections['innerPrice'],
        );
      if (sectionOptions['bottom'] == true)
        sectionSubAmt += _calcAmount(
          sections['bottomQty'],
          sections['bottomPrice'],
        );
      if (sectionOptions['die'] == true)
        sectionSubAmt += _calcAmount(sections['dieQty'], sections['diePrice']);
      if (sectionOptions['other'] == true)
        sectionSubAmt += _calcAmount(
          sections['otherQty'],
          sections['otherPrice'],
        );
      if (sectionOptions['extra'] == true) {
        final List extras = product['customExtraSections'] ?? [];
        for (var ex in extras) {
          sectionSubAmt += _calcAmount(ex['qty'], ex['price']);
        }
      }

      // HSN code
      final String hsnCode = (product['hsnCode']?.toString().isNotEmpty == true)
          ? product['hsnCode'].toString()
          : _hsnForCategory(category);

      productsWithImages.add({
        'productName': product['productName'] ?? product['name'] ?? 'N/A',
        'productCategory': category,
        'quantity': qty.toStringAsFixed(0),
        'price': price.toStringAsFixed(2),
        'subAmount': subAmount,
        'gstPercent': gstPct,
        'gstAmount': gstAmt,
        'amount': subAmount + gstAmt,
        'remarks': product['remarks'] ?? '',
        'pdfImages': pdfImages,
        'sections': sections,
        'customExtraSections': product['customExtraSections'] ?? [],
        'hsnCode': hsnCode,
        'sectionSubAmt': sectionSubAmt,
      });
    }

    // ── Grand totals ──────────────────────────────────────────────────────
    double subTotal = productsWithImages.fold(
      0.0,
      (s, p) => s + (p['subAmount'] as double),
    );
    double totalGst = productsWithImages.fold(
      0.0,
      (s, p) => s + (p['gstAmount'] as double),
    );
    double deliveryCharges =
        double.tryParse(job['deliveryCharges']?.toString() ?? '0') ?? 0;
    double advanceAmount =
        double.tryParse(job['advanceAmount']?.toString() ?? '0') ?? 0;
    double grandTotal = subTotal + totalGst + deliveryCharges - advanceAmount;

    // ── GST groups (for breakdown table like OrderHistoryScreen) ──────────
    final Map<double, Map<String, double>> gstGroups = {};
    for (final p in productsWithImages) {
      final pct = p['gstPercent'] as double;
      final sub = p['subAmount'] as double;
      final gst = p['gstAmount'] as double;
      gstGroups[pct] ??= {'taxable': 0.0, 'gstAmt': 0.0};
      gstGroups[pct]!['taxable'] = gstGroups[pct]!['taxable']! + sub;
      gstGroups[pct]!['gstAmt'] = gstGroups[pct]!['gstAmt']! + gst;
    }
    final sortedPcts = gstGroups.keys.toList()..sort();

    // ── Terms lines ───────────────────────────────────────────────────────
    List<String> termsLines = [];
    if (sectionOptions['advance50'] == true)
      termsLines.add(
        '50% advance payment is required to commence production.',
      );
      if (sectionOptions['balancePayment'] == true && sectionOptions['paymentTerms'] == true) {
        termsLines.add(
          'Balance payment must be paid before dispatch.',
        );
      }
    if (sectionOptions['paymentTerms'] == true)
      termsLines.add(
        'Goods will be dispatched only after receipt of full payment',
      );
    if (sectionOptions['freightTerms'] == true)
      termsLines.add('Freight charges are extra.');
    if (sectionOptions['packingTerms'] == true)
      termsLines.add('Packing charges are extra.');
    if (sectionOptions['gstTerms'] == true)
      termsLines.add('GST will be charged as per applicable rates (MDF Products - 18%; Cardboard Boxes - 5%).');

    // ═════════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return [
            // ── Header ──────────────────────────────────────────────────
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
                      'Grand Trunk Rd, Near Navdeep Resorts, Adjoining Sidak Resorts,\n'
                      'West, Bhattian Ludhiana, Punjab - 141008\n'
                      'Contact No.: 9872518000, 7888696774',
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
 pw.SizedBox(height: 5),
              pw.Divider(thickness: 1),
            pw.Center(
              child: pw.Text(
                'Estimate Order',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Sales Order: ${job['jobCardNumber'] ?? job['jobNo'] ?? 'N/A'}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height:7),

            // ── Customer + Order info ────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CUSTOMER INFORMATION',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                        pw.Divider(),
                        _pdfInfoRow(
                          'Customer',
                          companyName.isNotEmpty
                              ? '$customerName\n$companyName'
                              : customerName,
                        ),
                        _pdfInfoRow('Phone', job['phone'] ?? 'N/A'),
                        _pdfInfoRow('Location', job['location'] ?? 'N/A'),
                        if (job['salesPerson'] != null)
                          _pdfInfoRow('Sales Person', job['salesPerson']),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ORDER DETAILS',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                        pw.Divider(),
                        _pdfInfoRow('Order Date', orderDateStr),
                        _pdfInfoRow(
                          'Dispatch Date',
                          _formatDate(
                            job['deliveryDate'] ??
                                job['dispatchDate'] ??
                                job['date'] ??
                                job['createdAt'],
                          ),
                        ),
                        _pdfInfoRow('Status', job['status'] ?? 'Pending'),
                        _pdfInfoRow(
                          'Dispatch Type',
                          job['dispatchType'] ?? 'N/A',
                        ),
                        _pdfInfoRow('Order Location', job['unit'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // ── Products Table ───────────────────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: withHsn
                  ? {
                      0: const pw.FixedColumnWidth(25),
                      1: const pw.FixedColumnWidth(55),
                      2: const pw.FlexColumnWidth(1.8),
                      3: const pw.FlexColumnWidth(3.5),
                      4: const pw.FixedColumnWidth(38),
                      5: const pw.FixedColumnWidth(45),
                      6: const pw.FixedColumnWidth(55),
                    }
                  : {
                      0: const pw.FixedColumnWidth(25),
                      1: const pw.FlexColumnWidth(1.8),
                      2: const pw.FlexColumnWidth(4.0),
                      3: const pw.FixedColumnWidth(40),
                      4: const pw.FixedColumnWidth(40),
                      5: const pw.FixedColumnWidth(60),
                    },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  children: withHsn
                      ? [
                          _buildHeaderCell('Sr.'),
                          _buildHeaderCell('HSN Code'),
                          _buildHeaderCell('SUMMARY'),
                          _buildHeaderCell('DETAILS'),
                          _buildHeaderCell('QTY'),
                          _buildHeaderCell('RATE'),
                          _buildHeaderCell('AMOUNT'),
                        ]
                      : [
                          _buildHeaderCell('Sr.'),
                          _buildHeaderCell('SUMMARY'),
                          _buildHeaderCell('DETAILS'),
                          _buildHeaderCell('QTY'),
                          _buildHeaderCell('RATE'),
                          _buildHeaderCell('AMOUNT'),
                        ],
                ),

                // Product rows + section rows
                ...productsWithImages.asMap().entries.expand((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final List<pw.MemoryImage> imgs =
                      p['pdfImages'] as List<pw.MemoryImage>;
                  final sections = p['sections'] as Map<String, dynamic>? ?? {};

                  final detailsCol = pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (imgs.isNotEmpty) buildImageGrid(imgs),
                        if (imgs.isNotEmpty) pw.SizedBox(height: 2),
                        if (p['remarks'].toString().isNotEmpty)
                          pw.Text(
                            p['remarks'],
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.red800,
                            ),
                          ),
                      ],
                    ),
                  );

                  List<pw.TableRow> rows = [];

                  // Main product row
                  rows.add(
                    pw.TableRow(
                      children: withHsn
                          ? [
                              _buildDataCell('${idx + 1}', center: false),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      p['hsnCode'],
                                      style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                    pw.Text(
                                      'GST ${(p['gstPercent'] as double).toInt()}%',
                                      style: const pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.grey700,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  p['productName'],
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              detailsCol,
                              _buildDataCell(p['quantity']),
                              _buildDataCell(p['price']),
                              _buildDataCell(
                                (p['subAmount'] as double).toStringAsFixed(0),
                              ),
                            ]
                          : [
                              _buildDataCell('${idx + 1}', center: false),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  p['productName'],
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              detailsCol,
                              _buildDataCell(p['quantity']),
                              _buildDataCell(p['price']),
                              _buildDataCell(
                                (p['subAmount'] as double).toStringAsFixed(0),
                              ),
                            ],
                    ),
                  );

                  // Section rows
                  if (sectionOptions['tray'] == true &&
                      (sections['trayDetail'] ?? '').toString().isNotEmpty)
                    rows.add(
                      _buildSectionRow(
                        'Tray',
                        sections,
                        'tray',
                        withHsn: withHsn,
                      ),
                    );
                  if (sectionOptions['salophin'] == true &&
                      (sections['salophinDetail'] ?? '').toString().isNotEmpty)
                    rows.add(
                      _buildSectionRow(
                        'Salophin',
                        sections,
                        'salophin',
                        withHsn: withHsn,
                      ),
                    );
                  if (sectionOptions['boxCover'] == true &&
                      (sections['boxCoverDetail'] ?? '').toString().isNotEmpty)
                    rows.add(
                      _buildSectionRow(
                        'Box Cover',
                        sections,
                        'boxCover',
                        withHsn: withHsn,
                      ),
                    );
                  if (sectionOptions['inner'] == true &&
                      (sections['innerDetail'] ?? '').toString().isNotEmpty)
                    rows.add(
                      _buildSectionRow(
                        'Inner',
                        sections,
                        'inner',
                        withHsn: withHsn,
                      ),
                    );
                  if (sectionOptions['bottom'] == true &&
                      (sections['bottomDetail'] ?? '').toString().isNotEmpty)
                    rows.add(
                      _buildSectionRow(
                        'Bottom',
                        sections,
                        'bottom',
                        withHsn: withHsn,
                      ),
                    );
                  if (sectionOptions['die'] == true &&
                      (sections['dieDetail'] ?? '').toString().isNotEmpty)
                    rows.add(
                      _buildSectionRow(
                        'Die',
                        sections,
                        'die',
                        withHsn: withHsn,
                      ),
                    );
                  if (sectionOptions['other'] == true &&
                      (sections['otherDetail'] ?? '').toString().isNotEmpty)
                    rows.add(
                      _buildSectionRow(
                        'Other',
                        sections,
                        'other',
                        withHsn: withHsn,
                      ),
                    );

                  // Extra sections
                  if (sectionOptions['extra'] == true) {
                    final List extras = p['customExtraSections'] ?? [];
                    for (var ex in extras) {
                      final extraCells = withHsn
                          ? [
                              _buildDataCell(''),
                              _buildDataCell(''),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  ex['title'] ?? 'Extra',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildDataCell(
                                ex['detail']?.toString() ?? '',
                                center: false,
                              ),
                              _buildDataCell(ex['qty']?.toString() ?? '-'),
                              _buildDataCell(ex['price']?.toString() ?? '-'),
                              _buildDataCell(
                                _calcAmount(ex['qty'], ex['price']) > 0
                                    ? _calcAmount(
                                        ex['qty'],
                                        ex['price'],
                                      ).toStringAsFixed(0)
                                    : '-',
                              ),
                            ]
                          : [
                              _buildDataCell(''),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  ex['title'] ?? 'Extra',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildDataCell(
                                ex['detail']?.toString() ?? '',
                                center: false,
                              ),
                              _buildDataCell(ex['qty']?.toString() ?? '-'),
                              _buildDataCell(ex['price']?.toString() ?? '-'),
                              _buildDataCell(
                                _calcAmount(ex['qty'], ex['price']) > 0
                                    ? _calcAmount(
                                        ex['qty'],
                                        ex['price'],
                                      ).toStringAsFixed(0)
                                    : '-',
                              ),
                            ];
                      rows.add(pw.TableRow(children: extraCells));
                    }
                  }

                  return rows;
                }),

                // Subtotal row
                pw.TableRow(
                  children: withHsn
                      ? [
                          _buildDataCell(''),
                          _buildDataCell(''),
                          _buildDataCell(''),
                          _buildDataCell('SUBTOTAL', center: false),
                          _buildDataCell(''),
                          _buildDataCell(''),
                          _buildDataCell(
                            subTotal.toStringAsFixed(0),
                            fontSize: 12,
                          ),
                        ]
                      : [
                          _buildDataCell(''),
                          _buildDataCell(''),
                          _buildDataCell('SUBTOTAL', center: false),
                          _buildDataCell(''),
                          _buildDataCell(''),
                          _buildDataCell(
                            subTotal.toStringAsFixed(0),
                            fontSize: 12,
                          ),
                        ],
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // ── GST Breakdown table (CGST + SGST split) ──────────────────
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // GST table header
                  pw.Container(
                    color: PdfColors.blueGrey800,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Tax Rate',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            'Taxable Amt.',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            'CGST Amt.',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            'SGST Amt.',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            'Total Tax',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // GST rows
                  ...() {
                    double sumTaxable = 0,
                        sumCgst = 0,
                        sumSgst = 0,
                        sumTotalTax = 0;
                    final List<pw.Widget> rows = [];

                    for (int i = 0; i < sortedPcts.length; i++) {
                      final pct = sortedPcts[i];
                      final taxable = gstGroups[pct]!['taxable']!;
                      final totalGstForGroup = gstGroups[pct]!['gstAmt']!;
                      final cgst = totalGstForGroup / 2;
                      final sgst = totalGstForGroup / 2;

                      sumTaxable += taxable;
                      sumCgst += cgst;
                      sumSgst += sgst;
                      sumTotalTax += totalGstForGroup;

                      final bg = i % 2 == 0
                          ? PdfColors.white
                          : PdfColors.grey100;

                      rows.add(
                        pw.Container(
                          color: bg,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  '${pct.toInt()} %',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blueGrey800,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  taxable.toStringAsFixed(2),
                                  style: const pw.TextStyle(fontSize: 9),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  cgst.toStringAsFixed(2),
                                  style: const pw.TextStyle(fontSize: 9),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  sgst.toStringAsFixed(2),
                                  style: const pw.TextStyle(fontSize: 9),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  totalGstForGroup.toStringAsFixed(2),
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.orange900,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      // Totals row after last entry
                      if (i == sortedPcts.length - 1) {
                        rows.add(
                          pw.Container(
                            color: PdfColors.grey200,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text(
                                    'Total',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    sumTaxable.toStringAsFixed(2),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    sumCgst.toStringAsFixed(2),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    sumSgst.toStringAsFixed(2),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    sumTotalTax.toStringAsFixed(2),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.orange900,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                    return rows;
                  }(),

                  // Delivery charges row
                  if (deliveryCharges > 0)
                    pw.Container(
                      color: PdfColors.white,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 8,
                            child: pw.Text(
                              'Delivery Charges',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Expanded(
                            flex: 6,
                            child: pw.Text(
                              'Rs${deliveryCharges.toStringAsFixed(0)}',
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Advance row
                  if (advanceAmount > 0)
                    pw.Container(
                      color: PdfColors.white,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 8,
                            child: pw.Text(
                              'Advance Paid',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Expanded(
                            flex: 6,
                            child: pw.Text(
                              '-Rs${advanceAmount.toStringAsFixed(0)}',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.red,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Grand Total row
                  pw.Container(
                    color: PdfColors.green100,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 8,
                          child: pw.Text(
                            'GRAND TOTAL',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green900,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 6,
                          child: pw.Text(
                            'Rs${grandTotal.toStringAsFixed(0)}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green900,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 2),

            // ── Footer ───────────────────────────────────────────────────
            pw.Center(
              child: pw.Text(
                'All Rights Reserved © Dimple Packaging Pvt. Ltd.',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.yellow700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // ── Terms & Conditions ────────────────────────────────────────
            if (termsLines.isNotEmpty)
              pw.Container(
                width: double.infinity,
               // margin: const pw.EdgeInsets.only(top: 8),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700),
                  borderRadius: pw.BorderRadius.circular(10),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Terms & Conditions',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    
pw.Container(
  padding: const pw.EdgeInsets.all(6),
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: PdfColors.grey400),
    borderRadius: pw.BorderRadius.circular(8),
  ),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [

      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            pw.Text(
              'Bank Details',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),

            pw.SizedBox(height: 1),

            _pdfInfoRow(
              'Account Title',
              'DIMPLE PACKAGING PRIVATE LIMITED',
            ),

            _pdfInfoRow(
              'Account Number',
              '924030018463563',
            ),

            _pdfInfoRow(
              'IFSC',
              'UTIB0000042',
            ),

            _pdfInfoRow(
              'Bank',
              'Axis Bank Ltd., Mall Road, Ludhiana',
            ),

            _pdfInfoRow(
              'SWIFT',
              'AXISINBB042',
            ),
          ],
        ),
      ),

      pw.SizedBox(width: 10),

      pw.Container(
        width: 90,
        height: 80,
        child: pw.Image(qrImage),
      ),
    ],
  ),
),
                    pw.Text(
                      termsLines.join('\n'),
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.1),
                    ),
                  ],
                ),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ── Section row builder with withHsn support ───────────────────────────────
  pw.TableRow _buildSectionRow(
    String label,
    Map<String, dynamic> sections,
    String prefix, {
    required bool withHsn,
  }) {
    final cells = withHsn
        ? [
            _buildDataCell(''),
            _buildDataCell(''),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
            ),
            _buildDataCell(
              sections['${prefix}Detail']?.toString() ?? '',
              center: false,
            ),
            _buildDataCell(
              sections['${prefix}Qty']?.toString() ?? '-',
              center: true,
            ),
            _buildDataCell(
              sections['${prefix}Price']?.toString() ?? '-',
              center: true,
            ),
            _buildDataCell(
              _calcAmount(
                        sections['${prefix}Qty'],
                        sections['${prefix}Price'],
                      ) >
                      0
                  ? _calcAmount(
                      sections['${prefix}Qty'],
                      sections['${prefix}Price'],
                    ).toStringAsFixed(0)
                  : '-',
              center: true,
            ),
          ]
        : [
            _buildDataCell(''),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
            ),
            _buildDataCell(
              sections['${prefix}Detail']?.toString() ?? '',
              center: false,
            ),
            _buildDataCell(
              sections['${prefix}Qty']?.toString() ?? '-',
              center: true,
            ),
            _buildDataCell(
              sections['${prefix}Price']?.toString() ?? '-',
              center: true,
            ),
            _buildDataCell(
              _calcAmount(
                        sections['${prefix}Qty'],
                        sections['${prefix}Price'],
                      ) >
                      0
                  ? _calcAmount(
                      sections['${prefix}Qty'],
                      sections['${prefix}Price'],
                    ).toStringAsFixed(0)
                  : '-',
              center: true,
            ),
          ];
    return pw.TableRow(children: cells);
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 8 ),
            ),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 8))),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // JPG GENERATION
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateAndDownloadJPG(
    BuildContext buttonContext,
    Map<String, dynamic> job, {
    required Map<String, bool> sectionOptions,
  }) async {
    BuildContext? loadingContext;
    showDialog(
      context: buttonContext,
      barrierDismissible: false,
      builder: (ctx) {
        loadingContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );
    try {
      final pdfData = await _generatePDFData(
        job,
        withHsn: false,
        sectionOptions: sectionOptions,
      );
      final jobNo = job['jobCardNumber'] ?? job['jobNo'] ?? 'N/A';
      int pageIndex = 1;
      await for (final page in Printing.raster(pdfData, dpi: 200)) {
        final ui.Image image = await page.toImage();
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) continue;
        final pngBytes = byteData.buffer.asUint8List();
        await Printing.sharePdf(
          bytes: pngBytes,
          filename: 'SalesOrder_${jobNo}_Page_$pageIndex.png',
        );
        pageIndex++;
      }
      if (buttonContext.mounted) {
        ScaffoldMessenger.of(buttonContext).showSnackBar(
          SnackBar(
            content: const Text('Each page saved as separate image'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (buttonContext.mounted) {
        ScaffoldMessenger.of(buttonContext).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (loadingContext != null && loadingContext!.mounted) {
        Navigator.pop(loadingContext!);
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset('assets/dpl.png', height: 36),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'All Sales Orders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track & Download Orders',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50.withOpacity(0.3),
              Colors.blue.shade50.withOpacity(0.3),
              Colors.pink.shade50.withOpacity(0.2),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '🔍 Search by Job No, Customer, Status...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.blue.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _searchText = value.toLowerCase()),
                ),
              ),
            ),

            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedDateFilter,
                        decoration: InputDecoration(
                          labelText: '📅 Date Range',
                          labelStyle: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All Time'),
                          ),
                          DropdownMenuItem(value: 'Day', child: Text('Today')),
                          DropdownMenuItem(
                            value: 'Week',
                            child: Text('This Week'),
                          ),
                          DropdownMenuItem(
                            value: 'Month',
                            child: Text('This Month'),
                          ),
                          DropdownMenuItem(
                            value: 'Custom',
                            child: Text('Custom Range'),
                          ),
                        ],
                        onChanged: (val) async {
                          if (val == null) return;
                          if (val == 'Custom') {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) => Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.purple.shade600,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (range == null) return;
                            setState(() {
                              _selectedDateFilter = val;
                              _selectedDateRange = range;
                            });
                          } else {
                            setState(() {
                              _selectedDateFilter = val;
                              _selectedDateRange = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          labelText: '🏭 Unit Location',
                          labelStyle: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All Units'),
                          ),
                          DropdownMenuItem(
                            value: 'Unit 1',
                            child: Text('Unit 1'),
                          ),
                          DropdownMenuItem(
                            value: 'Unit 2',
                            child: Text('Unit 2'),
                          ),
                          DropdownMenuItem(
                            value: 'Meena Bazar',
                            child: Text('Meena Bazar'),
                          ),
                          DropdownMenuItem(
                            value: 'Collage Road',
                            child: Text('Collage Road'),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedUnit = val ?? 'All'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Job Cards List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('jobCards')
                    .orderBy('updatedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.blue.shade400,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.purple.shade700,
                                Colors.blue.shade700,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Loading Job Cards...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final jobNo =
                        (data['jobCardNumber'] ??
                                data['jobNo'] ??
                                data['orderId'] ??
                                doc.id)
                            .toString()
                            .toLowerCase();
                    final customer =
                        (data['customerName'] ?? data['customer'] ?? '')
                            .toString()
                            .toLowerCase();
                    final status = (data['status'] ?? '')
                        .toString()
                        .toLowerCase();
                    final searchMatch =
                        jobNo.contains(_searchText) ||
                        customer.contains(_searchText) ||
                        status.contains(_searchText);
                    final unit = (data['unit'] ?? '').toString();
                    final unitMatch =
                        _selectedUnit == 'All' || unit == _selectedUnit;
                    final Timestamp? ts = data['updatedAt'] ?? data['date'];
                    if (ts == null) return false;
                    final createdDate = ts.toDate();
                    final now = DateTime.now();
                    bool dateMatch = true;
                    if (_selectedDateFilter == 'Day') {
                      final start = DateTime(now.year, now.month, now.day);
                      dateMatch =
                          createdDate.isAfter(
                            start.subtract(const Duration(milliseconds: 1)),
                          ) &&
                          createdDate.isBefore(
                            start.add(const Duration(days: 1)),
                          );
                    } else if (_selectedDateFilter == 'Week') {
                      final weekStart = DateTime(
                        now.year,
                        now.month,
                        now.day - (now.weekday - 1),
                      );
                      dateMatch =
                          createdDate.isAfter(
                            weekStart.subtract(const Duration(milliseconds: 1)),
                          ) &&
                          createdDate.isBefore(
                            weekStart.add(const Duration(days: 7)),
                          );
                    } else if (_selectedDateFilter == 'Month') {
                      final monthStart = DateTime(now.year, now.month, 1);
                      final monthEnd = DateTime(now.year, now.month + 1, 1);
                      dateMatch =
                          createdDate.isAfter(
                            monthStart.subtract(
                              const Duration(milliseconds: 1),
                            ),
                          ) &&
                          createdDate.isBefore(monthEnd);
                    } else if (_selectedDateFilter == 'Custom' &&
                        _selectedDateRange != null) {
                      dateMatch =
                          createdDate.isAfter(
                            _selectedDateRange!.start.subtract(
                              const Duration(milliseconds: 1),
                            ),
                          ) &&
                          createdDate.isBefore(
                            _selectedDateRange!.end.add(
                              const Duration(days: 1),
                            ),
                          );
                    }
                    return searchMatch && unitMatch && dateMatch;
                  }).toList();

                  docs.sort((a, b) {
                    final ad = a.data() as Map<String, dynamic>;
                    final bd = b.data() as Map<String, dynamic>;
                    final at = (ad['updatedAt'] ?? ad['date']) as Timestamp?;
                    final bt = (bd['updatedAt'] ?? bd['date']) as Timestamp?;
                    return (bt?.toDate() ?? DateTime(2000)).compareTo(
                      at?.toDate() ?? DateTime(2000),
                    );
                  });

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(50),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade100.withOpacity(0.5),
                                  Colors.blue.shade100.withOpacity(0.5),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inbox_rounded,
                              size: 100,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.purple.shade700,
                                Colors.blue.shade700,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'No Job Cards Found',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchText.isNotEmpty
                                ? 'Try adjusting your search or filters'
                                : 'Start creating job cards to see them here',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final jobNo =
                          data['jobCardNumber'] ??
                          data['jobNo'] ??
                          data['orderId'] ??
                          docs[i].id;
                      final status = data['status'] ?? 'Pending';
                      final priority = data['priority'] ?? 'Low';
                      final unit = data['unit'] ?? 'N/A';
                      final customer =
                          data['customerName'] ?? data['customer'] ?? 'N/A';
                      final products = data['products'] as List<dynamic>? ?? [];
                      int totalQuantity = 0;
                      for (var product in products) {
                        totalQuantity +=
                            int.tryParse(
                              product['quantity']?.toString() ?? '0',
                            ) ??
                            0;
                      }
                      final orderDate = _formatDate(
                        data['orderDate'] ?? data['updatedAt'],
                      );

                      return FadeTransition(
                        opacity: _animationController,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.3, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Curves.easeOut,
                                ),
                              ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.purple.shade50.withOpacity(0.3),
                                  Colors.blue.shade50.withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.15),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.purple.shade600,
                                                        Colors.blue.shade600,
                                                      ],
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Flexible(
                                                  child: ShaderMask(
                                                    shaderCallback: (bounds) =>
                                                        LinearGradient(
                                                          colors: [
                                                            Colors
                                                                .purple
                                                                .shade700,
                                                            Colors
                                                                .blue
                                                                .shade700,
                                                          ],
                                                        ).createShader(bounds),
                                                    child: Text(
                                                      jobNo.toString(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 24,
                                                        color: Colors.white,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 22,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_rounded,
                                                    size: 18,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      customer,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          _buildModernStatusChip(status),
                                          const SizedBox(height: 10),
                                          _buildModernPriorityChip(priority),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.grey.shade300,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildModernDetailBox(
                                          icon: Icons.calendar_today_rounded,
                                          label: 'Date',
                                          value: orderDate,
                                          colors: [
                                            Colors.orange.shade400,
                                            Colors.orange.shade600,
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildModernDetailBox(
                                          icon: Icons.inventory_2_rounded,
                                          label: 'Products',
                                          value: '${products.length}',
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildModernDetailBox(
                                          icon: Icons.numbers_rounded,
                                          label: 'Quantity',
                                          value: '$totalQuantity',
                                          colors: [
                                            Colors.blue.shade400,
                                            Colors.blue.shade600,
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildModernDetailBox(
                                          icon: Icons.local_shipping,
                                          label: 'Dispatch',
                                          value:
                                              (data['dispatchType'] ?? '')
                                                  .toString()
                                                  .isEmpty
                                              ? 'N/A'
                                              : data['dispatchType'],
                                          colors: [
                                            Colors.purple.shade400,
                                            Colors.purple.shade700,
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple.shade600,
                                          Colors.blue.shade600,
                                          Colors.teal.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showDownloadOptionsDialog(
                                            context,
                                            data,
                                          ),
                                      icon: const Icon(
                                        Icons.download_rounded,
                                        size: 22,
                                      ),
                                      label: const Text(
                                        'Download File',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          0,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildModernDetailBox({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[0].withOpacity(0.15), colors[1].withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors[0].withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: colors).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusChip(String status) {
    List<Color> colors;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'completed':
        colors = [Colors.green.shade400, Colors.green.shade700];
        icon = Icons.check_circle_rounded;
        break;
      case 'in progress':
        colors = [Colors.orange.shade400, Colors.orange.shade700];
        icon = Icons.autorenew_rounded;
        break;
      case 'pending':
        colors = [Colors.blue.shade400, Colors.blue.shade700];
        icon = Icons.schedule_rounded;
        break;
      default:
        colors = [Colors.grey.shade400, Colors.grey.shade700];
        icon = Icons.help_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPriorityChip(String priority) {
    List<Color> colors;
    switch (priority.toLowerCase()) {
      case 'high':
        colors = [Colors.red.shade400, Colors.red.shade700];
        break;
      case 'medium':
        colors = [Colors.amber.shade400, Colors.amber.shade700];
        break;
      default:
        colors = [Colors.cyan.shade400, Colors.cyan.shade700];
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '● $priority',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS (same as other files)
// ══════════════════════════════════════════════════════════════════════════════
pw.Widget buildImageGrid(List<pw.MemoryImage> images) {
  if (images.isEmpty) return pw.SizedBox();
  const double fixedHeight = 90;
  final int columns = images.length == 1 ? 1 : (images.length == 2 ? 2 : 3);
  return pw.SizedBox(
    height: fixedHeight,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: List.generate(columns, (index) {
        if (index >= images.length) return pw.Expanded(child: pw.SizedBox());
        return pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Image(images[index], fit: pw.BoxFit.contain),
          ),
        );
      }),
    ),
  );
}
