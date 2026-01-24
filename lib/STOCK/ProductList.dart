import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});
  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  // Fixed widths to keep header & rows aligned
  static const double _wCheck = 36;
  static const double _wSno = 50;
  static const double _wPic = 70;
  static const double _wActs = 40;

  // Controllers
  final skuCtrl = TextEditingController();
  final designNoCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final sizeCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final pictureUrlCtrl = TextEditingController();
  final totalQtyCtrl = TextEditingController();
  final availableQtyCtrl = TextEditingController();
  final supplierCtrl = TextEditingController();
  final editorCtrl = TextEditingController();
  final searchCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isExporting = false;
  String _searchQuery = '';

  // Selection
  Set<String> _selectedProducts = <String>{};
  bool _selectAll = false;
  List<QueryDocumentSnapshot>? _currentProducts;

  // Image picker/upload
  final ImagePicker _picker = ImagePicker();
  bool _uploadingImage = false;
  double _uploadProgress = 0.0;

  // Stages
  final List<String> _stages = [
    'Production',
    'Dispatch',
    'Printing',
    'Lamination',
    'Correction',
    'Job Control',
    'Pasting',
    'Die Cutting',
  ];
  String _selectedStageInForm = 'Production';
  String _filterStage = 'All';

  // CUSTOM PRODUCTS HEADER
  Widget _buildProductsHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products Inventory',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage your product catalog and inventory',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isExporting ? null : _showExportOptionsDialog,
                      icon: _isExporting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.import_export, size: 18, color: Colors.white),
                      label: Text(
                        _isExporting ? 'Processing...' : 'Export/Import',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: showAddProductDialog,
                      icon: Icon(Icons.add, size: 20),
                      label: Text(
                        'New Product',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.indigo.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
                    Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search products by code, name, category...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _searchQuery = v.toLowerCase();
                        _selectedProducts.clear();
                        _selectAll = false;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: 16),
              
              // Stage Filter
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, size: 18, color: Colors.white.withOpacity(0.8)),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filterStage,
                      underline: SizedBox(),
                      dropdownColor: Colors.indigo.shade600,
                      style: TextStyle(color: Colors.white),
                      items: ['All', ..._stages]
                          .map((stage) => DropdownMenuItem(
                                value: stage,
                                child: Text(stage, style: TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _filterStage = v ?? 'All';
                          _selectedProducts.clear();
                          _selectAll = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    skuCtrl.clear();
    designNoCtrl.clear();
    nameCtrl.clear();
    sizeCtrl.clear();
    categoryCtrl.clear();
    locationCtrl.clear();
    pictureUrlCtrl.clear();
    totalQtyCtrl.clear();
    availableQtyCtrl.clear();
    supplierCtrl.clear();
    editorCtrl.clear();
    _uploadingImage = false;
    _uploadProgress = 0.0;
    _selectedStageInForm = 'Production';
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final sku = skuCtrl.text.trim().toUpperCase();
      final exists = await FirebaseFirestore.instance.collection('products').where('sku', isEqualTo: sku).get();
      if (exists.docs.isNotEmpty) {
        _showSnackBar('SKU already exists!', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      await FirebaseFirestore.instance.collection('products').add({
        'sku': sku,
        'designNo': designNoCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'size': sizeCtrl.text.trim(),
        'category': categoryCtrl.text.trim().toUpperCase(),
        'location': locationCtrl.text.trim(),
        'pictureUrl': pictureUrlCtrl.text.trim(),
        'totalStockIn': int.tryParse(totalQtyCtrl.text.trim()) ?? 0,
        'currentStock': int.tryParse(availableQtyCtrl.text.trim()) ?? 0,
        'supplier': supplierCtrl.text.trim(),
        'editor': editorCtrl.text.trim(),
        'stage': _selectedStageInForm,
      });
      _clearForm();
      _showSnackBar('Product added successfully!', isError: false);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateProduct(String docId, Map<String, dynamic> d) async {
    skuCtrl.text = (d['sku'] ?? '').toString();
    designNoCtrl.text = (d['designNo'] ?? '').toString();
    nameCtrl.text = (d['name'] ?? '').toString();
    sizeCtrl.text = (d['size'] ?? '').toString();
    categoryCtrl.text = (d['category'] ?? '').toString();
    locationCtrl.text = (d['location'] ?? '').toString();
    pictureUrlCtrl.text = (d['pictureUrl'] ?? '').toString();
    totalQtyCtrl.text = ((d['totalStockIn'] ?? 0)).toString();
    availableQtyCtrl.text = ((d['currentStock'] ?? 0)).toString();
    supplierCtrl.text = (d['supplier'] ?? '').toString();
    editorCtrl.text = (d['editor'] ?? '').toString();
    _selectedStageInForm = (d['stage'] ?? 'Production').toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildProductDialog(
        title: 'Edit Product',
        onSubmit: () async {
          if (!_formKey.currentState!.validate()) return;
          setState(() => _isLoading = true);
          try {
            final newSku = skuCtrl.text.trim().toUpperCase();
            final snap = await FirebaseFirestore.instance.collection('products').where('sku', isEqualTo: newSku).get();
            final exists = snap.docs.any((x) => x.id != docId);
            if (exists) {
              _showSnackBar('SKU already exists!', isError: true);
              setState(() => _isLoading = false);
              return;
            }
            await FirebaseFirestore.instance.collection('products').doc(docId).update({
              'sku': newSku,
              'designNo': designNoCtrl.text.trim(),
              'name': nameCtrl.text.trim(),
              'size': sizeCtrl.text.trim(),
              'category': categoryCtrl.text.trim().toUpperCase(),
              'location': locationCtrl.text.trim(),
              'pictureUrl': pictureUrlCtrl.text.trim(),
              'totalStockIn': int.tryParse(totalQtyCtrl.text.trim()) ?? 0,
              'currentStock': int.tryParse(availableQtyCtrl.text.trim()) ?? 0,
              'supplier': supplierCtrl.text.trim(),
              'editor': editorCtrl.text.trim(),
              'stage': _selectedStageInForm,
            });
            _clearForm();
            Navigator.pop(context);
            _showSnackBar('Product updated!', isError: false);
          } catch (e) {
            _showSnackBar('Error: $e', isError: true);
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  Future<void> deleteProduct(String docId, String productName) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(docId).delete();
      setState(() => _selectedProducts.remove(docId));
      _showSnackBar('Deleted "$productName"', isError: false);
    } catch (e) {
      _showSnackBar('Delete failed: $e', isError: true);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _uploadingImage = true;
        _uploadProgress = 0.0;
      });
      final bytes = await picked.readAsBytes();
      final ext = (picked.name.split('.').length > 1) ? picked.name.split('.').last.toLowerCase() : 'jpg';
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref().child('product_images/$fileName');
      final metadata = SettableMetadata(contentType: 'image/$ext', customMetadata: {'originalName': picked.name});
      final uploadTask = ref.putData(bytes, metadata);
      uploadTask.snapshotEvents.listen((s) {
        final total = s.totalBytes;
        final sent = s.bytesTransferred;
        if (total > 0) setState(() => _uploadProgress = sent / total);
      });
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      setState(() {
        pictureUrlCtrl.text = url;
        _uploadingImage = false;
        _uploadProgress = 0.0;
      });
      _showSnackBar('Image uploaded!', isError: false);
    } catch (e) {
      setState(() {
        _uploadingImage = false;
        _uploadProgress = 0.0;
      });
      _showSnackBar('Image upload failed: $e', isError: true);
    }
  }
  Future<void> exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final qs = await FirebaseFirestore.instance.collection('products').orderBy('name').get();
      if (qs.docs.isEmpty) {
        _showSnackBar('No products to export!', isError: true);
        setState(() => _isExporting = false);
        return;
      }
      final excel = Excel.createExcel();
      final sheet = excel['Products'];
      final headers = [
        'Item Code',
        'Design No',
        'Product Name',
        'Size',
        'Category',
        'Location',
        'Picture',
        'Total Qty',
        'Available Qty',
        'Supplier',
        'Editor',
        'Stage',
      ];
      for (int c = 0; c < headers.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = TextCellValue(headers[c]);
        cell.cellStyle = CellStyle(bold: true);
      }
      for (int i = 0; i < qs.docs.length; i++) {
        final p = qs.docs[i].data();
        final row = i + 1;
        String s(dynamic v) => (v ?? '').toString();
        int iVal(dynamic v) => (v is num) ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(s(p['sku']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(s(p['designNo']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(s(p['name']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(s(p['size']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(s(p['category']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(s(p['location']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(s(p['pictureUrl']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = IntCellValue(iVal(p['totalStockIn']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = IntCellValue(iVal(p['currentStock']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = TextCellValue(s(p['supplier']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value = TextCellValue(s(p['editor']));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value = TextCellValue(s(p['stage']));
      }
      final bytes = excel.save();
      if (bytes == null) {
        _showSnackBar('Error creating Excel file!', isError: true);
        setState(() => _isExporting = false);
        return;
      }
      final ref = FirebaseStorage.instance.ref().child('exports/products_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      final task = await ref.putData(Uint8List.fromList(bytes),
          SettableMetadata(contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'));
      final url = await task.ref.getDownloadURL();
      _showSnackBar('Exported to Excel!', isError: false);
      _showExportSuccessDialog('Products.xlsx', url);
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showExportSuccessDialog(String fileName, String downloadUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: const [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Export Successful')]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Excel file uploaded to Firebase Storage.'),
          const SizedBox(height: 8),
          Text(fileName, style: const TextStyle(fontFamily: 'monospace')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          )
        ],
      ),
    );
  }

  Future<void> previewAndImportExcel({bool alsoUploadToStorage = false}) async {
    final res = await FilePicker.platform.pickFiles(withData: true, allowMultiple: false, type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
    if (res == null || res.files.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final file = res.files.first;
      final bytes = file.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.containsKey('Products') ? 'Products' : (excel.tables.keys.isNotEmpty ? excel.tables.keys.first : null);
      if (sheetName == null) {
        _showSnackBar('No sheets found in Excel.', isError: true);
        setState(() => _isExporting = false);
        return;
      }
      final table = excel.tables[sheetName]!;
      final rows = table.rows;
      if (rows.length < 2) {
        _showSnackBar('Sheet "$sheetName" has no data rows.', isError: true);
        setState(() => _isExporting = false);
        return;
      }

      // map headers
      final headerRow = rows.first;
      final Map<String, int> idx = {};
      for (int i = 0; i < headerRow.length; i++) {
        final v = headerRow[i]?.value?.toString().trim().toLowerCase();
        if (v == null) continue;
        if (v == 'item code' || v == 'sku') idx['sku'] = i;
        if (v == 'design no' || v == 'design number') idx['designNo'] = i;
        if (v == 'product name' || v == 'name') idx['name'] = i;
        if (v == 'size') idx['size'] = i;
        if (v == 'category') idx['category'] = i;
        if (v == 'location') idx['location'] = i;
        if (v == 'picture' || v == 'picture url' || v == 'image' || v == 'image url') idx['pictureUrl'] = i;
        if (v == 'total qty' || v == 'total quantity') idx['totalStockIn'] = i;
        if (v == 'available qty' || v == 'available quantity' || v == 'current stock') idx['currentStock'] = i;
        if (v == 'supplier' || v == 'vendor') idx['supplier'] = i;
        if (v == 'editor') idx['editor'] = i;
        if (v == 'stage') idx['stage'] = i;
      }
      if (!idx.containsKey('sku') || !idx.containsKey('name')) {
        _showSnackBar('Excel must have Item Code and Product Name.', isError: true);
        setState(() => _isExporting = false);
        return;
      }

      String val(List<Data?> row, int? col) => (col != null && col < row.length) ? (row[col]?.value?.toString().trim() ?? '') : '';
      final parsed = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (int r = 1; r < rows.length; r++) {
        final row = rows[r];
        final sku = val(row, idx['sku']).toUpperCase();
        final name = val(row, idx['name']);
        if (sku.isEmpty || name.isEmpty) continue;
        if (!seen.add(sku)) continue;
        parsed.add({
          'sku': sku,
          'designNo': val(row, idx['designNo']),
          'name': name,
          'size': val(row, idx['size']),
          'category': val(row, idx['category']).toUpperCase(),
          'location': val(row, idx['location']),
          'pictureUrl': val(row, idx['pictureUrl']),
          'totalStockIn': int.tryParse(val(row, idx['totalStockIn'])) ?? 0,
          'currentStock': int.tryParse(val(row, idx['currentStock'])) ?? 0,
          'supplier': val(row, idx['supplier']),
          'editor': val(row, idx['editor']),
          'stage': (idx.containsKey('stage') ? val(row, idx['stage']) : '').isNotEmpty ? val(row, idx['stage']) : 'Production',
        });
      }

      if (parsed.isEmpty) {
        _showSnackBar('No valid rows to import.', isError: true);
        setState(() => _isExporting = false);
        return;
      }


      String importChoice = 'use_excel'; // 'use_excel' or 'override'
      String overrideStage = _stages.first;

      final userChoice = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Choose Stage for Import'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: 'use_excel',
                    groupValue: importChoice,
                    onChanged: (v) => setStateDialog(() => importChoice = v ?? 'use_excel'),
                    title: const Text('Use Stage from Excel (if column present)'),
                    subtitle: const Text('If Excel row has Stage, it will be used; blank => Production'),
                  ),
                  const Divider(),
                  RadioListTile<String>(
                    value: 'override',
                    groupValue: importChoice,
                    onChanged: (v) => setStateDialog(() => importChoice = v ?? 'override'),
                    title: const Text('Override with selected Stage'),
                  ),
                  if (importChoice == 'override')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: overrideStage,
                        items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setStateDialog(() => overrideStage = v ?? _stages.first),
                        decoration: InputDecoration(
                          labelText: 'Select Stage to apply to all rows',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {'choice': importChoice, 'stage': overrideStage}),
                  child: const Text('Continue'),
                )
              ],
            );
          });
        },
      );

      if (userChoice == null) {
        // user cancelled
        setState(() => _isExporting = false);
        return;
      }
      importChoice = userChoice['choice'] ?? 'use_excel';
      overrideStage = userChoice['stage'] ?? _stages.first;

      // -- Apply override if chosen --
      if (importChoice == 'override') {
        for (final row in parsed) {
          row['stage'] = overrideStage;
        }
      } else {
        for (final row in parsed) {
          if ((row['stage'] ?? '').toString().trim().isEmpty) row['stage'] = 'Production';
        }
      }

      // ---------- Preview ----------
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Preview (${parsed.length} rows)'),
          content: SizedBox(
            width: 900,
            height: 420,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 12,
                columns: const [
                  DataColumn(label: Text('Item Code')),
                  DataColumn(label: Text('Design No')),
                  DataColumn(label: Text('Product Name')),
                  DataColumn(label: Text('Size')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Total Qty')),
                  DataColumn(label: Text('Available Qty')),
                  DataColumn(label: Text('Stage')),
                ],
                rows: parsed.take(100).map((e) => DataRow(cells: [
                      DataCell(Text(e['sku'] ?? '')),
                      DataCell(Text(e['designNo'] ?? '')),
                      DataCell(Text(e['name'] ?? '')),
                      DataCell(Text(e['size'] ?? '')),
                      DataCell(Text(e['category'] ?? '')),
                      DataCell(Text('${e['totalStockIn'] ?? 0}')),
                      DataCell(Text('${e['currentStock'] ?? 0}')),
                      DataCell(Text(e['stage'] ?? 'Production')),
                    ])).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              child: Text('Import ${parsed.length}'),
              onPressed: () async {
                Navigator.pop(context);
                // dedupe vs DB
                final allSkus = parsed.map((e) => e['sku'] as String).toList();
                final dupInDb = <String>{};
                for (int i = 0; i < allSkus.length; i += 30) {
                  final chunk = allSkus.sublist(i, (i + 30 > allSkus.length) ? allSkus.length : i + 30);
                  final snap = await FirebaseFirestore.instance.collection('products').where('sku', whereIn: chunk).get();
                  for (final d in snap.docs) {
                    dupInDb.add((d.data()['sku'] ?? '').toString());
                  }
                }
                final toImport = parsed.where((e) => !dupInDb.contains(e['sku'] as String)).toList();
                if (toImport.isEmpty) {
                  _showSnackBar('All rows are duplicate SKUs. Nothing to import.', isError: true);
                  return;
                }
                int success = 0;
                for (int i = 0; i < toImport.length; i += 450) {
                  final chunk = toImport.sublist(i, (i + 450 > toImport.length) ? toImport.length : i + 450);
                  final batch = FirebaseFirestore.instance.batch();
                  for (final r in chunk) {
                    final ref = FirebaseFirestore.instance.collection('products').doc();
                    batch.set(ref, r);
                  }
                  await batch.commit();
                  success += chunk.length;
                }
                _showSnackBar('Imported $success product(s)', isError: false);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Import failed: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Widget _imageThumb(String? url) {
    final u = (url ?? '').trim();
    if (u.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(u, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        );
      }),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.shopping_bag_outlined, size: 0)]),
        Row(children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
        ),
      ]),
    );
  }

  Widget _buildImagePickerField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.image_outlined, size: 18, color: Colors.blue),
        const SizedBox(width: 2),
        Text('Picture', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: Row(children: [
          _imageThumb(pictureUrlCtrl.text),
          const SizedBox(width: 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pictureUrlCtrl.text.isEmpty ? 'No image selected' : pictureUrlCtrl.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              if (_uploadingImage) ...[const SizedBox(height: 8), LinearProgressIndicator(value: _uploadProgress)],
            ]),
          ),
          const SizedBox(width: 2),
          ElevatedButton.icon(onPressed: _uploadingImage ? null : _pickAndUploadImage, icon: const Icon(Icons.photo_library_outlined, size: 14), label: const Text('Upload')),
          TextButton(onPressed: _uploadingImage ? null : () => setState(() => pictureUrlCtrl.clear()), child: const Text('Clear')),
        ]),
      ),
    ]);
  }

  Widget _buildProductDialog({required String title, required VoidCallback onSubmit}) {
    String? req(String? v, String field) {
      if (v == null || v.trim().isEmpty) return '$field is required';
      return null;
    }

    String? num(String? v, String field) {
      if (v == null || v.trim().isEmpty) return '$field is required';
      final n = int.tryParse(v.trim());
      if (n == null || n < 0) return 'Enter a valid $field';
      return null;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: StatefulBuilder(builder: (context, setStateDialog) {
        return Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shopping_cart, color: Colors.blue, size: 24)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(children: [
                    _buildFormField(
                      controller: skuCtrl,
                      label: 'Item Code',
                      icon: Icons.qr_code_2_outlined,
                      hint: 'e.g., BOX-PLAIN-001',
                      validator: (v) {
                        final m = req(v, 'Item Code / SKU');
                        if (m != null) return m;
                        if (v!.trim().length < 3) return 'SKU must be at least 3 characters';
                        return null;
                      },
                      textCapitalization: TextCapitalization.characters,
                    ),
                    _buildFormField(controller: designNoCtrl, label: 'Design No', icon: Icons.brush_outlined, hint: 'e.g., D-102'),
                    _buildFormField(
                      controller: nameCtrl,
                      label: 'Product Name',
                      icon: Icons.shopping_bag_outlined,
                      hint: 'e.g., Corrugated Box',
                      validator: (v) {
                        final m = req(v, 'Product name');
                        if (m != null) return m;
                        if (v!.trim().length < 3) return 'Name must be at least 3 characters';
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    Row(children: [
                      Expanded(child: _buildFormField(controller: sizeCtrl, label: 'Size', icon: Icons.straighten_outlined, hint: 'e.g., 10x12 inch')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFormField(controller: categoryCtrl, label: 'Category', icon: Icons.category_outlined, hint: 'RAW / FG / SFG', textCapitalization: TextCapitalization.characters)),
                    ]),
                    Row(children: [
                      Expanded(child: _buildFormField(controller: locationCtrl, label: 'Location', icon: Icons.location_on_outlined, hint: 'e.g., WH-A / R1-S2')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildImagePickerField()),
                    ]),
                    // Stage dropdown inside dialog
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.flag_outlined, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('Stage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                        ]),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedStageInForm,
                          items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setStateDialog(() => _selectedStageInForm = v ?? _stages.first),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Stage is required' : null,
                        ),
                      ]),
                    ),
                    _buildFormField(controller: totalQtyCtrl, label: 'Total Qty', icon: Icons.format_list_numbered, hint: '0', keyboardType: const TextInputType.numberWithOptions(decimal: false), validator: (v) => num(v, 'Total Qty')),
                    _buildFormField(controller: availableQtyCtrl, label: 'Available Qty', icon: Icons.inventory_2_outlined, hint: '0', keyboardType: const TextInputType.numberWithOptions(decimal: false), validator: (v) => num(v, 'Available Qty')),
                    _buildFormField(controller: supplierCtrl, label: 'Supplier', icon: Icons.people_alt_outlined, hint: 'e.g., Dimple Suppliers'),
                    _buildFormField(controller: editorCtrl, label: 'Editor', icon: Icons.edit_note_outlined, hint: 'e.g., Admin / J. Doe'),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _clearForm();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.save, size: 18), SizedBox(width: 8), Text('Save')]),
                ),
              ),
            ]),
          ]),
        );
      }),
    );
  }

  List<QueryDocumentSnapshot> _filterProducts(List<QueryDocumentSnapshot> products) {
    var list = products;
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        final d = p.data() as Map<String, dynamic>;
        String v(String k) => (d[k] ?? '').toString().toLowerCase();
        return v('sku').contains(_searchQuery) || v('designNo').contains(_searchQuery) || v('name').contains(_searchQuery) || v('size').contains(_searchQuery) || v('category').contains(_searchQuery) || v('location').contains(_searchQuery) || v('supplier').contains(_searchQuery);
      }).toList();
    }
    if (_filterStage != 'All') {
      list = list.where((p) {
        final d = p.data() as Map<String, dynamic>;
        final stage = (d['stage'] ?? '').toString();
        return stage == _filterStage;
      }).toList();
    }
    return list;
  }

  void _selectAllProducts(List<QueryDocumentSnapshot> products, bool? value) {
    setState(() {
      _selectAll = value ?? false;
      _selectedProducts = _selectAll ? products.map((p) => p.id).toSet() : <String>{};
    });
  }

  void _selectProduct(String id, bool? v) {
    setState(() {
      if (v == true) {
        _selectedProducts.add(id);
      } else {
        _selectedProducts.remove(id);
      }
      _selectAll = _selectedProducts.length == _filterProducts(_currentProducts ?? []).length;
    });
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> products) {
    final headerTextStyle = const TextStyle(fontWeight: FontWeight.w600, color: Colors.white);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        if (_selectedProducts.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
            child: Row(children: [
              Text('${_selectedProducts.length} selected', style: TextStyle(color: Colors.blue.shade700)),
              const Spacer(),
              TextButton(onPressed: () => setState(() => _selectedProducts.clear()), child: const Text('Clear')),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: _showBulkDeleteDialog, icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
            ]),
          ),
        // header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.blue,
          child: Row(children: [
            SizedBox(width: _wCheck),
            SizedBox(width: _wSno, child: Text('S.No', style: headerTextStyle)),
            Expanded(flex: 2, child: Text('Item Code', style: headerTextStyle)),
            Expanded(flex: 2, child: Text('Design No', style: headerTextStyle)),
            Expanded(flex: 3, child: Text('Product Name', style: headerTextStyle)),
            Expanded(flex: 2, child: Text('Size', style: headerTextStyle)),
            Expanded(flex: 2, child: Text('Category', style: headerTextStyle)),
            Expanded(flex: 2, child: Text('Location', style: headerTextStyle)),
            SizedBox(width: _wPic, child: Text('Picture', style: headerTextStyle)),
            Expanded(flex: 2, child: Text('Total Qty', style: headerTextStyle)),
            Expanded(flex: 2, child: Text('Available Qty', style: headerTextStyle)),
            Expanded(flex: 2, child: Text('Supplier', style: headerTextStyle)),
            Expanded(flex: 2, child: Text('Stage', style: headerTextStyle)),
            SizedBox(width: _wActs),
          ]),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, i) {
            final d = products[i].data() as Map<String, dynamic>;
            final id = products[i].id;
            final selected = _selectedProducts.contains(id);
            String s(String k) => (d[k] ?? '').toString();
            int iVal(String k) => (d[k] is num) ? (d[k] as num).toInt() : int.tryParse(s(k)) ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: selected ? Colors.blue.shade50 : Colors.white,
              child: Row(children: [
                SizedBox(width: _wCheck, child: Checkbox(value: selected, onChanged: (v) => _selectProduct(id, v))),
                SizedBox(width: _wSno, child: Text('${i + 1}')),
                Expanded(flex: 2, child: Text(s('sku'), style: const TextStyle(fontFamily: 'monospace'))),
                Expanded(flex: 2, child: Text(s('designNo').isEmpty ? '-' : s('designNo'))),
                Expanded(flex: 3, child: Text(s('name'), overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text(s('size').isEmpty ? '-' : s('size'))),
                Expanded(flex: 2, child: Text(s('category').isEmpty ? '-' : s('category'))),
                Expanded(flex: 2, child: Text(s('location').isEmpty ? '-' : s('location'))),
                SizedBox(width: _wPic, child: _imageThumb(s('pictureUrl'))),
                Expanded(flex: 2, child: Text('${iVal('totalStockIn')}')),
                Expanded(flex: 2, child: Text('${iVal('currentStock')}')),
                Expanded(flex: 2, child: Text(s('supplier').isEmpty ? '-' : s('supplier'))),
                Expanded(flex: 2, child: Text(s('stage').isEmpty ? '-' : s('stage'))),
                SizedBox(
                  width: _wActs,
                  child: PopupMenuButton(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const ListTile(leading: Icon(Icons.edit_outlined, size: 18), title: Text('Edit', style: TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero, dense: true),
                        onTap: () => Future.microtask(() => updateProduct(id, d)),
                      ),
                      PopupMenuItem(
                        child: const ListTile(leading: Icon(Icons.delete_outline, size: 18, color: Colors.red), title: Text('Delete', style: TextStyle(fontSize: 14, color: Colors.red)), contentPadding: EdgeInsets.zero, dense: true),
                        onTap: () => Future.microtask(() => _showDeleteConfirmation(id, s('name').isEmpty ? 'this product' : s('name'))),
                      ),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
      ]),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Products'),
        content: Text('Delete ${_selectedProducts.length} selected product(s)? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _bulkDeleteProducts();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _bulkDeleteProducts() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedProducts) {
        batch.delete(FirebaseFirestore.instance.collection('products').doc(id));
      }
      await batch.commit();
      setState(() {
        _selectedProducts.clear();
        _selectAll = false;
      });
      _showSnackBar('Deleted selected products.', isError: false);
    } catch (e) {
      _showSnackBar('Bulk delete failed: $e', isError: true);
    }
  }

  void _showDeleteConfirmation(String docId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "$productName"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteProduct(docId, productName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // ================= PAGE =================
  void _showExportOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excel Operations'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.blue),
            title: const Text('Export to Excel'),
            onTap: () {
              Navigator.pop(context);
              exportToExcel();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.purple),
            title: const Text('Import from Excel'),
            onTap: () {
              Navigator.pop(context);
              previewAndImportExcel(alsoUploadToStorage: false);
            },
          ),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void showAddProductDialog() {
    _clearForm();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildProductDialog(
        title: 'Add New Product',
        onSubmit: () async {
          await addProduct();
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Products', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _isExporting ? null : _showExportOptionsDialog,
                icon: _isExporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.file_download_outlined, size: 18),
                label: Text(_isExporting ? 'Processing...' : 'Export / Import'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(onPressed: showAddProductDialog, icon: const Icon(Icons.add, size: 18), label: const Text('New product'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by code, name, category, supplier…',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) {
                    setState(() {
                      _searchQuery = v.toLowerCase();
                      _selectedProducts.clear();
                      _selectAll = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButton<String>(
                  underline: const SizedBox(),
                  value: _filterStage,
                  items: ['All', ..._stages].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _filterStage = v ?? 'All';
                      _selectedProducts.clear();
                      _selectAll = false;
                    });
                  },
                ),
              ),
            ]),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').orderBy('name').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return const Center(child: Text('Error loading products'));
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    const Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text('Add or import products to get started', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(onPressed: showAddProductDialog, icon: const Icon(Icons.add), label: const Text('Add Product')),
                  ]),
                );
              }
              final all = snap.data!.docs;
              _currentProducts = all;
              final filtered = _filterProducts(all);
              return SingleChildScrollView(child: _buildDataTable(filtered));
            },
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    skuCtrl.dispose();
    designNoCtrl.dispose();
    nameCtrl.dispose();
    sizeCtrl.dispose();
    categoryCtrl.dispose();
    locationCtrl.dispose();
    pictureUrlCtrl.dispose();
    totalQtyCtrl.dispose();
    availableQtyCtrl.dispose();
    supplierCtrl.dispose();
    editorCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }
}
