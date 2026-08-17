import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/challan/ChallanReturn.dart';
import 'package:dimple_erp/challan/chhallanhistory.dart';
import 'package:dimple_erp/challan/dispatcheditorsceen.dart';
import 'package:dimple_erp/challan/pdfall.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DispatchItem {
  final String productName;
  final String detail;
  final int totalQuantity;
  final double rate;
  int dispatchedQty;
  int currentPackets;
  bool isSelected;
  int inputQty;

  final String jobDocId;
  final String jobNo;
  final bool isManuallyAdded;
  final List<String> images; // ← NAYA FIELD - product ki images

  DispatchItem({
    required this.productName,
    required this.detail,
    required this.totalQuantity,
    required this.rate,
    required this.dispatchedQty,
    required this.currentPackets,
    required this.jobDocId,
    required this.jobNo,
    this.isSelected = false,
    this.isManuallyAdded = false,
    this.images = const [], // ← manual items ke liye default khali
  }) : inputQty = 0;

  int get remainingQty => totalQuantity - dispatchedQty;

  bool get isOverDispatched =>
      !isManuallyAdded && inputQty > remainingQty && remainingQty > 0;

  bool get isFullyDispatched => !isManuallyAdded && remainingQty <= 0;

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'detail': detail,
    'quantity': inputQty,
    'rate': rate,
    'packets': currentPackets,
    'jobNo': jobNo,
    'totalQuantity': totalQuantity,
    'previouslyDispatched': dispatchedQty,
    'isManuallyAdded': isManuallyAdded,
    'isOverDispatched': isOverDispatched,
    'images':
        images, // ← YE ZAROOR HONA CHAHIYE, warna dispatchSales me images save hi nahi hongi
  };
}

Text _sheetLabel(String label) => Text(
  label,
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.grey.shade700,
  ),
);

InputDecoration _sheetInputDec(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
  filled: true,
  fillColor: const Color(0xFFF4F6FF),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);

Future<DispatchItem?> showAddProductDialog(
  BuildContext context, {
  required String jobDocId,
  required String jobNo,
}) {
  final nameCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final pktCtrl = TextEditingController();

  return showModalBottomSheet<DispatchItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_box_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extra Product Added',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        'this product will be added to the dispatch list',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _sheetLabel('Product Name *'),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _sheetInputDec('added product name'),
              ),
              const SizedBox(height: 2),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetLabel('Rate Rs'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: rateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          decoration: _sheetInputDec('0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetLabel('Packets'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: pktCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _sheetInputDec('0'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Product Name is required!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final item = DispatchItem(
                      productName: name,
                      detail: detailCtrl.text.trim(),
                      totalQuantity: 999999,
                      rate: double.tryParse(rateCtrl.text) ?? 0,
                      dispatchedQty: 0,
                      currentPackets: int.tryParse(pktCtrl.text) ?? 0,
                      jobDocId: jobDocId,
                      jobNo: jobNo,
                      isSelected: true,
                      isManuallyAdded: true,
                    );
                    Navigator.pop(ctx, item);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Added as Extra Item',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
}

