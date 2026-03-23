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

class StoreStockScreen extends StatefulWidget {
  const StoreStockScreen({super.key});
  @override
  _StoreStockScreenState createState() => _StoreStockScreenState();
}

class _StoreStockScreenState extends State<StoreStockScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> stockData = [];
  List<Map<String, dynamic>> filteredData = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String _selectedDateFilter = 'All';
  String _selectedMovingFilter = 'All';
  DateTimeRange? _customDateRange;
  String _selectedGroupFilter = 'All';

  static const Color primaryOrange = Color(0xFFE65100);
  static const Color lightOrange = Color(0xFFFFB74D);
  static const Color darkOrange = Color(0xFFBF360C);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color bgOrange = Color(0xFFFFF3E0);
  static const Color cardOrange = Color(0xFFFFF8F0);

  final List<String> _movingFilters = [
    'All',
    'FAST MOVING',
    'SLOW MOVING',
    'NON MOVING',
    'NEW',
    'NEW JAR',
    'ON ORDER',
  ];
  final List<String> _dateFilters = [
    'All',
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'Custom',
  ];

  List<String> _groupList = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _rowsPerPage = 20;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _selectedDateFilter = 'All';
    _selectedGroupFilter = 'All';
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

  String normalizeHeader(String h) {
    h = h.toLowerCase().trim();
    if (h.contains('code')) return 'code';
    if (h.contains('item name') || h == 'name') return 'name';
    if (h == 'group') return 'group';
    if (h.contains('received')) return 'received';
    if (h.contains('issue')) return 'issue';
    if (h.contains('stock in hand') || h == 'current') return 'current';
    if (h.contains('stock located') || h == 'located') return 'located';
    if (h.contains('moving')) return 'moving';
    if (h.contains('sr')) return 'sr';
    return h;
  }

  Future<Uint8List?> _networkImageToBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {}
    return null;
  }

  // ==================== PDF ====================

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
    List<List<dynamic>> tableData = [];

    for (var item in filteredData) {
      Uint8List? imageBytes;
      if (item['image'] != null && item['image'].toString().isNotEmpty) {
        imageBytes = await _networkImageToBytes(item['image']);
      }
      final located = int.tryParse(item['located']?.toString() ?? '0') ?? 0;
      final received = item['received'] ?? 0;
      final issue = item['issue'] ?? 0;
      final stockInHand = located + received - issue;

      tableData.add([
        item['sr']?.toString() ?? '',
        item['code'] ?? '',
        item['name'] ?? '',
        item['group'] ?? '',
        imageBytes != null
            ? pw.Image(pw.MemoryImage(imageBytes), width: 40, height: 40)
            : pw.Text('No Image'),
        located.toString(),
        received.toString(),
        issue.toString(),
        stockInHand.toString(),
        item['moving'] ?? '',
        item['dateEdit'] ?? '',
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
                      color: PdfColors.orange900,
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
            'Store Stock Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Sr',
              'Code',
              'Item Name',
              'Group',
              'Image',
              'Total Stock',
              'Received',
              'Issue',
              'Stock In Hand',
              'Moving',
              'Date',
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
        ..setAttribute('download', 'store_stock_report.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/store_stock_report.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    }
    _showSnackBar('PDF Generated');
  }

  // ==================== DATA OPERATIONS ====================

  // ✅ Sr aur Code dono ek saath — next Sr number return karta hai
  Future<int> _getNextSrNumber() async {
    try {
      final snapshot = await _firestore.collection('stock_items').get();
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

  // ✅ Code = Sr ke hisaab se — Sr 1 = DPL-001, Sr 5 = DPL-005
  String _srToCode(int sr) => 'DPL-${sr.toString().padLeft(3, '0')}';

  // ✅ Auto code = next Sr se generate hota hai
  Future<String> _getNextAutoCode() async {
    final nextSr = await _getNextSrNumber();
    return _srToCode(nextSr);
  }

  // ✅ Delete ke baad Sr renumber + Code bhi sync
  Future<void> _renumberSrNumbers() async {
    try {
      final snapshot = await _firestore
          .collection('stock_items')
          .orderBy('createdAt', descending: false)
          .get();
      WriteBatch batch = _firestore.batch();
      int sr = 1;
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'sr': sr,
          'code': _srToCode(sr), // ✅ Code bhi Sr ke saath sync
        });
        sr++;
      }
      await batch.commit();
    } catch (e) {
      _showSnackBar('Renumbering failed: $e', isError: true);
    }
  }

  // ✅ Fix Codes — Sr ke hisaab se code set karta hai
  Future<void> _fixCodesSequentially() async {
    final snapshot = await _firestore
        .collection('stock_items')
        .orderBy('createdAt')
        .get();
    WriteBatch batch = _firestore.batch();
    int counter = 1;
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'sr': counter,
        'code': _srToCode(counter), // ✅ Sr 1 = DPL-001
      });
      counter++;
    }
    await batch.commit();
    await _loadDataFromFirebase();
  }

  Future<void> _loadDataFromFirebase() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('stock_items').get();
      stockData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      stockData.sort((a, b) {
        final aSr = a['sr'];
        final bSr = b['sr'];
        if (aSr != null && bSr != null && aSr is int && bSr is int)
          return aSr.compareTo(bSr);
        final aCreated = a['createdAt'];
        final bCreated = b['createdAt'];
        if (aCreated is Timestamp && bCreated is Timestamp)
          return aCreated.compareTo(bCreated);
        return 0;
      });

      final groups =
          stockData
              .map((e) => e['group']?.toString() ?? '')
              .where((g) => g.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      _groupList = ['All', ...groups];
      if (!_groupList.contains(_selectedGroupFilter))
        _selectedGroupFilter = 'All';

      filteredData = List.from(stockData);
      _applyFilters();
    } catch (e) {
      _showSnackBar('Error loading data: $e', isError: true);
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
            item['code'].toString().toLowerCase().contains(query) ||
            item['name'].toString().toLowerCase().contains(query) ||
            (item['group'] ?? '').toString().toLowerCase().contains(query);

        bool matchesMoving =
            _selectedMovingFilter == 'All' ||
            (item['moving'] ?? '').toString().toUpperCase() ==
                _selectedMovingFilter;
        bool matchesGroup =
            _selectedGroupFilter == 'All' ||
            item['group'] == _selectedGroupFilter;

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

        return matchesSearch && matchesMoving && matchesGroup && matchesDate;
      }).toList();
      _currentPage = 0;
    });
  }

  List<Map<String, dynamic>> get _paginatedData {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filteredData.length);
    return filteredData.sublist(start, end);
  }

  // ==================== IMAGE ====================

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String fileName = 'store_${DateTime.now().millisecondsSinceEpoch}';
      final Reference ref = _storage.ref().child(
        'store_stock_images/$fileName.png',
      );
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      _showSnackBar('Image upload failed: $e', isError: true);
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
                child: Image.network(imageUrl, fit: BoxFit.contain),
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
                    border: Border.all(color: lightOrange, width: 1.5),
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
                  color: bgOrange,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: lightOrange, width: 1.5),
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
          color: bgOrange,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentOrange, width: 2),
          boxShadow: [
            BoxShadow(
              color: accentOrange.withOpacity(0.2),
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
                      color: accentOrange,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload Image',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryOrange,
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
    final qtyCtrl = TextEditingController();
    String? selectedJobCard;
    String? selectedJobLabel;
    List<QueryDocumentSnapshot> jobCardDocs = [];
    bool isLoadingJobs = true;
    bool isSubmitting = false;

    // Pehle job cards load karo
    _firestore
        .collection('jobCards')
        .orderBy('createdAt', descending: true)
        .get()
        .then((snapshot) {
          jobCardDocs = snapshot.docs;
          isLoadingJobs = false;
        });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // Job cards load karo dialog open hote hi
          if (isLoadingJobs) {
            _firestore
                .collection('jobCards')
                .orderBy('createdAt', descending: true)
                .get()
                .then((snapshot) {
                  jobCardDocs = snapshot.docs;
                  isLoadingJobs = false;
                  setStateDialog(() {});
                });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Issue Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          item['name'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stock in hand dikhao
                    Builder(
                      builder: (_) {
                        final located =
                            int.tryParse(item['located']?.toString() ?? '0') ??
                            0;
                        final received = item['received'] ?? 0;
                        final issue = item['issue'] ?? 0;
                        final stockInHand = located + received - issue;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Stock In Hand: ',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$stockInHand',
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Job Card Dropdown — FutureBuilder nahi, direct list
                    Text(
                      'Select Job Card',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    isLoadingJobs
                        ? const Center(child: CircularProgressIndicator())
                        : jobCardDocs.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'No Job Cards found.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButton<String>(
                              value: selectedJobCard,
                              isExpanded: true,
                              underline: const SizedBox(),
                              hint: const Text('Select Job Card'),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.red[700],
                              ),
                              items: jobCardDocs.map((d) {
                                final data = d.data() as Map<String, dynamic>;
                                final jobNo =
                                    data['jobCardNumber'] ??
                                    data['jobNo'] ??
                                    'N/A';
                                final dplCode = data['dplCode'] ?? '';
                                final List products = data['products'] ?? [];
                                final qty = products.isNotEmpty
                                    ? products[0]['quantity']?.toString() ?? ''
                                    : '';
                                final label =
                                    'DPL: $dplCode | Job: $jobNo | Qty: $qty';
                                return DropdownMenuItem<String>(
                                  value: d.id,
                                  child: Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setStateDialog(() {
                                  selectedJobCard = v;
                                });
                              },
                            ),
                          ),

                    const SizedBox(height: 16),

                    // Quantity field
                    Text(
                      'Quantity to Issue',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setStateDialog(() {}),
                        decoration: InputDecoration(
                          hintText: 'Enter quantity',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.numbers,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedJobCard != null && qtyCtrl.text.isNotEmpty
                      ? Colors.red[600]
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    isSubmitting ||
                        selectedJobCard == null ||
                        qtyCtrl.text.isEmpty
                    ? null
                    : () async {
                        final qty = int.tryParse(qtyCtrl.text) ?? 0;
                        if (qty <= 0) {
                          _showSnackBar('Valid quantity daalo', isError: true);
                          return;
                        }

                        final located =
                            int.tryParse(item['located']?.toString() ?? '0') ??
                            0;
                        final received = item['received'] ?? 0;
                        final currentIssue = item['issue'] ?? 0;
                        final currentStock = located + received - currentIssue;

                        if (qty > currentStock) {
                          _showSnackBar(
                            'Stock mein sirf $currentStock bacha hai!',
                            isError: true,
                          );
                          return;
                        }

                        setStateDialog(() => isSubmitting = true);

                        try {
                          // Transaction record
                          await _firestore
                              .collection('stock_transactions')
                              .add({
                                'itemId': item['docId'],
                                'type': 'issue',
                                'jobCardId': selectedJobCard,
                                'quantity': qty,
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                          // ✅ Issue column mein add karo
                          final newIssue = currentIssue + qty;
                          await _firestore
                              .collection('stock_items')
                              .doc(item['docId'])
                              .update({
                                'issue': newIssue,
                                'dateEdit': DateFormat(
                                  'dd-MM-yyyy',
                                ).format(DateTime.now()),
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                          await _loadDataFromFirebase();
                          _showSnackBar(
                            '✓ $qty issue ho gaya | Issue Total: $newIssue | Bacha: ${currentStock - qty}',
                          );
                          Navigator.pop(ctx);
                        } catch (e) {
                          _showSnackBar('Error: $e', isError: true);
                          setStateDialog(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Issue Stock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addAdditionalWithParty(Map<String, dynamic> item) {
    final partyCtrl = TextEditingController();
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
                colors: [lightOrange, accentOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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
                  'Add Stock',
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
                    color: bgOrange,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightOrange),
                  ),
                  child: TextField(
                    controller: partyCtrl,
                    decoration: InputDecoration(
                      labelText: 'Second Party Name',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(Icons.people, color: primaryOrange),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: bgOrange,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightOrange),
                  ),
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(Icons.numbers, color: primaryOrange),
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
                'Cancel',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: partyCtrl.text.trim().isEmpty || qtyCtrl.text.isEmpty
                  ? null
                  : () async {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) {
                        _showSnackBar('Enter valid quantity', isError: true);
                        return;
                      }
                      await _firestore.collection('stock_transactions').add({
                        'itemId': item['docId'],
                        'type': 'received',
                        'party': partyCtrl.text.trim(),
                        'quantity': qty,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      await _firestore
                          .collection('stock_items')
                          .doc(item['docId'])
                          .update({
                            'received': (item['received'] ?? 0) + qty,
                            'dateEdit': DateFormat(
                              'dd-MM-yyyy',
                            ).format(DateTime.now()),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                      await _loadDataFromFirebase();
                      _showSnackBar(
                        '✓ Received $qty from ${partyCtrl.text.trim()}',
                      );
                      Navigator.pop(ctx);
                    },
              child: const Text(
                'Add Stock',
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
              'Update Stock',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryOrange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['name'] ?? '',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _buildUpdateButton(
                    icon: Icons.remove_circle_outline,
                    label: 'Issue Stock',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(ctx);
                      _issueStockWithDepartment(item);
                    },
                  ),
                ),
                // const SizedBox(width: 16),
                // Expanded(
                //   child: _buildUpdateButton(
                //     icon: Icons.add_box_outlined,
                //     label: 'Add Stock',
                //     color: accentOrange,
                //     onTap: () {
                //       Navigator.pop(ctx);
                //       _addAdditionalWithParty(item);
                //     },
                //   ),
                // ),
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
    final codeCtrl = TextEditingController();
    if (!isEdit) {
      codeCtrl.text = await _getNextAutoCode();
    } else {
      codeCtrl.text = existingItem['code'] ?? '';
    }

    final nameCtrl = TextEditingController(
      text: isEdit ? existingItem['name'] : '',
    );
    final groupCtrl = TextEditingController(
      text: isEdit ? existingItem['group'] : '',
    );
    final locatedCtrl = TextEditingController(
      text: isEdit ? (existingItem['located'] ?? 0).toString() : '0',
    );
    final receivedCtrl = TextEditingController(
      text: isEdit ? (existingItem['received'] ?? 0).toString() : '0',
    );
    final issueCtrl = TextEditingController(text: '0');
    String movingValue = isEdit
        ? (existingItem['moving'] ?? 'FAST MOVING')
        : 'FAST MOVING';
    String? imageUrl = isEdit ? existingItem['image'] : null;
    XFile? selectedImage;
    bool isUploading = false;
    int nextSr = isEdit
        ? (existingItem['sr'] is int
              ? existingItem['sr']
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
                      colors: [primaryOrange, accentOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
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
                              isEdit ? 'Edit Stock Item' : 'Add New Stock Item',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEdit
                                  ? 'Update item details'
                                  : 'Create new stock entry',
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
                          'Code${!isEdit ? " (Auto-generated)" : ""}',
                          Icons.qr_code_2,
                          required: true,
                          readOnly: !isEdit,
                        ),
                        const SizedBox(height: 16),
                        _buildModernField(
                          nameCtrl,
                          'Item Name',
                          Icons.inventory,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernField(
                          groupCtrl,
                          'Group / Category',
                          Icons.category_outlined,
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: bgOrange,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: lightOrange, width: 1.5),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: movingValue,
                            items:
                                [
                                      'FAST MOVING',
                                      'SLOW MOVING',
                                      'NON MOVING',
                                      'NEW',
                                      'NEW JAR',
                                      'ON ORDER',
                                    ]
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) =>
                                setDialogState(() => movingValue = v!),
                            decoration: InputDecoration(
                              labelText: 'Moving Status *',
                              labelStyle: TextStyle(color: primaryOrange),
                              prefixIcon: Icon(
                                Icons.trending_up,
                                color: primaryOrange,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Divider(color: Colors.grey[300], thickness: 1),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: bgOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: primaryOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Stock Information',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: primaryOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgOrange.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // ✅ 'Total Stock' label (tumhara change)
                              _buildModernField(
                                locatedCtrl,
                                'Total Stock',
                                Icons.inventory_2_outlined,
                                isNumber: true,
                              ),
                              const SizedBox(height: 12),
                              _buildModernField(
                                receivedCtrl,
                                isEdit ? 'Add More Received' : 'Received Stock',
                                Icons.add_box,
                                isNumber: true,
                              ),
                              const SizedBox(height: 12),
                              _buildModernField(
                                issueCtrl,
                                isEdit ? 'Add More Issue' : 'Issue Stock',
                                Icons.remove_circle,
                                isNumber: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [bgOrange, cardOrange],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: lightOrange, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: primaryOrange),
                              const SizedBox(width: 14),
                              Text(
                                'Date: $currentDate',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: darkOrange,
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

                // FOOTER
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
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
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
                                  final name = nameCtrl.text.trim();
                                  final group = groupCtrl.text.trim();
                                  if (code.isEmpty ||
                                      name.isEmpty ||
                                      group.isEmpty) {
                                    _showSnackBar(
                                      'Please fill all required fields',
                                      isError: true,
                                    );
                                    setDialogState(() => isUploading = false);
                                    return;
                                  }
                                  if (!isEdit) {
                                    final existing = await _firestore
                                        .collection('stock_items')
                                        .where('code', isEqualTo: code)
                                        .get();
                                    if (existing.docs.isNotEmpty) {
                                      _showSnackBar(
                                        'Code already exists!',
                                        isError: true,
                                      );
                                      setDialogState(() => isUploading = false);
                                      return;
                                    }
                                  }

                                  final inputReceived =
                                      int.tryParse(receivedCtrl.text) ?? 0;
                                  final inputIssue =
                                      int.tryParse(issueCtrl.text) ?? 0;
                                  final located =
                                      int.tryParse(locatedCtrl.text) ?? 0;
                                  int finalReceived = isEdit
                                      ? (existingItem['received'] ?? 0) +
                                            inputReceived
                                      : inputReceived;
                                  int finalIssue = isEdit
                                      ? (existingItem['issue'] ?? 0) +
                                            inputIssue
                                      : inputIssue;
                                  final stockInHand =
                                      located + finalReceived - finalIssue;

                                  if (stockInHand < 0) {
                                    _showSnackBar(
                                      'Not enough stock!',
                                      isError: true,
                                    );
                                    setDialogState(() => isUploading = false);
                                    return;
                                  }

                                  final newItem = {
                                    'code': code,
                                    'image': imageUrl ?? '',
                                    'name': name,
                                    'group': group,
                                    'located': located,
                                    'received': finalReceived,
                                    'issue': finalIssue,
                                    'moving': movingValue,
                                    'dateEdit': currentDate,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  };

                                  if (isEdit) {
                                    await _firestore
                                        .collection('stock_items')
                                        .doc(existingItem['docId'])
                                        .update(newItem);
                                    _showSnackBar(
                                      '✓ Item updated successfully',
                                    );
                                  } else {
                                    // ✅ Sr aur Code sync — Sr 1 = DPL-001
                                    newItem['sr'] = nextSr;
                                    newItem['code'] = _srToCode(nextSr);
                                    newItem['createdAt'] =
                                        FieldValue.serverTimestamp();
                                    await _firestore
                                        .collection('stock_items')
                                        .add(newItem);
                                    _showSnackBar('✓ Item added successfully');
                                  }
                                  await _loadDataFromFirebase();
                                  Navigator.pop(ctx);
                                } catch (e) {
                                  _showSnackBar(
                                    'Error saving item: $e',
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
                          isEdit ? 'Update Item' : 'Add Item',
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
        _showSnackBar('No file selected', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        _showSnackBar('Failed to read file', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      var excel = Excel.decodeBytes(fileBytes as List<int>);
      if (excel.tables.isEmpty) {
        _showSnackBar('Excel file is empty', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      var sheet = excel.tables.values.first;
      var rows = sheet.rows;
      if (rows.isEmpty) {
        _showSnackBar('No data in Excel sheet', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      var headerRow = rows[0]
          .map((cell) => normalizeHeader(cell?.value?.toString().trim() ?? ''))
          .toList();
      bool hasRequired = [
        'code',
        'name',
        'group',
      ].every((h) => headerRow.contains(h));
      if (!hasRequired) {
        _showSnackBar(
          'Missing required columns: code, name, group',
          isError: true,
        );
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
          var value = row[j]?.value;
          if (value == null) continue;
          switch (header) {
            case 'sr':
              break;
            case 'located':
            case 'received':
            case 'issue':
              item[header] = int.tryParse(value.toString()) ?? 0;
              break;
            case 'code':
            case 'name':
            case 'group':
            case 'moving':
            case 'image':
              item[header] = value.toString().trim();
              break;
          }
        }
        if (item['code'] == null ||
            item['name'] == null ||
            item['group'] == null)
          continue;
        item['located'] = item['located'] ?? 0;
        item['received'] = item['received'] ?? 0;
        item['issue'] = item['issue'] ?? 0;
        item['moving'] = (item['moving'] ?? 'FAST MOVING')
            .toString()
            .toUpperCase();
        item['image'] = item['image'] ?? '';
        item['dateEdit'] = today;
        // Sr aur Code sync
        final assignedSr = await _getNextSrNumber();
        item['sr'] = assignedSr;
        item['code'] = _srToCode(assignedSr);
        importedItems.add(item);
      }

      if (importedItems.isEmpty) {
        _showSnackBar('No valid data found in Excel', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      for (var item in importedItems) {
        var existingQuery = await _firestore
            .collection('stock_items')
            .where('sr', isEqualTo: item['sr'])
            .limit(1)
            .get();
        if (existingQuery.docs.isNotEmpty) {
          batch.update(existingQuery.docs.first.reference, {
            ...item,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          var docRef = _firestore.collection('stock_items').doc();
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
        '✓ Excel imported! ${importedItems.length} items processed.',
      );
    } catch (e) {
      _showSnackBar('Import failed: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  // ==================== DELETE ====================

  void _deleteItem(String docId) {
    if (docId.isEmpty) {
      _showSnackBar('Invalid document reference', isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Item?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _firestore.collection('stock_items').doc(docId).delete();
                await _renumberSrNumbers();
                await _loadDataFromFirebase();
                _showSnackBar('✓ Item deleted');
              } catch (e) {
                _showSnackBar('Error: $e', isError: true);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
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
              color: isError ? Colors.red : accentOrange,
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
        color: readOnly ? Colors.grey[100] : bgOrange,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: readOnly ? Colors.grey[300]! : lightOrange,
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
          labelText: label + (required ? ' *' : ''),
          labelStyle: TextStyle(color: primaryOrange),
          prefixIcon: Icon(icon, color: primaryOrange),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _headerFlex(String text, int flex) => Expanded(
    flex: flex,
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _cellFlex(String text, int flex, {bool bold = false, Color? color}) =>
      Expanded(
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

  Widget _statusCellFlex(String status, int flex) {
    Color bgColor;
    switch (status.toUpperCase()) {
      case 'FAST MOVING':
        bgColor = Colors.green[600]!;
        break;
      case 'SLOW MOVING':
        bgColor = Colors.orange[600]!;
        break;
      case 'NON MOVING':
        bgColor = Colors.red[600]!;
        break;
      default:
        bgColor = Colors.grey[600]!;
    }
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _actionFlex(Map<String, dynamic> item, int flex) => Expanded(
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
              color: accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.edit_outlined, color: primaryOrange, size: 18),
              onPressed: () => _addOrUpdateItem(existingItem: item),
              tooltip: 'Edit',
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
              onPressed: () => _deleteItem(item['docId'] ?? ''),
              tooltip: 'Delete',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _updateFlex(Map<String, dynamic> item, int flex) => Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: () => _showUpdateOptions(item),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: const Text(
          'Update',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double tableWidth = screenWidth < 1200 ? 1600 : screenWidth;

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
                  Color(0xFFE65100),
                  Color(0xFFFF9800),
                  Color(0xFFFFB300),
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
                        'Store Stock Report',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track & manage store stock',
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
                  CircularProgressIndicator(
                    color: accentOrange,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Loading store stock...',
                    style: TextStyle(
                      color: primaryOrange,
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
                  // SEARCH & FILTER BAR
                  Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accentOrange.withOpacity(0.1),
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
                              color: bgOrange,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: lightOrange,
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by Code, Name, or Group...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: accentOrange,
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
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentOrange, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              DropdownButton<String>(
                                value: _selectedMovingFilter,
                                underline: const SizedBox(),
                                icon: Icon(
                                  Icons.filter_list,
                                  color: primaryOrange,
                                ),
                                items: _movingFilters
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  setState(() => _selectedMovingFilter = v!);
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(width: 4),
                              DropdownButton<String>(
                                value: _selectedGroupFilter,
                                underline: const SizedBox(),
                                icon: Icon(
                                  Icons.category,
                                  color: primaryOrange,
                                ),
                                items: _groupList
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(
                                          g == 'All' ? 'All Groups' : g,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  setState(() => _selectedGroupFilter = v!);
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
                                label: const Text('PDF'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: bgOrange,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: lightOrange, width: 1.5),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedDateFilter,
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.calendar_today,
                              color: accentOrange,
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

                  // TABLE
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryOrange, accentOrange],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  _headerFlex('Sr', 1),
                                  _headerFlex('Code', 2),
                                  _headerFlex('Image', 2),
                                  _headerFlex('Item Name', 3),
                                  _headerFlex('Group', 2),
                                  _headerFlex(
                                    'Total Stock',
                                    2,
                                  ), // ✅ tumhara change
                                  _headerFlex('Received', 2),
                                  _headerFlex('Issue', 2),
                                  _headerFlex('Stock In Hand', 2),
                                  _headerFlex('Moving', 2),
                                  _headerFlex('Date', 2),
                                  _headerFlex('Actions', 3),
                                  _headerFlex('Update', 2),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),

                            Expanded(
                              child: ListView.builder(
                                itemCount: _paginatedData.length,
                                itemBuilder: (ctx, i) {
                                  final item = _paginatedData[i];
                                  final located =
                                      int.tryParse(
                                        item['located']?.toString() ?? '0',
                                      ) ??
                                      0;
                                  final received = item['received'] ?? 0;
                                  final issue = item['issue'] ?? 0;
                                  final stockInHand =
                                      located + received - issue;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        _cellFlex(
                                          item['sr']?.toString() ??
                                              '${(_currentPage * _rowsPerPage) + i + 1}',
                                          1,
                                        ),
                                        _cellFlex(
                                          item['code'] ?? '-',
                                          2,
                                          bold: true,
                                        ),
                                        _imageCellFlex(item, 2),
                                        _cellFlex(
                                          item['name'] ?? '-',
                                          3,
                                          bold: true,
                                          color: Colors.blue[700],
                                        ),
                                        _cellFlex(item['group'] ?? '-', 2),
                                        _cellFlex(located.toString(), 2),
                                        _cellFlex(received.toString(), 2),
                                        _cellFlex(issue.toString(), 2),
                                        _cellFlex(
                                          stockInHand.toString(),
                                          2,
                                          bold: true,
                                          color: stockInHand <= 0
                                              ? Colors.red[700]
                                              : Colors.green[800],
                                        ),
                                        _statusCellFlex(
                                          (item['moving'] ?? '-')
                                              .toString()
                                              .toUpperCase(),
                                          2,
                                        ),
                                        _cellFlex(item['dateEdit'] ?? '-', 2),
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

                  // PAGINATION
                  if (filteredData.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accentOrange.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Showing ${(_currentPage * _rowsPerPage) + 1}–${((_currentPage + 1) * _rowsPerPage).clamp(0, filteredData.length)} of ${filteredData.length}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                          ),
                          DropdownButton<int>(
                            value: _rowsPerPage,
                            underline: const SizedBox(),
                            items: [10, 20, 50]
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text('$n / page'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() {
                              _rowsPerPage = v!;
                              _currentPage = 0;
                            }),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed:
                                (_currentPage + 1) * _rowsPerPage <
                                    filteredData.length
                                ? () => setState(() => _currentPage++)
                                : null,
                          ),
                        ],
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
              heroTag: 'add_store_item',
              backgroundColor: accentOrange,
              elevation: 8,
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 15.sp,
              ),
              label: Text(
                'Add Item',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 5),
            FloatingActionButton.extended(
              heroTag: 'fix_codes_store',
              backgroundColor: Colors.deepOrange,
              icon: const Icon(Icons.auto_fix_high, color: Colors.white),
              label: const Text(
                'Fix Codes',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _fixCodesSequentially,
            ),
            const SizedBox(width: 5),
            FloatingActionButton.extended(
              onPressed: _uploadExcelFile,
              heroTag: 'upload_excel_store',
              backgroundColor: primaryOrange,
              elevation: 8,
              icon: Icon(
                Icons.upload_file_outlined,
                color: Colors.white,
                size: 15.sp,
              ),
              label: Text(
                'Upload Excel',
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
