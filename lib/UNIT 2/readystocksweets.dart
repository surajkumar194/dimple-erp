import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ReadyStockSweetsScreen extends StatefulWidget {
  const ReadyStockSweetsScreen({super.key});
  @override
  _ReadyStockSweetsScreenState createState() => _ReadyStockSweetsScreenState();
}

class _ReadyStockSweetsScreenState extends State<ReadyStockSweetsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> stockData = [];
  List<Map<String, dynamic>> filteredData = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String _selectedDateFilter = 'All';
  String _selectedSalesFilter = 'All';
  DateTimeRange? _customDateRange;
  String _selectedTypeFilter = "All";
  String _selectedRangeFilter = "All";

  // ── Summary totals (computed from filteredData) ──
  int get _totalIn => filteredData.fold(
    0,
    (s, i) => s + (int.tryParse(i['in']?.toString() ?? '0') ?? 0),
  );
  int get _totalOut => filteredData.fold(
    0,
    (s, i) => s + (int.tryParse(i['out']?.toString() ?? '0') ?? 0),
  );
  int get _totalBal => filteredData.fold(
    0,
    (s, i) => s + (int.tryParse(i['bal']?.toString() ?? '0') ?? 0),
  );

  Future<Uint8List?> _networkImageToBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {}
    return null;
  }

  final List<String> _typeFilters = [
    "All",
    "Regular",
    "Dead Stock",
    "Medium Moving",
    "Slow Moving",
    "Fast Moving",
  ];

  final List<String> _rangeFilters = [
    "1 Day",
    "2 Day",
    "1 Week",
    "1 Month",
    "All",
  ];

  Future<void> _downloadPdf() async {
    final pdf = pw.Document();

    Uint8List logoBytes;
    try {
      final data = await rootBundle.load('assets/logo.png');
      logoBytes = data.buffer.asUint8List();
    } catch (e) {
      logoBytes = Uint8List(0);
    }

    final logoImage = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final data = filteredData;
    List<List<dynamic>> tableData = [];

    for (var item in data) {
      Uint8List? imageBytes;
      if (item['image'] != null && item['image'].toString().isNotEmpty) {
        imageBytes = await _networkImageToBytes(item['image']);
      }
      tableData.add([
        item["code"] ?? "",
        item["location"] ?? "",
        item["size"] ?? "",
        item["detail"] ?? "",
        item["stock_type"] ?? "",
        imageBytes != null
            ? pw.Image(pw.MemoryImage(imageBytes), width: 40, height: 40)
            : pw.Text("No Image"),
        item["in"]?.toString() ?? "0",
        item["bal"]?.toString() ?? "0",
        item["sales_person"] ?? "",
        item["dateEdit"] ?? "",
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(width: 80, height: 80, child: pw.Image(logoImage)),
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
          pw.SizedBox(height: 1),
          pw.Divider(thickness: 1),
          pw.Text(
            "Sweets Stock Report",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          // Summary row in PDF
          pw.Row(
            children: [
              pw.Text(
                'Total Stock (IN): $_totalIn   |   Issue Stock (OUT): $_totalOut   |   Stock in Hand (BAL): $_totalBal',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: [
              "Code",
              "Location",
              "Size",
              "Item",
              "Type",
              "Image",
              "Total Stock",
              "Stock In Hand",
              "Sales Person",
              "Date",
            ],
            data: tableData,
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "sweets_stock_report.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/sweets_stock_report.pdf");
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    }

    _showSnackBar("PDF Generated");
  }

  final List<String> _dateFilters = [
    'All',
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'Custom',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _stockTypes = [
    'Regular',
    'Dead Stock',
    'Medium Moving',
    'Slow Moving',
    'Fast Moving',
  ];

  final List<String> _salesPersons = [
    'Sunny ji',
    'Hardeep ji',
    'Krishna ji',
    'Ashish Tandon (Shop)',
    'MB Shop',
    'Other',
  ];

  List<String> get _salesFilterOptions {
    final salesSet = <String>{};
    for (var item in stockData) {
      final sp = item['sales_person'];
      if (sp != null && sp.toString().trim().isNotEmpty)
        salesSet.add(sp.toString());
    }
    final sortedList = salesSet.toList()..sort();
    return ['All', ...sortedList];
  }

  String? _selectedGroup;
  final List<String> _groupList = [];

  final List<String> _departments = [
    'Production',
    'Maintenance',
    'QC',
    'Packing',
    'Store',
    'Admin',
  ];

  final List<String> _secondParties = [
    'Vendor A',
    'Vendor B',
    'Supplier X',
    'Client Y',
    'Other',
  ];

  Future<void> _reorderSrNumbers() async {
    final snapshot = await _firestore
        .collection('readystock_sweets_items')
        .orderBy('createdAt', descending: false)
        .get();

    WriteBatch batch = _firestore.batch();
    int sr = 1;
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'sr': sr});
      sr++;
    }
    await batch.commit();
  }

  Future<void> _fixCodesSequentially() async {
    final snapshot = await _firestore
        .collection('readystock_sweets_items')
        .orderBy('createdAt')
        .get();

    WriteBatch batch = _firestore.batch();
    int counter = 1;
    for (var doc in snapshot.docs) {
      final newCode = "HSP-SS-${counter.toString().padLeft(2, '0')}";
      batch.update(doc.reference, {'code': newCode});
      counter++;
    }
    await batch.commit();
    await _loadDataFromFirebase();
  }

  // 🎨 COLOR PALETTE
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color bgGreen = Color(0xFFE8F5E9);
  static const Color cardGreen = Color(0xFFF1F8F4);

  @override
  void initState() {
    super.initState();
    _selectedDateFilter = 'All';
    _selectedGroup = 'All';

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadDataFromFirebase();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ==================== DATA OPERATIONS ====================

  Future<int> _getNextSrNumber() async {
    try {
      final snapshot = await _firestore
          .collection('readystock_sweets_items')
          .get();
      int maxSr = 0;
      for (var doc in snapshot.docs) {
        final sr = doc.data()['sr'];
        if (sr != null && sr is int && sr > maxSr) maxSr = sr;
      }
      return maxSr + 1;
    } catch (e) {
      return 1;
    }
  }

  Future<String> _getNextAutoCode() async {
    try {
      final snapshot = await _firestore
          .collection('readystock_sweets_items')
          .get();
      if (snapshot.docs.isEmpty) return "HSP-SS-01";

      final List<int> numbers = [];
      for (var doc in snapshot.docs) {
        final code = doc.data()['code']?.toString();
        if (code != null && code.startsWith("HSP-SS-")) {
          final parts = code.split('-');
          if (parts.length == 3) {
            final num = int.tryParse(parts[2]);
            if (num != null) numbers.add(num);
          }
        }
      }
      numbers.sort();

      int nextNumber = 1;
      for (int n in numbers) {
        if (n == nextNumber)
          nextNumber++;
        else if (n > nextNumber)
          break;
      }
      return "HSP-SS-${nextNumber.toString().padLeft(3, '0')}";
    } catch (e) {
      return "HSP-SS-01";
    }
  }

  Future<void> _loadDataFromFirebase() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('readystock_sweets_items')
          .get();

      stockData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      // ── A to Z sort by detail (Item/Party Name) ──
      stockData.sort((a, b) {
        final aDetail = (a['detail'] ?? '').toString().toLowerCase();
        final bDetail = (b['detail'] ?? '').toString().toLowerCase();
        return aDetail.compareTo(bDetail);
      });

      if (_selectedGroup == null || !_groupList.contains(_selectedGroup)) {
        _selectedGroup = 'All';
      }

      filteredData = List.from(stockData);
      _applyFilters();
    } catch (e) {
      _showSnackBar("Error loading data: $e", isError: true);
    }
    setState(() => _isLoading = false);
  }

  void _filterData() => _applyFilters();

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();

    setState(() {
      filteredData = stockData.where((item) {
        final matchesSearch =
            item["code"].toString().toLowerCase().contains(query) ||
            item["detail"].toString().toLowerCase().contains(query) ||
            item["location"].toString().toLowerCase().contains(query) ||
            (item["design_no"] ?? "").toString().toLowerCase().contains(query);

        bool matchesType =
            _selectedTypeFilter == "All" ||
            item["stock_type"] == _selectedTypeFilter;

        bool matchesSales =
            _selectedSalesFilter == "All" ||
            item["sales_person"] == _selectedSalesFilter;

        bool matchesDate = true;
        try {
          DateTime? itemDate;
          if (item['dateEdit'] != null &&
              item['dateEdit'].toString().isNotEmpty) {
            itemDate = DateFormat('dd-MM-yyyy').parse(item['dateEdit']);
          }
          if (itemDate != null) {
            if (_selectedDateFilter == 'Today') {
              matchesDate =
                  itemDate.year == now.year &&
                  itemDate.month == now.month &&
                  itemDate.day == now.day;
            } else if (_selectedDateFilter == 'Last 7 Days') {
              matchesDate = itemDate.isAfter(
                now.subtract(const Duration(days: 7)),
              );
            } else if (_selectedDateFilter == 'Last 30 Days') {
              matchesDate = itemDate.isAfter(
                now.subtract(const Duration(days: 30)),
              );
            } else if (_selectedDateFilter == 'Custom' &&
                _customDateRange != null) {
              matchesDate =
                  itemDate.isAfter(
                    _customDateRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  itemDate.isBefore(
                    _customDateRange!.end.add(const Duration(days: 1)),
                  );
            }
          }
        } catch (e) {
          matchesDate = true;
        }

        return matchesSearch && matchesType && matchesSales && matchesDate;
      }).toList();

      // ── Keep A–Z sort in filtered result too ──
      filteredData.sort((a, b) {
        final aDetail = (a['detail'] ?? '').toString().toLowerCase();
        final bDetail = (b['detail'] ?? '').toString().toLowerCase();
        return aDetail.compareTo(bDetail);
      });
    });
  }

  // ==================== IMAGE OPERATIONS ====================

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String fileName = 'sweets_${DateTime.now().millisecondsSinceEpoch}';
      final Reference ref = _storage.ref().child(
        'readystock_sweets_images/$fileName.png',
      );
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      _showSnackBar("Image upload failed: $e", isError: true);
      return null;
    }
  }

  void _showImageZoom(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: imageUrl,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: accentGreen,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[300],
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageCellFlex(Map<String, dynamic> item, int flex) {
    final url = item['image'];
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: url != null && url.toString().isNotEmpty
            ? GestureDetector(
                onTap: () => _showImageZoom(url),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: lightGreen, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      url,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bgGreen,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: lightGreen, width: 1.5),
                ),
                child: Icon(Icons.image, color: Colors.grey[400], size: 24),
              ),
      ),
    );
  }

  Widget _imagePickerBox({
    XFile? imageFile,
    String? imageUrl,
    required VoidCallback onPick,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: bgGreen,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentGreen, width: 2),
          boxShadow: [
            BoxShadow(
              color: accentGreen.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: imageFile != null
              ? (kIsWeb
                    ? FutureBuilder<Uint8List>(
                        future: imageFile.readAsBytes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.file(File(imageFile.path), fit: BoxFit.cover))
              : imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 50,
                      color: accentGreen,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Upload Image",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ==================== STOCK OPERATIONS ====================

  void _issueStockWithDepartment(Map<String, dynamic> item) {
    String? selectedDept;
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Issue Stock",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedDept,
                    hint: const Text("Select Department"),
                    items: _departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => selectedDept = v),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(Icons.business, color: Colors.red[700]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Quantity",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(Icons.numbers, color: Colors.red[700]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: selectedDept == null || qtyCtrl.text.isEmpty
                  ? null
                  : () async {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) {
                        _showSnackBar("Enter valid quantity", isError: true);
                        return;
                      }
                      final currentBal =
                          int.tryParse(item['bal'].toString()) ?? 0;
                      final newBal = currentBal - qty;
                      if (newBal < 0) {
                        _showSnackBar("Not enough stock!", isError: true);
                        return;
                      }
                      final currentOut =
                          int.tryParse(item['out'].toString()) ?? 0;

                      await _firestore
                          .collection('readystock_sweets_transactions')
                          .add({
                            'itemId': item['docId'],
                            'type': 'issue',
                            'department': selectedDept,
                            'quantity': qty,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                      await _firestore
                          .collection('readystock_sweets_items')
                          .doc(item['docId'])
                          .update({
                            'bal': newBal,
                            'out': currentOut + qty,
                            'dateEdit': DateFormat(
                              'dd-MM-yyyy',
                            ).format(DateTime.now()),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                      await _loadDataFromFirebase();
                      _showSnackBar("✓ Issued $qty to $selectedDept");
                      Navigator.pop(ctx);
                    },
              child: const Text(
                "Issue Stock",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addAdditionalWithParty(Map<String, dynamic> item) {
    String? selectedParty;
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [lightGreen, accentGreen]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_box_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Add Stock",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bgGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightGreen),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedParty,
                    hint: const Text("Select Second Party"),
                    items: _secondParties
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => selectedParty = v),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(Icons.people, color: primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: bgGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightGreen),
                  ),
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Quantity",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(Icons.numbers, color: primaryGreen),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: selectedParty == null || qtyCtrl.text.isEmpty
                  ? null
                  : () async {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) {
                        _showSnackBar("Enter valid quantity", isError: true);
                        return;
                      }
                      final currentBal =
                          int.tryParse(item['bal'].toString()) ?? 0;
                      final currentIn =
                          int.tryParse(item['in'].toString()) ?? 0;

                      await _firestore
                          .collection('readystock_sweets_transactions')
                          .add({
                            'itemId': item['docId'],
                            'type': 'received',
                            'party': selectedParty,
                            'quantity': qty,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                      await _firestore
                          .collection('readystock_sweets_items')
                          .doc(item['docId'])
                          .update({
                            'bal': currentBal + qty,
                            'in': currentIn + qty,
                            'dateEdit': DateFormat(
                              'dd-MM-yyyy',
                            ).format(DateTime.now()),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                      await _loadDataFromFirebase();
                      _showSnackBar("✓ Received $qty from $selectedParty");
                      Navigator.pop(ctx);
                    },
              child: const Text(
                "Add Stock",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Update Stock",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['detail'] ?? '',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _buildUpdateButton(
                    icon: Icons.remove_circle_outline,
                    label: "Issue Stock",
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(ctx);
                      _issueStockWithDepartment(item);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUpdateButton(
                    icon: Icons.add_box_outlined,
                    label: "Add Stock",
                    color: accentGreen,
                    onTap: () {
                      Navigator.pop(ctx);
                      _addAdditionalWithParty(item);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 42),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ADD/EDIT ITEM ====================

  void _addOrUpdateItem({Map<String, dynamic>? existingItem}) async {
    final isEdit = existingItem != null;
    String? selectedStockType;
    String? selectedSalesPerson;
    TextEditingController otherSalesCtrl = TextEditingController();

    if (isEdit) {
      selectedSalesPerson = existingItem['sales_person']?.toString();
      if (selectedSalesPerson != null &&
          !_salesPersons.contains(selectedSalesPerson)) {
        otherSalesCtrl.text = selectedSalesPerson;
        selectedSalesPerson = "Other";
      }
      selectedStockType = existingItem['stock_type']?.toString();
    }

    final codeCtrl = TextEditingController();
    if (!isEdit) {
      final autoCode = await _getNextAutoCode();
      codeCtrl.text = autoCode;
    } else {
      codeCtrl.text = existingItem["code"];
    }

    final detailCtrl = TextEditingController(
      text: isEdit ? existingItem["detail"] : '',
    );
    final inCtrl = TextEditingController(
      text: isEdit ? (existingItem["in"] ?? 0).toString() : '0',
    );
    final outCtrl = TextEditingController(
      text: isEdit ? (existingItem["out"] ?? 0).toString() : '0',
    );
    final balCtrl = TextEditingController();
    final remarkCtrl = TextEditingController(
      text: isEdit ? (existingItem["remark1"] ?? '') : '',
    );
    final locationCtrl = TextEditingController(
      text: isEdit ? (existingItem["location"] ?? "") : "",
    );
    final sizeCtrl = TextEditingController(
      text: isEdit ? (existingItem["size"] ?? "") : "",
    );
    final designNoCtrl = TextEditingController(
      text: isEdit ? (existingItem["design_no"] ?? "") : "",
    );

    String? imageUrl = isEdit ? existingItem["image"] : null;
    XFile? selectedImage;

    void calcBal() {
      final i = int.tryParse(inCtrl.text) ?? 0;
      final o = int.tryParse(outCtrl.text) ?? 0;
      balCtrl.text = (i - o).toString();
    }

    inCtrl.addListener(calcBal);
    outCtrl.addListener(calcBal);
    calcBal();

    bool isUploading = false;
    int nextSr = isEdit
        ? (existingItem["sr"] is int
              ? existingItem["sr"]
              : await _getNextSrNumber())
        : await _getNextSrNumber();
    final String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            width: 100.w,
            constraints: BoxConstraints(maxHeight: 88.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryGreen, accentGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentGreen.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_note : Icons.add_circle_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? "Edit Sweet Item" : "Add New Sweet",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEdit
                                  ? "Update item details"
                                  : "Create new stock entry",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // CONTENT
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: _imagePickerBox(
                            imageFile: selectedImage,
                            imageUrl: imageUrl,
                            onPick: () async {
                              final img = await _picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (img != null)
                                setDialogState(() => selectedImage = img);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildModernField(
                          codeCtrl,
                          "Code${!isEdit ? " (Auto-generated)" : ""}",
                          Icons.qr_code_2,
                          required: true,
                          readOnly: !isEdit,
                        ),
                        const SizedBox(height: 16),
                        _buildModernField(
                          locationCtrl,
                          "Location",
                          Icons.location_on_outlined,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernField(
                          sizeCtrl,
                          "Size",
                          Icons.straighten,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernField(
                          designNoCtrl,
                          "Design Number",
                          Icons.design_services_outlined,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernField(
                          detailCtrl,
                          "Item/Party Name",
                          Icons.cake_outlined,
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        // Stock Type
                        Container(
                          decoration: BoxDecoration(
                            color: bgGreen,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: lightGreen, width: 1.5),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _stockTypes.contains(selectedStockType)
                                ? selectedStockType
                                : null,
                            items: _stockTypes
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => selectedStockType = v),
                            decoration: InputDecoration(
                              labelText: "Stock Type *",
                              labelStyle: TextStyle(color: primaryGreen),
                              prefixIcon: Icon(
                                Icons.trending_up,
                                color: primaryGreen,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: bgGreen,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: lightGreen, width: 1.5),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _salesPersons.contains(selectedSalesPerson)
                                ? selectedSalesPerson
                                : null,
                            items: _salesPersons
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => selectedSalesPerson = v),
                            decoration: InputDecoration(
                              labelText: "Sales Person *",
                              labelStyle: TextStyle(color: primaryGreen),
                              prefixIcon: Icon(
                                Icons.person,
                                color: primaryGreen,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),

                        if (selectedSalesPerson == "Other") ...[
                          const SizedBox(height: 12),
                          _buildModernField(
                            otherSalesCtrl,
                            "Enter Sales Person Name",
                            Icons.edit,
                            required: true,
                          ),
                        ],

                        const SizedBox(height: 18),
                        Divider(color: Colors.grey[300], thickness: 1),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: bgGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: primaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Stock Information",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgGreen.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildModernField(
                                inCtrl,
                                "IN",
                                Icons.add_box,
                                isNumber: true,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernField(
                                      outCtrl,
                                      "OUT",
                                      Icons.remove_circle,
                                      isNumber: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: balCtrl,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: "Balance",
                                        filled: true,
                                        fillColor: Colors.grey[200],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.account_balance,
                                          color: primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                        _buildModernField(
                          remarkCtrl,
                          "Remark",
                          Icons.note_alt_outlined,
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [bgGreen, cardGreen],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: lightGreen, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: primaryGreen),
                              const SizedBox(width: 14),
                              Text(
                                "Date: $currentDate",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: darkGreen,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // FOOTER ACTIONS
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isUploading
                            ? null
                            : () async {
                                setDialogState(() => isUploading = true);
                                try {
                                  if (selectedImage != null)
                                    imageUrl = await _uploadImage(
                                      selectedImage!,
                                    );
                                  final code = codeCtrl.text.trim();
                                  final detail = detailCtrl.text.trim();

                                  if (!isEdit) {
                                    var existing = await _firestore
                                        .collection('readystock_sweets_items')
                                        .where('code', isEqualTo: code)
                                        .get();
                                    if (existing.docs.isNotEmpty) {
                                      _showSnackBar(
                                        "Code already exists!",
                                        isError: true,
                                      );
                                      setDialogState(() => isUploading = false);
                                      return;
                                    }
                                  }

                                  if (selectedStockType == null) {
                                    _showSnackBar(
                                      "Please select Stock Type",
                                      isError: true,
                                    );
                                    setDialogState(() => isUploading = false);
                                    return;
                                  }

                                  int finalIn = int.tryParse(inCtrl.text) ?? 0;
                                  int finalOut =
                                      int.tryParse(outCtrl.text) ?? 0;
                                  int finalBal = finalIn - finalOut;

                                  if (finalBal < 0) {
                                    _showSnackBar(
                                      "Not enough stock!",
                                      isError: true,
                                    );
                                    setDialogState(() => isUploading = false);
                                    return;
                                  }

                                  String finalSalesPerson =
                                      selectedSalesPerson ?? "";
                                  if (selectedSalesPerson == "Other") {
                                    if (otherSalesCtrl.text.trim().isEmpty) {
                                      _showSnackBar(
                                        "Please enter Sales Person name",
                                        isError: true,
                                      );
                                      setDialogState(() => isUploading = false);
                                      return;
                                    }
                                    finalSalesPerson = otherSalesCtrl.text
                                        .trim();
                                  }

                                  final newItem = {
                                    "code": code,
                                    "image": imageUrl ?? "",
                                    "detail": detail,
                                    "location": locationCtrl.text.trim(),
                                    "size": sizeCtrl.text.trim(),
                                    "design_no": designNoCtrl.text.trim(),
                                    "stock_type": selectedStockType,
                                    "sales_person": finalSalesPerson,
                                    "in": finalIn,
                                    "out": finalOut,
                                    "bal": finalBal,
                                    "remark1": remarkCtrl.text.trim(),
                                    "dateEdit": currentDate,
                                    "updatedAt": FieldValue.serverTimestamp(),
                                  };

                                  if (isEdit) {
                                    await _firestore
                                        .collection('readystock_sweets_items')
                                        .doc(existingItem["docId"])
                                        .update(newItem);
                                    _showSnackBar(
                                      "✓ Item updated successfully",
                                    );
                                  } else {
                                    newItem["sr"] = nextSr;
                                    newItem["createdAt"] =
                                        FieldValue.serverTimestamp();
                                    await _firestore
                                        .collection('readystock_sweets_items')
                                        .add(newItem);
                                    _showSnackBar("✓ Item added successfully");
                                  }

                                  await _loadDataFromFirebase();
                                  Navigator.pop(ctx);
                                } catch (e) {
                                  _showSnackBar(
                                    "Error saving item: $e",
                                    isError: true,
                                  );
                                } finally {
                                  setDialogState(() => isUploading = false);
                                }
                              },
                        icon: isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(isEdit ? Icons.check : Icons.add),
                        label: Text(
                          isEdit ? "Update Item" : "Add Item",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== EXCEL UPLOAD ====================

  Future<void> _uploadExcelFile() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        _showSnackBar("No file selected", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        _showSnackBar("Failed to read file", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      var excel = Excel.decodeBytes(fileBytes as List<int>);
      if (excel.tables.isEmpty) {
        _showSnackBar("Excel file is empty", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      var sheet = excel.tables.values.first;
      var rows = sheet.rows;
      if (rows.isEmpty) {
        _showSnackBar("No data in Excel sheet", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      var headerRow = rows[0]
          .map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '')
          .toList();
      bool hasRequired = ['code', 'detail'].every((h) => headerRow.contains(h));
      if (!hasRequired) {
        _showSnackBar("Missing required columns: code, detail", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      List<Map<String, dynamic>> importedItems = [];
      final String today = DateFormat('dd-MM-yyyy').format(DateTime.now());

      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        if (row.length < 2) continue;
        Map<String, dynamic> item = {};

        for (int j = 0; j < headerRow.length && j < row.length; j++) {
          var header = headerRow[j];
          var cell = row[j];
          var value = cell?.value;
          if (value == null) continue;

          switch (header) {
            case 'sr':
              break;
            case 'in':
            case 'out':
            case 'bal':
              item[header] = int.tryParse(value.toString()) ?? 0;
              break;
            case 'code':
            case 'detail':
            case 'image':
              item[header] = value.toString().trim();
              break;
            case 'remark':
            case 'remark1':
              item['remark1'] = value.toString().trim();
              break;
          }
        }

        if (item['code'] == null || item['detail'] == null) continue;
        item['in'] = item['in'] ?? 0;
        item['out'] = item['out'] ?? 0;
        item['bal'] = item['bal'] ?? (item['in'] - item['out']);
        item['image'] = item['image'] ?? '';
        item['remark1'] = item['remark1'] ?? '';
        item['dateEdit'] = today;
        item['sr'] = await _getNextSrNumber();
        importedItems.add(item);
      }

      if (importedItems.isEmpty) {
        _showSnackBar("No valid data found in Excel", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (var item in importedItems) {
        var existingQuery = await _firestore
            .collection('readystock_sweets_items')
            .where('code', isEqualTo: item['code'])
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          batch.update(existingQuery.docs.first.reference, {
            ...item,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          var docRef = _firestore.collection('readystock_sweets_items').doc();
          item['createdAt'] = FieldValue.serverTimestamp();
          item['updatedAt'] = FieldValue.serverTimestamp();
          batch.set(docRef, item);
        }

        batchCount++;
        if (batchCount >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) await batch.commit();
      await _loadDataFromFirebase();
      _showSnackBar(
        "✓ Excel imported! ${importedItems.length} items processed.",
      );
    } catch (e) {
      _showSnackBar("Import failed: $e", isError: true);
    }
    setState(() => _isLoading = false);
  }

  // ==================== DELETE ITEM ====================

  void _deleteItem(String docId) {
    if (docId.isEmpty) {
      _showSnackBar("Invalid document reference", isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Item?"),
        content: const Text(
          "This action cannot be undone. Are you sure you want to delete this item?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _firestore
                    .collection('readystock_sweets_items')
                    .doc(docId)
                    .delete();
                await _reorderSrNumbers();
                await _loadDataFromFirebase();
                _showSnackBar("✓ Item deleted");
              } catch (e) {
                _showSnackBar("Error: $e", isError: true);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ==================== UI HELPERS ====================

  void _showSnackBar(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isError ? Colors.red : accentGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(
      const Duration(seconds: 2),
    ).then((_) => overlayEntry.remove());
  }

  Widget _buildModernField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool required = false,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[100] : bgGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: readOnly ? Colors.grey[300]! : lightGreen,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label + (required ? " *" : ""),
          labelStyle: TextStyle(color: primaryGreen),
          prefixIcon: Icon(icon, color: primaryGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _headerFlex(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _cellFlex(String text, int flex, {bool bold = false, Color? color}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: color ?? Colors.grey[800],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _actionFlex(Map<String, dynamic> item, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.edit_outlined, color: primaryGreen, size: 18),
                onPressed: () => _addOrUpdateItem(existingItem: item),
                tooltip: "Edit",
              ),
            ),
            const SizedBox(width: 1),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 18,
                ),
                onPressed: () => _deleteItem(item["docId"] ?? ''),
                tooltip: "Delete",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _updateFlex(Map<String, dynamic> item, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        alignment: Alignment.center,
        child: ElevatedButton(
          onPressed: () => _showUpdateOptions(item),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Update",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ── Summary Card Widget ──
  Widget _summaryCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double tableWidth = screenWidth < 1200 ? 1500 : screenWidth;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF7B1FA2),
                  Color(0xFF1565C0),
                  Color(0xFF00695C),
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
                        'Ready Stock Sweets',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage ready stock sweets',
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentGreen, strokeWidth: 3),
                  const SizedBox(height: 28),
                  Text(
                    "Loading sweets stock...",
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // ── SUMMARY CARDS ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        _summaryCard(
                          title: "Total Stock (IN)",
                          value: _totalIn,
                          icon: Icons.inventory_2_outlined,
                          color: primaryGreen,
                          bgColor: bgGreen,
                        ),
                        const SizedBox(width: 8),
                        _summaryCard(
                          title: "Issue Stock (OUT)",
                          value: _totalOut,
                          icon: Icons.remove_circle_outline,
                          color: Colors.red.shade600,
                          bgColor: Colors.red.shade50,
                        ),
                        const SizedBox(width: 8),
                        _summaryCard(
                          title: "Stock in Hand (BAL)",
                          value: _totalBal,
                          icon: Icons.account_balance_outlined,
                          color: Colors.blue.shade700,
                          bgColor: Colors.blue.shade50,
                        ),
                      ],
                    ),
                  ),

                  // ── SEARCH & FILTER BAR ──
                  Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accentGreen.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgGreen,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: lightGreen, width: 1.5),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText:
                                    "Search by Code, Sweet Name, or Location...",
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: accentGreen,
                                  size: 17.sp,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              DropdownButton<String>(
                                value: _selectedTypeFilter,
                                underline: const SizedBox(),
                                icon: const Icon(
                                  Icons.filter_list,
                                  color: Colors.red,
                                ),
                                items: _typeFilters
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  setState(() => _selectedTypeFilter = v!);
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(width: 2),
                              DropdownButton<String>(
                                value: _selectedSalesFilter,
                                underline: const SizedBox(),
                                icon: Icon(Icons.person, color: accentGreen),
                                items: _salesFilterOptions
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  setState(() => _selectedSalesFilter = v!);
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton.icon(
                                onPressed: _downloadPdf,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text("PDF"),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: bgGreen,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: lightGreen, width: 1.5),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedDateFilter,
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.calendar_today,
                              color: accentGreen,
                            ),
                            items: _dateFilters
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) async {
                              if (v == 'Custom') {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  initialDateRange: _customDateRange,
                                );
                                if (picked == null) return;
                                _customDateRange = picked;
                                _selectedDateFilter = 'Custom';
                              } else {
                                _selectedDateFilter = v!;
                                _customDateRange = null;
                              }
                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── TABLE ──
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            // HEADER
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryGreen, accentGreen],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  _headerFlex("Sr", 1),
                                  _headerFlex("Code", 2),
                                  _headerFlex("Location", 2),
                                  _headerFlex("Size", 2),
                                  _headerFlex("Design No", 2),
                                  _headerFlex("Image", 2),
                                  _headerFlex("Item/Party", 3),
                                  _headerFlex("Type", 2),
                                  _headerFlex("Total Stock", 2),
                                  _headerFlex("Issue Stock", 2),
                                  _headerFlex("Stock in Hand", 2),
                                  _headerFlex("Sales Person", 2),
                                  _headerFlex("Date", 2),
                                  _headerFlex("Remarks", 3),
                                  _headerFlex("Actions", 3),
                                  _headerFlex("Update", 2),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),

                            // BODY
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.62,
                              child: ListView.builder(
                                itemCount: filteredData.length,
                                itemBuilder: (ctx, i) {
                                  final item = filteredData[i];
                                  final bal =
                                      int.tryParse(
                                        item['bal']?.toString() ?? '0',
                                      ) ??
                                      0;
                                  // Low stock highlight
                                  final rowColor = bal == 0
                                      ? Colors.red.shade50
                                      : bal <= 5
                                      ? Colors.orange.shade50
                                      : Colors.white;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: rowColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        _cellFlex("${i + 1}", 1),
                                        _cellFlex(item["code"] ?? "-", 2),
                                        _cellFlex(item["location"] ?? "-", 2),
                                        _cellFlex(item["size"] ?? "-", 2),
                                        _cellFlex(item["design_no"] ?? "-", 2),
                                        _imageCellFlex(item, 2),
                                        _cellFlex(item["detail"] ?? "-", 3),
                                        _cellFlex(item["stock_type"] ?? "-", 2),
                                        _cellFlex(
                                          "${item["in"] ?? 0}",
                                          2,
                                          bold: true,
                                          color: primaryGreen,
                                        ),
                                        _cellFlex(
                                          "${item["out"] ?? 0}",
                                          2,
                                          bold: true,
                                          color: Colors.red.shade700,
                                        ),
                                        _cellFlex(
                                          "${item["bal"] ?? 0}",
                                          2,
                                          bold: true,
                                          color: bal == 0
                                              ? Colors.red
                                              : bal <= 5
                                              ? Colors.orange.shade800
                                              : Colors.blue.shade700,
                                        ),
                                        _cellFlex(
                                          item["sales_person"] ?? "-",
                                          2,
                                        ),
                                        _cellFlex(item["dateEdit"] ?? "", 2),
                                        _cellFlex(item["remark1"] ?? "-", 3),
                                        _actionFlex(item, 3),
                                        _updateFlex(item, 2),
                                      ],
                                    ),
                                  );
                                },
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 1, left: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: _addOrUpdateItem,
              heroTag: "add_sweet",
              backgroundColor: accentGreen,
              elevation: 8,
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 15.sp,
              ),
              label: Text(
                "Add Sweet",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 5),
            FloatingActionButton.extended(
              heroTag: "fix_codes",
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.auto_fix_high, color: Colors.white),
              label: const Text(
                "Fix Codes",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _fixCodesSequentially,
            ),
            const SizedBox(width: 5),
            FloatingActionButton.extended(
              onPressed: _uploadExcelFile,
              heroTag: "upload_excel",
              backgroundColor: primaryGreen,
              elevation: 8,
              icon: Icon(
                Icons.upload_file_outlined,
                color: Colors.white,
                size: 15.sp,
              ),
              label: Text(
                "Upload Excel",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
