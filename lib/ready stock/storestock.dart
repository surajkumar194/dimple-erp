import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class StoreStockScreen extends StatefulWidget {
  const StoreStockScreen({super.key});
  @override
  _StoreStockScreenState createState() => _StoreStockScreenState();
}

class _StoreStockScreenState extends State<StoreStockScreen> {
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

  final List<String> _departments = ['Gora Depatment', 'Mdf hall 1', 'Mdf hall 2', 'designing room', ];

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

  // RE-NUMBER SR AFTER DELETE
  Future<void> _renumberSrNumbers() async {
    try {
      final snapshot = await _firestore.collection('stock_items').orderBy('sr').get();
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

  Future<void> _loadDataFromFirebase() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('stock_items').orderBy('sr').get();
      stockData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      final groups = stockData.map((e) => e['group'] as String).toSet().toList()..sort();
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

  void _filterData() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredData = stockData.where((item) {
        final matchesSearch = item["code"].toString().toLowerCase().contains(query) ||
            item["name"].toString().toLowerCase().contains(query) ||
            item["group"].toString().toLowerCase().contains(query);
        final matchesGroup = _selectedGroup == 'All' || item['group'] == _selectedGroup;
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

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('stock_images/$fileName.png');
      final uploadTask = await ref.putData(imageBytes, SettableMetadata(contentType: 'image/png'));
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
                icon: Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

 void _issueStockWithDepartment(Map<String, dynamic> item) {
  final qtyCtrl = TextEditingController();
  String? selectedJobCard;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Issue Stock to Job", style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Fetch job cards
                FutureBuilder<QuerySnapshot>(
                  future: _firestore.collection('jobCards').orderBy('createdAt', descending: true).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Colors.orange));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text("No Job Cards found.", style: TextStyle(color: Colors.grey[600]));
                    }

                    final jobCards = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: selectedJobCard,
                      decoration: InputDecoration(
                        labelText: "Select Job Card",
                        prefixIcon: Icon(Icons.work, color: Colors.red[700]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: jobCards.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final jobNo = data['jobNo'] ?? 'N/A';
                        final product = data['productName'] ?? '';
                        return DropdownMenuItem(
                          value: d.id,
                          child: Text("$jobNo - $product"),
                        );
                      }).toList(),
                      onChanged: (v) => setStateDialog(() => selectedJobCard = v),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Enter Quantity to Issue",
                    prefixIcon: Icon(Icons.inventory, color: Colors.red[700]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              onPressed: () async {
                if (selectedJobCard == null) {
                  _showSnackBar("Please select a Job Card", isError: true);
                  return;
                }

                final qtyText = qtyCtrl.text.trim();
                final qty = int.tryParse(qtyText) ?? 0;
                if (qty <= 0) {
                  _showSnackBar("Enter valid quantity", isError: true);
                  return;
                }

                final currentStock = item['current'] ?? 0;
                if (currentStock < qty) {
                  _showSnackBar("Not enough stock available!", isError: true);
                  return;
                }

             try {
  // ✅ 1️⃣ Record issue transaction
  await _firestore.collection('stock_transactions').add({
    'itemId': item['docId'],
    'type': 'issue',
    'jobCardId': selectedJobCard,
    'quantity': qty,
    'timestamp': FieldValue.serverTimestamp(),
  });

                  // 🔹 Update stock item
                await _firestore.collection('stock_items').doc(item['docId']).update({
    'current': currentStock - qty,
    'issue': (item['issue'] ?? 0) + qty,
    'dateEdit': DateFormat('dd-MM-yyyy').format(DateTime.now()),
    'updatedAt': FieldValue.serverTimestamp(),
  });

                  // 🔹 Update jobCard dispatch log
                final jobDoc = _firestore.collection('jobCards').doc(selectedJobCard);
  final jobSnap = await jobDoc.get();
  if (jobSnap.exists) {
    final jobData = jobSnap.data() as Map<String, dynamic>;
    final totalQty = int.tryParse(jobData['quantity']?.toString() ?? '0') ?? 0;
    final issuedQty = int.tryParse(jobData['issuedQuantity']?.toString() ?? '0') ?? 0;
    final newIssued = issuedQty + qty;
    final newStatus = newIssued >= totalQty ? "Completed" : "Partially Issued";

    await jobDoc.update({
      'issuedQuantity': newIssued,
      'status': newStatus,
      'dispatchLog': FieldValue.arrayUnion([
        {
          'department': 'Store',
          'issuedQty': qty,
          'time': DateTime.now(),
          'itemName': item['name'],
        }
      ]),
    });
  }
  final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final dailyRef = _firestore
      .collection('stock_daily_history')
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
      'itemName': item['name'],
      'totalIssued': qty,
      'date': todayKey,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

                  await _loadDataFromFirebase();
                  Navigator.pop(ctx);
                  _showSnackBar("Issued $qty units to Job successfully!");
                } catch (e) {
                  _showSnackBar("Error issuing stock: $e", isError: true);
                }
              },
              child: Text("Issue Now"),
            ),
          ],
        );
      },
    ),
  );
}



