import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart';
import 'package:sizer/sizer.dart';

class IssueInventoryScreen extends StatefulWidget {
  const IssueInventoryScreen({super.key});

  @override
  State<IssueInventoryScreen> createState() => _IssueInventoryScreenState();
}

class _IssueInventoryScreenState extends State<IssueInventoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String? currentUserDept;
  bool isUserLoaded = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> jobCards = [];
  List<Map<String, dynamic>> filteredCards = [];
  final List<String> artSubSteps = ['Keyline', 'Design', 'Prepress'];

  final List<String> darkRoomSubSteps = ['Leaf Block', 'Screen Exposing'];

  final List<String> departments = [
    'Paper cutting instructions',
    'Mdf cutting instructions',
    'Art Department',
    'Material Required',
    'Dark Room',
    'Offset printing',
    'Digital printing',
    'Lamination',
    'Scodix',
    'Screen',
    'lesser',
    'Letter press/Die',
    'Binding',
    'Quality checking',
    'Dispatch',
  ];

  final Map<String, Color> departmentColors = {
    'Paper cutting instructions': const Color(0xFF8B4513), // Brown
    'Mdf cutting instructions': const Color(0xFF6D4C41), // Dark Brown
    'Art Department': const Color(0xFF1976D2), // Blue
    'Material Required': const Color(0xFF00796B), // Teal
    'Dark Room': const Color(0xFF424242), // Dark Grey
    'Offset printing': const Color(0xFFD32F2F), // Red
    'Digital printing': const Color(0xFFF57C00), // Orange
    'Lamination': const Color(0xFF0097A7), // Cyan
    'Scodix': const Color(0xFF7B1FA2), // Purple
    'Screen': const Color(0xFF455A64), // Blue Grey
    'lesser': const Color(0xFF9E9E9E), // Grey
    'Letter press /Die': const Color(0xFF5E35B1), // Deep Purple
    'Binding': const Color(0xFF388E3C), // Green
    'Quality checking': const Color(0xFFFBC02D), // Yellow
    'Dispatch': const Color(0xFF00695C), // Dark Teal
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUserDept(); // 🔥 YAHI SET HOTA HAI
    _loadJobCards();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserDept() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      currentUserDept = doc['department'];
    }

    setState(() {
      isUserLoaded = true;
    });
  }

  Widget _buildSubDepartmentTile({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> subSteps,
    required Map<String, dynamic> job,
    required String totalQty,
  }) {
    final subData = job['departmentTracking']?[title]?['subSteps'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        children: subSteps.map((step) {
          final stepData = subData[step] ?? {};

          return _buildDepartmentTile(
            index: subSteps.indexOf(step) + 1,
            deptName: '$title → $step',
            deptColor: color,
            isCompleted: stepData['completed'] ?? false,
            jobId: job['docId'],
            currentQty: stepData['quantity']?.toString() ?? '0',
            totalQty: totalQty,
            currentRemark: stepData['remark'] ?? '',
            lastDispatchedDept: '',
          );
        }).toList(),
      ),
    );
  }

  Future<void> _loadJobCards() async {
    setState(() => _isLoading = true);
    final snap = await _firestore
        .collection('jobCards')
        .orderBy('createdAt', descending: true)
        .get();

    jobCards = snap.docs.map((d) {
      final data = d.data();
      data['docId'] = d.id;
      return data;
    }).toList();

    _applyFilters();
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      filteredCards = jobCards.where((j) {
        return (j['jobNo'] ?? '').toString().toLowerCase().contains(q) ||
            (j['customer'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    });
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final jobNo = job['jobNo'] ?? '';
    final customer = job['customerName'] ?? job['customer'] ?? 'N/A';
    final salesPerson = job['salesPerson'] ?? 'N/A';
    //final size = job['size'] ?? 'N/A';

    final orderDate = job['createdAt'] is Timestamp
        ? DateFormat(
            'dd MMM yyyy',
          ).format((job['createdAt'] as Timestamp).toDate())
        : '-';

    final List<dynamic> products = job['products'] as List<dynamic>? ?? [];

    int totalQuantity = 0;
    for (var p in products) {
      final qty = p['quantity'] ?? '0';
      totalQuantity += int.tryParse(qty.toString()) ?? 0;
    }

    final Map<String, dynamic> departmentTracking =
        job['departmentTracking'] ?? {};
    final String lastDispatchedDept = job['lastDispatchedDept'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.blue.shade50]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(6),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Card: $jobNo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  Text(
                    'Customer: $customer',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowText('Sales Person', salesPerson),
              // _rowText('Size', size),
              _rowText('Total Quantity', '$totalQuantity pcs'),
              _rowText('Order Date', orderDate),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // ================= PRODUCTS =================
          if (products.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade50, Colors.blue.shade50],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Products (${products.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...products.asMap().entries.map((entry) {
                    final productIndex = entry.key;
                    final p = entry.value;

                    final productName = p['productName'] ?? 'N/A';
                    final qty = p['quantity']?.toString() ?? '0';
                    final images = p['images'] as List<dynamic>? ?? [];

                    final Map<String, dynamic> departmentTracking =
                        p['departmentTracking'] ?? {}; // 🔥 PRODUCT WISE

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Text(
                            '${productIndex + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        subtitle: Text(
                          'Quantity: $qty',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: images.isNotEmpty
                            ? Chip(
                                avatar: const Icon(
                                  Icons.image,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  images.length.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green,
                              )
                            : null,

                        /// 🔽 OPEN PRODUCT → SHOW DEPARTMENTS
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (images.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  SizedBox(
                                    height: 80, // 🔥 VERY IMPORTANT
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: images.length,
                                      itemBuilder: (context, imgIndex) {
                                        final imageUrl = images[imgIndex];

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.network(
                                              imageUrl,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.fill,
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                    if (progress == null)
                                                      return child;
                                                    return Container(
                                                      width: 60,
                                                      height: 60,
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.auto_graph,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Department Tracking',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                /// ===== DEPARTMENTS =====
                                ...departments.map((deptName) {
                                  // 🔹 ART / MATERIAL / DARK ROOM
                                  if (deptName == 'Art Department') {
                                    return _buildSubDepartmentTile(
                                      title: 'Art Department',
                                      icon: Icons.palette,
                                      color: Colors.blue,
                                      subSteps: artSubSteps,
                                      job: {
                                        'docId': job['docId'],
                                        'departmentTracking':
                                            departmentTracking,
                                      },
                                      totalQty: qty,
                                    );
                                  }

                                  if (deptName == 'Material Required') {
                                    final deptData =
                                        departmentTracking[deptName] ?? {};

                                    return _buildDepartmentTile(
                                      index: departments.indexOf(deptName) + 1,
                                      deptName: deptName,
                                      deptColor: Colors.teal,
                                      isCompleted:
                                          deptData['completed'] ?? false,
                                      jobId: job['docId'],
                                      currentQty:
                                          deptData['quantity']?.toString() ??
                                          '0',
                                      totalQty: qty,
                                      currentRemark: deptData['remark'] ?? '',
                                      lastDispatchedDept: '',
                                    );
                                  }

                                  if (deptName == 'Dark Room') {
                                    return _buildSubDepartmentTile(
                                      title: 'Dark Room',
                                      icon: Icons.dark_mode,
                                      color: Colors.grey,
                                      subSteps: darkRoomSubSteps,
                                      job: {
                                        'docId': job['docId'],
                                        'departmentTracking':
                                            departmentTracking,
                                      },
                                      totalQty: qty,
                                    );
                                  }

                                  // 🔹 NORMAL DEPARTMENTS
                                  final deptData =
                                      departmentTracking[deptName] ?? {};

                                  return _buildDepartmentTile(
                                    index: departments.indexOf(deptName) + 1,
                                    deptName: deptName,
                                    deptColor:
                                        departmentColors[deptName] ??
                                        Colors.grey,
                                    isCompleted: deptData['completed'] ?? false,
                                    jobId: job['docId'],
                                    currentQty:
                                        deptData['quantity']?.toString() ?? '0',
                                    totalQty: qty,
                                    currentRemark: deptData['remark'] ?? '',
                                    lastDispatchedDept: '',
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ================= BUTTONS =================
          Row(
            children: [
              // ====== GENERATE PDF ======
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.teal.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _generateAndDownloadPDF(context, job),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: const Text(
                      'Generate PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ====== MARK AS DISPATCH ======
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade600,
                        Colors.indigo.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: lastDispatchedDept == 'Dispatch'
                        ? () => _markAsDispatch(job['docId'])
                        : null,
                    icon: const Icon(Icons.local_shipping, color: Colors.white),
                    label: const Text(
                      'Mark as Dispatch',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentTile({
    required int index,
    required String deptName,
    required Color deptColor,
    required bool isCompleted,
    required String jobId,
    required String currentQty,
    required String totalQty,
    required String currentRemark,
    required String lastDispatchedDept,
  }) {
    // 🔥 YAHI PE SET HOTA HAI PERMISSION
    final bool canEdit =
        currentUserDept == deptName || currentUserDept == 'admin';

    return GestureDetector(
      onTap: canEdit
          ? () => _showDepartmentDialog(
              jobId,
              deptName,
              currentQty,
              totalQty,
              currentRemark,
            )
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '⛔ You are not allowed to edit this department',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
      child: Opacity(
        opacity: canEdit ? 1.0 : 0.4, // 🔥 GREY EFFECT
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCompleted ? deptColor.withOpacity(0.15) : Colors.white,
            border: Border.all(color: deptColor, width: isCompleted ? 2 : 1.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: deptColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [deptColor, deptColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    index.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deptName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: deptColor,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (currentRemark.isNotEmpty)
                      Text(
                        'Remark: $currentRemark',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    Text(
                      'Qty: $currentQty / $totalQty pcs',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDepartmentDialog(
    String jobId,
    String deptName,
    String currentQty,
    String totalQty,
    String currentRemark,
  ) {
    final qtyController = TextEditingController(text: currentQty);
    final remarkController = TextEditingController(text: currentRemark);
    bool isCompleted = false;

    int totalQtyInt = int.tryParse(totalQty) ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: departmentColors[deptName] ?? Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            deptName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Update Quantity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      int enteredQty = int.tryParse(value) ?? 0;
                      if (enteredQty > totalQtyInt) {
                        qtyController.text = totalQty;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Quantity cannot exceed $totalQty'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(totalQty.length),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter quantity (0 - $totalQty)',
                      prefixIcon: Icon(
                        Icons.production_quantity_limits,
                        color: departmentColors[deptName],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add Remark',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: remarkController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add any remarks or notes',
                      prefixIcon: const Icon(Icons.note, color: Colors.indigo),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mark as Completed?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: isCompleted,
                          onChanged: (val) {
                            setState(() => isCompleted = val ?? false);
                          },
                          activeColor:
                              departmentColors[deptName] ?? Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  departmentColors[deptName] ?? Colors.grey,
                  (departmentColors[deptName] ?? Colors.grey).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: (departmentColors[deptName] ?? Colors.grey)
                      .withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                int enteredQty = int.tryParse(qtyController.text) ?? 0;
                if (enteredQty > totalQtyInt) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Quantity cannot exceed $totalQty'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                _updateDepartment(
                  jobId,
                  deptName,
                  qtyController.text,
                  remarkController.text,
                  isCompleted,
                );
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDepartment(
    String jobId,
    String deptName,
    String quantity,
    String remark,
    bool isCompleted,
  ) async {
    try {
      Map<String, dynamic> updateData = {};

      // 🔹 SUB-DEPARTMENT CASE (Art → Keyline, Material → Rexin, Dark Room → Leaf Block)
      if (deptName.contains('→')) {
        final parts = deptName.split('→');
        final mainDept = parts[0].trim();
        final subStep = parts[1].trim();

        updateData = {
          'departmentTracking.$mainDept.subSteps.$subStep': {
            'completed': isCompleted,
            'quantity': quantity,
            'remark': remark,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'lastDispatchedDept': mainDept,
        };
      }
      // 🔹 NORMAL DEPARTMENT (same as before)
      else {
        updateData = {
          'departmentTracking.$deptName': {
            'completed': isCompleted,
            'quantity': quantity,
            'remark': remark,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'lastDispatchedDept': deptName,
        };
      }

      await _firestore.collection('jobCards').doc(jobId).update(updateData);

      _loadJobCards();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $deptName updated successfully'),
            backgroundColor: departmentColors[deptName] ?? Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAsDispatch(String jobId) async {
    try {
      await _firestore.collection('jobCards').doc(jobId).update({
        'dispatchedAt': FieldValue.serverTimestamp(),
        'status': 'Dispatched',
      });

      await _firestore.collection('dispatchedOrders').doc(jobId).set({
        'jobId': jobId,
        'dispatchedAt': FieldValue.serverTimestamp(),
        'data': jobCards.firstWhere((j) => j['docId'] == jobId),
      });

      _loadJobCards();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order marked as Dispatched successfully'),
            backgroundColor: Color(0xFF00695C),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _rowText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          '📦 Issue Inventory System',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 8,
        shadowColor: Colors.black45,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                hintText: 'Search Job No / Customer',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF1565C0),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF1565C0),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.indigo.shade600,
                        ),
                      ),
                    )
                  : filteredCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Job Cards Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCards.length,
                      itemBuilder: (_, i) => _buildJobCard(filteredCards[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndDownloadPDF(
    BuildContext context,
    Map<String, dynamic> job,
  ) async {
    final pdf = pw.Document();
    final List products = job['products'] ?? [];
    final Map<String, dynamic> departmentTracking =
        job['departmentTracking'] ?? {};

    Uint8List logoBytes;
    try {
      final data = await rootBundle.load('assets/logo.png');
      logoBytes = data.buffer.asUint8List();
    } catch (e) {
      logoBytes = Uint8List(0);
    }

    final logoImage = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

    final jobNo = job['jobNo'] ?? 'N/A';
    final date = job['createdAt'] is Timestamp
        ? (job['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    List<Map<String, dynamic>> productsWithImages = [];

    for (var product in products) {
      final images = product['images'] as List<dynamic>? ?? [];
      List<pw.MemoryImage> pdfImages = [];

      for (var imageUrl in images) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            pdfImages.add(pw.MemoryImage(response.bodyBytes));
          }
        } catch (_) {}
      }

      productsWithImages.add({
        'name': product['productName'] ?? 'N/A', // ✅ FIX
        'quantity': product['quantity'] ?? '0',
        'pdfImages': pdfImages,
      });
    }

    int totalQuantity = 0;
    for (var p in products) {
      totalQuantity += int.tryParse(p['quantity']?.toString() ?? '0') ?? 0;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 90,
                height: 90,
                child: logoImage != null
                    ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                    : null,
              ),
              pw.SizedBox(width: 16),
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
                  pw.SizedBox(height: 4),
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
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'PRODUCTION JOB CARD WITH DEPARTMENT TRACKING',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo400, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.indigo50,
            ),
            child: pw.Column(
              children: [
                _pdfRow('Job No', jobNo),
                _pdfRow('Order Date', '${date.day}/${date.month}/${date.year}'),
                _pdfRow('customerName', job['customerName'] ?? 'N/A'),

                _pdfRow('Sales Person', job['salesPerson'] ?? 'N/A'),
                _pdfRow('Size', job['size'] ?? 'N/A'),
                _pdfRow('Total Quantity', totalQuantity.toString()),
                _pdfRow('Status', job['status'] ?? 'In Progress'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          if (productsWithImages.isNotEmpty) ...[
            pw.Text(
              'PRODUCT DETAILS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FixedColumnWidth(35),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo300,
                  ),
                  children: [
                    _pdfCell('No', header: true),
                    _pdfCell('Product', header: true),
                    _pdfCell('Qty', header: true),
                    _pdfCell('Images', header: true),
                  ],
                ),
                ...productsWithImages.asMap().entries.map((e) {
                  final idx = e.key + 1;
                  final p = e.value;
                  final imgs = p['pdfImages'] as List<pw.MemoryImage>;

                  return pw.TableRow(
                    children: [
                      _pdfCell(idx.toString()),
                      _pdfCell(p['name']),
                      _pdfCell(p['quantity'].toString()),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: imgs.isNotEmpty
                            ? pw.Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: imgs
                                    .map(
                                      (img) => pw.Container(
                                        width: 45,
                                        height: 45,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(
                                            color: PdfColors.grey400,
                                          ),
                                        ),
                                        child: pw.Image(
                                          img,
                                          fit: pw.BoxFit.cover,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              )
                            : pw.Text(
                                'No Images',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600,
                                ),
                              ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'DEPARTMENT TRACKING STATUS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.orange200),
                children: [
                  _pdfCell('S.No', header: true),
                  _pdfCell('Department', header: true),
                  _pdfCell('Qty', header: true),
                  _pdfCell('Remark', header: true),
                ],
              ),
              ...departments.asMap().entries.map((e) {
                final idx = e.key + 1;
                final dept = e.value;
                final deptData = departmentTracking[dept] ?? {};
                final isCompleted = deptData['completed'] ?? false;
                final qty = deptData['quantity'] ?? '0';
                final remark = deptData['remark'] ?? '-';

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isCompleted ? PdfColors.green50 : PdfColors.grey100,
                  ),
                  children: [
                    _pdfCell(idx.toString()),
                    _pdfCell(dept),
                    _pdfCell(qty.toString()),
                    _pdfCell(remark),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Center(
            child: pw.Text(
              'All Rights Reserved Dimple Packaging Pvt. Ltd.',
            //  'Printed on ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 12.sp, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'JobCard_$jobNo.pdf',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Job Card PDF Generated Successfully'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: header ? 11 : 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
