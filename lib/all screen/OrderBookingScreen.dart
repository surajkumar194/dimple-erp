import 'dart:io';
import 'package:dimple_erp/all%20screen/historysalesorder.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

class OrderBookingScreen extends StatefulWidget {
  const OrderBookingScreen({super.key});
  @override
  State<OrderBookingScreen> createState() => _OrderBookingScreenState();
}
class _OrderBookingScreenState extends State<OrderBookingScreen> {
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
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
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _attachProductListeners(int index) {
    _products[index]['quantity']!.addListener(() {
      setState(() {});
    });

    _products[index]['price']!.addListener(() {
      setState(() {});
    });
  }

  bool _validateBasicDetails() {
    if (_customerNameController.text.trim().isEmpty) {
      _showError('Please enter customer name');
      return false;
    }

    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter location');
      return false;
    }

    if (_selectedUnit == null || _selectedUnit!.isEmpty) {
      _showError('Please select unit');
      return false;
    }

    if (_selectedSalesPerson == null || _selectedSalesPerson!.isEmpty) {
      _showError('Please select sales person');
      return false;
    }

    if (_selectedSalesPerson == 'Others' &&
        (_customSalesPerson == null || _customSalesPerson!.trim().isEmpty)) {
      _showError('Please enter sales person name');
      return false;
    }

    return true;
  }

  bool _validateProducts() {
    for (int i = 0; i < _products.length; i++) {
      final item = _products[i];

      final category = item['category'];
      final name = item['name']?.text.trim() ?? '';
      final qty = int.tryParse(item['quantity']?.text ?? '') ?? 0;
      final price = double.tryParse(item['price']?.text ?? '') ?? 0;

      if (category == null || category.toString().isEmpty) {
        _showError('Select category for Product ${i + 1}');
        return false;
      }

      if (name.isEmpty) {
        _showError('Enter product name for Product ${i + 1}');
        return false;
      }

      if (qty <= 0) {
        _showError('Enter valid quantity for Product ${i + 1}');
        return false;
      }

      if (price <= 0) {
        _showError('Enter valid price for Product ${i + 1}');
        return false;
      }
    }
    return true;
  }

  double _advanceAmount = 0.0;
  double _deliveryCharges = 0.0;
  bool _showDeliveryCharges = false;

  final TextEditingController _advanceController = TextEditingController();
  final TextEditingController _deliveryController = TextEditingController();

  Future<List<Map<String, dynamic>>> _fetchCustomers(String query) async {
    if (query.length < 2) return [];

    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(25)
        .get();

    final Map<String, Map<String, dynamic>> uniqueCustomers = {};

    for (final doc in snap.docs) {
      final data = doc.data();
      final name = (data['customerName'] ?? '').toString();

      if (name.toLowerCase().contains(query.toLowerCase())) {
        uniqueCustomers[name] = {
          'customerName': data['customerName'],
          'companyName': data['companyName'],
          'phone': data['phone'],
          'email': data['email'],
          'location': data['location'],
          'gst': data['customerGstNumber'],
        };
      }
    }

    return uniqueCustomers.values.toList();
  }

  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();

  double _gstPercent = 5.0;
  final List<double> _gstOptions = [5.0, 12.0, 18.0];
  DateTime _selectedDate = DateTime.now();
  String _selectedPriority = 'Medium';
  String? _selectedSalesPerson;
  String? _customSalesPerson;
  final String _selectedProductCategory = 'MDF';
  final List<String> _productCategories =  ['MDF', 'Kappa Box', 'Packaging', 'Rigid Box (unit 2)', 'Others'];
  String? _selectedUnit;

  final List<String> _units = [
    'Unit 1',
    'Unit 2',
    'Meena Bazar',
    'College Road',
  ];
  double get _subTotal => _calculateTotalAmount();

  double get _taxableAmount => _subTotal;

  double get _gstAmount => _taxableAmount * _gstPercent / 100;
  double get _grossTotal => _subTotal + _gstAmount + _deliveryCharges;
  double get _finalTotal =>
      (_grossTotal - _advanceAmount).clamp(0, double.infinity);

