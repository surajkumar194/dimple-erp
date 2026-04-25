import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:ui' as ui;

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
    bool hasTray = false;
    bool hasSalophin = false;
    bool hasBoxCover = false;
    bool hasInner = false;
    bool hasBottom = false;
    bool hasDie = false;
    bool hasOther = false;
    bool hasExtra = false;
    for (var product in products) {
      final sections = product['sections'] as Map<String, dynamic>? ?? {};
      if (sections['trayDetail'] != null &&
          sections['trayDetail'].toString().isNotEmpty) {
        hasTray = true;
      }
      if (sections['salophinDetail'] != null &&
          sections['salophinDetail'].toString().isNotEmpty) {
        hasSalophin = true;
      }
      if (sections['boxCoverDetail'] != null &&
          sections['boxCoverDetail'].toString().isNotEmpty) {
        hasBoxCover = true;
      }
      if (sections['innerDetail'] != null &&
          sections['innerDetail'].toString().isNotEmpty) {
        hasInner = true;
      }
      if (sections['bottomDetail'] != null &&
          sections['bottomDetail'].toString().isNotEmpty) {
        hasBottom = true;
      }
      if (sections['dieDetail'] != null &&
          sections['dieDetail'].toString().isNotEmpty) {
        hasDie = true;
      }
      if (sections['otherDetail'] != null &&
          sections['otherDetail'].toString().isNotEmpty) {
        hasOther = true;
      }

      final List extras = product['customExtraSections'] ?? [];
      if (extras.isNotEmpty) hasExtra = true;
    }
    bool includeTray = hasTray;
    bool includeSalophin = hasSalophin;
    bool includeBoxCover = hasBoxCover;
    bool includeInner = hasInner;
    bool includeBottom = hasBottom;
    bool includeDie = hasDie;
    bool includeOther = hasOther;
    bool includeExtra = hasExtra;
    bool includePaymentTerms = true;
    bool include50PercentAdvance = false;
    bool includeFreightTerms = true;
    bool includePackingTerms = true;
    bool includeGSTTerms = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 20,
              child: Container(
                padding: const EdgeInsets.all(28),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with gradient icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.blue.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.cloud_download_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.purple.shade700,
                                      Colors.blue.shade700,
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Download Options',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose sections to include',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ✅ Product Sections (only show if they exist)
                      if (hasTray ||
                          hasSalophin ||
                          hasBoxCover ||
                          hasInner ||
                          hasBottom ||
                          hasDie ||
                          hasOther ||
                          hasExtra) ...[
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.purple.shade50.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.purple.shade200,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Product Sections',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ),
                              if (hasTray)
                                _buildCheckboxTile(
                                  'Tray',
                                  includeTray,
                                  (val) =>
                                      setState(() => includeTray = val ?? true),
                                ),
                              if (hasSalophin)
                                _buildCheckboxTile(
                                  'Salophin',
                                  includeSalophin,
                                  (val) => setState(
                                    () => includeSalophin = val ?? true,
                                  ),
                                ),
                              if (hasBoxCover)
                                _buildCheckboxTile(
                                  'Box Cover',
                                  includeBoxCover,
                                  (val) => setState(
                                    () => includeBoxCover = val ?? true,
                                  ),
                                ),
                              if (hasInner)
                                _buildCheckboxTile(
                                  'Inner',
                                  includeInner,
                                  (val) => setState(
                                    () => includeInner = val ?? true,
                                  ),
                                ),
                              if (hasBottom)
                                _buildCheckboxTile(
                                  'Bottom',
                                  includeBottom,
                                  (val) => setState(
                                    () => includeBottom = val ?? true,
                                  ),
                                ),
                              if (hasDie)
                                _buildCheckboxTile(
                                  'Die',
                                  includeDie,
                                  (val) =>
                                      setState(() => includeDie = val ?? true),
                                ),
                              if (hasOther)
                                _buildCheckboxTile(
                                  'Other',
                                  includeOther,
                                  (val) => setState(
                                    () => includeOther = val ?? true,
                                  ),
                                ),
                              if (hasExtra)
                                _buildCheckboxTile(
                                  'Extra Sections',
                                  includeExtra,
                                  (val) => setState(
                                    () => includeExtra = val ?? true,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ✅ Terms & Conditions - Always show with 4 options
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.blue.shade50.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Terms & Conditions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            _buildCheckboxTile(
                              '50% advance for start working rest payment before delivery',
                              include50PercentAdvance,
                              (val) => setState(
                                () => include50PercentAdvance = val ?? true,
                              ),
                            ),

                            _buildCheckboxTile(
                              'All payments within 15 days',
                              includePaymentTerms,
                              (val) => setState(
                                () => includePaymentTerms = val ?? true,
                              ),
                            ),

                            _buildCheckboxTile(
                              'Freight charges extra',
                              includeFreightTerms,
                              (val) => setState(
                                () => includeFreightTerms = val ?? true,
                              ),
                            ),
                            _buildCheckboxTile(
                              'Packing charges extra',
                              includePackingTerms,
                              (val) => setState(
                                () => includePackingTerms = val ?? true,
                              ),
                            ),
                            _buildCheckboxTile(
                              'GST extra as per invoice',
                              includeGSTTerms,
                              (val) =>
                                  setState(() => includeGSTTerms = val ?? true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Download Buttons with gradients
                      Row(
                        children: [
                          // PDF Button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade500,
                                    Colors.red.shade700,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _generateAndDownloadPDF(
                                    context,
                                    job,
                                    sectionOptions: {
                                      'tray': includeTray,
                                      'salophin': includeSalophin,
                                      'boxCover': includeBoxCover,
                                      'inner': includeInner,
                                      'bottom': includeBottom,
                                      'die': includeDie,
                                      'other': includeOther,
                                      'extra': includeExtra,
                                      'paymentTerms': includePaymentTerms,
                                      'advance50':
                                          include50PercentAdvance, // ✅ ADD

                                      'freightTerms': includeFreightTerms,
                                      'packingTerms': includePackingTerms,
                                      'gstTerms': includeGSTTerms,
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 24,
                                ),
                                label: const Text(
                                  'PDF',
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
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // JPG Button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade500,
                                    Colors.blue.shade700,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _generateAndDownloadJPG(
                                    context,
                                    job,
                                    sectionOptions: {
                                      'tray': includeTray,
                                      'salophin': includeSalophin,
                                      'boxCover': includeBoxCover,
                                      'inner': includeInner,
                                      'bottom': includeBottom,
                                      'die': includeDie,
                                      'other': includeOther,
                                      'extra': includeExtra,
                                      'paymentTerms': includePaymentTerms,
                                      'advance50': include50PercentAdvance,
                                      'freightTerms': includeFreightTerms,
                                      'packingTerms': includePackingTerms,
                                      'gstTerms': includeGSTTerms,
                                    },
                                  );
                                },
                                icon: const Icon(Icons.image_rounded, size: 24),
                                label: const Text(
                                  'JPG',
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
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
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

  // ✅ Helper widget for checkbox tiles
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
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      activeColor: Colors.purple.shade600,
      checkColor: Colors.white,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    );
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

  Future<void> _generateAndDownloadPDF(
    BuildContext buttonContext,
    Map<String, dynamic> job, {
    required Map<String, bool> sectionOptions,
  }) async {
    BuildContext? loadingContext;
    showDialog(
      context: buttonContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        loadingContext = dialogContext;
        return WillPopScope(
          onWillPop: () async => false,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
    try {
      final pdfData = await _generatePDFData(
        job,
        sectionOptions: sectionOptions,
      );
      final jobNo = job['jobCardNumber'] ?? job['jobNo'] ?? 'N/A';

    await Printing.layoutPdf(
  onLayout: (PdfPageFormat format) async => pdfData,
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

  Future<Uint8List> _generatePDFData(
    Map<String, dynamic> job, {
    required Map<String, bool> sectionOptions,
  }) async {
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

    final jobNo = job['jobCardNumber'] ?? job['jobNo'] ?? 'N/A';
    DateTime date;

    if (job['date'] is Timestamp) {
      date = (job['date'] as Timestamp).toDate();
    } else if (job['createdAt'] is Timestamp) {
      date = (job['createdAt'] as Timestamp).toDate();
    } else {
      date = DateTime.now();
    }

    final String customerName = job['customerName'] ?? job['customer'] ?? 'N/A';

    final String companyName =
        job['companyName'] ?? job['company'] ?? job['firmName'] ?? '';

    // Load product images with timeout optimization
    List<Map<String, dynamic>> productsWithImages = [];
    for (var product in products) {
      final images = product['images'] as List<dynamic>? ?? [];
      List<pw.MemoryImage> pdfImages = [];

      for (var imgUrl in images) {
        try {
          final response = await http
              .get(Uri.parse(imgUrl))
              .timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            pdfImages.add(pw.MemoryImage(response.bodyBytes));
          }
        } catch (_) {
          // Skip failed images
        }
      }

      final int qty = int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
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
    final double deliveryCharges =
        double.tryParse(job['deliveryCharges']?.toString() ?? '0') ?? 0;

    final double advanceAmount =
        double.tryParse(job['advanceAmount']?.toString() ?? '0') ?? 0;

    for (var product in productsWithImages) {
      // ✅ MAIN PRODUCT AMOUNT (ALWAYS ADD)
      grandTotal += double.tryParse(product['amount'] ?? '0') ?? 0;

      final sections = product['sections'] as Map<String, dynamic>? ?? {};

      // ✅ Add section amounts based on sectionOptions
      if (sectionOptions['tray'] == true) {
        grandTotal += _calcAmount(sections['trayQty'], sections['trayPrice']);
      }
      if (sectionOptions['salophin'] == true) {
        grandTotal += _calcAmount(
          sections['salophinQty'],
          sections['salophinPrice'],
        );
      }
      if (sectionOptions['boxCover'] == true) {
        grandTotal += _calcAmount(
          sections['boxCoverQty'],
          sections['boxCoverPrice'],
        );
      }
      if (sectionOptions['inner'] == true) {
        grandTotal += _calcAmount(sections['innerQty'], sections['innerPrice']);
      }
      if (sectionOptions['bottom'] == true) {
        grandTotal += _calcAmount(
          sections['bottomQty'],
          sections['bottomPrice'],
        );
      }
      if (sectionOptions['die'] == true) {
        grandTotal += _calcAmount(sections['dieQty'], sections['diePrice']);
      }
      if (sectionOptions['other'] == true) {
        grandTotal += _calcAmount(sections['otherQty'], sections['otherPrice']);
      }

      // ✅ Custom extras based on option
      if (sectionOptions['extra'] == true) {
        final List extras = product['customExtraSections'] ?? [];
        for (var extra in extras) {
          grandTotal += _calcAmount(extra['qty'], extra['price']);
        }
      }
    }

    final double subTotal = grandTotal;
    final double gstAmount = subTotal * 0.05;

    final double totalWithDelivery = subTotal + gstAmount + deliveryCharges;

    final double finalTotal = (totalWithDelivery - advanceAmount).clamp(
      0,
      double.infinity,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          List<String> termsLines = []; // ⬅️ YE LINE YAHAN ADD KARO
          if (sectionOptions['advance50'] == true) {
            termsLines.add(
              '50% advance for start working, rest payment before delivery.',
            );
            if (sectionOptions['paymentTerms'] == true) {
              termsLines.add(
                'All payments will be clear within 15 days of receiving goods.',
              );
            }
          }

          if (sectionOptions['freightTerms'] == true) {
            termsLines.add('Freight charges will be extra.');
          }
          if (sectionOptions['packingTerms'] == true) {
            termsLines.add('Packing charges will be extra.');
          }
          if (sectionOptions['gstTerms'] == true) {
            termsLines.add('G.S.T will be charged extra as per invoice.');
          }

          return [
            // Header
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
            pw.SizedBox(height: 6),
            pw.Text(
              'Sales Order: ${job['jobCardNumber'] ?? job['jobNo'] ?? 'N/A'}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Customer & Order Info Box
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
                        _buildPdfRow(
                          'Customer',
                          companyName.isNotEmpty
                              ? '$customerName\n$companyName'
                              : customerName,
                          valueStyle: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red800,
                            fontSize: 14,
                          ),
                        ),
                        _buildPdfRow('Phone', job['phone'] ?? 'N/A'),
                        _buildPdfRow('Location', job['location'] ?? 'N/A'),
                        if (job['salesPerson'] != null)
                          _buildPdfRow('Sales Person', job['salesPerson']),
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
                        _buildPdfRow('Order Date', _formatDate(date)),
                        _buildPdfRow(
                          'Dispatch Date',
                          _formatDate(
                            job['deliveryDate'] ??
                                job['dispatchDate'] ??
                                job['date'] ??
                                job['createdAt'],
                          ),
                        ),
                        _buildPdfRow('Status', job['status'] ?? 'Pending'),
                        _buildPdfRow(
                          'Dispatch Type',
                          job['dispatchType'] ?? 'N/A',
                        ),
                        _buildPdfRow('Order Location', job['unit'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Products Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FlexColumnWidth(1.8),
                2: const pw.FlexColumnWidth(4.0),
                3: const pw.FixedColumnWidth(40),
                4: const pw.FixedColumnWidth(40),
                5: const pw.FixedColumnWidth(60),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  children: [
                    _buildHeaderCell('Sr.'),
                    _buildHeaderCell('SUMMARY'),
                    _buildHeaderCell('DETAILS'),
                    _buildHeaderCell('QTY'),
                    _buildHeaderCell('RATE'),
                    _buildHeaderCell('AMOUNT'),
                  ],
                ),
                ...productsWithImages.asMap().entries.expand((entry) {
                  final index = entry.key + 1;
                  final product = entry.value;
                  final List<pw.MemoryImage> imgs =
                      product['pdfImages'] as List<pw.MemoryImage>;
                  final sections =
                      product['sections'] as Map<String, dynamic>? ?? {};

                  List<pw.TableRow> rows = [];

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
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // ✅ IMAGES GRID
                              if (imgs.isNotEmpty) buildImageGrid(imgs),

                              if (imgs.isNotEmpty) pw.SizedBox(height: 6),

                              // ✅ REMARKS
                              if (product['remarks'] != null &&
                                  product['remarks'].toString().isNotEmpty)
                                pw.Text(
                                  product['remarks'],
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.red800,
                                  ),
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

                  // ✅ CONDITIONAL SECTIONS BASED ON OPTIONS
                  if (sectionOptions['tray'] == true &&
                      sections['trayDetail'] != null) {
                    rows.add(_buildSectionRow('Tray', sections, 'tray'));
                  }
                  if (sectionOptions['salophin'] == true &&
                      sections['salophinDetail'] != null) {
                    rows.add(
                      _buildSectionRow('Salophin', sections, 'salophin'),
                    );
                  }
                  if (sectionOptions['boxCover'] == true &&
                      sections['boxCoverDetail'] != null) {
                    rows.add(
                      _buildSectionRow('Box Cover', sections, 'boxCover'),
                    );
                  }
                  if (sectionOptions['inner'] == true &&
                      sections['innerDetail'] != null) {
                    rows.add(_buildSectionRow('Inner', sections, 'inner'));
                  }
                  if (sectionOptions['bottom'] == true &&
                      sections['bottomDetail'] != null) {
                    rows.add(_buildSectionRow('Bottom', sections, 'bottom'));
                  }
                  if (sectionOptions['die'] == true &&
                      sections['dieDetail'] != null) {
                    rows.add(_buildSectionRow('Die', sections, 'die'));
                  }
                  if (sectionOptions['other'] == true &&
                      sections['otherDetail'] != null) {
                    rows.add(_buildSectionRow('Other', sections, 'other'));
                  }

                  // ✅ EXTRA SECTIONS
                  if (sectionOptions['extra'] == true) {
                    final List extras = product['customExtraSections'] ?? [];
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
                }),
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
                // DELIVERY CHARGES
                // DELIVERY CHARGES
                // pw.TableRow(
                //   children: [
                //     _buildDataCell(''),
                //     _buildDataCell(''),
                //     _buildDataCell('DELIVERY CHARGES', center: false),
                //     _buildDataCell(''),
                //     _buildDataCell(''),
                //     pw.Padding(
                //       padding: const pw.EdgeInsets.all(4),
                //       child: pw.Text(
                //         deliveryCharges.toStringAsFixed(0),
                //         textAlign: pw.TextAlign.center,
                //         style: const pw.TextStyle(fontSize: 10),
                //       ),
                //     ),
                //   ],
                // ),

                // // ADVANCE
                // pw.TableRow(
                //   children: [
                //     _buildDataCell(''),
                //     _buildDataCell(''),
                //     _buildDataCell('ADVANCE', center: false),
                //     _buildDataCell(''),
                //     _buildDataCell(''),
                //     pw.Padding(
                //       padding: const pw.EdgeInsets.all(4),
                //       child: pw.Text(
                //         '-${advanceAmount.toStringAsFixed(0)}',
                //         textAlign: pw.TextAlign.center,
                //         style: const pw.TextStyle(fontSize: 10),
                //       ),
                //     ),
                //   ],
                // ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildDataCell(''),
                    _buildDataCell(''),
                    _buildDataCell('GRAND TOTAL', center: false, fontSize: 12),
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
            pw.SizedBox(height: 1),
            pw.Divider(thickness: 1, color: PdfColors.black),
            // pw.SizedBox(height: 1),
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
            pw.SizedBox(height: 2),

            // ✅ CONDITIONAL TERMS & CONDITIONS

            // Only show T&C section if at least one option is selected
            // ✅ CONDITIONAL TERMS & CONDITIONS (MATCH TABLE WIDTH)
            if (termsLines.isNotEmpty)
              pw.Container(
                width: double.infinity, // 🔥 SAME AS TABLE
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700, width: 1.2),
                  borderRadius: pw.BorderRadius.circular(10),
                  color: PdfColors.grey100,
                  boxShadow: [
                    pw.BoxShadow(
                      color: PdfColors.grey300,
                      blurRadius: 4,
                      //  offset: const pw.Offset(0, 2),
                    ),
                  ],
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Terms & Conditions',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      termsLines.join('\n'),
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
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

  pw.TableRow _buildSectionRow(
    String label,
    Map<String, dynamic> sections,
    String prefix,
  ) {
    return pw.TableRow(
      children: [
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
          _calcAmount(sections['${prefix}Qty'], sections['${prefix}Price']) > 0
              ? _calcAmount(
                  sections['${prefix}Qty'],
                  sections['${prefix}Price'],
                ).toStringAsFixed(0)
              : '-',
          center: true,
        ),
      ],
    );
  }

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
          filename: 'ProformaInvoice_${jobNo}_Page_$pageIndex.png',
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
            // Modern AppBar with gradient

            // Enhanced Search Bar
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
                  onChanged: (value) {
                    setState(() {
                      _searchText = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),

            // Enhanced Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                children: [
                  // Date Filter
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
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.purple.shade600,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
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

                  // Unit Filter
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
                        onChanged: (val) {
                          setState(() => _selectedUnit = val ?? 'All');
                        },
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

                    Timestamp? ts = data['updatedAt'] ?? data['date'];
                    if (ts == null) return false;

                    final createdDate = ts.toDate();
                    final now = DateTime.now();

                    bool dateMatch = true;

                    if (_selectedDateFilter == 'Day') {
                      final start = DateTime(now.year, now.month, now.day);
                      final end = start.add(const Duration(days: 1));

                      dateMatch =
                          createdDate.isAfter(
                            start.subtract(const Duration(milliseconds: 1)),
                          ) &&
                          createdDate.isBefore(end);
                    } else if (_selectedDateFilter == 'Week') {
                      final start = now.subtract(
                        Duration(days: now.weekday - 1),
                      );
                      final weekStart = DateTime(
                        start.year,
                        start.month,
                        start.day,
                      );
                      final weekEnd = weekStart.add(const Duration(days: 7));

                      dateMatch =
                          createdDate.isAfter(
                            weekStart.subtract(const Duration(milliseconds: 1)),
                          ) &&
                          createdDate.isBefore(weekEnd);
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

                    final adate = at?.toDate() ?? DateTime(2000);
                    final bdate = bt?.toDate() ?? DateTime(2000);

                    return bdate.compareTo(adate);
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
                      final deliveryDate = data['deliveryDate'];
                      final customer =
                          data['customerName'] ?? data['customer'] ?? 'N/A';
                      final products = data['products'] as List<dynamic>? ?? [];

                      int totalQuantity = 0;
                      for (var product in products) {
                        final qty = product['quantity'] ?? '0';
                        totalQuantity += int.tryParse(qty.toString()) ?? 0;
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
                                                      jobNo,
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
      case 'low':
      default:
        colors = [Colors.cyan.shade400, Colors.cyan.shade700];
        break;
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

pw.Widget buildImageGrid(List<pw.MemoryImage> images) {
  if (images.isEmpty) return pw.SizedBox();

  const double fixedHeight = 90;

  int columns;
  if (images.length == 1) {
    columns = 1;
  } else if (images.length == 2) {
    columns = 2;
  } else {
    columns = 3;
  }

  return pw.SizedBox(
    height: fixedHeight,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: List.generate(columns, (index) {
        if (index >= images.length) {
          return pw.Expanded(child: pw.SizedBox());
        }

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

pw.Widget _buildPdfRow(String label, String value, {pw.TextStyle? valueStyle}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: valueStyle, // 👈 yahan apply hoga
            softWrap: true,
            maxLines: null, // ← full text show karega
          ),
        ),
      ],
    ),
  );
}