void _showItemHistoryBelowDialog(Map<String, dynamic> item) {
  showDialog(
    context: context,
    builder: (ctx) => FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('stock_transactions')
          .where('itemId', isEqualTo: item['docId'])
          .where('type', isEqualTo: 'issue')
          .orderBy('timestamp', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.history, color: Colors.orange[700]),
                SizedBox(width: 8),
                Text("Issue History", style: TextStyle(color: Colors.orange[700])),
              ],
            ),
            content: Text("No previous issues found."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close")),
            ],
          );
        }

        final docs = snapshot.data!.docs;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.history, color: Colors.orange[700]),
              SizedBox(width: 8),
              Text("${item['name']} Issue History", style: TextStyle(color: Colors.orange[700])),
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
                final remaining = data['remaining'] ?? '-';
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                final dateStr = timestamp != null
                    ? DateFormat('dd-MM-yyyy hh:mm a').format(timestamp)
                    : '';

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.arrow_upward, color: Colors.red[700]),
                    title: Text("Issued $qty → $dept", style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600)),
                    subtitle: Text("Remaining: $remaining | $dateStr", style: TextStyle(fontSize: 12)),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close", style: TextStyle(color: Colors.orange[700])),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Add Additional Stock", style: TextStyle(color: Colors.green[700])),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TEXT FIELD FOR PARTY NAME
              TextField(
                controller: partyCtrl,
                decoration: InputDecoration(
                  labelText: "Second Party Name",
                  hintText: "Enter party name (e.g., Vendor A)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.person, color: Colors.green[700]),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.add_box, color: Colors.green[700]),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
              onPressed: partyCtrl.text.trim().isEmpty || qtyCtrl.text.isEmpty
                  ? null
                  : () async {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) {
                        _showSnackBar("Enter valid quantity", isError: true);
                        return;
                      }
                      final newStock = (item['current'] ?? 0) + qty;

                      await _firestore.collection('stock_transactions').add({
                        'itemId': item['docId'],
                        'type': 'received',
                        'party': partyCtrl.text.trim(),
                        'quantity': qty,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      await _firestore.collection('stock_items').doc(item['docId']).update({
                        'current': newStock,
                        'received': (item['received'] ?? 0) + qty,
                        'dateEdit': DateFormat('dd-MM-yyyy').format(DateTime.now()),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      await _loadDataFromFirebase();
                      _showSnackBar("Received $qty from ${partyCtrl.text.trim()}");
                      Navigator.pop(ctx);
                    },
              child: Text("Continue Received"),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Update Stock", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[700])),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _issueStockWithDepartment(item);
                  },
                  icon: Icon(Icons.remove_circle, color: Colors.white),
                  label: Text("Issue Stock"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _addAdditionalWithParty(item);
                  },
                  icon: Icon(Icons.add_box, color: Colors.white),
                  label: Text("Add Additional"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<double> _calculateAverageStock(String itemId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final snapshot = await _firestore
          .collection('stock_transactions')
          .where('itemId', isEqualTo: itemId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('timestamp')
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final itemDoc = await _firestore.collection('stock_items').doc(itemId).get();
      int currentStock = itemDoc.exists ? (itemDoc['current'] ?? 0) : 0;

      Map<String, int> dailyStock = {};
      DateTime? lastDate;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
        final qty = data['quantity'] as int;
        final type = data['type'];

        if (lastDate != null) {
          var fillDate = lastDate.add(Duration(days: 1));
          while (fillDate.isBefore(timestamp)) {
            final fillKey = DateFormat('yyyy-MM-dd').format(fillDate);
            dailyStock[fillKey] = currentStock;
            fillDate = fillDate.add(Duration(days: 1));
          }
        }

        if (type == 'issue') currentStock -= qty;
        if (type == 'received') currentStock += qty;

        dailyStock[dateKey] = currentStock;
        lastDate = timestamp;
      }

      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      dailyStock[todayKey] = dailyStock[todayKey] ?? currentStock;

      if (dailyStock.isEmpty) return 0.0;
      final total = dailyStock.values.reduce((a, b) => a + b);
      return total / dailyStock.length;
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
            SizedBox(width: 8),
            Text("1-Month Average", style: TextStyle(color: Colors.purple[700])),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Item: ${item['name']}", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Code: ${item['code']}"),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text("Average Stock (30 Days)", style: TextStyle(fontSize: 12, color: Colors.purple[700])),
                  SizedBox(height: 4),
                  Text(
                    avg.toStringAsFixed(2),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                  ),
                  Text("units", style: TextStyle(fontSize: 12, color: Colors.purple[600])),
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
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    final itemSnapshot = await _firestore.collection('stock_items').get();
    final transSnapshot = await _firestore
        .collection('stock_transactions')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    Map<String, List<Map<String, dynamic>>> groupItems = {};
    for (var doc in itemSnapshot.docs) {
      final data = doc.data();
      final group = data['group'] ?? 'Unknown';
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
        int currentStock = item['current'] ?? 0;

        final itemTrans = transSnapshot.docs
            .where((t) => t['itemId'] == itemId)
            .toList()
          ..sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));

        DateTime? lastDate;
        for (var trans in itemTrans) {
          final timestamp = (trans['timestamp'] as Timestamp).toDate();
          final qty = trans['quantity'] as int;
          final type = trans['type'];

          if (lastDate != null) {
            var fillDate = lastDate.add(Duration(days: 1));
            while (fillDate.isBefore(timestamp)) {
              totalStockDays += currentStock;
              totalDays++;
              fillDate = fillDate.add(Duration(days: 1));
            }
          }

          if (type == 'issue') currentStock -= qty;
          if (type == 'received') currentStock += qty;

          totalStockDays += currentStock;
          totalDays++;
          lastDate = timestamp;
        }

        totalStockDays += currentStock;
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
            SizedBox(width: 8),
            Text("Group-wise 30-Day Average", style: TextStyle(color: Colors.purple[700])),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 60.h),
          child: groupAverages.isEmpty
              ? Center(child: Text("No data in last 30 days"))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: groupAverages.length,
                  itemBuilder: (context, i) {
                    final group = groupAverages.keys.elementAt(i);
                    final avg = groupAverages[group]!;
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple[100],
                          child: Text(group[0], style: TextStyle(color: Colors.purple[900])),
                        ),
                        title: Text(group, style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text(
                          avg.toStringAsFixed(2),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple[900]),
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

  void _addOrUpdateItem({Map<String, dynamic>? existingItem}) async {
    final isEdit = existingItem != null;
    final codeCtrl = TextEditingController(text: isEdit ? existingItem["code"] : '');
    final nameCtrl = TextEditingController(text: isEdit ? existingItem["name"] : '');
    final groupCtrl = TextEditingController(text: isEdit ? existingItem["group"] : '');
    final oldCtrl = TextEditingController(text: isEdit ? existingItem["old"].toString() : '0');
    final receivedCtrl = TextEditingController(text: isEdit ? existingItem["received"].toString() : '0');
    final issueCtrl = TextEditingController(text: isEdit ? existingItem["issue"].toString() : '0');
    final currentCtrl = TextEditingController(text: isEdit ? existingItem["current"].toString() : '0');
    final movingCtrl = TextEditingController(text: isEdit ? existingItem["moving"] : 'FAST MOVING');
    final locatedCtrl = TextEditingController(text: isEdit ? (existingItem["located"] ?? '') : '');

    String? imageUrl = isEdit ? existingItem["image"] : null;
    XFile? selectedImage;
    bool isUploading = false;

    int nextSr = isEdit ? existingItem["sr"] : await _getNextSrNumber();
    final String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

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
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.orange[700]!, Colors.orange[500]!]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(isEdit ? Icons.edit : Icons.add_circle, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(isEdit ? "Edit Stock Item" : "Add New Stock Item",
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
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                                child: selectedImage != null
                                    ? FutureBuilder<Uint8List>(
                                        future: selectedImage!.readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(snapshot.data!, fit: BoxFit.cover));
                                          }
                                          return Center(child: CircularProgressIndicator());
                                        },
                                      )
                                    : imageUrl != null && imageUrl!.isNotEmpty
                                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(imageUrl!, fit: BoxFit.cover))
                                        : Icon(Icons.image, size: 60, color: Colors.grey[400]),
                              ),
                              SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: isUploading ? null : () async {
                                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) setDialogState(() => selectedImage = image);
                                },
                                icon: Icon(Icons.upload_file, size: 18),
                                label: Text(selectedImage != null ? "Change Image" : "Upload Image"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        _buildModernField(codeCtrl, "Item Code", Icons.qr_code, required: true),
                        SizedBox(height: 16),
                        _buildModernField(nameCtrl, "Item Name", Icons.inventory, required: true),
                        SizedBox(height: 16),
                        _buildModernField(groupCtrl, "Group/Category", Icons.category, required: true),
                        SizedBox(height: 24),
                        Text("Stock Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                        SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _buildModernField(currentCtrl, "Stock in Hand", Icons.inventory_2, isNumber: true)),
                          SizedBox(width: 12),
                          Expanded(child: _buildModernField(receivedCtrl, "Received (if any)", Icons.add_box, isNumber: true)),
                        ]),
                        SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _buildModernField(issueCtrl, "Issue (if any)", Icons.remove_circle, isNumber: true)),
                          SizedBox(width: 12),
                          Expanded(child: _buildModernField(locatedCtrl, "Stock Located", Icons.location_on, isNumber: false)),
                        ]),
                        SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.orange[700]),
                                  SizedBox(width: 12),
                                  Text("Date Edit: $currentDate", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange[900])),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: movingCtrl.text.isEmpty ? "FAST MOVING" : movingCtrl.text,
                              decoration: InputDecoration(
                                labelText: "Moving Status",
                                prefixIcon: Icon(Icons.trending_up, color: Colors.orange[700]),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.orange[50],
                              ),
                              items: ["FAST MOVING", "SLOW MOVING", "NON MOVING", "NEW", "NEW JAR", "ON ORDER"]
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setDialogState(() => movingCtrl.text = v!),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(fontSize: 16))),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600], foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: isUploading ? null : () async {
                          final code = codeCtrl.text.trim();
                          final name = nameCtrl.text.trim();
                          final group = groupCtrl.text.trim();
                          if (code.isEmpty || name.isEmpty || group.isEmpty) {
                            _showSnackBar("Please fill all required fields", isError: true);
                            return;
                          }
                          setDialogState(() => isUploading = true);
                          if (selectedImage != null) imageUrl = await _uploadImage(selectedImage!);
                          final old = int.tryParse(oldCtrl.text) ?? 0;
                          final received = int.tryParse(receivedCtrl.text) ?? 0;
                          final issue = int.tryParse(issueCtrl.text) ?? 0;
                          final current = int.tryParse(currentCtrl.text) ?? 0;

                          final newItem = {
                            "sr": nextSr,
                            "code": code,
                            "image": imageUrl ?? "",
                            "name": name,
                            "group": group,
                            "old": old,
                            "received": received,
                            "issue": issue,
                            "current": current,
                            "moving": movingCtrl.text.trim(),
                            "located": locatedCtrl.text.trim(),
                            "dateEdit": currentDate,
                            "updatedAt": FieldValue.serverTimestamp(),
                          };

                          try {
                            if (isEdit) {
                              await _firestore.collection('stock_items').doc(existingItem["docId"]).update(newItem);
                              _showSnackBar("Item updated successfully");
                            } else {
                              newItem["createdAt"] = FieldValue.serverTimestamp();
                              await _firestore.collection('stock_items').add(newItem);
                              _showSnackBar("Item added successfully!");
                            }
                            await _loadDataFromFirebase();
                            Navigator.pop(ctx);
                          } catch (e) {
                            _showSnackBar("Error saving item: $e", isError: true);
                          } finally {
                            setDialogState(() => isUploading = false);
                          }
                        },
                        icon: isUploading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(isEdit ? Icons.check : Icons.add),
                        label: Text(isEdit ? "Update Item" : "Add Item", style: TextStyle(fontSize: 16)),
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
      var headerRow = rows[0].map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '').toList();
      bool hasRequired = ['code', 'name', 'group'].every((h) => headerRow.contains(h));
      if (!hasRequired) {
        _showSnackBar("Missing required columns: code, name, group", isError: true);
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
            case 'sr': case 'old': case 'received': case 'issue': case 'current':
              item[header] = int.tryParse(value.toString()) ?? 0; break;
            case 'code': case 'name': case 'group': case 'moving': case 'image': case 'located':
              item[header] = value.toString().trim(); break;
          }
        }
        if (item['code'] == null || item['name'] == null || item['group'] == null) continue;
        int old = item['old'] ?? 0;
        int received = item['received'] ?? 0;
        item['issue'] = item['issue'] ?? 0;
        item['current'] = item['current'] ?? (old + received);
        item['moving'] = (item['moving'] ?? 'FAST MOVING').toString().toUpperCase();
        item['image'] = item['image'] ?? '';
        item['located'] = item['located'] ?? '';
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
        var existingQuery = await _firestore.collection('stock_items').where('code', isEqualTo: item['code']).limit(1).get();
        if (existingQuery.docs.isNotEmpty) {
          var docRef = existingQuery.docs.first.reference;
          batch.update(docRef, {...item, 'updatedAt': FieldValue.serverTimestamp()});
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
      _showSnackBar("Excel imported successfully! ${importedItems.length} items processed.");
    } catch (e) {
      _showSnackBar("Import failed: $e", isError: true);
    }
    setState(() => _isLoading = false);
  }

  void _deleteItem(String docId, int sr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.warning_amber, color: Colors.red[700], size: 28), SizedBox(width: 12), Text("Delete Item?", style: TextStyle(color: Colors.red[700]))]),
        content: Text("This action cannot be undone. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _firestore.collection('stock_items').doc(docId).delete();
                await _renumberSrNumbers();
                await _loadDataFromFirebase();
                _showSnackBar("Item deleted & Sr No. updated");
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
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red[600] : Colors.green[600], behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool required = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label + (required ? " *" : ""),
        prefixIcon: Icon(icon, color: Colors.orange[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange[600]!, width: 2)),
        filled: true,
        fillColor: Colors.orange[50],
      ),
    );
  }

  Widget _header(String text, double width) => SizedBox(width: width, child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.visible, softWrap: true));

  Widget _cell(String text, double width, {Color? color, bool bold = false, double fontSize = 13}) => 
      SizedBox(width: width, child: Text(text, style: TextStyle(color: color ?? Colors.black87, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, fontSize: fontSize), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis));

  Widget _cellImage(String? url, double width) {
    if (url == null || url.isEmpty) return _placeholderImage(width);
    return SizedBox(
      width: width,
      child: Center(
        child: GestureDetector(
          onTap: () => _showImageZoom(url.trim()),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url.trim(), width: 55, height: 55, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _errorImage(width)),
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage(double width) => SizedBox(width: width, child: Center(child: Container(width: 55, height: 55, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: Icon(Icons.image, size: 28, color: Colors.grey[500]))));
  Widget _errorImage(double width) => SizedBox(width: width, child: Center(child: Container(width: 55, height: 55, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.broken_image, size: 24, color: Colors.red[400]), Text("Error", style: TextStyle(fontSize: 8, color: Colors.red[600]))]))));

  Widget _statusBadge(String status, double width) {
    Color bgColor;
    switch (status.toUpperCase()) {
      case "FAST MOVING": bgColor = Colors.green[600]!; break;
      case "SLOW MOVING": bgColor = Colors.orange[600]!; break;
      case "NON MOVING": bgColor = Colors.red[600]!; break;
      default: bgColor = Colors.grey[600]!;
    }
    return SizedBox(width: width, child: Center(child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)))));
  }

  Widget _actionButtons(Map<String, dynamic> item, double width) => SizedBox(
    width: width,
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(icon: Icon(Icons.edit, color: Colors.orange[700], size: 20), onPressed: () => _addOrUpdateItem(existingItem: item), tooltip: "Edit"),
      IconButton(icon: Icon(Icons.delete, color: Colors.red[700], size: 20), onPressed: () => _deleteItem(item["docId"] ?? '', item["sr"]), tooltip: "Delete"),
    ]),
  );

  Widget _updateButton(Map<String, dynamic> item, double width) => SizedBox(
    width: width,
    child: Center(
      child: ElevatedButton(
        onPressed: () => _showUpdateOptions(item),
        child: Text("Edit", style: TextStyle(fontSize: 12, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    ),
  );


void _showDailyIssueHistory() async {
  final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final dayRef = _firestore.collection('stock_daily_history').doc(todayKey).collection('items');

  showDialog(
    context: context,
    builder: (ctx) => StreamBuilder<QuerySnapshot>(
      stream: dayRef.orderBy('itemName').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text("Issued Today", style: TextStyle(color: Colors.deepOrange)),
            content: Text("No items issued today."),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close"))],
          );
        }

        final items = snapshot.data!.docs;

        return AlertDialog(
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.history, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text("Issued Today (${items.length})",
                  style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 60.h),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i].data() as Map<String, dynamic>;
                final itemId = items[i].id;

                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: Icon(Icons.inventory_2, color: Colors.deepOrange),
                  ),
                  title: Text(
                    item['itemName'] ?? '-',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: Text(
                    "${item['totalIssued'] ?? 0} pcs",
                    style: TextStyle(
                        color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: dayRef.doc(itemId).collection('transactions').orderBy('timestamp', descending: true).snapshots(),
                      builder: (context, txSnap) {
                        if (!txSnap.hasData || txSnap.data!.docs.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("No detailed records",
                                style: TextStyle(color: Colors.grey[600])),
                          );
                        }

                        return Column(
                          children: txSnap.data!.docs.map((t) {
                            final tx = t.data() as Map<String, dynamic>;
                            final time = (tx['timestamp'] as Timestamp?)?.toDate();
                            final dateStr = time != null
                                ? DateFormat('dd-MM-yyyy hh:mm a').format(time)
                                : '-';
                            return ListTile(
                              dense: true,
                              leading: Icon(Icons.arrow_right, color: Colors.orange),
                              title: Text(
                                "JobCard: ${tx['jobNo'] ?? '-'} (${tx['productName'] ?? ''})",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text("Issued on: $dateStr",
                                  style: TextStyle(fontSize: 12)),
                              trailing: Text(
                                "${tx['quantity']} pcs",
                                style: TextStyle(
                                    color: Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close", style: TextStyle(color: Colors.deepOrange)),
            ),
          ],
        );
      },
    ),
  );
}


Widget _responsiveTable() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: BouncingScrollPhysics(),
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: BouncingScrollPhysics(),
      child: Container(
        width: 1500, // Increased width to fit all columns properly
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // 🔹 Table Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange[600]!, Colors.orange[400]!]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 3))
                ],
              ),
              child: Row(children: [
                      _header("Sr No.", 70),
                      _header("CODE", 100),
                      _header("ITEM PICTURES", 110),
                      _header("ITEM NAME", 160),
                      _header("GROUP", 110),
                      _header("STOCK LOCATED", 110),
                      _header("RECEIVED STOCK", 130),
                      _header("ISSUE STOCK", 110),
                      _header("STOCK IN HAND", 120),
                      _header("DATE EDIT", 90),
                      _header("MOVING ITEMS", 130),
                      _header("ACTIONS", 100),
                      _header("UPDATE", 100),
                    ]),
                  ),
                  SizedBox(height: 4),

                  // 🔹 Rows with collapsible history
                  ..._paginatedData.map((item) {
                    final itemId = item['docId'];
                    final bool isExpanded = item['isExpanded'] == true;

                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            item['isExpanded'] = !isExpanded;
                          }),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 4),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(children: [
                              _cell(item["sr"].toString(), 70),
                              _cell(item["code"], 100, bold: true),
                              _cellImage(item["image"], 110),
                              _cell(item["name"], 160, bold: true, color: Colors.blue[700]),
                              _cell(item["group"], 110),
                              _cell(item["located"] ?? "", 110),
                              _cell(item["received"].toString(), 130),
                              _cell(item["issue"].toString(), 110),
                              _cell(item["current"].toString(), 120,
                                  color: Colors.green[900], bold: true, fontSize: 16.sp),
                              _cell(item["dateEdit"]?.toString() ?? "", 90),
                              _statusBadge(item["moving"], 130),
                              _actionButtons(item, 100),
                              _updateButton(item, 100),
                            ]),
                          ),
                        ),

                        // 🔻 Expandable History Section
                        if (isExpanded)
                          Container(
                            margin: EdgeInsets.only(bottom: 8, left: 8, right: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('stock_transactions')
                                  .where('itemId', isEqualTo: itemId)
                                  .where('type', isEqualTo: 'issue')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(color: Colors.orange),
                                    ),
                                  );
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text("No issue history for this item.",
                                        style: TextStyle(color: Colors.grey[700])),
                                  );
                                }

                                final docs = snapshot.data!.docs;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.history, color: Colors.orange[700], size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          "Issue History (${docs.length})",
                                          style: TextStyle(
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: docs.length,
                                        itemBuilder: (context, i) {
                                          final data = docs[i].data() as Map<String, dynamic>;
                                          final qty = data['quantity'] ?? 0;
                                          final jobId = data['jobCardId'] ?? '-';
                                          final ts = (data['timestamp'] as Timestamp?)?.toDate();
                                          final dateStr = ts != null
                                              ? DateFormat('dd-MM-yyyy hh:mm a').format(ts)
                                              : '-';

                                          return ListTile(
                                            dense: true,
                                            leading: Icon(Icons.arrow_upward,
                                                color: Colors.red[600]),
                                            title: Text(
                                              "Issued $qty pcs",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red[700]),
                                            ),
                                            subtitle: Text(
                                              "Job Card: $jobId\n$dateStr",
                                              style: TextStyle(fontSize: 12),
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
                  }).toList(),
                ],
              ),
            ),
          ),
        );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 85,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xffb4d449), Color(0xffb4d449)]))),
        title: Row(children: [
          Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Image.asset('assets/1.jpg', height: 50, width: 50, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: Colors.blue[700], size: 36))),
          SizedBox(width: 16),
          Text("Store Stock Report", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
        ]),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showGroupWiseAverageDialog,
              icon: Icon(Icons.analytics, size: 18),
              label: Text("Group Avg", style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),Padding(
  padding: EdgeInsets.only(right: 16),
  child: ElevatedButton.icon(
    onPressed: _showDailyIssueHistory,
    icon: Icon(Icons.history, size: 18),
    label: Text("Daily Issue", style: TextStyle(fontSize: 12)),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepOrange,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))]),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(hintText: "Search by Code, Name or Group...", hintStyle: TextStyle(color: Colors.grey[400]), border: InputBorder.none, prefixIcon: Icon(Icons.search, color: Colors.orange[600], size: 24)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 8)]),
                      child: DropdownButton<String>(
                        value: _selectedGroup,
                        hint: Text("Filter Group"),
                        items: _groupList.map((g) => DropdownMenuItem(value: g, child: Text(g == 'All' ? 'All Groups' : g))).toList(),
                        onChanged: (v) {
                          setState(() => _selectedGroup = v!);
                          _applyFilters();
                        },
                        underline: SizedBox(),
                      ),
                    ),
                  ]),
                ),
                Expanded(child: _responsiveTable()),
                if (filteredData.isNotEmpty)
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(onPressed: _addOrUpdateItem, heroTag: "add_item", backgroundColor: Colors.orange[600], icon: Icon(Icons.add, color: Colors.white, size: 20), label: Text("Add Item", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600))),
          SizedBox(height: 0.5.h),
          FloatingActionButton.extended(onPressed: _uploadExcelFile, heroTag: "upload_excel", backgroundColor: Colors.green[600], icon: Icon(Icons.upload_file, color: Colors.white, size: 20), label: Text("Upload Excel", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}