Future<bool?> showPdfTypeDialog(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Challan PDF Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rate Column will be included in the PDF',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'With Rate',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Rate column included',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00695C), Color(0xFF00897B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Without Rate',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Rate column hidden',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> generateChallanPDF(
  Map<String, dynamic> data, {
  bool showRate = true,
}) async {
  final pdf = pw.Document();

  Uint8List logoBytes;
  try {
    final raw = await rootBundle.load('assets/1.jpg');
    logoBytes = raw.buffer.asUint8List();
  } catch (_) {
    logoBytes = Uint8List(0);
  }
  final logoImage = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

  // ─── FIX: PDF pe "aaj ki date" nahi, balki jis din yeh challan/dispatch
  // Firebase me CREATE hua tha wahi date print hogi. Pehle yaha
  // DateTime.now() use ho raha tha, isliye PDF me hamesha aaj ki date
  // aa jaati thi — chahe purana challan re-print kyun na kiya jaye.
  // Ab hum data['createdAt'] (ya fallback me data['date']) — jo ki
  // Firestore Timestamp hota hai — use karke uski date nikal rahe hain.
  DateTime challanDate = DateTime.now();
  final dynamic rawChallanDate = data['createdAt'] ?? data['date'];
  if (rawChallanDate is Timestamp) {
    challanDate = rawChallanDate.toDate();
  } else if (rawChallanDate is DateTime) {
    challanDate = rawChallanDate;
  }
  final String dateStr = DateFormat('dd/MM/yyyy').format(challanDate);

  final String customerName = data['customerName'] ?? 'N/A';
  final String challNo = data['challNo'] ?? 'N/A';

  final String jobCardNo =
      (data['jobCardNumber'] ?? data['jobNo'])?.toString().trim().isNotEmpty ==
          true
      ? (data['jobCardNumber'] ?? data['jobNo']).toString()
      : 'N/A';

  final String driverName = data['driverName'] ?? '';
  final String signature = data['signature'] ?? '';
  final List items = data['items'] ?? [];
  final int totalQty = data['totalQty'] ?? 0;
  final int totalPackets = data['totalPackets'] ?? 0;

  final List<pw.MemoryImage?> itemImages = [];
  for (final item in items) {
    final imgs = (item['images'] as List?) ?? [];
    pw.MemoryImage? img;
    if (imgs.isNotEmpty && imgs.first.toString().isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(imgs.first.toString()))
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          img = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {
        img = null;
      }
    }
    itemImages.add(img);
  }

  // ─── Reusable cell widget ────────────────────────
  pw.Widget pdfCell(
    String text, {
    bool bold = false,
    bool center = false,
    double fontSize = 11,
    PdfColor? color,
    PdfColor? bgColor,
  }) {
    return pw.Container(
      color: bgColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  // image cell widget
  pw.Widget pdfImageCell(pw.MemoryImage? img) {
    return pw.Container(
      height: 55,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(3),
      child: img != null
          ? pw.Image(img, fit: pw.BoxFit.contain)
          : pw.SizedBox(),
    );
  }

  pw.Widget buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 110,
          child: pw.Stack(
            children: [
              if (logoImage != null)
                pw.Positioned(
                  left: 20,
                  top: 20,
                  child: pw.Image(
                    logoImage,
                    width: 120,
                    height: 110,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              pw.Positioned(
                right: 10,
                top: 10,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'CHALLAN /',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'ESTIMATE',
                      style: pw.TextStyle(
                        fontSize: 37,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF005B4F),
                      ),
                    ),
                    pw.Container(
                      width: 190,
                      height: 2,
                      color: PdfColor.fromInt(0xFF7CB342),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'No.',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Text(
                      challNo,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF005B4F),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  'To: ${customerName.toUpperCase()}',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    pw.Text(
                      'J.C: ',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      jobCardNo,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF005B4F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFF7CB342),
                  width: 1,
                ),
              ),
              child: pw.Column(
                children: [
                  pw.Text('Date', style: pw.TextStyle(fontSize: 13)),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    dateStr,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget buildItemsTable() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.7),
      columnWidths: {
        0: const pw.FixedColumnWidth(55), // QNTY
        1: const pw.FixedColumnWidth(55), // IMAGE
        2: const pw.FlexColumnWidth(3.2), // PARTICULARS
        3: const pw.FixedColumnWidth(80), // RATE
        4: const pw.FixedColumnWidth(65), // PACKET
        5: const pw.FixedColumnWidth(80), // EXTRA
      },
      children: [
        // Table header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF005B4F)),
          children: [
            pdfCell('QNTY.', bold: true, center: true, color: PdfColors.white),
            pdfCell('IMAGE', bold: true, center: true, color: PdfColors.white),
            pdfCell('PARTICULARS', bold: true, color: PdfColors.white),
            pdfCell('RATE', bold: true, center: true, color: PdfColors.white),
            pdfCell('PACKET', bold: true, center: true, color: PdfColors.white),
            pdfCell('EXTRA', bold: true, center: true, color: PdfColors.white),
          ],
        ),

        // Item rows
        ...items.asMap().entries.map<pw.TableRow>((entry) {
          final int globalIdx = entry.key;
          final item = entry.value;
          final pw.MemoryImage? img = globalIdx < itemImages.length
              ? itemImages[globalIdx]
              : null;

          final bool isOver = item['isOverDispatched'] == true;
          final bool isManual = item['isManuallyAdded'] == true;

          final PdfColor textColor = isOver
              ? PdfColor.fromInt(0xFFCC0000)
              : isManual
              ? PdfColor.fromInt(0xFFE65C00)
              : PdfColors.black;

          return pw.TableRow(
            children: [
              pdfCell(
                item['quantity'].toString(),
                bold: true,
                center: true,
                fontSize: 16,
                color: textColor,
              ),
              pdfImageCell(img),
              pdfCell(
                item['productName'] ?? '',
                bold: true,
                fontSize: 14,
                color: textColor,
              ),
              pdfCell(
                showRate ? 'Rs ${item['rate']}/-' : '',
                bold: true,
                center: true,
                color: textColor,
              ),
              pdfCell(
                item['packets'].toString(),
                bold: true,
                center: true,
                color: textColor,
              ),
              pdfCell(
                isManual
                    ? 'EXTRA\nITEM'
                    : isOver
                    ? '+${item['quantity'] - ((item['totalQuantity'] ?? 0) - (item['previouslyDispatched'] ?? 0))}\nEXTRA'
                    : '-',
                bold: true,
                center: true,
                color: textColor,
              ),
            ],
          );
        }).toList(),

        // Totals row — ab yeh table ki hamesha aakhri row hai,
        // jis page pe table khatam hogi wahin dikhegi
        pw.TableRow(
          children: [
            pdfCell(
              'Qty : $totalQty',
              bold: true,
              color: PdfColors.white,
              bgColor: PdfColor.fromInt(0xFF005B4F),
            ),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pdfCell('Pct : $totalPackets', bold: true, center: true),
            pw.SizedBox(),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════
  //   SIGNATURE TABLE — agar current page pe jagah nahi bachi
  //   to MultiPage khud isse next page (2, 3, jitna zaroorat ho) pe daal dega
  // ═══════════════════════════════════
  pw.Widget buildSignatureTable() {
    return pw.Inseparable(
      child: pw.Table(
        border: pw.TableBorder.all(
          color: PdfColor.fromInt(0xFF005B4F),
          width: 0.7,
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              pdfCell("Receiver's Signature", bold: true, center: true),
              pdfCell("Driver Name", bold: true, center: true),
              pdfCell("Signature", bold: true, center: true),
            ],
          ),
          pw.TableRow(
            children: [
              pw.SizedBox(height: 70),
              pdfCell(driverName.toUpperCase(), center: true, bold: true),
              pdfCell(signature, center: true, bold: true),
            ],
          ),
          pw.TableRow(
            children: [
              pdfCell("DATE...................."),
              pdfCell("Outgoing Time........"),
              pw.SizedBox(),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════
  //   FINAL PAGE — MultiPage khud decide karega kitne pages banane hain
  // ═══════════════════════════════════
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(
        left: 18,
        right: 18,
        top: 10,
        bottom: 18,
      ),
      header: (pw.Context ctx) => buildHeader(),
      build: (pw.Context ctx) {
        return [
          buildItemsTable(),
          pw.SizedBox(height: 12),
          buildSignatureTable(),
        ];
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat fmt) async => pdf.save());
}

class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';
  late AnimationController _animCtrl;

  String _selectedFilter = 'All';
  String _statusFilter = 'All'; // NEW: All | Pending | Complete
  DateTime? _customFrom;
  DateTime? _customTo;
  int _quickBadge = 0; // ← YE ADD KARO

  final List<String> _filterLabels = [
    'All',
    'Today',
    '2 Days',
    '3 Days',
    '1 Week',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTimeRange _getFilterRange() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_selectedFilter) {
      case 'Today':
        return DateTimeRange(start: todayStart, end: todayEnd);
      case '2 Days':
        return DateTimeRange(
          start: todayStart.subtract(const Duration(days: 1)),
          end: todayEnd,
        );
      case '3 Days':
        return DateTimeRange(
          start: todayStart.subtract(const Duration(days: 2)),
          end: todayEnd,
        );
      case '1 Week':
        return DateTimeRange(
          start: todayStart.subtract(const Duration(days: 6)),
          end: todayEnd,
        );
      case 'Custom':
        return DateTimeRange(
          start: _customFrom ?? todayStart,
          end: _customTo != null
              ? DateTime(
                  _customTo!.year,
                  _customTo!.month,
                  _customTo!.day,
                  23,
                  59,
                  59,
                )
              : todayEnd,
        );
      default:
        return DateTimeRange(start: DateTime(2020), end: DateTime(2100));
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _customFrom != null && _customTo != null
          ? DateTimeRange(start: _customFrom!, end: _customTo!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A237E),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customFrom = picked.start;
        _customTo = picked.end;
        _selectedFilter = 'Custom';
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime dt;
      if (date is Timestamp) {
        dt = date.toDate();
      } else if (date is DateTime) {
        dt = date;
      } else {
        return 'N/A';
      }
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return 'N/A';
    }
  }

  void _openMultiOrderEditor(
    BuildContext context,
    String customerName,
    List<QueryDocumentSnapshot> docs,
  ) {
    final orders = docs.map((doc) {
      return {'docId': doc.id, 'data': doc.data() as Map<String, dynamic>};
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiOrderDispatchEditorScreen(
          customerName: customerName,
          orders: orders,
        ),
      ),
    );
  }

  Future<void> _reprintLatestPDF(String docId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('dispatchSales')
          .where('jobDocId', isEqualTo: docId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispatch record not found for this job.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final dispatchData = snap.docs.first.data();
      if (!mounted) return;
      final bool? withRate = await showPdfTypeDialog(context);
      if (withRate == null) return;
      await generateChallanPDF(dispatchData, showRate: withRate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
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
                        'Dispatch Challan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Search aur manage dispatch records',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Icon(Icons.history, color: Colors.white, size: 22),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DispatchAllDataScreen(),
                  ),
                );
              },
              child: const Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 2),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snap.data!.docs;

          final range = _getFilterRange();
          final dateDocs = allDocs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final rawDate = d['updatedAt'] ?? d['orderDate'];
            DateTime? docDate;
            if (rawDate is Timestamp) docDate = rawDate.toDate();
            if (rawDate is DateTime) docDate = rawDate;
            if (docDate == null) return true;
            return !docDate.isBefore(range.start) &&
                !docDate.isAfter(range.end);
          }).toList();

          // Status filter
          final statusDocs = dateDocs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;

            final bool hasDispatch = d['hasDispatch'] == true;
            final bool completed = d['dispatchCreated'] == true;

            if (_statusFilter == 'Complete') {
              return completed;
            } else if (_statusFilter == 'Pending') {
              return !completed;
            }

            return true;
          }).toList();

          final query = _searchText.toLowerCase().trim();
          final filteredDocs = query.isEmpty
              ? statusDocs
              : statusDocs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = (d['customerName'] ?? d['customer'] ?? '')
                      .toString()
                      .toLowerCase();
                  final jobNo = (d['jobCardNumber'] ?? d['jobNo'] ?? doc.id)
                      .toString()
                      .toLowerCase();
                  return name.contains(query) || jobNo.contains(query);
                }).toList();

          Map<String, List<QueryDocumentSnapshot>> groupedByCustomer = {};
          if (query.isNotEmpty) {
            for (final doc in filteredDocs) {
              final d = doc.data() as Map<String, dynamic>;
              final name = (d['customerName'] ?? d['customer'] ?? 'Unknown')
                  .toString();
              groupedByCustomer.putIfAbsent(name, () => []).add(doc);
            }
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchText = v),
                    decoration: InputDecoration(
                      hintText: '🔍 Search by Customer Name or Job No...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchText = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Date Filter Chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterLabels.map((label) {
                      if (label == 'Custom') {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: _pickCustomRange,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedFilter == 'Custom'
                                    ? const Color(0xFFE65100)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedFilter == 'Custom'
                                      ? const Color(0xFFE65100)
                                      : Colors.orange.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.date_range_rounded,
                                    size: 14,
                                    color: _selectedFilter == 'Custom'
                                        ? Colors.white
                                        : Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _selectedFilter == 'Custom' &&
                                            _customFrom != null &&
                                            _customTo != null
                                        ? '${DateFormat('dd/MM').format(_customFrom!)} - ${DateFormat('dd/MM').format(_customTo!)}'
                                        : 'Custom Range',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedFilter == 'Custom'
                                          ? Colors.white
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      final active = _selectedFilter == label;
                      return Padding(
                        padding: EdgeInsets.only(left: label == 'All' ? 0 : 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = label),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF1A237E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF1A237E)
                                    : Colors.indigo.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF1A237E),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── STATUS FILTER: All / Pending / Complete ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: ['All', 'Pending', 'Complete'].map((s) {
                    final active = _statusFilter == s;
                    Color activeColor;
                    Color borderColor;
                    IconData icon;
                    if (s == 'Complete') {
                      activeColor = Colors.green.shade700;
                      borderColor = Colors.green.shade300;
                      icon = Icons.check_circle_rounded;
                    } else if (s == 'Pending') {
                      activeColor = Colors.orange.shade700;
                      borderColor = Colors.orange.shade300;
                      icon = Icons.hourglass_empty_rounded;
                    } else {
                      activeColor = Colors.grey.shade700;
                      borderColor = Colors.grey.shade300;
                      icon = Icons.all_inclusive_rounded;
                    }
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: s != 'Complete' ? 8 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _statusFilter = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: active ? activeColor : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active ? activeColor : borderColor,
                                width: 1.5,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: activeColor.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  size: 14,
                                  color: active ? Colors.white : activeColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: active ? Colors.white : activeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              Expanded(
                child: query.isNotEmpty
                    ? groupedByCustomer.isEmpty
                          ? _buildNotFound(query)
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                              children: groupedByCustomer.entries
                                  .map(
                                    (entry) => _buildCustomerGroup(
                                      entry.key,
                                      entry.value,
                                    ),
                                  )
                                  .toList(),
                            )
                    : filteredDocs.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                        itemCount: filteredDocs.length,
                        itemBuilder: (ctx, i) {
                          final data =
                              filteredDocs[i].data() as Map<String, dynamic>;
                          return _buildJobCard(data, filteredDocs[i].id, i);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerGroup(
    String customerName,
    List<QueryDocumentSnapshot> docs,
  ) {
    final dispatchedDocs = docs
        .where((d) => (d.data() as Map)['dispatchCreated'] == true)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.indigo.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.blue.shade600],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${docs.length} Order${docs.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ...docs.asMap().entries.map((entry) {
            final i = entry.key;
            final doc = entry.value;
            final data = doc.data() as Map<String, dynamic>;
            final jobNo = data['jobCardNumber'] ?? data['jobNo'] ?? doc.id;
            final products = data['products'] as List<dynamic>? ?? [];
            final bool dispatched = data['dispatchCreated'] == true;
            final String? challNo = data['dispatchChallNo']?.toString();
            final orderDate = _formatDate(
              data['orderDate'] ?? data['updatedAt'],
            );
            final status = data['status'] ?? 'Pending';

            return Container(
              decoration: BoxDecoration(
                border: i < docs.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade100,
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: dispatched
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [
                                  const Color(0xFF1A237E),
                                  const Color(0xFF1565C0),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            jobNo.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          if (dispatched && challNo != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 10,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    challNo,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _miniChip(
                            Icons.calendar_today_rounded,
                            orderDate,
                            Colors.blue.shade50,
                            Colors.blue.shade700,
                          ),
                          _miniChip(
                            Icons.inventory_2_rounded,
                            '${products.length} Items',
                            Colors.green.shade50,
                            Colors.green.shade700,
                          ),
                          _statusChip(status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: docs.length > 1
                            ? 'Dispatch / Challan (${docs.length} Orders)'
                            : 'Dispatch / Challan',
                        icon: Icons.local_shipping_rounded,
                        colors: const [Color(0xFF1A237E), Color(0xFF1565C0)],
                        onTap: () =>
                            _openMultiOrderEditor(context, customerName, docs),
                      ),
                    ),
                    if (dispatchedDocs.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionButton(
                          label: 'Re-print PDF',
                          icon: Icons.picture_as_pdf_rounded,
                          colors: const [Color(0xFF1B5E20), Color(0xFF388E3C)],
                          onTap: () =>
                              _reprintLatestPDF(dispatchedDocs.last.id),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // History Button
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DispatchHistoryScreen(
                        jobDocId: docs.first.id,
                        jobNo:
                            (docs.first.data() as Map)['jobCardNumber']
                                ?.toString() ??
                            docs.first.id,
                        customerName: customerName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> data, String docId, int index) {
    final jobNo = data['jobCardNumber'] ?? data['jobNo'] ?? docId;
    final customer = data['customerName'] ?? data['customer'] ?? 'N/A';
    final status = data['status'] ?? 'Pending';
    final products = data['products'] as List<dynamic>? ?? [];
    final orderDate = _formatDate(data['orderDate'] ?? data['updatedAt']);
    final bool dispatched = data['dispatchCreated'] == true;
    final String? challNo = data['dispatchChallNo']?.toString();

    return FadeTransition(
      opacity: _animCtrl,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.09),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
          border: Border.all(
            color: dispatched ? Colors.green.shade300 : Colors.indigo.shade100,
            width: dispatched ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: dispatched
                            ? [Colors.green.shade500, Colors.green.shade700]
                            : [
                                const Color(0xFF1A237E),
                                const Color(0xFF1565C0),
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              jobNo.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            if (dispatched && challNo != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      challNo,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _miniChip(
                    Icons.calendar_today_rounded,
                    orderDate,
                    Colors.blue.shade50,
                    Colors.blue.shade700,
                  ),
                  _miniChip(
                    Icons.inventory_2_rounded,
                    '${products.length} Items',
                    Colors.green.shade50,
                    Colors.green.shade700,
                  ),
                  _miniChip(
                    Icons.location_on_rounded,
                    data['unit']?.toString() ?? 'N/A',
                    Colors.orange.shade50,
                    Colors.orange.shade700,
                  ),
                  if (dispatched)
                    _miniChip(
                      Icons.check_circle_rounded,
                      'Dispatched',
                      Colors.green.shade50,
                      Colors.green.shade700,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      label: 'Dispatch / Challan',
                      icon: Icons.local_shipping_rounded,
                      colors: const [Color(0xFF1A237E), Color(0xFF1565C0)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DispatchEditorScreen(
                            jobData: data,
                            jobDocId: docId,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (dispatched) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        label: 'Re-print PDF',
                        icon: Icons.picture_as_pdf_rounded,
                        colors: const [Color(0xFF1B5E20), Color(0xFF388E3C)],
                        onTap: () => _reprintLatestPDF(docId),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // History Button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DispatchHistoryScreen(
                      jobDocId: docId,
                      jobNo: jobNo.toString(),
                      customerName: customer.toString(),
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dispatch History',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.30),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'any order not found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Date range ya status filter change karein',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(String q) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '"$q" ka koi record nahi',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'in progress':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        break;
      default:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MULTI-ORDER DISPATCH EDITOR SCREEN
// ─────────────────────────────────────────────

class MultiOrderDispatchEditorScreen extends StatefulWidget {
  final String customerName;
  final List<Map<String, dynamic>> orders;

  const MultiOrderDispatchEditorScreen({
    super.key,
    required this.customerName,
    required this.orders,
  });

  @override
  State<MultiOrderDispatchEditorScreen> createState() =>
      _MultiOrderDispatchEditorScreenState();
}

class _MultiOrderDispatchEditorScreenState
    extends State<MultiOrderDispatchEditorScreen> {
  List<DispatchItem> _items = [];
  List<TextEditingController> _qtyControllers = [];
  List<TextEditingController> _packetControllers = [];

  String _autoChallNo = '';
  int _challNumericId = 1;

  final TextEditingController _driverNameCtrl = TextEditingController();
  final TextEditingController _signatureCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingChallNo = true;
  bool _isLoadingItems = true;

  @override
  void initState() {
    super.initState();
    if (widget.orders.isNotEmpty) {
      _signatureCtrl.text =
          widget.orders.first['data']['signature']?.toString() ?? '';
    }
    _loadAllItemsWithDispatchHistory();
    _fetchNextChallanNumber();
  }

  Future<void> _loadAllItemsWithDispatchHistory() async {
    final List<DispatchItem> allItems = [];

    for (final order in widget.orders) {
      final String docId = order['docId'];
      final Map<String, dynamic> data = order['data'];
      final List products = data['products'] ?? [];
      final String jobNo = data['jobCardNumber'] ?? data['jobNo'] ?? docId;

      final prevDispatches = await FirebaseFirestore.instance
          .collection('dispatchSales')
          .where('jobDocId', isEqualTo: docId)
          .get();

      final Map<String, int> dispatchedMap = {};
      for (final doc in prevDispatches.docs) {
        final dispItems = doc.data()['items'] as List<dynamic>? ?? [];
        for (final di in dispItems) {
          final name = di['productName']?.toString() ?? '';
          final qty = int.tryParse(di['quantity']?.toString() ?? '0') ?? 0;
          dispatchedMap[name] = (dispatchedMap[name] ?? 0) + qty;
        }
      }

      for (final p in products) {
        final int totalQty =
            int.tryParse(p['quantity']?.toString() ?? '0') ?? 0;
        final double rate = double.tryParse(p['price']?.toString() ?? '0') ?? 0;
        final int packets = int.tryParse(p['packets']?.toString() ?? '0') ?? 0;
        final String name = p['productName'] ?? p['name'] ?? 'Product';
        final String detail = p['remarks'] ?? p['detail'] ?? '';
        final int dispatched = dispatchedMap[name] ?? 0;

        final List<String> images = (p['images'] is List)
            ? List<String>.from(p['images'].map((e) => e.toString()))
            : <String>[];

        allItems.add(
          DispatchItem(
            productName: name,
            detail: detail,
            totalQuantity: totalQty,
            rate: rate,
            dispatchedQty: dispatched,
            currentPackets: packets,
            jobDocId: docId,
            jobNo: jobNo,
            images: images,
          ),
        );
      }
    }

    final qtyCtrl = allItems
        .map((_) => TextEditingController(text: ''))
        .toList();
    final pktCtrl = allItems
        .map((_) => TextEditingController(text: ''))
        .toList();

    setState(() {
      _items = allItems;
      _qtyControllers = qtyCtrl;
      _packetControllers = pktCtrl;
      _isLoadingItems = false;
    });
  }

  Future<void> _fetchNextChallanNumber() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('dispatchSales')
          .orderBy('challNumericId', descending: true)
          .limit(1)
          .get();

      int nextNum = 1;
      if (snap.docs.isNotEmpty) {
        final last = snap.docs.first.data()['challNumericId'] as int? ?? 0;
        nextNum = last + 1;
      }
      if (mounted) {
        setState(() {
          _challNumericId = nextNum;
          _autoChallNo = 'CH$nextNum';
          _isLoadingChallNo = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _challNumericId = 1;
          _autoChallNo = 'CH1';
          _isLoadingChallNo = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var c in _qtyControllers) c.dispose();
    for (var c in _packetControllers) c.dispose();
    _driverNameCtrl.dispose();
    _signatureCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _addManualProduct() async {
    final defaultDocId = widget.orders.first['docId'] as String;
    final defaultData = widget.orders.first['data'] as Map<String, dynamic>;
    final defaultJobNo =
        defaultData['jobCardNumber'] ?? defaultData['jobNo'] ?? defaultDocId;

    final newItem = await showAddProductDialog(
      context,
      jobDocId: defaultDocId,
      jobNo: defaultJobNo.toString(),
    );
    if (newItem == null) return;

    setState(() {
      _items.add(newItem);
      _qtyControllers.add(TextEditingController(text: ''));
      _packetControllers.add(
        TextEditingController(
          text: newItem.currentPackets > 0
              ? newItem.currentPackets.toString()
              : '',
        ),
      );
    });
  }

  List<DispatchItem> get _selectedItems =>
      _items.where((e) => e.isSelected && !e.isFullyDispatched).toList();

  int get _totalQty => _selectedItems.fold(0, (s, e) => s + e.inputQty);
  int get _totalPackets =>
      _selectedItems.fold(0, (s, e) => s + e.currentPackets);
  bool get _hasOverDispatched => _selectedItems.any((e) => e.isOverDispatched);

  String? _validate() {
    if (_selectedItems.isEmpty) return 'any product select';
    for (final item in _selectedItems) {
      if (item.inputQty <= 0)
        return '${item.productName}: Quantity should be greater than 0';
    }
    return null;
  }

  Future<void> _saveDispatch() async {
    for (int i = 0; i < _items.length; i++) {
      _items[i].inputQty = int.tryParse(_qtyControllers[i].text) ?? 0;
      _items[i].currentPackets =
          int.tryParse(_packetControllers[i].text) ?? _items[i].currentPackets;
    }

    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange.shade700),
      );
      return;
    }

    if (_isLoadingChallNo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challan number load '),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hasOverDispatched) {
      final confirmed = await _showOverDispatchDialog();
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final dispatchItemsList = _selectedItems.map((e) => e.toMap()).toList();

      final Map<String, List<DispatchItem>> byOrder = {};
      for (final item in _selectedItems) {
        byOrder.putIfAbsent(item.jobDocId, () => []).add(item);
      }

      final String jobNos = widget.orders
          .map(
            (o) =>
                o['data']['jobCardNumber'] ?? o['data']['jobNo'] ?? o['docId'],
          )
          .join(', ');

      final dispatchData = <String, dynamic>{
        'challNo': _autoChallNo,
        'challNumericId': _challNumericId,
        'jobDocId': widget.orders.first['docId'],
        'jobDocIds': widget.orders.map((o) => o['docId']).toList(),
        'jobCardNumber': jobNos,
        'customerName': widget.customerName,
        'driverName': _driverNameCtrl.text.trim(),
        'signature': _signatureCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
        'date': Timestamp.now(),
        'totalQty': _totalQty,
        'totalPackets': _totalPackets,
        'items': dispatchItemsList,
        'status': 'Dispatched',
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('dispatchSales')
          .add(dispatchData);

      for (final entry in byOrder.entries) {
        final docId = entry.key;
        final orderAllItems = _items.where((i) => i.jobDocId == docId).toList();
        final bool allDone = orderAllItems.every((item) {
          if (item.isSelected) {
            return (item.dispatchedQty + item.inputQty) >= item.totalQuantity;
          }
          return item.isFullyDispatched;
        });

        await FirebaseFirestore.instance
            .collection('orders')
            .doc(docId)
            .update({
              'dispatchCreated': allDone,
              'dispatchChallNo': _autoChallNo,
              'lastDispatchAt': Timestamp.now(),
            });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved! Challan No: $_autoChallNo'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      if (!mounted) return;
      final bool? withRate = await showPdfTypeDialog(context);
      if (withRate == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      await generateChallanPDF(dispatchData, showRate: withRate);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool?> _showOverDispatchDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),

        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Over Dispatch Alert',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    'Some items exceed the remaining order quantity.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange.shade800,
                    size: 20,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'The following products contain extra dispatch quantities. These entries will be marked as EXTRA in the PDF document.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            ..._selectedItems.where((e) => e.isOverDispatched).map((e) {
              final extraQty = e.inputQty - e.remainingQty;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.red.shade700,
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Dispatch Qty: ${e.inputQty}   |   Remaining Qty: ${e.remainingQty}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+$extraQty',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                  Color(0xFF0277BD),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Dispatch: ${widget.customerName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.orders.length} Order${widget.orders.length > 1 ? 's' : ''} — Combined Challan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: _isLoadingChallNo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _autoChallNo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoadingItems
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _challBanner(),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Dispatch Details',
                    icon: Icons.local_shipping_rounded,
                    color: const Color(0xFF0D47A1),
                    child: Column(
                      children: [
                        _inputRow(
                          'Driver Name',
                          _driverNameCtrl,
                          hint: 'Driver ka naam',
                        ),
                        const SizedBox(height: 12),
                        _inputRow(
                          'Signature',
                          _signatureCtrl,
                          hint: 'Hastaakshar / Naam',
                        ),
                        const SizedBox(height: 12),
                        _inputRow(
                          'Remarks',
                          _remarksCtrl,
                          hint: 'Optional remarks',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Items — Sabhi Orders ke Products',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF1B5E20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoTip(),
                        const SizedBox(height: 14),
                        ..._buildItemsByOrder(),
                        const SizedBox(height: 8),
                        _addProductButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_hasOverDispatched) _overDispatchBanner(),
                  _summaryCard(),
                  const SizedBox(height: 20),
                  _saveButton(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }

  Widget _challBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Auto Challan Number',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              _isLoadingChallNo
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _autoChallNo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        letterSpacing: 1,
                      ),
                    ),
            ],
          ),
          const Spacer(),
          const Column(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white54, size: 20),
              SizedBox(height: 4),
              Text(
                'Auto',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 15, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Item tap karein select/deselect ke liye. Order se zyada quantity allowed hai (PDF mein highlighted hogi).',
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addProductButton() {
    return GestureDetector(
      onTap: _addManualProduct,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade400, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Extra Product Added (Manual)',
              style: TextStyle(
                color: Colors.amber.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(PDF mein show hoga)',
              style: TextStyle(color: Colors.amber.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overDispatchBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Over-Dispatch Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _selectedItems.isEmpty
              ? [Colors.grey.shade400, Colors.grey.shade600]
              : [const Color(0xFF1A237E), const Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                (_selectedItems.isEmpty ? Colors.grey : const Color(0xFF1A237E))
                    .withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.summarize_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedItems.isEmpty
                    ? 'no items selected'
                    : 'Total Qty: $_totalQty   |   Total Packets: $_totalPackets',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _selectedItems.isEmpty
                ? [Colors.grey.shade400, Colors.grey.shade600]
                : [const Color(0xFF1B5E20), const Color(0xFF388E3C)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ElevatedButton.icon(
          onPressed: (_isSaving || _selectedItems.isEmpty)
              ? null
              : _saveDispatch,
          icon: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_alt_rounded, size: 22),
          label: Text(
            _isSaving ? 'Saving...' : 'Save & Challan PDF',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            disabledForegroundColor: Colors.white60,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItemsByOrder() {
    final List<Widget> result = [];

    final Map<String, List<int>> orderIndexMap = {};
    for (int i = 0; i < _items.length; i++) {
      if (!_items[i].isManuallyAdded) {
        orderIndexMap.putIfAbsent(_items[i].jobDocId, () => []).add(i);
      }
    }

    for (final order in widget.orders) {
      final String docId = order['docId'];
      final Map<String, dynamic> data = order['data'];
      final String jobNo = data['jobCardNumber'] ?? data['jobNo'] ?? docId;
      final indices = orderIndexMap[docId] ?? [];

      result.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '📋 $jobNo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: Colors.indigo.shade100),
              ),
            ],
          ),
        ),
      );

      for (final i in indices) {
        result.add(_buildProductCard(i, _items[i]));
      }
      result.add(const SizedBox(height: 8));
    }

    final manualIndices = <int>[];
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isManuallyAdded) manualIndices.add(i);
    }

    if (manualIndices.isNotEmpty) {
      result.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade700, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '➕ Extra / Manual Items',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: Colors.amber.shade200),
              ),
            ],
          ),
        ),
      );
      for (final i in manualIndices) {
        result.add(_buildProductCard(i, _items[i]));
      }
    }

    return result;
  }

  Widget _buildProductCard(int i, DispatchItem item) {
    final bool locked = item.isFullyDispatched;
    final bool selected = item.isSelected && !locked;
    final bool isManual = item.isManuallyAdded;
    final bool liveOver =
        !isManual &&
        selected &&
        (_items[i].inputQty) > item.remainingQty &&
        item.remainingQty > 0;

    Color cardBg;
    Color cardBorder;
    if (locked) {
      cardBg = Colors.green.shade50;
      cardBorder = Colors.green.shade300;
    } else if (isManual && selected) {
      cardBg = Colors.amber.shade50;
      cardBorder = Colors.amber.shade400;
    } else if (liveOver) {
      cardBg = Colors.red.shade50;
      cardBorder = Colors.red.shade400;
    } else if (selected) {
      cardBg = const Color(0xFFE8EAF6);
      cardBorder = const Color(0xFF1A237E);
    } else {
      cardBg = Colors.white;
      cardBorder = Colors.grey.shade200;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorder,
          width: (selected || locked || liveOver) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (liveOver
                        ? Colors.red
                        : isManual
                        ? Colors.amber
                        : locked
                        ? Colors.green
                        : selected
                        ? const Color(0xFF1A237E)
                        : Colors.grey)
                    .withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: locked
                ? null
                : () {
                    setState(() {
                      _items[i].isSelected = !_items[i].isSelected;
                      if (!_items[i].isSelected) {
                        _qtyControllers[i].text = '';
                        _packetControllers[i].text = '';
                        _items[i].inputQty = 0;
                      }
                    });
                  },
            child: _buildCardHeader(
              i,
              item,
              selected,
              locked,
              isManual,
              liveOver,
            ),
          ),
          if (selected) _buildInputArea(i, item, isManual, liveOver),
          if (isManual)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _items.removeAt(i);
                  _qtyControllers.removeAt(i);
                  _packetControllers.removeAt(i);
                });
              },
              icon: Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.red.shade400,
              ),
              label: Text(
                'Remove',
                style: TextStyle(fontSize: 12, color: Colors.red.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(
    int i,
    DispatchItem item,
    bool selected,
    bool locked,
    bool isManual,
    bool liveOver,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: locked
            ? Colors.green.shade100
            : isManual && selected
            ? Colors.amber.shade100
            : liveOver
            ? Colors.red.shade100
            : selected
            ? const Color(0xFF1A237E).withOpacity(0.08)
            : Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: locked
                  ? Colors.green
                  : isManual && selected
                  ? Colors.amber.shade600
                  : liveOver
                  ? Colors.red.shade600
                  : selected
                  ? const Color(0xFF1A237E)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              locked
                  ? Icons.lock_rounded
                  : isManual
                  ? Icons.add_rounded
                  : liveOver
                  ? Icons.warning_rounded
                  : selected
                  ? Icons.check_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: locked || selected ? Colors.white : Colors.grey.shade500,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: locked
                              ? Colors.green.shade800
                              : liveOver
                              ? Colors.red.shade700
                              : isManual
                              ? Colors.amber.shade800
                              : const Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    if (isManual) ...[
                      const SizedBox(width: 6),
                      _badge('EXTRA', Colors.amber.shade600),
                    ],
                    if (liveOver) ...[
                      const SizedBox(width: 6),
                      _badge('OVER', Colors.red.shade600),
                    ],
                  ],
                ),
                if (item.detail.isNotEmpty)
                  Text(
                    item.detail,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          if (locked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'FULLY\nDISPATCHED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isManual)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Manual Item',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'No limit',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total: ${item.totalQuantity}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  'Done: ${item.dispatchedQty}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Left: ${item.remainingQty}',
                  style: TextStyle(
                    fontSize: 12,
                    color: liveOver
                        ? Colors.red.shade700
                        : Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
    int i,
    DispatchItem item,
    bool isManual,
    bool liveOver,
  ) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (item.rate > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'Price: ${item.rate.toStringAsFixed(2)}/-',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: liveOver
                              ? [Colors.red.shade600, Colors.red.shade800]
                              : [
                                  const Color(0xFF1565C0),
                                  const Color(0xFF1A237E),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                liveOver
                                    ? Icons.warning_rounded
                                    : Icons.numbers_rounded,
                                color: Colors.white70,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                liveOver ? 'QTY (OVER!)' : 'QUANTITY',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _qtyControllers[i],
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (v) => setState(
                                () => _items[i].inputQty = int.tryParse(v) ?? 0,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isManual
                          ? 'No limit (manual)'
                          : liveOver
                          ? '⚠ Max: ${item.remainingQty}'
                          : 'Max: ${item.remainingQty}',
                      style: TextStyle(
                        fontSize: 10,
                        color: liveOver
                            ? Colors.red.shade700
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white70,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PACKETS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _packetControllers[i],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (v) => setState(
                            () =>
                                _items[i].currentPackets = int.tryParse(v) ?? 0,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _inputRow(
    String label,
    TextEditingController ctrl, {
    String hint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF4F6FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
