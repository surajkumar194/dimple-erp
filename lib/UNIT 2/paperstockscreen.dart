import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
import 'package:open_file/open_file.dart';

class PaperStockScreen extends StatefulWidget {
  const PaperStockScreen({super.key});
  @override
  _PaperStockScreenState createState() => _PaperStockScreenState();

}
class _PaperStockScreenState extends State<PaperStockScreen>
with SingleTickerProviderStateMixin {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseStorage _storage = FirebaseStorage.instance;
final ImagePicker _picker = ImagePicker();
List<Map<String, dynamic>> stockData = [];
List<Map<String, dynamic>> filteredData = [];
final TextEditingController _searchController = TextEditingController();
String? selectedPosition;
bool _isLoading = false;
String _selectedDateFilter = 'All';
DateTimeRange? _customDateRange;
String _selectedTypeFilter = "All";
String _selectedRangeFilter = "All";
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
  String? _selectedGroup;
  List<String> _groupList = [];
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
  Future<void> _reorderPaperSrNumbers() async {
    final snapshot = await _firestore
        .collection('paper_stock_items')
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
  Widget _buildStockSummary() {
    final totals = _calculateStockTotals();
    return Container(
     margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      // padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accentGreen.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryCard("Top Stock", totals["top"].toString(), Colors.blue),
          _summaryCard(
            "Bottom Stock",
            totals["bottom"].toString(),
            Colors.orange,
          ),
          _summaryCard("Overall", totals["overall"].toString(), primaryGreen),
        ],
      ),
    );
  }
