// lib/ExcelBrowserPage.dart
import 'dart:typed_data';
import 'package:dimple_erp/all%20pages/firebase_optional.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

const String kStorageFolder = 'EXCEL/';            // case-sensitive
const int kMaxExcelBytes  = 20 * 1024 * 1024;      // 20 MB cap

class ExcelBrowserPage extends StatefulWidget {
  const ExcelBrowserPage({super.key});
  @override
  State<ExcelBrowserPage> createState() => _ExcelBrowserPageState();
}

class _ExcelBrowserPageState extends State<ExcelBrowserPage> {
  bool _initDone = false;
  bool _loading = false;
  String? _error;
  List<Reference> _files = [];

  String? _selectedFilePath;
  List<String> _sheetNames = [];
  String? _selectedSheet;
  List<List<dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Sign-in (Anonymous ok; make sure Anonymous is enabled in Console)
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      await _loadFiles();
      setState(() => _initDone = true);
    } catch (e, st) {
      debugPrint('INIT ERROR: $e\n$st');
      setState(() => _error = 'Init error: $e');
    }
  }

  Future<void> _loadFiles() async {
    try {
      final ref = FirebaseStorage.instance.ref(kStorageFolder);
      final ListResult result = await ref.listAll();

      final files = result.items
          .where((r) => r.name.toLowerCase().endsWith('.xlsx'))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      setState(() => _files = files);
    } on FirebaseException catch (e, st) {
      debugPrint('LIST ERROR(Firebase): ${e.code} ${e.message}\n$st');
      setState(() => _error = 'List error: [${e.code}] ${e.message}');
    } catch (e, st) {
      debugPrint('LIST ERROR: $e\n$st');
      setState(() => _error = 'List error: $e');
    }
  }

  // -------- OPEN FILE (WEB-SAFE via getData) --------
  Future<void> _openExcel(Reference fileRef) async {
    try {
      setState(() {
        _loading = true;
        _error = null;
        _selectedFilePath = fileRef.fullPath;
        _sheetNames = [];
        _selectedSheet = null;
        _rows = [];
      });

      // >>> This is the key: read bytes via Storage SDK, not http.get
      final Uint8List? bytes = await fileRef.getData(kMaxExcelBytes);
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Empty file or blocked read');
      }

      final excel = Excel.decodeBytes(bytes);
      final sheets = excel.tables.keys.toList();
      if (sheets.isEmpty) throw Exception('No sheets found');

      setState(() {
        _sheetNames = sheets;
        _selectedSheet = sheets.first;
        _rows = excel.tables[_selectedSheet]!
            .rows
            .map((r) => r.map((c) => c?.value).toList())
            .toList();
      });
    } on FirebaseException catch (e, st) {
      // e.g. storage/unauthorized, storage/object-not-found, etc.
      debugPrint('OPEN ERROR(Firebase): ${e.code} ${e.message}\n$st');
      setState(() => _error = 'Open error: [${e.code}] ${e.message}');
    } catch (e, st) {
      debugPrint('OPEN ERROR: $e\n$st');
      setState(() => _error = 'Open error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -------- CHANGE SHEET (also uses getData) --------
  Future<void> _changeSheet(String sheet) async {
    try {
      if (_selectedFilePath == null) return;
      setState(() => _loading = true);

      final ref = FirebaseStorage.instance.ref(_selectedFilePath!);
      final Uint8List? bytes = await ref.getData(kMaxExcelBytes);
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Empty file or blocked read');
      }

      final excel = Excel.decodeBytes(bytes);
      final table = excel.tables[sheet];
      if (table == null) throw Exception('Sheet "$sheet" not found');

      setState(() {
        _selectedSheet = sheet;
        _rows = table.rows.map((r) => r.map((c) => c?.value).toList()).toList();
      });
    } on FirebaseException catch (e, st) {
      debugPrint('SHEET ERROR(Firebase): ${e.code} ${e.message}\n$st');
      setState(() => _error = 'Sheet switch error: [${e.code}] ${e.message}');
    } catch (e, st) {
      debugPrint('SHEET ERROR: $e\n$st');
      setState(() => _error = 'Sheet switch error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Excel Browser')),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }
    if (!_initDone) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel Browser (Firebase Storage)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFiles)
        ],
      ),
      body: Row(
        children: [
          // LEFT: file list
          SizedBox(
            width: 320,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  child: Text('Files in "$kStorageFolder"',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _files.isEmpty
                      ? const Center(child: Text('No .xlsx files found'))
                      : ListView.separated(
                          itemCount: _files.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final r = _files[i];
                            final selected = r.fullPath == _selectedFilePath;
                            return ListTile(
                              leading: const Icon(Icons.table_view),
                              title: Text(r.name),
                              subtitle: Text(r.fullPath),
                              selected: selected,
                              onTap: () => _openExcel(r),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),

          // RIGHT: preview
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedFilePath != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Text(_selectedFilePath!,
                            style: Theme.of(context).textTheme.titleSmall),
                        const Spacer(),
                        if (_sheetNames.isNotEmpty)
                          DropdownButton<String>(
                            value: _selectedSheet,
                            hint: const Text('Select sheet'),
                            items: _sheetNames
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => v != null ? _changeSheet(v) : null,
                          ),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _rows.isEmpty
                          ? const Center(child: Text('Select an Excel file to preview'))
                          : _ExcelTable(rows: _rows),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExcelTable extends StatelessWidget {
  final List<List<dynamic>> rows;
  const _ExcelTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final normalized = rows
        .map<List<String>>((r) => r.map((c) => (c ?? '').toString()).toList())
        .toList();

    int colCount = 0;
    for (final r in normalized) {
      if (r.length > colCount) colCount = r.length;
    }

    final hasHeader =
        normalized.isNotEmpty && normalized.first.any((e) => e.trim().isNotEmpty);
    final headers =
        hasHeader ? normalized.first : List.generate(colCount, (i) => 'Col ${i + 1}');
    final dataRows = hasHeader ? normalized.skip(1).toList() : normalized;

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: List.generate(
              colCount,
              (i) => DataColumn(label: Text(i < headers.length ? headers[i] : ''))),
            rows: dataRows
                .map((r) => DataRow(
                      cells: List.generate(
                        colCount,
                        (i) => DataCell(Text(i < r.length ? r[i] : '')),
                      ),
                    ))
                .toList(),
            headingRowHeight: 42,
            dataRowMinHeight: 38,
          ),
        ),
      ),
    );
  }
}
