import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ReadyStockScreen extends StatefulWidget {
  const ReadyStockScreen({super.key});

  @override
  _ReadyStockScreenState createState() => _ReadyStockScreenState();
}

class _ReadyStockScreenState extends State<ReadyStockScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> stockData = [];
  List<Map<String, dynamic>> filteredData = [];
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDataFromFirebase();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ====================== SAFE SR NUMBER ======================
  Future<int> _getNextSrNumber() async {
    try {
      final snapshot = await _firestore
          .collection('stock_items')
          .orderBy('sr', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 1;
      final lastSr = snapshot.docs.first.data()['sr'] as int?;
      return (lastSr ?? 0) + 1;
    } catch (e) {
      return 1;
    }
  }

  // ====================== LOAD DATA ======================
  Future<void> _loadDataFromFirebase() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('stock_items').orderBy('sr').get();
      stockData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
      filteredData = List.from(stockData);
    } catch (e) {
      _showSnackBar("Error loading data: $e", isError: true);
    }
    setState(() => _isLoading = false);
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredData = stockData.where((item) {
        return (item["code"]?.toString().toLowerCase().contains(query) ?? false) ||
            (item["detail"]?.toString().toLowerCase().contains(query) ?? false) ||
            (item["piller_no"]?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
      _currentPage = 0;
    });
  }

  List<Map<String, dynamic>> get _paginatedData {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filteredData.length);
    return filteredData.sublist(start, end);
  }

  // ====================== IMAGE UPLOAD ======================
  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('stock_images/$fileName.png');
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

  // ====================== ADD / EDIT ITEM ======================
  void _addOrUpdateItem({Map<String, dynamic>? existingItem}) async {
    final isEdit = existingItem != null;
    final codeCtrl = TextEditingController(text: isEdit ? existingItem["code"] : '');
    final detailCtrl = TextEditingController(text: isEdit ? existingItem["detail"] : '');
    final pillerCtrl = TextEditingController(text: isEdit ? existingItem["piller_no"] : '');
    final inCtrl = TextEditingController(text: isEdit ? existingItem["in"].toString() : '0');
    final incomingCtrl = TextEditingController(text: isEdit ? existingItem["incoming"].toString() : '0');
    final outCtrl = TextEditingController(text: isEdit ? existingItem["out"].toString() : '0');
    final balCtrl = TextEditingController(text: isEdit ? existingItem["bal"].toString() : '0');
    final remarkCtrl = TextEditingController(text: isEdit ? existingItem["remark1"] : '');

    String? imageUrl = isEdit ? existingItem["image"] : null;
    XFile? selectedImage;
    bool isUploading = false;

    int nextSr = isEdit ? existingItem["sr"] : await _getNextSrNumber();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: 80.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.pink[700]!, Colors.pink[500]!]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(isEdit ? Icons.edit : Icons.add_circle, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(isEdit ? "Edit Item" : "Add New Item",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                      Spacer(),
                      IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Upload
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: selectedImage != null
                                    ? FutureBuilder<Uint8List>(
                                        future: selectedImage!.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                                            );
                                          }
                                          return Center(child: CircularProgressIndicator());
                                        },
                                      )
                                    : imageUrl != null && imageUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(imageUrl!, fit: BoxFit.cover),
                                          )
                                        : Icon(Icons.image, size: 60, color: Colors.grey[400]),
                              ),
                              SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                        if (image != null) setDialogState(() => selectedImage = image);
                                      },
                                icon: Icon(Icons.upload_file, size: 18),
                                label: Text(selectedImage != null ? "Change Image" : "Upload Image"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        _buildModernField(codeCtrl, "DPL Code", Icons.qr_code, required: true),
                        SizedBox(height: 16),
                        _buildModernField(detailCtrl, "Detail", Icons.description, required: true),
                        SizedBox(height: 16),
                        _buildModernField(pillerCtrl, "Piller No.", Icons.pin, required: true),
                        SizedBox(height: 24),
                        Text("Stock Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink[800])),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildModernField(inCtrl, "IN", Icons.add_box, isNumber: true)),
                            SizedBox(width: 12),
                            Expanded(child: _buildModernField(incomingCtrl, "Incoming", Icons.input, isNumber: true)),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildModernField(outCtrl, "OUT", Icons.remove_circle, isNumber: true)),
                            SizedBox(width: 12),
                            Expanded(child: _buildModernField(balCtrl, "Balance (BAL)", Icons.account_balance, isNumber: true)),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildModernField(remarkCtrl, "Remark 1", Icons.note),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(fontSize: 16))),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isUploading
                            ? null
                            : () async {
                                final code = codeCtrl.text.trim();
                                final detail = detailCtrl.text.trim();
                                final piller = pillerCtrl.text.trim();

                                if (code.isEmpty || detail.isEmpty || piller.isEmpty) {
                                  _showSnackBar("Please fill required fields", isError: true);
                                  return;
                                }

                                setDialogState(() => isUploading = true);

                                if (selectedImage != null) {
                                  imageUrl = await _uploadImage(selectedImage!);
                                }

                                final inVal = int.tryParse(inCtrl.text) ?? 0;
                                final incomingVal = int.tryParse(incomingCtrl.text) ?? 0;
                                final outVal = int.tryParse(outCtrl.text) ?? 0;
                                final balVal = int.tryParse(balCtrl.text) ?? (inVal + incomingVal - outVal);

                                final newItem = {
                                  "sr": nextSr,
                                  "code": code,
                                  "detail": detail,
                                  "piller_no": piller,
                                  "image": imageUrl ?? "",
                                  "in": inVal,
                                  "incoming": incomingVal,
                                  "out": outVal,
                                  "bal": balVal,
                                  "remark1": remarkCtrl.text.trim(),
                                  "updatedAt": FieldValue.serverTimestamp(),
                                };

                                try {
                                  if (isEdit) {
                                    await _firestore.collection('stock_items').doc(existingItem["docId"]).update(newItem);
                                    _showSnackBar("Item updated");
                                  } else {
                                    newItem["createdAt"] = FieldValue.serverTimestamp();
                                    await _firestore.collection('stock_items').add(newItem);
                                    _showSnackBar("Item added!");
                                  }
                                  await _loadDataFromFirebase();
                                  Navigator.pop(ctx);
                                } catch (e) {
                                  _showSnackBar("Error: $e", isError: true);
                                } finally {
                                  setDialogState(() => isUploading = false);
                                }
                              },
                        icon: isUploading
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(isEdit ? Icons.check : Icons.add),
                        label: Text(isEdit ? "Update" : "Add Item", style: TextStyle(fontSize: 16)),
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

  // ====================== EXCEL UPLOAD ======================
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

      var excel = Excel.decodeBytes(fileBytes);
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

      var headerRow = rows[0].map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '').toList();
      final expectedHeaders = ['sr', 'dpl code', 'detail', 'piller no.', 'in', 'incoming', 'out', 'bal', 'remark 1', 'photo'];

      bool hasRequired = ['dpl code', 'detail', 'piller no.'].every((h) => headerRow.contains(h.toLowerCase()));
      if (!hasRequired) {
        _showSnackBar("Missing required columns: DPL CODE, DETAIL, PILLER NO.", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      List<Map<String, dynamic>> importedItems = [];
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
              item[header.replaceAll(' ', '_').toLowerCase()] = int.tryParse(value.toString()) ?? 0;
              break;
            case 'dpl code':
              item['code'] = value.toString().trim();
              break;
            case 'detail':
              item['detail'] = value.toString().trim();
              break;
            case 'piller no.':
              item['piller_no'] = value.toString().trim();
              break;
            case 'remark 1':
              item['remark1'] = value.toString().trim();
              break;
            case 'photo':
              item['image'] = value.toString().trim();
              break;
          }
        }

        if (item['code'] == null || item['detail'] == null || item['piller_no'] == null) continue;

        int inVal = item['in'] ?? 0;
        int incomingVal = item['incoming'] ?? 0;
        int outVal = item['out'] ?? 0;
        item['bal'] = item['bal'] ?? (inVal + incomingVal - outVal);
        item['image'] = item['image'] ?? '';

        if (item['sr'] == null || item['sr'] == 0) {
          item['sr'] = await _getNextSrNumber();
        }

        importedItems.add(item);
      }

      if (importedItems.isEmpty) {
        _showSnackBar("No valid data found", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (var item in importedItems) {
        var existingQuery = await _firestore.collection('stock_items').where('code', isEqualTo: item['code']).limit(1).get();

        if (existingQuery.docs.isNotEmpty) {
          var docRef = existingQuery.docs.first.reference;
          batch.update(docRef, {
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
      _showSnackBar("Excel imported! ${importedItems.length} items.");
    } catch (e) {
      _showSnackBar("Import failed: $e", isError: true);
    }

    setState(() => _isLoading = false);
  }

  // ====================== DELETE ITEM ======================
  void _deleteItem(String docId, int sr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.warning_amber, color: Colors.red[700], size: 28), SizedBox(width: 12), Text("Delete Item?", style: TextStyle(color: Colors.red[700]))]),
        content: Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _firestore.collection('stock_items').doc(docId).delete();
                await _loadDataFromFirebase();
                _showSnackBar("Item deleted");
              } catch (e) {
                _showSnackBar("Error: $e", isError: true);
              }
              Navigator.pop(ctx);
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool required = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label + (required ? " *" : ""),
        prefixIcon: Icon(icon, color: Colors.pink[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.pink[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.pink[600]!, width: 2)),
        filled: true,
        fillColor: Colors.pink[50],
      ),
    );
  }

  // ====================== TABLE WIDGETS ======================
  Widget _header(String text, double width) => SizedBox(
        width: width,
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      );

  Widget _cell(String text, double width, {Color? color, bool bold = false}) => SizedBox(
        width: width,
        child: Text(
          text,
          style: TextStyle(color: color ?? Colors.black87, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, fontSize: 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      );

  Widget _cellImage(String? url, double width) {
    if (url == null || url.isEmpty) return _placeholderImage(width);
    return SizedBox(
      width: width,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            url.trim(),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _errorImage(width),
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage(double width) => SizedBox(
        width: width,
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
            child: Icon(Icons.image, size: 24, color: Colors.grey[500]),
          ),
        ),
      );

  Widget _errorImage(double width) => SizedBox(
        width: width,
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 20, color: Colors.red[400]),
                Text("Error", style: TextStyle(fontSize: 7, color: Colors.red[600])),
              ],
            ),
          ),
        ),
      );

  Widget _actionButtons(Map<String, dynamic> item, double width) => SizedBox(
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: Icon(Icons.edit, color: Colors.pink[700], size: 18), onPressed: () => _addOrUpdateItem(existingItem: item), tooltip: "Edit"),
            IconButton(icon: Icon(Icons.delete, color: Colors.red[700], size: 18), onPressed: () => _deleteItem(item["docId"] ?? '', item["sr"]), tooltip: "Delete"),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 85,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.pink[700]!, Colors.pink[500]!]))),
        title: Row(
          children: [
            Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Image.asset('assets/1.jpg', height: 50, width: 50, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: Colors.pink[700], size: 36))),
            SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Dimple Packaging Pvt Ltd", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              Text("Ludhiana, Punjab", style: TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
            Expanded(child: Center(child: Text("Ready Stock Basket Report", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)))),
            IconButton(icon: Icon(Icons.refresh, color: Colors.white, size: 28), onPressed: _loadDataFromFirebase, tooltip: "Refresh"),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.pink))
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))]),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(hintText: "Search by Code, Detail or Piller...", hintStyle: TextStyle(color: Colors.grey[400]), border: InputBorder.none, prefixIcon: Icon(Icons.search, color: Colors.pink[600], size: 24)),
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.pink[600]!, Colors.pink[400]!]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 3))]),
                          child: Row(children: [
                            _header("SR NO.", 70),
                            _header("DPL CODE", 100),
                            _header("DETAIL", 140),
                            _header("PILLER NO.", 100),
                            _header("PHOTO", 90),
                            _header("IN", 70),
                            _header("INCOMING", 100),
                            _header("OUT", 70),
                            _header("BAL", 80),
                            _header("Remark 1", 120),
                            _header("ACTIONS", 90),
                          ]),
                        ),
                        SizedBox(height: 0.2.h),
                        Expanded(
                          child: filteredData.isEmpty
                              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                                  SizedBox(height: 16),
                                  Text("No items found", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                  SizedBox(height: 8),
                                  Text("Click + to add or upload Excel", style: TextStyle(color: Colors.grey[400])),
                                ]))
                              : ListView.builder(
                                  itemCount: _paginatedData.length,
                                  itemBuilder: (ctx, i) {
                                    final item = _paginatedData[i];
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 0.2.h),
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2))]),
                                      child: Row(children: [
                                        _cell(item["sr"].toString(), 70),
                                        _cell(item["code"] ?? "", 100, bold: true),
                                        _cell(item["detail"] ?? "", 140),
                                        _cell(item["piller_no"] ?? "", 100),
                                        _cellImage(item["image"], 90),
                                        _cell(item["in"]?.toString() ?? "0", 70),
                                        _cell(item["incoming"]?.toString() ?? "0", 100),
                                        _cell(item["out"]?.toString() ?? "0", 70, color: Colors.red[700]),
                                        _cell(item["bal"]?.toString() ?? "0", 80, color: Colors.green[700], bold: true),
                                        _cell(item["remark1"] ?? "", 120),
                                        _actionButtons(item, 90),
                                      ]),
                                    );
                                  },
                                ),
                        ),
                        if (stockData.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 16),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                              Text("Page ${_currentPage + 1} of ${((filteredData.length - 1) / _rowsPerPage).ceil()}", style: TextStyle(fontWeight: FontWeight.w600)),
                              Row(children: [
                                IconButton(icon: Icon(Icons.chevron_left), onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButton<int>(
                                    value: _rowsPerPage,
                                    underline: SizedBox(),
                                    items: [5, 10, 20, 50].map((n) => DropdownMenuItem(value: n, child: Text("$n / page"))).toList(),
                                    onChanged: (v) => setState(() => {_rowsPerPage = v!, _currentPage = 0}),
                                  ),
                                ),
                                IconButton(icon: Icon(Icons.chevron_right), onPressed: (_currentPage + 1) * _rowsPerPage < filteredData.length ? () => setState(() => _currentPage++) : null),
                              ]),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _addOrUpdateItem,
            heroTag: "add_item",
            backgroundColor: Colors.pink[600],
            elevation: 4,
            icon: Icon(Icons.add, color: Colors.white, size: 20),
            label: Text("Add Item", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: 0.5.h),
          FloatingActionButton.extended(
            onPressed: _uploadExcelFile,
            heroTag: "upload_excel",
            backgroundColor: Colors.green[600],
            elevation: 4,
            icon: Icon(Icons.upload_file, color: Colors.white, size: 20),
            label: Text("Upload Excel", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}