List<Map<String, dynamic>> _filterForPdf() {
  final now = DateTime.now();

  return stockData.where((item) {
    bool typeMatch =
        _selectedTypeFilter == "All" || item["stock_type"] == _selectedTypeFilter;

    bool dateMatch = true;

    if (_selectedRangeFilter != "All") {
      try {
        DateTime itemDate =
            DateFormat('dd-MM-yyyy').parse(item['dateEdit']);

        if (_selectedRangeFilter == "1 Day") {
          dateMatch = itemDate.isAfter(now.subtract(Duration(days: 1)));
        } else if (_selectedRangeFilter == "2 Day") {
          dateMatch = itemDate.isAfter(now.subtract(Duration(days: 2)));
        } else if (_selectedRangeFilter == "1 Week") {
          dateMatch = itemDate.isAfter(now.subtract(Duration(days: 7)));
        } else if (_selectedRangeFilter == "1 Month") {
          dateMatch = itemDate.isAfter(now.subtract(Duration(days: 30)));
        }
      } catch (e) {}
    }
    return typeMatch && dateMatch;
  }).toList();
}Future<Uint8List?> _networkImageToBytes(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
  } catch (e) {}
  return null;
}
  Widget _summaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 0.1),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color bgGreen = Color(0xFFE8F5E9);
  static const Color cardGreen = Color(0xFFF1F8F4);
  Future<void> _fixPaperCodesSequentially() async {
    final snapshot = await _firestore
        .collection('paper_stock_items')
        .orderBy('sr') 
        .get();
    WriteBatch batch = _firestore.batch();
    int counter = 1;
    for (var doc in snapshot.docs) {
      final newCode = "HSP-LB-${counter.toString().padLeft(2, '0')}";
      batch.update(doc.reference, {
        "code": newCode,
        "updatedAt": FieldValue.serverTimestamp(),
      });
      counter++;
    }
    await batch.commit();
    await _loadDataFromFirebase();
    _showSnackBar("✓ Codes fixed sequentially");
  }
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
  Future<int> _getNextSrNumber() async {
    try {
      final snapshot = await _firestore.collection('paper_stock_items').get();
      int maxSr = 0;
      for (var doc in snapshot.docs) {
        final sr = doc.data()['sr'];
        if (sr != null && sr is int && sr > maxSr) {
          maxSr = sr;
        }
      }
      return maxSr + 1;
    } catch (e) {
      return 1;
    }
  }
  Future<String> _getNextPaperCode() async {
    try {
      final snapshot = await _firestore.collection('paper_stock_items').get();
      if (snapshot.docs.isEmpty) {
        return "HSP-LB-01";
      }
      final List<int> numbers = [];
      for (var doc in snapshot.docs) {
        final code = doc.data()['code']?.toString();
        if (code != null && code.startsWith("HSP-LB-")) {
          final parts = code.split('-');
          if (parts.length == 3) {
            final num = int.tryParse(parts[2]);
            if (num != null) numbers.add(num);
          }
        }
      }
      numbers.sort();
      int nextNumber = 1;
      for (final n in numbers) {
        if (n == nextNumber) {
          nextNumber++;
        } else if (n > nextNumber) {
          break;
        }
      }
      return "HSP-LB-${nextNumber.toString().padLeft(2, '0')}";
    } catch (e) {
      return "HSP-LB-01";
    }
  }
  Future<void> _loadDataFromFirebase() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('paper_stock_items')
          .orderBy('sr') 
          .get();
      stockData = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['docId'] = doc.id;
        data['sr'] = data['sr'] ?? '-';
        return data;
      }).toList();
      final groups =
          stockData
              .map((e) => e['piller_no']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      _groupList = ['All', ...groups];
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
            item["piller_no"].toString().toLowerCase().contains(query) ||
            item["location"].toString().toLowerCase().contains(query) ||
            item["design_no"].toString().toLowerCase().contains(query);
        final matchesGroup =
            _selectedGroup == 'All' || item['piller_no'] == _selectedGroup;
        bool matchesDate = true;
        if (_selectedDateFilter != 'All') {
          try {
            DateTime? itemDate;

            if (item['dateEdit'] != null &&
                item['dateEdit'].toString().isNotEmpty) {
              itemDate = DateFormat('dd-MM-yyyy').parse(item['dateEdit']);
            }
            if (itemDate == null) return matchesSearch && matchesGroup;
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
          } catch (_) {
            matchesDate = true;
          }
        }
        return matchesSearch && matchesGroup && matchesDate;
      }).toList();
    });
  }

  Map<String, dynamic> _calculateStockTotals() {
    int totalTop = 0;
    int totalBottom = 0;
    Map<String, Map<String, int>> sizeTotals = {};
    for (final item in filteredData) {
      final top = (item['top_bal'] ?? 0) as int;
      final bottom = (item['bottom_bal'] ?? 0) as int;
      final size = item['piller_no']?.toString() ?? 'Unknown';
      totalTop += top;
      totalBottom += bottom;
      if (!sizeTotals.containsKey(size)) {
        sizeTotals[size] = {"top": 0, "bottom": 0};
      }
      sizeTotals[size]!["top"] = sizeTotals[size]!["top"]! + top;
      sizeTotals[size]!["bottom"] = sizeTotals[size]!["bottom"]! + bottom;
    }
    return {
      "top": totalTop,
      "bottom": totalBottom,
      "overall": totalTop + totalBottom,
      "sizeTotals": sizeTotals,
    };
  }
  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String fileName = 'paper_${DateTime.now().millisecondsSinceEpoch}';
      final Reference ref = _storage.ref().child(
        'paper_stock_images/$fileName.png',
      );
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
    final topUrl = item['top_image'];
    final bottomUrl = item['bottom_image'];
    final positionType = item['position_type'];

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
        child: Row(
          children: [
            if ((positionType == 'Top' || positionType == 'Both') &&
                topUrl != null &&
                topUrl.toString().isNotEmpty)
              _smallImage("TOP", topUrl),
            if ((positionType == 'Bottom' || positionType == 'Both') &&
                bottomUrl != null &&
                bottomUrl.toString().isNotEmpty)
              _smallImage("BOTTOM", bottomUrl),
          ],
        ),
      ),
    );
  }

  Widget _smallImage(String label, String url) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
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
                width: 34,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePickerBox({
    XFile? imageFile,
    String? imageUrl,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
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
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
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
        ),
      ],
    );
  }
  void _issueStockWithDepartment(Map<String, dynamic> item) {
    String? selectedDept;
    String? selectedPos;
    final qtyCtrl = TextEditingController();
    final positionType = item['position_type'];
    if (positionType == 'Top') {
      selectedPos = 'Top';
    } else if (positionType == 'Bottom') {
      selectedPos = 'Bottom';
    }
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                if (positionType == 'Both')
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedPos,
                      hint: const Text("Select Position"),
                      items: const [
                        DropdownMenuItem(value: 'Top', child: Text('Top')),
                        DropdownMenuItem(
                          value: 'Bottom',
                          child: Text('Bottom'),
                        ),
                      ],
                      onChanged: (v) => setStateDialog(() => selectedPos = v),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(Icons.layers, color: Colors.red[700]),
                      ),
                    ),
                  ),

                if (positionType == 'Both') const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
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
                elevation: 2,
              ),
              onPressed:
                  selectedDept == null ||
                      qtyCtrl.text.isEmpty ||
                      (positionType == 'Both' && selectedPos == null)
                  ? null
                  : () async {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) {
                        _showSnackBar("Enter valid quantity", isError: true);
                        return;
                      }

                      // ✅ FIXED: Properly determine which position to update
                      final isTop = selectedPos == 'Top';
                      final balKey = isTop ? 'top_bal' : 'bottom_bal';
                      final outKey = isTop ? 'top_out' : 'bottom_out';

                      final currentBal = item[balKey] ?? 0;
                      if (currentBal < qty) {
                        _showSnackBar("Not enough stock!", isError: true);
                        return;
                      }

                      await _firestore
                          .collection('paper_stock_items')
                          .doc(item['docId'])
                          .update({
                            balKey: currentBal - qty,
                            outKey: (item[outKey] ?? 0) + qty,
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

  // ✅ FIXED ADD STOCK - Now properly handles position selection
  void _addAdditionalWithParty(Map<String, dynamic> item) {
    String? selectedParty;
    String? selectedPos;
    final qtyCtrl = TextEditingController();
    final positionType = item['position_type'];

    // Auto-select position if only one option available
    if (positionType == 'Top') {
      selectedPos = 'Top';
    } else if (positionType == 'Bottom') {
      selectedPos = 'Bottom';
    }

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
                colors: [lightGreen, accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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

                // Position Dropdown (if Both)
                if (positionType == 'Both')
                  Container(
                    decoration: BoxDecoration(
                      color: bgGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lightGreen),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedPos,
                      hint: const Text("Select Position"),
                      items: const [
                        DropdownMenuItem(value: 'Top', child: Text('Top')),
                        DropdownMenuItem(
                          value: 'Bottom',
                          child: Text('Bottom'),
                        ),
                      ],
                      onChanged: (v) => setStateDialog(() => selectedPos = v),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(Icons.layers, color: primaryGreen),
                      ),
                    ),
                  ),

                if (positionType == 'Both') const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: bgGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightGreen),
                  ),
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
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
                elevation: 2,
              ),
              onPressed:
                  selectedParty == null ||
                      qtyCtrl.text.isEmpty ||
                      (positionType == 'Both' && selectedPos == null)
                  ? null
                  : () async {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) {
                        _showSnackBar("Enter valid quantity", isError: true);
                        return;
                      }

                      // ✅ FIXED: Properly determine which position to update
                      final isTop = selectedPos == 'Top';
                      final balKey = isTop ? 'top_bal' : 'bottom_bal';
                      final inKey = isTop ? 'top_in' : 'bottom_in';

                      final currentBal = item[balKey] ?? 0;
                      final currentIn = item[inKey] ?? 0;

                      await _firestore
                          .collection('paper_stock_items')
                          .doc(item['docId'])
                          .update({
                            balKey: currentBal + qty,
                            inKey: currentIn + qty,
                            'dateEdit': DateFormat(
                              'dd-MM-yyyy',
                            ).format(DateTime.now()),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                      await _firestore
                          .collection('paper_stock_transactions')
                          .add({
                            'itemId': item['docId'],
                            'type': 'received',
                            'party': selectedParty,
                            'quantity': qty,
                            'position': selectedPos,
                            'timestamp': FieldValue.serverTimestamp(),
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

    if (isEdit) {
      selectedStockType = existingItem['stock_type']?.toString();
    }

    final codeCtrl = TextEditingController(
      text: isEdit ? existingItem["code"] : await _getNextPaperCode(),
    );

    final detailCtrl = TextEditingController(
      text: isEdit ? existingItem["detail"] : '',
    );
    final pillerCtrl = TextEditingController(
      text: isEdit ? existingItem["piller_no"] : '',
    );
    final topInCtrl = TextEditingController(
      text: isEdit ? (existingItem["top_in"] ?? 0).toString() : '0',
    );
    final topOutCtrl = TextEditingController(
      text: isEdit ? (existingItem["top_out"] ?? 0).toString() : '0',
    );
    final topBalCtrl = TextEditingController();

    final bottomInCtrl = TextEditingController(
      text: isEdit ? (existingItem["bottom_in"] ?? 0).toString() : '0',
    );
    final bottomOutCtrl = TextEditingController(
      text: isEdit ? (existingItem["bottom_out"] ?? 0).toString() : '0',
    );
    final locationCtrl = TextEditingController(
      text: isEdit ? (existingItem["location"] ?? "") : "",
    );

    final designNoCtrl = TextEditingController(
      text: isEdit ? (existingItem["design_no"] ?? "") : "",
    );

    final bottomBalCtrl = TextEditingController();

    final remarkCtrl = TextEditingController(
      text: isEdit ? (existingItem["remark1"] ?? '') : '',
    );

    final item = existingItem ?? {};
    String positionType = isEdit
        ? item['position_type']?.toString() ?? 'Top'
        : 'Top';
    String? topImageUrl = isEdit ? item['top_image']?.toString() : null;
    String? bottomImageUrl = isEdit ? item['bottom_image']?.toString() : null;
    XFile? topImageFile;
    XFile? bottomImageFile;

    void calcTopBal() {
      final i = int.tryParse(topInCtrl.text) ?? 0;
      final o = int.tryParse(topOutCtrl.text) ?? 0;
      topBalCtrl.text = (i - o).toString();
    }

    void calcBottomBal() {
      final i = int.tryParse(bottomInCtrl.text) ?? 0;
      final o = int.tryParse(bottomOutCtrl.text) ?? 0;
      bottomBalCtrl.text = (i - o).toString();
    }

    topInCtrl.addListener(calcTopBal);
    topOutCtrl.addListener(calcTopBal);
    bottomInCtrl.addListener(calcBottomBal);
    bottomOutCtrl.addListener(calcBottomBal);

    calcTopBal();
    calcBottomBal();

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
                              isEdit ? "Edit Paper Item" : "Add New Paper",
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
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModernField(
                          codeCtrl,
                          "Paper Code${!isEdit ? " (Auto-generated)" : ""}",
                          Icons.qr_code_2,
                          required: true,
                          readOnly: !isEdit,
                        ),
                        const SizedBox(height: 8),

                        _buildModernField(
                          locationCtrl,
                          "Location",
                          Icons.location_on_outlined,
                          required: true,
                        ),

                        const SizedBox(height: 8),

                        _buildModernField(
                          designNoCtrl,
                          "Design Number",
                          Icons.design_services_outlined,
                          required: true,
                        ),

                        const SizedBox(height: 8),

                        _buildModernField(
                          detailCtrl,
                          "Paper Detail",
                          Icons.description_outlined,
                          required: true,
                        ),
                        const SizedBox(height: 8),

                        // Position Type
                        Container(
                          decoration: BoxDecoration(
                            color: bgGreen,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: lightGreen, width: 1.5),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: positionType,
                            items: const [
                              DropdownMenuItem(
                                value: 'Top',
                                child: Text('Top'),
                              ),
                              DropdownMenuItem(
                                value: 'Bottom',
                                child: Text('Bottom'),
                              ),
                              DropdownMenuItem(
                                value: 'Both',
                                child: Text('Both'),
                              ),
                            ],
                            onChanged: (v) {
                              setDialogState(() => positionType = v!);
                            },
                            decoration: InputDecoration(
                              labelText: "Position Type *",
                              labelStyle: TextStyle(color: primaryGreen),
                              prefixIcon: Icon(
                                Icons.layers_outlined,
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

                        // Image Pickers
                        if (positionType == 'Top' ||
                            positionType == 'Both') ...[
                          const SizedBox(height: 18),
                          Text(
                            "Top Image",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _imagePickerBox(
                            imageFile: topImageFile,
                            imageUrl: topImageUrl,
                            onPick: () async {
                              final img = await _picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (img != null) {
                                setDialogState(() => topImageFile = img);
                              }
                            },
                          ),
                        ],

                        if (positionType == 'Bottom' ||
                            positionType == 'Both') ...[
                          const SizedBox(height: 18),
                          Text(
                            "Bottom Image",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _imagePickerBox(
                            imageFile: bottomImageFile,
                            imageUrl: bottomImageUrl,
                            onPick: () async {
                              final img = await _picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (img != null) {
                                setDialogState(() => bottomImageFile = img);
                              }
                            },
                          ),
                        ],

                        const SizedBox(height: 18),

                        _buildModernField(
                          pillerCtrl,
                          "Size of Sheet",
                          Icons.straighten,
                          required: true,
                        ),
                        const SizedBox(height: 8),

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
                            onChanged: (v) {
                              setDialogState(() => selectedStockType = v);
                            },
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

                        const SizedBox(height: 18),
                        Divider(color: Colors.grey[300], thickness: 1),
                        const SizedBox(height: 10),

                        // Stock Information Header
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

                        // TOP STOCK
                        if (positionType == 'Top' ||
                            positionType == 'Both') ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgGreen.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TOP STOCK",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildModernField(
                                  topInCtrl,
                                  "Top Total",
                                  Icons.add,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 12),
                                _buildModernField(
                                  topOutCtrl,
                                  "Top Issue",
                                  Icons.remove,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: topBalCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: "Top Balance",
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // BOTTOM STOCK
                        if (positionType == 'Bottom' ||
                            positionType == 'Both') ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgGreen.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "BOTTOM STOCK",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildModernField(
                                  bottomInCtrl,
                                  "Bottom Total",
                                  Icons.add,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 12),
                                _buildModernField(
                                  bottomOutCtrl,
                                  "Bottom Issue",
                                  Icons.remove,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: bottomBalCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: "Bottom Balance",
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),
                        _buildModernField(
                          remarkCtrl,
                          "Remark",
                          Icons.note_alt_outlined,
                        ),
                        const SizedBox(height: 20),

                        // Date Display
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
                          elevation: 2,
                        ),
                        onPressed: isUploading
                            ? null
                            : () async {
                                setDialogState(() => isUploading = true);

                                try {
                                  // Upload images
                                  if (topImageFile != null) {
                                    topImageUrl = await _uploadImage(
                                      topImageFile!,
                                    );
                                  }
                                  if (bottomImageFile != null) {
                                    bottomImageUrl = await _uploadImage(
                                      bottomImageFile!,
                                    );
                                  }

                                  // Validation
                                  final code = codeCtrl.text.trim();
                                  final detail = detailCtrl.text.trim();
                                  final piller = pillerCtrl.text.trim();

                                  if (code.isEmpty ||
                                      detail.isEmpty ||
                                      piller.isEmpty) {
                                    _showSnackBar(
                                      "Please fill all required fields",
                                      isError: true,
                                    );
                                    return;
                                  }

                                  if (selectedStockType == null) {
                                    _showSnackBar(
                                      "Please select Stock Type",
                                      isError: true,
                                    );
                                    return;
                                  }

                                  if (positionType == 'Both' &&
                                      (topImageUrl == null ||
                                          bottomImageUrl == null)) {
                                    _showSnackBar(
                                      "Please upload both Top and Bottom images",
                                      isError: true,
                                    );
                                    return;
                                  }

                                  final newItem = {
                                    "code": code,
                                    "detail": detail,
                                    "piller_no": piller,
                                    "location": locationCtrl.text.trim(),
                                    "design_no": designNoCtrl.text.trim(),
                                    "stock_type": selectedStockType,
                                    "position_type": positionType,
                                    "top_image": topImageUrl ?? "",
                                    "bottom_image": bottomImageUrl ?? "",
                                    "remark1": remarkCtrl.text.trim(),
                                    "dateEdit": currentDate,
                                    "updatedAt": FieldValue.serverTimestamp(),
                                  };

                                  if (positionType == 'Top' ||
                                      positionType == 'Both') {
                                    newItem.addAll({
                                      "top_in": int.parse(topInCtrl.text),
                                      "top_out": int.parse(topOutCtrl.text),
                                      "top_bal": int.parse(topBalCtrl.text),
                                    });
                                  }

                                  if (positionType == 'Bottom' ||
                                      positionType == 'Both') {
                                    newItem.addAll({
                                      "bottom_in": int.parse(bottomInCtrl.text),
                                      "bottom_out": int.parse(
                                        bottomOutCtrl.text,
                                      ),
                                      "bottom_bal": int.parse(
                                        bottomBalCtrl.text,
                                      ),
                                    });
                                  }

                                  if (isEdit) {
                                    // ✅ EDIT: Don't change 'sr' or 'createdAt'
                                    await _firestore
                                        .collection('paper_stock_items')
                                        .doc(existingItem["docId"])
                                        .update(newItem);
                                    _showSnackBar(
                                      "✓ Item updated successfully",
                                    );
                                  } else {
                                    // ✅ NEW: Add 'sr' and 'createdAt'
                                    newItem["sr"] = nextSr;
                                    newItem["createdAt"] =
                                        FieldValue.serverTimestamp();
                                    await _firestore
                                        .collection('paper_stock_items')
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
                                width: 23,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(isEdit ? Icons.check : Icons.add),
                        label: Text(
                          isEdit ? "Update Item" : "Add Item",
                          style:  TextStyle(
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

      bool hasRequired = [
        'code',
        'detail',
        'piller_no',
      ].every((h) => headerRow.contains(h));

      if (!hasRequired) {
        _showSnackBar(
          "Missing required columns: code, detail, piller_no",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      List<Map<String, dynamic>> importedItems = [];
      final String today = DateFormat('dd-MM-yyyy').format(DateTime.now());

      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        if (row.length < 3) continue;

        Map<String, dynamic> item = {};
        for (int j = 0; j < headerRow.length && j < row.length; j++) {
          var header = headerRow[j];
          var cell = row[j];
          var value = cell?.value;
          if (value == null) continue;

          switch (header) {
            case 'sr':
            case 'in':
            case 'incoming':
            case 'out':
            case 'bal':
              item[header] = int.tryParse(value.toString()) ?? 0;
              break;
            case 'code':
            case 'detail':
            case 'piller_no':
              item[header] = value.toString().trim();
              break;
            case 'remark':
            case 'remark1':
              item['remark1'] = value.toString().trim();
              break;
          }
        }

        if (item['code'] == null ||
            item['detail'] == null ||
            item['piller_no'] == null) {
          continue;
        }

        item['in'] = item['in'] ?? 0;
        item['incoming'] = item['incoming'] ?? 0;
        item['out'] = item['out'] ?? 0;
        item['bal'] =
            item['bal'] ?? (item['in'] + item['incoming'] - item['out']);
        item['remark1'] = item['remark1'] ?? '';
        item['dateEdit'] = today;

        if (item['sr'] == null || item['sr'] == 0) {
          item['sr'] = await _getNextSrNumber();
        }
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
            .collection('paper_stock_items')
            .where('code', isEqualTo: item['code'])
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          var docRef = existingQuery.docs.first.reference;
          batch.update(docRef, {
            ...item,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          var docRef = _firestore.collection('paper_stock_items').doc();
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

  // ✅ FIXED DELETE - Now properly validates docId
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
                    .collection('paper_stock_items')
                    .doc(docId)
                    .delete();

                await _reorderPaperSrNumbers();
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

Future<void> _downloadPdf() async {

  final pdf = pw.Document();
  final data = _filterForPdf();

  List<List<dynamic>> tableData = [];

  for (var item in data) {

    Uint8List? imageBytes;

    if (item['top_image'] != null &&
        item['top_image'].toString().isNotEmpty) {
      imageBytes = await _networkImageToBytes(item['top_image']);
    }

    tableData.add([
      item["code"] ?? "",
      item["location"] ?? "",
      item["design_no"] ?? "",
      item["detail"] ?? "",
      item["piller_no"] ?? "",
      item["stock_type"] ?? "",
      imageBytes != null
          ? pw.Image(pw.MemoryImage(imageBytes), width: 40, height: 40)
          : pw.Text("No Image"),
      item["top_bal"]?.toString() ?? "0",
      item["bottom_bal"]?.toString() ?? "0",
      item["dateEdit"] ?? "",
    ]);
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => [
        pw.Text(
          "Paper Stock Report",
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: [
            "Code",
            "Location",
            "Design",
            "Item",
            "Size",
            "Type",
            "Image",
            "Top",
            "Bottom",
            "Date"
          ],
          data: tableData,
        ),
      ],
    ),
  );

  final bytes = await pdf.save();

if (kIsWeb) {
    _showSnackBar("PDF download works only on Web");
  } else {

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/paper_stock_report.pdf");

    await file.writeAsBytes(bytes);

    await OpenFile.open(file.path);
  }

  _showSnackBar("PDF Generated");
}

  // ==================== UI HELPERS ====================

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
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

  // Table Header
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
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _actionFlex(Map<String, dynamic> item, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                icon: Icon(Icons.edit_outlined, color: primaryGreen, size: 20),
                onPressed: () => _addOrUpdateItem(existingItem: item),
                tooltip: "Edit",
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[700],
                  size: 20,
                ),
                onPressed: () => _deleteItem(item["docId"] ?? ''),
                tooltip: "Delete",
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        alignment: Alignment.center,
        child: ElevatedButton(
          onPressed: () => _showUpdateOptions(item),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: const Text(
            "Update",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
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
                  'Paper Stock',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage paper stock items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentGreen, strokeWidth: 3),
                  const SizedBox(height: 0.1),
                  Text(
                    "Loading paper stock...",
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
                  // SEARCH & FILTER BAR
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
                                hintText: "Search by Code, Name, or Size...",
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
                        const SizedBox(width: 10),
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  decoration: BoxDecoration(
    color: Colors.red.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.red, width: 1.5),
  ),
  child: Row(
    children: [

      DropdownButton<String>(
        value: _selectedTypeFilter,
        underline: SizedBox(),
        icon: Icon(Icons.filter_list, color: Colors.red),
        items: _typeFilters
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          setState(() {
            _selectedTypeFilter = v!;
          });
        },
      ),

      SizedBox(width: 10),

      DropdownButton<String>(
        value: _selectedRangeFilter,
        underline: SizedBox(),
        icon: Icon(Icons.date_range, color: Colors.red),
        items: _rangeFilters
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          setState(() {
            _selectedRangeFilter = v!;
          });
        },
      ),

      SizedBox(width: 10),

      ElevatedButton.icon(
        onPressed: _downloadPdf,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        icon: Icon(Icons.picture_as_pdf),
        label: Text("PDF"),
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
                  _buildStockSummary(),

                  // TABLE HEADER
Expanded(
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: tableWidth,
      child: Column(
        children: [

          /// 🔹 HEADER
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
                _headerFlex("Design No", 2),
                _headerFlex("Image", 3),
                _headerFlex("Item Name", 4),
                _headerFlex("Size", 2),
                _headerFlex("Type", 2),
                _headerFlex("Total", 2),
                _headerFlex("Issue", 2),
                _headerFlex("In Hand", 2),
                _headerFlex("Date", 2),
                _headerFlex("Remarks", 3),
                _headerFlex("Actions", 3),
                _headerFlex("Update", 2),
              ],
            ),
          ),

          const SizedBox(height: 5),

          /// 🔹 BODY
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 110),
              itemCount: filteredData.length,
              itemBuilder: (ctx, i) {
                final item = filteredData[i];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: accentGreen, width: 4),
                    ),
                  ),
                  child: Row(
                    children: [

                      _cellFlex((i + 1).toString(), 1),

                      _cellFlex(item["code"], 2, bold: true),
                      _cellFlex(item["location"] ?? "-", 2),
                      _cellFlex(item["design_no"] ?? "-", 2),
                      _imageCellFlex(item, 3),
                      _cellFlex(item["detail"], 4, bold: true),
                      _cellFlex(item["piller_no"], 2),
                      _cellFlex(item["stock_type"] ?? "-", 2),

                      _cellFlex(
                        item['position_type'] == 'Top'
                            ? "T:${item['top_in'] ?? 0}"
                            : item['position_type'] == 'Bottom'
                                ? "B:${item['bottom_in'] ?? 0}"
                                : "T:${item['top_in'] ?? 0} | B:${item['bottom_in'] ?? 0}",
                        2,
                      ),

                      _cellFlex(
                        item['position_type'] == 'Top'
                            ? "T:${item['top_out'] ?? 0}"
                            : item['position_type'] == 'Bottom'
                                ? "B:${item['bottom_out'] ?? 0}"
                                : "T:${item['top_out'] ?? 0} | B:${item['bottom_out'] ?? 0}",
                        2,
                      ),

                      _cellFlex(
                        item['position_type'] == 'Top'
                            ? "T:${item['top_bal'] ?? 0}"
                            : item['position_type'] == 'Bottom'
                                ? "B:${item['bottom_bal'] ?? 0}"
                                : "T:${item['top_bal'] ?? 0} | B:${item['bottom_bal'] ?? 0}",
                        2,
                        bold: true,
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
)
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 1, left: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: _addOrUpdateItem,
              heroTag: "add_paper",
              backgroundColor: accentGreen,
              elevation: 8,
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 16.sp,
              ),
              label: Text(
                "Add Paper",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
  //           SizedBox(width: 10),
  //             FloatingActionButton.extended(
  //   heroTag: "pdf_download",
  //   backgroundColor: Colors.red,
  //   icon: Icon(Icons.picture_as_pdf, color: Colors.white),
  //   label: Text("PDF", style: TextStyle(color: Colors.white)),
  //   onPressed: _downloadPdf,
  // ),

  SizedBox(width: 5),
            FloatingActionButton.extended(
              heroTag: "fix_paper_codes",
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.auto_fix_high, color: Colors.white),
              label: const Text(
                "Fix Codes",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _fixPaperCodesSequentially,
            ),
            SizedBox(width: 5),
            FloatingActionButton.extended(
              onPressed: _uploadExcelFile,
              heroTag: "upload_excel",
              backgroundColor: primaryGreen,
              elevation: 8,
              icon: Icon(
                Icons.upload_file_outlined,
                color: Colors.white,
                size: 16.sp,
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

