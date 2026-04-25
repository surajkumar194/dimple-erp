import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

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

  // ─── RE-NUMBER SR ─────────────────────────────────────────────────────────────
  Future<void> _renumberSrNumbers() async {
    try {
      final snapshot = await _firestore
          .collection('ready_stock_items')
          .orderBy('sr')
          .get();
      final WriteBatch batch = _firestore.batch();
      int newSr = 1;
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'sr': newSr});
        newSr++;
      }
      await batch.commit();
    } catch (e) {
      _showSnackBar('Renumbering failed: $e', isError: true);
    }
  }

  Future<int> _getNextSrNumber() async {
    try {
      final snapshot = await _firestore
          .collection('ready_stock_items')
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

  // ─── LOAD DATA ────────────────────────────────────────────────────────────────
  Future<void> _loadDataFromFirebase() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('ready_stock_items')
          .orderBy('sr')
          .get();

      stockData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      final groups =
          stockData
              .map((e) => (e['piller_no'] ?? '').toString())
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
    setState(() {
      filteredData = stockData.where((item) {
        final matchesSearch =
            (item["code"] ?? '').toString().toLowerCase().contains(query) ||
            (item["detail"] ?? '').toString().toLowerCase().contains(query) ||
            (item["piller_no"] ?? '').toString().toLowerCase().contains(query);
        final matchesGroup =
            _selectedGroup == 'All' || item['piller_no'] == _selectedGroup;
        return matchesSearch && matchesGroup;
      }).toList();
      _currentPage = 0;
    });
  }

  List<Map<String, dynamic>> get _paginatedData {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filteredData.length);
    return filteredData.sublist(start, end);
  }

  // ─── IMAGE ────────────────────────────────────────────────────────────────────
  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child(
        'ready_stock_images/$fileName.png',
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ISSUE STOCK ──────────────────────────────────────────────────────────────
  void _issueStockWithDepartment(Map<String, dynamic> item) {
    String? selectedDept;
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Issue Stock",
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDept,
                  hint: const Text("Select Department"),
                  items: _departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => selectedDept = v),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.work, color: Colors.red[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Enter Quantity to Issue",
                    prefixIcon: Icon(Icons.inventory, color: Colors.red[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              onPressed: () async {
                if (selectedDept == null) {
                  _showSnackBar("Please select a Department", isError: true);
                  return;
                }
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (qty <= 0) {
                  _showSnackBar("Enter valid quantity", isError: true);
                  return;
                }
                final currentBal = (item['bal'] ?? 0) as int;
                if (currentBal < qty) {
                  _showSnackBar("Not enough stock available!", isError: true);
                  return;
                }
                try {
                  await _firestore.collection('ready_stock_transactions').add({
                    'itemId': item['docId'],
                    'type': 'issue',
                    'department': selectedDept,
                    'quantity': qty,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  await _firestore
                      .collection('ready_stock_items')
                      .doc(item['docId'])
                      .update({
                        'bal': currentBal - qty,
                        'out': (item['out'] ?? 0) + qty,
                        'dateEdit': DateFormat(
                          'dd-MM-yyyy',
                        ).format(DateTime.now()),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                  // daily history
                  final todayKey = DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.now());
                  final dailyRef = _firestore
                      .collection('ready_stock_daily_history')
                      .doc(todayKey)
                      .collection('items')
                      .doc(item['docId']);
                  final dailySnap = await dailyRef.get();
                  if (dailySnap.exists) {
                    await dailyRef.update({
                      'totalIssued': FieldValue.increment(qty),
                      'lastUpdated': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await dailyRef.set({
                      'itemId': item['docId'],
                      'itemName': item['detail'],
                      'totalIssued': qty,
                      'date': todayKey,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }

                  await _loadDataFromFirebase();
                  Navigator.pop(ctx);
                  _showSnackBar("Issued $qty units to $selectedDept");
                } catch (e) {
                  _showSnackBar("Error issuing stock: $e", isError: true);
                }
              },
              child: const Text("Issue Now"),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADD ADDITIONAL ──────────────────────────────────────────────────────────
  void _addAdditionalWithParty(Map<String, dynamic> item) {
    final partyCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Add Additional Stock",
            style: TextStyle(color: Colors.green[700]),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: partyCtrl,
                decoration: InputDecoration(
                  labelText: "Second Party Name",
                  hintText: "Enter party name (e.g., Vendor A)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.person, color: Colors.green[700]),
                ),
                onChanged: (_) => setStateDialog(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.add_box, color: Colors.green[700]),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
              ),
              onPressed: partyCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) {
                        _showSnackBar("Enter valid quantity", isError: true);
                        return;
                      }
                      final newBal = (item['bal'] ?? 0) + qty;

                      await _firestore
                          .collection('ready_stock_transactions')
                          .add({
                            'itemId': item['docId'],
                            'type': 'received',
                            'party': partyCtrl.text.trim(),
                            'quantity': qty,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                      await _firestore
                          .collection('ready_stock_items')
                          .doc(item['docId'])
                          .update({
                            'bal': newBal,
                            'incoming': (item['incoming'] ?? 0) + qty,
                            'dateEdit': DateFormat(
                              'dd-MM-yyyy',
                            ).format(DateTime.now()),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                      await _loadDataFromFirebase();
                      _showSnackBar(
                        "Received $qty from ${partyCtrl.text.trim()}",
                      );
                      Navigator.pop(ctx);
                    },
              child: const Text("Continue Received"),
            ),
          ],
        ),
      ),
    );
  }

  // ─── UPDATE OPTIONS BOTTOM SHEET ──────────────────────────────────────────────
  void _showUpdateOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Update Stock",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _issueStockWithDepartment(item);
                  },
                  icon: const Icon(Icons.remove_circle, color: Colors.white),
                  label: const Text("Issue Stock"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _addAdditionalWithParty(item);
                  },
                  icon: const Icon(Icons.add_box, color: Colors.white),
                  label: const Text("Add Additional"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
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

  // ─── ITEM HISTORY DIALOG ──────────────────────────────────────────────────────
  void _showItemHistoryDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('ready_stock_transactions')
            .where('itemId', isEqualTo: item['docId'])
            .where('type', isEqualTo: 'issue')
            .orderBy('timestamp', descending: true)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.history, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    "Issue History",
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ],
              ),
              content: const Text("No previous issues found."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close"),
                ),
              ],
            );
          }
          final docs = snapshot.data!.docs;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.history, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${item['detail']} Issue History",
                    style: TextStyle(color: Colors.orange[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: 60.h),
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final dept = data['department'] ?? '-';
                  final qty = data['quantity'] ?? 0;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final dateStr = timestamp != null
                      ? DateFormat('dd-MM-yyyy hh:mm a').format(timestamp)
                      : '';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.arrow_upward, color: Colors.red[700]),
                      title: Text(
                        "Issued $qty → $dept",
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Close",
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── DAILY ISSUE HISTORY ──────────────────────────────────────────────────────
  void _showDailyIssueHistory() {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayRef = _firestore
        .collection('ready_stock_daily_history')
        .doc(todayKey)
        .collection('items');

    showDialog(
      context: context,
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: dayRef.orderBy('itemName').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Issued Today",
                style: TextStyle(color: Colors.deepOrange),
              ),
              content: const Text("No items issued today."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close"),
                ),
              ],
            );
          }
          final items = snapshot.data!.docs;
          return AlertDialog(
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.history, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text(
                  "Issued Today (${items.length})",
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: 60.h),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i].data() as Map<String, dynamic>;
                  return ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.deepOrange,
                      ),
                    ),
                    title: Text(
                      item['itemName'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: Text(
                      "${item['totalIssued'] ?? 0} pcs",
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── AVERAGE STOCK ────────────────────────────────────────────────────────────
  Future<double> _calculateAverageStock(String itemId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('ready_stock_transactions')
          .where('itemId', isEqualTo: itemId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('timestamp')
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final itemDoc = await _firestore
          .collection('ready_stock_items')
          .doc(itemId)
          .get();
      int currentBal = itemDoc.exists ? (itemDoc['bal'] ?? 0) : 0;

      Map<String, int> dailyBal = {};
      DateTime? lastDate;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
        final qty = data['quantity'] as int;
        final type = data['type'];

        if (lastDate != null) {
          var fillDate = lastDate.add(const Duration(days: 1));
          while (fillDate.isBefore(timestamp)) {
            dailyBal[DateFormat('yyyy-MM-dd').format(fillDate)] = currentBal;
            fillDate = fillDate.add(const Duration(days: 1));
          }
        }

        if (type == 'issue') currentBal -= qty;
        if (type == 'received') currentBal += qty;
        dailyBal[dateKey] = currentBal;
        lastDate = timestamp;
      }

      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      dailyBal[todayKey] = dailyBal[todayKey] ?? currentBal;
      if (dailyBal.isEmpty) return 0.0;
      final total = dailyBal.values.reduce((a, b) => a + b);
      return total / dailyBal.length;
    } catch (e) {
      return 0.0;
    }
  }

  void _showAverageStockDialog(Map<String, dynamic> item) async {
    final avg = await _calculateAverageStock(item['docId']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.purple[700]),
            const SizedBox(width: 8),
            Text(
              "1-Month Average",
              style: TextStyle(color: Colors.purple[700]),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Item: ${item['detail']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Code: ${item['code']}"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    "Average Stock (30 Days)",
                    style: TextStyle(fontSize: 12, color: Colors.purple[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    avg.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
                  ),
                  Text(
                    "units",
                    style: TextStyle(fontSize: 12, color: Colors.purple[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close", style: TextStyle(color: Colors.purple[700])),
          ),
        ],
      ),
    );
  }

  Future<void> _showGroupWiseAverageDialog() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final itemSnapshot = await _firestore.collection('ready_stock_items').get();
    final transSnapshot = await _firestore
        .collection('ready_stock_transactions')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    Map<String, List<Map<String, dynamic>>> groupItems = {};
    for (var doc in itemSnapshot.docs) {
      final data = doc.data();
      final group = data['piller_no'] ?? 'Unknown';
      groupItems[group] ??= [];
      groupItems[group]!.add({...data, 'docId': doc.id});
    }

    Map<String, double> groupAverages = {};
    for (var entry in groupItems.entries) {
      final group = entry.key;
      final items = entry.value;
      double totalStockDays = 0;
      int totalDays = 0;

      for (var item in items) {
        final itemId = item['docId'];
        int currentBal = item['bal'] ?? 0;
        final itemTrans =
            transSnapshot.docs.where((t) => t['itemId'] == itemId).toList()
              ..sort(
                (a, b) => (a['timestamp'] as Timestamp).compareTo(
                  b['timestamp'] as Timestamp,
                ),
              );

        DateTime? lastDate;
        for (var trans in itemTrans) {
          final timestamp = (trans['timestamp'] as Timestamp).toDate();
          final qty = trans['quantity'] as int;
          final type = trans['type'];

          if (lastDate != null) {
            var fillDate = lastDate.add(const Duration(days: 1));
            while (fillDate.isBefore(timestamp)) {
              totalStockDays += currentBal;
              totalDays++;
              fillDate = fillDate.add(const Duration(days: 1));
            }
          }
          if (type == 'issue') currentBal -= qty;
          if (type == 'received') currentBal += qty;
          totalStockDays += currentBal;
          totalDays++;
          lastDate = timestamp;
        }
        totalStockDays += currentBal;
        totalDays++;
      }
      groupAverages[group] = totalDays > 0 ? totalStockDays / totalDays : 0.0;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.purple[700]),
            const SizedBox(width: 8),
            Text(
              "Group-wise 30-Day Average",
              style: TextStyle(color: Colors.purple[700]),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 60.h),
          child: groupAverages.isEmpty
              ? const Center(child: Text("No data in last 30 days"))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: groupAverages.length,
                  itemBuilder: (context, i) {
                    final group = groupAverages.keys.elementAt(i);
                    final avg = groupAverages[group]!;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple[100],
                          child: Text(
                            group.isNotEmpty ? group[0] : '?',
                            style: TextStyle(color: Colors.purple[900]),
                          ),
                        ),
                        title: Text(
                          group,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          avg.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[900],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close", style: TextStyle(color: Colors.purple[700])),
          ),
        ],
      ),
    );
  }

  // ─── ADD / EDIT ITEM DIALOG ───────────────────────────────────────────────────
  void _addOrUpdateItem({Map<String, dynamic>? existingItem}) async {
    final isEdit = existingItem != null;

    final codeCtrl = TextEditingController(
      text: isEdit ? existingItem["code"] : '',
    );
    final detailCtrl = TextEditingController(
      text: isEdit ? existingItem["detail"] : '',
    );
    final pillerCtrl = TextEditingController(
      text: isEdit ? existingItem["piller_no"] : '',
    );
    final inCtrl = TextEditingController(
      text: isEdit ? existingItem["in"].toString() : '0',
    );
    final incomingCtrl = TextEditingController(
      text: isEdit ? existingItem["incoming"].toString() : '0',
    );
    final outCtrl = TextEditingController(
      text: isEdit ? existingItem["out"].toString() : '0',
    );
    final balCtrl = TextEditingController(
      text: isEdit ? existingItem["bal"].toString() : '0',
    );
    final remarkCtrl = TextEditingController(
      text: isEdit ? (existingItem["remark1"] ?? '') : '',
    );

    String? imageUrl = isEdit ? existingItem["image"] : null;
    XFile? selectedImage;
    bool isUploading = false;
    int nextSr = isEdit ? existingItem["sr"] : await _getNextSrNumber();
    final String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: 80.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[700]!, Colors.orange[500]!],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEdit ? Icons.edit : Icons.add_circle,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? "Edit Ready Stock Item" : "Add New Item",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 150,
                                height: 150,
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          }
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      )
                                    : imageUrl != null && imageUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          imageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        Icons.image,
                                        size: 60,
                                        color: Colors.grey[400],
                                      ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        final XFile? image = await _picker
                                            .pickImage(
                                              source: ImageSource.gallery,
                                            );
                                        if (image != null) {
                                          setDialogState(
                                            () => selectedImage = image,
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: Text(
                                  selectedImage != null
                                      ? "Change Image"
                                      : "Upload Image",
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildModernField(
                          codeCtrl,
                          "DPL Code",
                          Icons.qr_code,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernField(
                          detailCtrl,
                          "Detail",
                          Icons.description,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernField(
                          pillerCtrl,
                          "Piller No.",
                          Icons.pin,
                          required: true,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Stock Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                inCtrl,
                                "IN",
                                Icons.add_box,
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernField(
                                incomingCtrl,
                                "Incoming",
                                Icons.input,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                              child: _buildModernField(
                                balCtrl,
                                "Balance",
                                Icons.account_balance,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildModernField(remarkCtrl, "Remark 1", Icons.note),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Date Edit: $currentDate",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isUploading
                            ? null
                            : () async {
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
                                setDialogState(() => isUploading = true);
                                if (selectedImage != null) {
                                  imageUrl = await _uploadImage(selectedImage!);
                                }

                                final inVal = int.tryParse(inCtrl.text) ?? 0;
                                final incomingVal =
                                    int.tryParse(incomingCtrl.text) ?? 0;
                                final outVal = int.tryParse(outCtrl.text) ?? 0;
                                final balVal =
                                    int.tryParse(balCtrl.text) ??
                                    (inVal + incomingVal - outVal);

                                final newItem = {
                                  "sr": nextSr,
                                  "code": code,
                                  "image": imageUrl ?? "",
                                  "detail": detail,
                                  "piller_no": piller,
                                  "in": inVal,
                                  "incoming": incomingVal,
                                  "out": outVal,
                                  "bal": balVal,
                                  "remark1": remarkCtrl.text.trim(),
                                  "dateEdit": currentDate,
                                  "updatedAt": FieldValue.serverTimestamp(),
                                };

                                try {
                                  if (isEdit) {
                                    await _firestore
                                        .collection('ready_stock_items')
                                        .doc(existingItem["docId"])
                                        .update(newItem);
                                    _showSnackBar("Item updated successfully");
                                  } else {
                                    newItem["createdAt"] =
                                        FieldValue.serverTimestamp();
                                    await _firestore
                                        .collection('ready_stock_items')
                                        .add(newItem);
                                    _showSnackBar("Item added successfully!");
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
                          style: const TextStyle(fontSize: 16),
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

  // ─── EXCEL UPLOAD ─────────────────────────────────────────────────────────────
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
          var value = row[j]?.value;
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
            case 'image':
            case 'remark1':
              item[header] = value.toString().trim();
              break;
          }
        }
        if (item['code'] == null ||
            item['detail'] == null ||
            item['piller_no'] == null)
          continue;

        item['in'] = item['in'] ?? 0;
        item['incoming'] = item['incoming'] ?? 0;
        item['out'] = item['out'] ?? 0;
        item['bal'] =
            item['bal'] ?? (item['in'] + item['incoming'] - item['out']);
        item['image'] = item['image'] ?? '';
        item['remark1'] = item['remark1'] ?? '';
        item['dateEdit'] = today;
        item['sr'] ??= await _getNextSrNumber();
        importedItems.add(item);
      }

      if (importedItems.isEmpty) {
        _showSnackBar("No valid data found in Excel", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      WriteBatch batch = _firestore.batch();
      final existingSnapshot = await _firestore
          .collection('ready_stock_items')
          .get();
      final Map<String, DocumentReference> existingMap = {
        for (var d in existingSnapshot.docs) d['code']: d.reference,
      };
      int batchCount = 0;
      for (var item in importedItems) {
        if (existingMap.containsKey(item['code'])) {
          batch.update(existingMap[item['code']]!, {
            ...item,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final docRef = _firestore.collection('ready_stock_items').doc();
          batch.set(docRef, {
            ...item,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
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
      _showSnackBar("Excel imported! ${importedItems.length} items processed.");
    } catch (e) {
      _showSnackBar("Import failed: $e", isError: true);
    }
    setState(() => _isLoading = false);
  }

  // ─── DELETE ITEM ──────────────────────────────────────────────────────────────
  void _deleteItem(String docId, int sr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            Text("Delete Item?", style: TextStyle(color: Colors.red[700])),
          ],
        ),
        content: const Text("This action cannot be undone. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _firestore
                    .collection('ready_stock_items')
                    .doc(docId)
                    .delete();
                await _renumberSrNumbers();
                await _loadDataFromFirebase();
                _showSnackBar("Item deleted & Sr No. updated");
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

  // ─── HELPER WIDGETS ───────────────────────────────────────────────────────────
  Widget _buildModernField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool required = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label + (required ? " *" : ""),
        prefixIcon: Icon(icon, color: Colors.orange[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.orange[50],
      ),
    );
  }

  Widget _header(String text, double width) => SizedBox(
    width: width,
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.visible,
      softWrap: true,
    ),
  );

  Widget _cell(
    String text,
    double width, {
    Color? color,
    bool bold = false,
    double fontSize = 13,
  }) => SizedBox(
    width: width,
    child: Text(
      text,
      style: TextStyle(
        color: color ?? Colors.black87,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        fontSize: fontSize,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _cellImage(String? url, double width) {
    if (url == null || url.isEmpty) return _placeholderImage(width);
    return SizedBox(
      width: width,
      child: Center(
        child: GestureDetector(
          onTap: () => _showImageZoom(url.trim()),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url.trim(),
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              cacheWidth: 120,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => _errorImage(width),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage(double width) => SizedBox(
    width: width,
    child: Center(
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image, size: 28, color: Colors.grey[500]),
      ),
    ),
  );

  Widget _errorImage(double width) => SizedBox(
    width: width,
    child: Center(
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 24, color: Colors.red[400]),
            Text(
              "Error",
              style: TextStyle(fontSize: 8, color: Colors.red[600]),
            ),
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
        IconButton(
          icon: Icon(Icons.edit, color: Colors.orange[700], size: 20),
          onPressed: () => _addOrUpdateItem(existingItem: item),
          tooltip: "Edit",
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red[700], size: 20),
          onPressed: () => _deleteItem(item["docId"] ?? '', item["sr"]),
          tooltip: "Delete",
        ),
      ],
    ),
  );

  Widget _updateButton(Map<String, dynamic> item, double width) => SizedBox(
    width: width,
    child: Center(
      child: ElevatedButton(
        onPressed: () => _showUpdateOptions(item),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          "Update",
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    ),
  );

  // ─── RESPONSIVE TABLE (same structure as StoreStockScreen) ───────────────────
  Widget _responsiveTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: 1500,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _header("Sr No.", 70),
                    _header("CODE", 100),
                    _header("ITEM PICTURES", 110),
                    _header("DETAIL", 160),
                    _header("PILLER NO.", 110),
                    _header("IN", 90),
                    _header("INCOMING", 100),
                    _header("OUT", 90),
                    _header("BALANCE", 100),
                    _header("DATE EDIT", 90),
                    _header("REMARK", 120),
                    _header("ACTIONS", 100),
                    _header("UPDATE", 100),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Rows with expandable history
              ..._paginatedData.map((item) {
                final itemId = item['docId'];
                final bool isExpanded = item['isExpanded'] == true;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => item['isExpanded'] = !isExpanded),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _cell(item["sr"].toString(), 70),
                            _cell(item["code"] ?? '', 100, bold: true),
                            _cellImage(item["image"], 110),
                            _cell(
                              item["detail"] ?? '',
                              160,
                              bold: true,
                              color: Colors.blue[700],
                            ),
                            _cell(item["piller_no"] ?? '', 110),
                            _cell(item["in"].toString(), 90),
                            _cell(item["incoming"].toString(), 100),
                            _cell(
                              item["out"].toString(),
                              90,
                              color: Colors.red[700],
                            ),
                            _cell(
                              item["bal"].toString(),
                              100,
                              color: Colors.green[900],
                              bold: true,
                              fontSize: 14,
                            ),
                            _cell(item["dateEdit"]?.toString() ?? '', 90),
                            _cell(
                              item["remark1"] ?? '–',
                              120,
                              color: Colors.grey[700],
                            ),
                            _actionButtons(item, 100),
                            _updateButton(item, 100),
                          ],
                        ),
                      ),
                    ),

                    // Expandable Issue History
                    if (isExpanded)
                      Container(
                        margin: const EdgeInsets.only(
                          bottom: 8,
                          left: 8,
                          right: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('ready_stock_transactions')
                              .where('itemId', isEqualTo: itemId)
                              .where('type', isEqualTo: 'issue')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                  ),
                                ),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  "No issue history for this item.",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              );
                            }

                            final docs = snapshot.data!.docs;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      color: Colors.orange[700],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Issue History (${docs.length})",
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: docs.length,
                                    itemBuilder: (context, i) {
                                      final data =
                                          docs[i].data()
                                              as Map<String, dynamic>;
                                      final qty = data['quantity'] ?? 0;
                                      final dept = data['department'] ?? '-';
                                      final ts =
                                          (data['timestamp'] as Timestamp?)
                                              ?.toDate();
                                      final dateStr = ts != null
                                          ? DateFormat(
                                              'dd-MM-yyyy hh:mm a',
                                            ).format(ts)
                                          : '-';
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          Icons.arrow_upward,
                                          color: Colors.red[600],
                                        ),
                                        title: Text(
                                          "Issued $qty pcs → $dept",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                        subtitle: Text(
                                          dateStr,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────
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
                        'Ready Stock',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage Ready Stock Items',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                // Daily Issue History button
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  tooltip: "Today's Issues",
                  onPressed: _showDailyIssueHistory,
                ),
                // Group Average button
                IconButton(
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  tooltip: "Group-wise Average",
                  onPressed: _showGroupWiseAverageDialog,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                // Search + Group Filter
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  "Search by Code, Detail or Piller No...",
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.orange[600],
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          value: _selectedGroup,
                          hint: const Text("Filter Group"),
                          items: _groupList
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g == 'All' ? 'All Groups' : g),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => _selectedGroup = v!);
                            _applyFilters();
                          },
                          underline: const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table
                Expanded(child: _responsiveTable()),

                // Pagination
                if (filteredData.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Page ${_currentPage + 1} of ${((filteredData.length - 1) / _rowsPerPage).ceil()}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0
                                  ? () => setState(() => _currentPage--)
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<int>(
                                value: _rowsPerPage,
                                underline: const SizedBox(),
                                items: [5, 10, 20, 50]
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text("$n / page"),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _rowsPerPage = v!;
                                  _currentPage = 0;
                                }),
                              ),
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
                      ],
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
            backgroundColor: Colors.orange[600],
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: Text(
              "Add Item",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          FloatingActionButton.extended(
            onPressed: _uploadExcelFile,
            heroTag: "upload_excel",
            backgroundColor: Colors.green[600],
            icon: const Icon(Icons.upload_file, color: Colors.white, size: 20),
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
    );
  }
}
