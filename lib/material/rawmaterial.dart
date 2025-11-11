import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';

class RawMaterialScreen extends StatefulWidget {
  const RawMaterialScreen({Key? key}) : super(key: key);

  @override
  State<RawMaterialScreen> createState() => _RawMaterialScreenState();
}

class _RawMaterialScreenState extends State<RawMaterialScreen> {
  String searchQuery = '';
  String filterCategory = 'All';

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }

  String _safeString(dynamic value) =>
      (value?.toString().trim().isNotEmpty == true) ? value.toString().trim() : '-';
  double _safeDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

  Future<void> _deleteMaterial(String docId, String boardSize) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material?'),
        content: Text('Are you sure you want to delete "$boardSize"?\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('rawMaterials').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material Deleted!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  void _showAddEditDialog({String? docId, Map<String, dynamic>? existing}) {
    final isEdit = docId != null && existing != null;
    final _formKey = GlobalKey<FormState>();

    final boardInchController = TextEditingController(text: _safeString(existing?['boardSizeInch']));
    final boardCmController = TextEditingController(text: _safeString(existing?['boardSizeCm']));
    final gsmController = TextEditingController(text: existing?['gsm']?.toString() ?? '');
    final pktWtController = TextEditingController(text: existing?['pktWt']?.toString() ?? '');
    final recPktController = TextEditingController(text: existing?['recPkt']?.toString() ?? '');
    final recWtController = TextEditingController(text: existing?['recWt']?.toString() ?? '');
    final issuedPktController = TextEditingController(text: existing?['issuedPkt']?.toString() ?? '');
    final issuedWtController = TextEditingController(text: existing?['issuedWt']?.toString() ?? '');
    final balPktController = TextEditingController(text: existing?['balPkt']?.toString() ?? '');
    final balWtController = TextEditingController(text: existing?['balWt']?.toString() ?? '');
    final millNameController = TextEditingController(text: _safeString(existing?['millname']));
    final remarkController = TextEditingController(text: _safeString(existing?['remark']));
    final locationController = TextEditingController(text: _safeString(existing?['location']));

    DateTime recDate = (existing?['recDate'] as Timestamp?)?.toDate() ?? DateTime.now();

    void rebuild() => setState(() {});

    final isDesktop = MediaQuery.of(context).size.width > 800;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 720 : double.infinity),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(isEdit ? 'Edit Board Material' : 'Add Board Material',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(boardInchController, 'BOARD SIZE INCH *', required: true),
                          const SizedBox(height: 12),
                          _buildTextField(boardCmController, 'BOARD SIZE CM *', required: true),
                          const SizedBox(height: 12),
                          _buildTextField(gsmController, 'GSM *', keyboardType: TextInputType.number, required: true),
                          const SizedBox(height: 12),
                          _buildTextField(pktWtController, 'PKT WT *', keyboardType: TextInputType.number, required: true),
                          const SizedBox(height: 12),
                          _buildTextField(recPktController, 'REC pkt', keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildTextField(recWtController, 'REC WT', keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildTextField(issuedPktController, 'ISSUED pkt', keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildTextField(issuedWtController, 'ISSUED WT', keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildTextField(balPktController, 'BAL pkt', keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildTextField(balWtController, 'BAL WT', keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildTextField(millNameController, 'MILL NAME'),
                          const SizedBox(height: 12),
                          _buildTextField(remarkController, 'REMARK'),
                          const SizedBox(height: 12),
                          _buildTextField(locationController, 'LOCATION'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('REC DATE: ', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text("${recDate.day}/${recDate.month}/${recDate.year}"),
                              const Spacer(),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.date_range, size: 18),
                                label: const Text('Pick'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: recDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    recDate = picked;
                                    rebuild();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final payload = {
                            'boardSizeInch': boardInchController.text.trim(),
                            'boardSizeCm': boardCmController.text.trim(),
                            'gsm': double.tryParse(gsmController.text.trim()) ?? 0,
                            'pktWt': double.tryParse(pktWtController.text.trim()) ?? 0,
                            'recPkt': double.tryParse(recPktController.text.trim()) ?? 0,
                            'recWt': double.tryParse(recWtController.text.trim()) ?? 0,
                            'issuedPkt': double.tryParse(issuedPktController.text.trim()) ?? 0,
                            'issuedWt': double.tryParse(issuedWtController.text.trim()) ?? 0,
                            'balPkt': double.tryParse(balPktController.text.trim()) ?? 0,
                            'balWt': double.tryParse(balWtController.text.trim()) ?? 0,
                            'millname': millNameController.text.trim(),
                            'remark': remarkController.text.trim(),
                            'location': locationController.text.trim(),
                            'recDate': Timestamp.fromDate(recDate),
                            'lastUpdated': FieldValue.serverTimestamp(),
                          };

                          if (isEdit) {
                            await FirebaseFirestore.instance.collection('rawMaterials').doc(docId).update(payload);
                          } else {
                            payload['createdAt'] = FieldValue.serverTimestamp();
                            await FirebaseFirestore.instance.collection('rawMaterials').add(payload);
                          }

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'Updated!' : 'Added!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(isEdit ? 'Update' : 'Add Material'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType, bool required = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: required ? (v) => v?.trim().isEmpty ?? true ? 'Required' : null : null,
    );
  }

  // -------------------------------------------------------------------------
  // DETAIL VIEW + DELETE BUTTON
  // -------------------------------------------------------------------------
  void _showMaterialDetails(String docId, Map<String, dynamic> data) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final child = _detailContent(docId, data);

    if (isDesktop) {
      showDialog(context: context, builder: (_) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 650), child: child)));
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.88,
          expand: false,
          builder: (_, controller) => SingleChildScrollView(controller: controller, padding: const EdgeInsets.all(24), child: child),
        ),
      );
    }
  }

  Widget _detailContent(String docId, Map<String, dynamic> data) {
    final boardSize = _safeString(data['boardSizeInch']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 50, height: 5, color: Colors.grey[300])),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BOARD SIZE: $boardSize', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('CM: ${_safeString(data['boardSizeCm'])}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)), onPressed: () { Navigator.pop(context); _showAddEditDialog(docId: docId, existing: data); }),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () {
                Navigator.pop(context);
                _deleteMaterial(docId, boardSize);
              },
            ),
          ],
        ),
        const Divider(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 500;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: wide ? 2 : 1,
              childAspectRatio: wide ? 4.5 : 5.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 8,
              children: [
                _detailTile('GSM', data['gsm']?.toString() ?? '0'),
                _detailTile('PKT WT', data['pktWt']?.toString() ?? '0'),
                _detailTile('REC pkt', data['recPkt']?.toString() ?? '0'),
                _detailTile('REC WT', data['recWt']?.toString() ?? '0'),
                _detailTile('ISSUED pkt', data['issuedPkt']?.toString() ?? '0'),
                _detailTile('ISSUED WT', data['issuedWt']?.toString() ?? '0'),
                _detailTile('BAL pkt', data['balPkt']?.toString() ?? '0'),
                _detailTile('BAL WT', data['balWt']?.toString() ?? '0'),
                _detailTile('MILL NAME', _safeString(data['millname'])),
                _detailTile('REMARK', _safeString(data['remark'])),
                _detailTile('LOCATION', _safeString(data['location'])),
                _detailTile('REC DATE', _formatTimestamp(data['recDate'])),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
              onPressed: () { Navigator.pop(context); _showAddEditDialog(docId: docId, existing: data); },
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () { Navigator.pop(context); _deleteMaterial(docId, boardSize); },
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // EXCEL / CSV UPLOAD
  // -------------------------------------------------------------------------
  Future<void> _uploadExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();

      List<Map<String, dynamic>> records = [];

      if (result.files.single.extension == 'csv') {
        final csvString = String.fromCharCodes(bytes);
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
        if (csvTable.isEmpty) return;

        final headers = csvTable[0].map((e) => e.toString().trim()).toList();
        for (int i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          final map = <String, dynamic>{};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            map[headers[j]] = row[j];
          }
          records.add(map);
        }
      } else {
        var excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables.values.first;
        final rows = sheet.rows;
        if (rows.isEmpty) return;

        final headers = rows[0].map((cell) => cell?.value?.toString().trim() ?? '').toList();
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          final map = <String, dynamic>{};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            final cell = row[j];
            map[headers[j]] = cell?.value;
          }
          records.add(map);
        }
      }

      if (records.isEmpty) {
        _showSnackBar('No data found in file!', Colors.orange);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (var data in records) {
        final payload = _mapExcelToFirestore(data);
        if (payload != null) {
          final docRef = FirebaseFirestore.instance.collection('rawMaterials').doc();
          batch.set(docRef, payload);
          count++;
        }
      }

      await batch.commit();
      _showSnackBar('$count materials uploaded successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Upload failed: $e', Colors.red);
    }
  }

  Map<String, dynamic>? _mapExcelToFirestore(Map<String, dynamic> row) {
    try {
      final boardInch = _cleanString(row['BOARD SIZE INCH'] ?? row['boardSizeInch'] ?? row['Board Size Inch']);
      final boardCm = _cleanString(row['BOARD SIZE CM'] ?? row['boardSizeCm'] ?? row['Board Size Cm']);
      final gsm = _cleanNum(row['GSM'] ?? row['gsm']);
      final pktWt = _cleanNum(row['PKT WT'] ?? row['pktWt']);

      if (boardInch.isEmpty || boardCm.isEmpty || gsm == 0 || pktWt == 0) return null;

      final recDateStr = _cleanString(row['REC DATE'] ?? row['recDate']);
      DateTime recDate = DateTime.now();
      if (recDateStr.isNotEmpty) {
        try {
          final parts = recDateStr.split(RegExp(r'[/\.\-]'));
          if (parts.length == 3) {
            recDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        } catch (_) {}
      }

      return {
        'boardSizeInch': boardInch,
        'boardSizeCm': boardCm,
        'gsm': gsm,
        'pktWt': pktWt,
        'recPkt': _cleanNum(row['REC pkt'] ?? row['recPkt']),
        'recWt': _cleanNum(row['REC WT'] ?? row['recWt']),
        'issuedPkt': _cleanNum(row['ISSUED pkt'] ?? row['issuedPkt']),
        'issuedWt': _cleanNum(row['ISSUED WT'] ?? row['issuedWt']),
        'balPkt': _cleanNum(row['BAL pkt'] ?? row['balPkt']),
        'balWt': _cleanNum(row['BAL WT'] ?? row['balWt']),
        'millname': _cleanString(row['MILL NAME'] ?? row['millname']),
        'remark': _cleanString(row['REMARK'] ?? row['remark']),
        'location': _cleanString(row['LOCATION'] ?? row['location']),
        'recDate': Timestamp.fromDate(recDate),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      return null;
    }
  }

  String _cleanString(dynamic val) => (val?.toString().trim() ?? '').isNotEmpty ? val.toString().trim() : '';
  double _cleanNum(dynamic val) => double.tryParse(val?.toString().trim() ?? '') ?? 0.0;

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
      );
    }
  }

  // -------------------------------------------------------------------------
  // MAIN BUILD
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Material Inventory'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by Board Size, CM, Mill Name, Remark, or Location...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                if (isDesktop)
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: filterCategory,
                      decoration: InputDecoration(
                        labelText: 'Filter',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ['All', 'In Stock', 'Low Stock'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => filterCategory = v!),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('rawMaterials').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('No materials found.', style: TextStyle(fontSize: 18)));

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final inch = _safeString(data['boardSizeInch']).toLowerCase();
                  final cm = _safeString(data['boardSizeCm']).toLowerCase();
                  final mill = _safeString(data['millname']).toLowerCase();
                  final remark = _safeString(data['remark']).toLowerCase();
                  final loc = _safeString(data['location']).toLowerCase();

                  final matchesSearch = inch.contains(searchQuery) || cm.contains(searchQuery) || mill.contains(searchQuery) || remark.contains(searchQuery) || loc.contains(searchQuery);

                  if (filterCategory == 'Low Stock') return matchesSearch && _safeDouble(data['balWt']) < 50;
                  if (filterCategory == 'In Stock') return matchesSearch && _safeDouble(data['balWt']) > 0;
                  return matchesSearch;
                }).toList();

                return isDesktop
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.6,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _buildMaterialCard(filtered[i]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _buildMaterialCard(filtered[i], isList: true),
                      );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "add",
            onPressed: _showAddEditDialog,
            backgroundColor: const Color(0xFF4CAF50),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Material', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "upload",
            onPressed: _uploadExcel,
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text('Upload Excel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // CARD + DELETE ICON
  // -------------------------------------------------------------------------
  Widget _buildMaterialCard(QueryDocumentSnapshot doc, {bool isList = false}) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    final boardSize = _safeString(data['boardSizeInch']);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMaterialDetails(id, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        boardSize,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isList || MediaQuery.of(context).size.width > 900)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showAddEditDialog(docId: id, existing: data),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      tooltip: 'Delete',
                      onPressed: () => _deleteMaterial(id, boardSize),
                    ),
                    if (!isList)
                      Text(_formatTimestamp(data['recDate']), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('CM: ${_safeString(data['boardSizeCm'])}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text('GSM: ${data['gsm'] ?? 0}  |  BAL WT: ${data['balWt'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w500)),
                if (!isList && _safeString(data['millname']) != '-') ...[
                  const SizedBox(height: 2),
                  Text('Mill: ${_safeString(data['millname'])}', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 13)),
                ],
                if (!isList && _safeString(data['remark']) != '-') ...[
                  const SizedBox(height: 1),
                  Text('Remark: ${_safeString(data['remark'])}', style: TextStyle(color: Colors.orange[700], fontStyle: FontStyle.italic, fontSize: 13)),
                ],
                if (!isList) ...[
                  const SizedBox(height: 2),
                  Text('Location: ${_safeString(data['location'])}', style: TextStyle(color: Colors.grey[700])),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}