String generateProductCode(int index) {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  String code = '';
  int i = index;

  while (i >= 0) {
    code = letters[i % 26] + code;
    i = (i ~/ 26) - 1;
  }
  return code;
}

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _otherSalesPersonController =
      TextEditingController();
  final List<String> _salesPersons = [
    "Abhijit Sinha",
    "Komal Sir",
    "Ajay Talwar",
    "Amarjit Singh",
    "Ashish",
    "Harjap ji",
    "Gunnet Singh",
    "Hardeep Singh",
    "Jagdish Suri",
    "Karan",
    "Krishna Arora",
    "Kuldeep Singh",
    "Neeraj Batta",
    "Prabhu Dayal",
    "Rajiv Markanda",
    "Raju",
    "Sanjeev Jain",
    "Sumeet narula",
    "Sunny Kalra",
    "Others",
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'code': 'A',
      'category': 'MDF',
      'name': TextEditingController(),
      'quantity': TextEditingController(),
      'price': TextEditingController(),
      'remarks': TextEditingController(),
      'images': <XFile>[],
      'fetchedImages': <String>[],
      'autoFilled': false,
      'userEdited': false,
    },
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _attachProductListeners(0);
  }

  Future<void> _pickProductImages(int index) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF5F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Add Product Image',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              title: const Text(
                'Pick from Gallery',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: const Text('Choose multiple images'),
              onTap: () async {
                Navigator.pop(ctx);
                final files = await _picker.pickMultiImage(imageQuality: 85);
                if (files.isNotEmpty) {
                  setState(() {
                    _products[index]['images'].addAll(files);
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade700],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              title: const Text(
                'Use Camera',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (file != null) {
                  setState(() {
                    _products[index]['images'].add(file);
                  });
                }
              },
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  void _showAdvanceDialog() {
    _advanceController.text = _advanceAmount > 0
        ? _advanceAmount.toString()
        : '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.payment_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Enter Advance Amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          controller: _advanceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: 'Enter advance amount',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _advanceAmount = double.tryParse(_advanceController.text) ?? 0;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> migrateOldOrdersToDPL() async {
    final firestore = FirebaseFirestore.instance;

    final snapshot = await firestore
        .collection('orders')
        .orderBy('createdAt')
        .get();

    int counter = 1;
    final batch = firestore.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data['salesOrderNo'] != null &&
          data['salesOrderNo'].toString().startsWith('DPL')) {
        continue;
      }

      final dplNo = 'DPL$counter';

      batch.update(doc.reference, {'salesOrderNo': dplNo, 'orderId': dplNo});

      counter++;
    }

    await batch.commit();

    await firestore.collection('meta').doc('salesOrderCounter').set({
      'last': counter - 1,
    }, SetOptions(merge: true));

    debugPrint('✅ Old orders migrated successfully');
  }

  Future<String?> _uploadImageToStorage(
    XFile imageFile,
    String productName,
  ) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'order_products/$productName/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(imageFile.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("❌ Image upload failed: $e");
      return null;
    }
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var item in _products) {
      final qty = double.tryParse(item['quantity']!.text) ?? 0;
      final price = double.tryParse(item['price']!.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  Future<void> _submitOrder() async {
    if (!_validateBasicDetails()) return;

    if (!_validateProducts()) return;

    if (!_formKey.currentState!.validate()) return;
    final subTotal = _subTotal;
    final gstAmount = _gstAmount;
    final grandTotal = _finalTotal;

    if (_customerNameController.text.trim().isEmpty) {
      _showError('Customer name is required');
      return;
    }

    if (_selectedSalesPerson == null || _selectedSalesPerson!.trim().isEmpty) {
      _showError('Please select a sales person');
      return;
    }

    if (_selectedSalesPerson == 'Others' &&
        (_customSalesPerson == null || _customSalesPerson!.trim().isEmpty)) {
      _showError('Please enter sales person name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> productList = [];

      for (var item in _products) {
        List<String> imageUrls = [];
        for (var img in item['images']) {
          final url = await _uploadImageToStorage(img, item['name']!.text);
          if (url != null) imageUrls.add(url);
        }
        final qty = int.tryParse(item['quantity']!.text) ?? 0;
        final price = double.tryParse(item['price']!.text) ?? 0;
        final amount = qty * price;

        productList.add({
          'productCode': item['code'],
          'productCategory': item['category'],
          'productName': item['name']!.text,
          'quantity': qty,
          'price': price,
          'amount': amount,
          'remarks': item['remarks']!.text,
          'images': imageUrls,
        });
      }

      final counterRef = FirebaseFirestore.instance
          .collection('meta')
          .doc('salesOrderCounter');

      String salesOrderNo = '';

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        final last = (snap.data()?['last'] ?? 0) as int;
        final next = last + 1;

        tx.set(counterRef, {'last': next}, SetOptions(merge: true));
        salesOrderNo = 'DPL$next';
      });

      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(salesOrderNo);

      await orderRef.set({
        'orderId': salesOrderNo,
        'salesOrderNo': salesOrderNo,
        'customerName': _customerNameController.text,
        'companyName': _companyNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'customerGstNumber': _gstNumberController.text,
        'location': _locationController.text,
        'productCategory': _selectedProductCategory,
        'unit': _selectedUnit,
        'salesPerson': _selectedSalesPerson == 'Others'
            ? _customSalesPerson
            : _selectedSalesPerson,
        'products': productList,
        'advanceAmount': _advanceAmount,
        'deliveryCharges': _deliveryCharges,
        'taxableAmount': _taxableAmount,
        'totalAmount': subTotal,
        'gstAmount': gstAmount,
        'grandTotal': grandTotal,
        'gstPercent': _gstPercent,
        'deliveryDate': _selectedDate,
        'priority': _selectedPriority,
        'notes': _notesController.text,
        'status': 'Pending',
        'orderDate': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '✅ Order booked successfully!',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 8,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }



void _addProduct() {
  setState(() {
    _products.add({
      'code': generateProductCode(_products.length), // ✅ UNLIMITED
      'category': 'MDF',
      'name': TextEditingController(),
      'quantity': TextEditingController(),
      'price': TextEditingController(),
      'remarks': TextEditingController(),
      'images': <XFile>[],
      'fetchedImages': <String>[],
      'autoFilled': false,
      'userEdited': false,
    });

    _attachProductListeners(_products.length - 1);
  });
}

  void _removeProduct(int index) {
    if (index == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'At least one product is required',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ),
      );
      return;
    }

    setState(() {
      _products[index]['name']!.dispose();
      _products[index]['quantity']!.dispose();
      _products[index]['price']!.dispose();
      _products[index]['remarks']!.dispose();

      _products.removeAt(index);

   for (int i = 0; i < _products.length; i++) {
  _products[i]['code'] = generateProductCode(i);
}
    });
  }

  void _removeProductImage(int productIndex, int imageIndex) {
    setState(() {
      _products[productIndex]['images'].removeAt(imageIndex);
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _gstNumberController.dispose();
    _otherSalesPersonController.dispose();
    _advanceController.dispose();
    _deliveryController.dispose();
    for (var item in _products) {
      item['name']!.dispose();
      item['quantity']!.dispose();
      item['price']!.dispose();
      item['remarks']!.dispose();
    }
    super.dispose();
  }

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
                  'New Sales Order',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Create and manage new sales orders',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    ),

    // 🔥 RIGHT SIDE HISTORY ICON
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderHistoryScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    ],
  ),
),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Customer Information Section
            _buildSection(
              title: 'Customer Information',
              icon: Icons.person_outline_rounded,
              gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
              children: [
                Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue value) async {
                    return await _fetchCustomers(value.text);
                  },
                  displayStringForOption: (option) =>
                      option['customerName'] ?? '',
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    controller.text = _customerNameController.text;
                    controller.addListener(() {
                      _customerNameController.text = controller.text;
                    });

                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Customer Name',
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.purple.shade600,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.purple.shade600,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Customer name is required';
                        }
                        return null;
                      },
                    );
                  },
                  onSelected: (customer) {
                    setState(() {
                      _customerNameController.text =
                          customer['customerName'] ?? '';
                      _companyNameController.text =
                          customer['companyName'] ?? '';
                      _phoneController.text = customer['phone'] ?? '';
                      _emailController.text = customer['email'] ?? '';
                      _locationController.text = customer['location'] ?? '';
                      _gstNumberController.text = customer['gst'] ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyNameController,
                  label: 'Company Name (Optional)',
                  icon: Icons.business_rounded,
                  iconColor: Colors.purple.shade600,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  icon: Icons.phone_rounded,
                  iconColor: Colors.purple.shade600,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  icon: Icons.email_rounded,
                  iconColor: Colors.purple.shade600,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.purple.shade600,
                  validator: (value) =>
                      value!.isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _gstNumberController,
                  label: 'Customer GST Number (Optional)',
                  icon: Icons.receipt_long_rounded,
                  iconColor: Colors.purple.shade600,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        value.length != 15) {
                      return 'GST number must be 15 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Order Location Section
            _buildSection(
              title: 'Order Location',
              icon: Icons.location_city_rounded,
              gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Select Unit',
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.factory_rounded,
                        color: Colors.orange.shade600,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.orange.shade600,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _units
                      .map(
                        (unit) => DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value == 'Select') {
                      return 'Please select a unit';
                    }
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sales Person Section
            _buildSection(
              title: 'Sales Person',
              icon: Icons.badge_rounded,
              gradientColors: [Colors.teal.shade400, Colors.teal.shade600],
              children: [
                DropdownButtonFormField<String>(
                  value: _salesPersons.contains(_selectedSalesPerson)
                      ? _selectedSalesPerson
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Select Sales Person',
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.person_pin_rounded,
                        color: Colors.teal.shade600,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.teal.shade600,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _salesPersons.map((person) {
                    return DropdownMenuItem<String>(
                      value: person,
                      child: Text(person),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSalesPerson = value;
                      _customSalesPerson = null;
                      _otherSalesPersonController.clear();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a sales person';
                    }
                    return null;
                  },
                ),
                if (_selectedSalesPerson == 'Others') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otherSalesPersonController,
                    decoration: InputDecoration(
                      labelText: 'Enter Sales Person Name',
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.edit_rounded,
                          color: Colors.teal.shade600,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.teal.shade600,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) {
                      _customSalesPerson = val.trim();
                    },
                    validator: (val) {
                      if (_selectedSalesPerson == 'Others' &&
                          (val == null || val.trim().isEmpty)) {
                        return 'Sales person name is required';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Products Section
            _buildSection(
              title: 'Products',
              icon: Icons.inventory_2_rounded,
              gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
              children: [
                ...List.generate(_products.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.blue.shade50.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.blue.shade100, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade700,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _products[index]['code'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Product ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            if (_products.length > 1)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_rounded,
                                    color: Colors.red.shade600,
                                    size: 24,
                                  ),
                                  onPressed: () => _removeProduct(index),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _products[index]['category'],
                          decoration: InputDecoration(
                            labelText: 'Product Category',
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.category_rounded,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.blue.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: _productCategories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _products[index]['category'] = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        Autocomplete<Map<String, dynamic>>(
                          optionsBuilder: (TextEditingValue value) async {
                            if (value.text.length < 2) return const [];

                            final snap = await FirebaseFirestore.instance
                                .collection('orders')
                                .orderBy('createdAt', descending: true)
                                .limit(500)
                                .get();

                            final List<Map<String, dynamic>> results = [];

                            for (final doc in snap.docs) {
                              final products = doc['products'];
                              if (products is List) {
                                for (final p in products) {
                                  if (p['productName']
                                      .toString()
                                      .toLowerCase()
                                      .contains(value.text.toLowerCase())) {
                                    results.add(Map<String, dynamic>.from(p));
                                  }
                                }
                              }
                            }
                            return results;
                          },
                          displayStringForOption: (option) =>
                              option['productName'],
                          fieldViewBuilder:
                              (context, controller, focusNode, onSubmit) {
                                _products[index]['name'] = controller;

                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Product Name',
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.shopping_bag_rounded,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade600,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Product name required'
                                      : null,
                                );
                              },
                          onSelected: (data) {
                            setState(() {
                              _products[index]['price']!.text =
                                  (data['price'] ?? 0).toString();
                              _products[index]['quantity']!.text =
                                  (data['quantity'] ?? 0).toString();
                              _products[index]['remarks']!.text =
                                  data['remarks'] ?? '';
                              _products[index]['fetchedImages'] =
                                  List<String>.from(data['images'] ?? []);
                              _products[index]['autoFilled'] = true;
                              _products[index]['userEdited'] = false;
                            });
                          },
                        ),

                        if (((_products[index]['fetchedImages'] ?? []) as List)
                            .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade50,
                                  Colors.green.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.image_rounded,
                                  color: Colors.green.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Saved Images',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(
                              ((_products[index]['fetchedImages'] ?? [])
                                      as List)
                                  .length,
                              (imgIndex) {
                                final imageUrl =
                                    ((_products[index]['fetchedImages'] ?? [])
                                            as List)[imgIndex]
                                        as String;

                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: InteractiveViewer(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.network(imageUrl),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.shade200,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.shade100,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                          image: DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.red.shade400,
                                                Colors.red.shade700,
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.shade200,
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                (_products[index]['fetchedImages']
                                                        as List)
                                                    .removeAt(imgIndex);
                                              });
                                            },
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _products[index]['quantity']!,
                                label: 'Quantity',
                                icon: Icons.numbers_rounded,
                                iconColor: Colors.blue.shade600,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onChanged: (_) {
                                  setState(() {
                                    _products[index]['userEdited'] = true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildTextField(
                                controller: _products[index]['price']!,
                                label: 'Price/Unit',
                                icon: Icons.currency_rupee_rounded,
                                iconColor: Colors.blue.shade600,
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    value!.isEmpty ? 'Required' : null,
                                onChanged: (_) {
                                  setState(() {
                                    _products[index]['userEdited'] = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _products[index]['remarks']!,
                          label: 'Remarks (Optional)',
                          icon: Icons.comment_rounded,
                          iconColor: Colors.blue.shade600,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          onPressed: () => _pickProductImages(index),
                          icon: const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 22,
                          ),
                          label: Text(
                            _products[index]['images'].isEmpty
                                ? 'Add Product Images'
                                : 'Add More Images',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade600,
                            side: BorderSide(
                              color: Colors.blue.shade600,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),

                        if (_products[index]['images'].isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(
                              _products[index]['images'].length,
                              (imgIndex) {
                                final image =
                                    _products[index]['images'][imgIndex];
                                return Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: InteractiveViewer(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: kIsWeb
                                                    ? Image.network(image.path)
                                                    : Image.file(
                                                        File(image.path),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade200,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.shade100,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                          image: DecorationImage(
                                            image: kIsWeb
                                                ? NetworkImage(image.path)
                                                : FileImage(File(image.path))
                                                      as ImageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red.shade400,
                                              Colors.red.shade700,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.shade200,
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          onPressed: () => _removeProductImage(
                                            index,
                                            imgIndex,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Builder(
                            builder: (context) {
                              final qty =
                                  double.tryParse(
                                    _products[index]['quantity']!.text,
                                  ) ??
                                  0;
                              final price =
                                  double.tryParse(
                                    _products[index]['price']!.text,
                                  ) ??
                                  0;
                              final total = qty * price;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade200,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Total: ₹${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add_circle_rounded, size: 24),
                  label: const Text(
                    'Add Another Product',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade600,
                    side: BorderSide(color: Colors.blue.shade600, width: 2.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Total Amount Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade300.withOpacity(0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SUBTOTAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '₹${_subTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // GST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'GST',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<double>(
                              value: _gstPercent,
                              underline: const SizedBox(),
                              isDense: true,
                              items: _gstOptions
                                  .map(
                                    (gst) => DropdownMenuItem(
                                      value: gst,
                                      child: Text('${gst.toInt()}%'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _gstPercent = v!),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${_gstAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // DELIVERY CHARGES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Delivery Charges',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showDeliveryCharges = !_showDeliveryCharges;
                                if (!_showDeliveryCharges) {
                                  _deliveryCharges = 0;
                                  _deliveryController.clear();
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _showDeliveryCharges
                                        ? Icons.remove_circle_rounded
                                        : Icons.add_circle_rounded,
                                    color: Colors.green.shade600,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _showDeliveryCharges ? 'Remove' : 'Add',
                                    style: TextStyle(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showDeliveryCharges)
                        SizedBox(
                          width: 130,
                          child: TextField(
                            controller: _deliveryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {
                                _deliveryCharges = double.tryParse(v) ?? 0;
                              });
                            },
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ADVANCE (DELIVERY KE NICHE)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Advance Paid',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_advanceAmount > 0) {
                                  _advanceAmount = 0;
                                  _advanceController.clear();
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _advanceAmount > 0
                                        ? Icons.remove_circle_rounded
                                        : Icons.add_circle_rounded,
                                    color: Colors.green.shade600,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _advanceAmount > 0 ? 'Remove' : 'Add',
                                    style: TextStyle(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 130,
                        child: TextField(
                          controller: _advanceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _advanceAmount = double.tryParse(v) ?? 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white, thickness: 2),
                  const SizedBox(height: 16),

                  // FINAL TOTAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${_finalTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Order Details Section
            _buildSection(
              title: 'Order Details',
              icon: Icons.receipt_long_rounded,
              gradientColors: [Colors.indigo.shade400, Colors.indigo.shade600],
              children: [
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.indigo.shade50.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.indigo.shade200,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade400,
                                Colors.indigo.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Planned Dispatch Date',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 20,
                          color: Colors.indigo.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priority Level',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ['Low', 'Medium', 'High', 'Urgent'].map((
                        priority,
                      ) {
                        final isSelected = _selectedPriority == priority;
                        Color priorityColor;
                        List<Color> gradientColors;
                        switch (priority) {
                          case 'Low':
                            priorityColor = Colors.green.shade600;
                            gradientColors = [
                              Colors.green.shade400,
                              Colors.green.shade700,
                            ];
                            break;
                          case 'Medium':
                            priorityColor = Colors.orange.shade600;
                            gradientColors = [
                              Colors.orange.shade400,
                              Colors.orange.shade700,
                            ];
                            break;
                          case 'High':
                            priorityColor = Colors.deepOrange.shade600;
                            gradientColors = [
                              Colors.deepOrange.shade400,
                              Colors.deepOrange.shade700,
                            ];
                            break;
                          case 'Urgent':
                            priorityColor = Colors.red.shade600;
                            gradientColors = [
                              Colors.red.shade400,
                              Colors.red.shade700,
                            ];
                            break;
                          default:
                            priorityColor = Colors.blue.shade600;
                            gradientColors = [
                              Colors.blue.shade400,
                              Colors.blue.shade700,
                            ];
                        }
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPriority = priority;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(colors: gradientColors)
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : priorityColor,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: priorityColor.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  color: isSelected
                                      ? Colors.white
                                      : priorityColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  priority,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : priorityColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _notesController,
                  label: 'Additional Notes (Optional)',
                  icon: Icons.note_rounded,
                  iconColor: Colors.indigo.shade600,
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit Button
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade300.withOpacity(0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 26),
                          const SizedBox(width: 12),
                          Text(
                            'Book Order',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required List<Color> gradientColors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        prefixIcon: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: iconColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}
