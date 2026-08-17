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
      if (mounted) setState(() {});
    });
    _products[index]['price']!.addListener(() {
      if (mounted) setState(() {});
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


Future<List<Map<String, dynamic>>> _fetchProductSuggestions(String query) async {
  if (query.trim().length < 2) return [];
  final snap = await FirebaseFirestore.instance
      .collection('masterProducts')
      .orderBy('createdAt', descending: true)
      .limit(1500)
      .get();

  final Map<String, Map<String, dynamic>> unique = {};
  final q = query.toLowerCase();

  for (final doc in snap.docs) {
    final data = doc.data();
    final products = (data['products'] as List?) ?? [];
    for (final raw in products) {
      final p = Map<String, dynamic>.from(raw as Map);
      final name = (p['productName'] ?? '').toString();
      if (name.isNotEmpty && name.toLowerCase().contains(q)) {
        unique[name] = {
          'productName': p['productName'],
          'quantity': p['quantity'],
          'price': p['price'],
          'images': (p['images'] as List?) ?? [],
        };
      }
    }
  }
  return unique.values.toList();
}

  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedPriority = 'Medium';
  String? _selectedSalesPerson;
  String? _customSalesPerson;

  final List<String> _productCategories = [
    'MDF',
    'Kappa Box (Gora)',
    'Packaging',
    'Shagun Envelopes',
    'Rigid Box (unit 2 Hussainpura)',
    'Laddu Paper',
    'Others',
  ];

  String? _selectedUnit;
  String? _dispatchType;

  final List<String> _dispatchOptions = ['Transport', 'Vehicle'];
  final List<String> _units = [
    'Unit 1',
    'Unit 2',
    'Meena Bazar',
    'College Road',
  ];

  double _gstForCategory(String? category) {
    if (category == 'MDF') return 18.0;
    if (category == 'Laddu Paper') return 18.0;
    return 5.0;
  }

  String _hsnForCategory(String? category) {
    if (category == 'Laddu Paper') return '48062000';
    return '';
  }

  double _productSubTotal(Map<String, dynamic> item) {
    final qty = double.tryParse(item['quantity']?.text ?? '') ?? 0;
    final price = double.tryParse(item['price']?.text ?? '') ?? 0;
    return qty * price;
  }

  double _productGstAmount(Map<String, dynamic> item) {
    final gstPct =
        item['gstPercent'] as double? ?? _gstForCategory(item['category']);
    return _productSubTotal(item) * gstPct / 100;
  }

  double _productTotal(Map<String, dynamic> item) {
    return _productSubTotal(item) + _productGstAmount(item);
  }

  double get _subTotal {
    double t = 0;
    for (var item in _products) t += _productSubTotal(item);
    return t;
  }

  double get _totalGstAmount {
    double t = 0;
    for (var item in _products) t += _productGstAmount(item);
    return t;
  }

  double get _grossTotal => _subTotal + _totalGstAmount + _deliveryCharges;

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
  bool _isDesignerRequired = false;
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

  // ─── FIX: Unique ID add kiya har product mein (mixing fix ke liye) ───
  int _productIdCounter = 0;

  Map<String, dynamic> _createProduct() {
    _productIdCounter++;
    return {
      'id': _productIdCounter, // <-- UNIQUE ID - yahi key banega
      'code': generateProductCode(_products.length),
      'category': 'MDF',
      'gstPercent': 18.0,
      'hsnCode': '',
      'name': TextEditingController(),
      'quantity': TextEditingController(),
      'price': TextEditingController(),
      'remarks': TextEditingController(),
      'images': <XFile>[],
      'fetchedImages': <String>[],
      'autoFilled': false,
      'userEdited': false,
    };
  }

  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    // Pehla product add karo
    _products.add({
      'id': ++_productIdCounter,
      'code': 'A',
      'category': 'MDF',
      'gstPercent': 18.0,
      'hsnCode': '',
      'name': TextEditingController(),
      'quantity': TextEditingController(),
      'price': TextEditingController(),
      'remarks': TextEditingController(),
      'images': <XFile>[],
      'fetchedImages': <String>[],
      'autoFilled': false,
      'userEdited': false,
    });
    _attachProductListeners(0);
  }

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
      setState(() => _selectedDate = picked);
    }
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
                  setState(() => _products[index]['images'].addAll(files));
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
                  setState(() => _products[index]['images'].add(file));
                }
              },
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
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

  Future<void> _submitOrder() async {
    if (!_validateBasicDetails()) return;
    if (_dispatchType == null || _dispatchType!.isEmpty) {
      _showError('Please select dispatch type');
      return;
    }
    if (!_validateProducts()) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> productList = [];

      for (var item in _products) {
  List<String> imageUrls = List<String>.from(item['fetchedImages'] ?? []);  // ✅ FIX
        for (var img in item['images']) {
          final url = await _uploadImageToStorage(img, item['name']!.text);
          if (url != null) imageUrls.add(url);
        }
        final qty = int.tryParse(item['quantity']!.text) ?? 0;
        final price = double.tryParse(item['price']!.text) ?? 0;
        final gstPct = item['gstPercent'] as double;
        final subAmount = qty * price;
        final gstAmt = subAmount * gstPct / 100;
        final totalAmt = subAmount + gstAmt;

        productList.add({
          'productCode': item['code'],
          'productCategory': item['category'],
          'productName': item['name']!.text,
          'hsnCode': item['hsnCode'] ?? '',
          'quantity': qty,
          'price': price,
          'subAmount': subAmount,
          'gstPercent': gstPct,
          'gstAmount': gstAmt,
          'amount': totalAmt,
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
        'designerRequired': _isDesignerRequired,
        'companyName': _companyNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'customerGstNumber': _gstNumberController.text,
        'location': _locationController.text,
        'dispatchType': _dispatchType,
        'unit': _selectedUnit,
        'salesPerson': _selectedSalesPerson == 'Others'
            ? _customSalesPerson
            : _selectedSalesPerson,
        'products': productList,
        'advanceAmount': _advanceAmount,
        'deliveryCharges': _deliveryCharges,
        'subTotal': _subTotal,
        'totalGstAmount': _totalGstAmount,
        'grossTotal': _grossTotal,
        'grandTotal': _finalTotal,
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

  // ─── FIX: _createProduct() use karo ───
  void _addProduct() {
    setState(() {
      final newProduct = _createProduct();
      newProduct['code'] = generateProductCode(_products.length);
      _products.add(newProduct);
      _attachProductListeners(_products.length - 1);
    });
  }

  // ─── FIX: Delete ke baad sab codes reassign ───
  void _removeProduct(int index) {
    if (_products.length == 1) {
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
      // Controllers dispose karo
      _products[index]['name']!.dispose();
      _products[index]['quantity']!.dispose();
      _products[index]['price']!.dispose();
      _products[index]['remarks']!.dispose();
      _products.removeAt(index);
      // Codes reassign karo sab ke liye
      for (int i = 0; i < _products.length; i++) {
        _products[i]['code'] = generateProductCode(i);
      }
    });
  }

  void _removeProductImage(int productIndex, int imageIndex) {
    setState(() => _products[productIndex]['images'].removeAt(imageIndex));
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
          padding: const EdgeInsets.all(10),
          children: [
            // ── Customer Information ──────────────────────────────────────
            _buildSection(
              title: 'Customer Information',
              icon: Icons.person_outline_rounded,
              gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
              children: [
                Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue value) async =>
                      await _fetchCustomers(value.text),
                  displayStringForOption: (option) =>
                      option['customerName'] ?? '',
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    controller.text = _customerNameController.text;
                    controller.addListener(
                      () => _customerNameController.text = controller.text,
                    );
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
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Customer name is required'
                          : null,
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
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _companyNameController,
                  label: 'Company Name (Optional)',
                  icon: Icons.business_rounded,
                  iconColor: Colors.purple.shade600,
                ),
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  icon: Icons.phone_rounded,
                  iconColor: Colors.purple.shade600,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  icon: Icons.email_rounded,
                  iconColor: Colors.purple.shade600,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.purple.shade600,
                  validator: (value) =>
                      value!.isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 5),
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

            const SizedBox(height: 10),

            // ── Dispatch Type ────────────────────────────────────────────
            _buildSection(
              title: 'Dispatch Type',
              icon: Icons.local_shipping_rounded,
              gradientColors: [Colors.green.shade400, Colors.green.shade600],
              children: [
                DropdownButtonFormField<String>(
                  value: _dispatchOptions.contains(_dispatchType)
                      ? _dispatchType
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Select Dispatch Type',
                    prefixIcon: const Icon(Icons.local_shipping),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: _dispatchOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _dispatchType = val),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Please select dispatch type'
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Order Location ───────────────────────────────────────────
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
                  onChanged: (value) => setState(() => _selectedUnit = value!),
                  validator: (value) => (value == null || value == 'Select')
                      ? 'Please select a unit'
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Sales Person ─────────────────────────────────────────────
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
                  items: _salesPersons
                      .map(
                        (person) => DropdownMenuItem<String>(
                          value: person,
                          child: Text(person),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSalesPerson = value;
                      _customSalesPerson = null;
                      _otherSalesPersonController.clear();
                    });
                  },
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please select a sales person'
                      : null,
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
                    onChanged: (val) => _customSalesPerson = val.trim(),
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

            const SizedBox(height: 10),

            // ── Products ─────────────────────────────────────────────────
            _buildSection(
              title: 'Products',
              icon: Icons.inventory_2_rounded,
              gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
              children: [
                // ─── FIX: ObjectKey use karo unique id se ───
                ...List.generate(
                  _products.length,
                  (index) => KeyedSubtree(
                    key: ValueKey(_products[index]['id']),
                    child: _buildProductCard(index),
                  ),
                ),
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

            const SizedBox(height: 10),

            // ── Designer Required ────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _isDesignerRequired
                    ? LinearGradient(
                        colors: [Colors.purple.shade400, Colors.blue.shade500],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFEFD8D8), Color(0xFFEDBCBC)],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: _isDesignerRequired
                        ? Colors.purple.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    setState(() => _isDesignerRequired = !_isDesignerRequired),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.design_services_rounded,
                        color: _isDesignerRequired
                            ? Colors.white
                            : const Color(0xFFFA0101),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Designer Required",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isDesignerRequired
                                  ? Colors.white
                                  : const Color(0xFFF30202),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isDesignerRequired
                                ? "Design team will handle this order"
                                : "No design work needed",
                            style: TextStyle(
                              fontSize: 12,
                              color: _isDesignerRequired
                                  ? Colors.white70
                                  : const Color(0xFFF40303),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isDesignerRequired,
                      activeColor: Colors.white,
                      onChanged: (val) =>
                          setState(() => _isDesignerRequired = val),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Grand Total Summary ──────────────────────────────────────
            _buildGrandTotalCard(),

            const SizedBox(height: 10),

            // ── Order Details ────────────────────────────────────────────
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ['Low', 'Medium', 'High', 'Urgent'].map((
                        priority,
                      ) {
                        final isSelected = _selectedPriority == priority;
                        late Color priorityColor;
                        late List<Color> gradientColors;
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
                          onTap: () =>
                              setState(() => _selectedPriority = priority),
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
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _notesController,
                  label: 'Additional Notes (Optional)',
                  icon: Icons.note_rounded,
                  iconColor: Colors.indigo.shade600,
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ── Submit Button ────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCT CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductCard(int index) {
    final item = _products[index];
    final gstPct = item['gstPercent'] as double;
    final subAmt = _productSubTotal(item);
    final gstAmt = _productGstAmount(item);
    final totalAmt = _productTotal(item);
    final category = item['category'] as String? ?? '';
    final isMdf = category == 'MDF';
    final isLadduPaper = category == 'Laddu Paper';
    final isOthers = category == 'Others';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
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
          // ── Header row ───────────────────────────────────────────────
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
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
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
                      item['code'],
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

          // ── Category Dropdown ────────────────────────────────────────
          DropdownButtonFormField<String>(
            value: item['category'],
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
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _productCategories
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _products[index]['category'] = value;
                _products[index]['gstPercent'] = _gstForCategory(value);
                _products[index]['hsnCode'] = _hsnForCategory(value);
              });
            },
          ),

          // ── Others: custom HSN Code field + GST selector ─────────────
          if (isOthers) ...[
            const SizedBox(height: 10),
            TextFormField(
              initialValue: item['hsnCode'] ?? '',
              decoration: InputDecoration(
                labelText: 'HSN Code (Optional)',
                hintText: 'e.g. 48062000',
                prefixIcon: Container(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.tag_rounded, color: Colors.blue.shade600),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.text,
              onChanged: (val) =>
                  setState(() => _products[index]['hsnCode'] = val.trim()),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.percent_rounded,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Select GST Rate',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [5.0, 18.0].map((pct) {
                      final isActive = gstPct == pct;
                      final btnColor = pct == 18.0
                          ? Colors.orange.shade600
                          : Colors.blue.shade600;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _products[index]['gstPercent'] = pct,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? LinearGradient(
                                      colors: [
                                        btnColor.withOpacity(0.85),
                                        btnColor,
                                      ],
                                    )
                                  : null,
                              color: isActive ? null : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive ? Colors.transparent : btnColor,
                                width: 1.5,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: btnColor.withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${pct.toInt()}%',
                                style: TextStyle(
                                  color: isActive ? Colors.white : btnColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ─── FIX: Autocomplete hatao, direct TextFormField use karo ───
          // Yahi tha asli bug - Autocomplete ka internal controller
          // index shift pe sync nahi hota tha
        Autocomplete<Map<String, dynamic>>(
  optionsBuilder: (TextEditingValue value) async =>
      await _fetchProductSuggestions(value.text),
  displayStringForOption: (option) => option['productName'] ?? '',
  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
    if (controller.text != _products[index]['name']!.text) {
      controller.text = _products[index]['name']!.text;
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    }
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
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (val) {
        _products[index]['name']!.text = val;
        _products[index]['userEdited'] = true;
      },
      validator: (value) => (value == null || value.isEmpty)
          ? 'Product name required'
          : null,
    );
  },
  onSelected: (selected) {
    setState(() {
      _products[index]['name']!.text = selected['productName'] ?? '';

      if (selected['quantity'] != null) {
        _products[index]['quantity']!.text = selected['quantity'].toString();
      }
      if (selected['price'] != null) {
        _products[index]['price']!.text = selected['price'].toString();
      }
      _products[index]['fetchedImages'] =
          List<String>.from(selected['images'] ?? []);
      _products[index]['autoFilled'] = true;
    });
  },
),
          // ── Fetched Images ─────────────────────────────────────────────
          if (((_products[index]['fetchedImages'] ?? []) as List)
              .isNotEmpty) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
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
            const SizedBox(height: 5),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                ((_products[index]['fetchedImages'] ?? []) as List).length,
                (imgIndex) {
                  final imageUrl =
                      ((_products[index]['fetchedImages'] ?? [])
                              as List)[imgIndex]
                          as String;
                  return GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: InteractiveViewer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(imageUrl),
                          ),
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 2,
                            ),
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
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () => setState(
                                () =>
                                    (_products[index]['fetchedImages'] as List)
                                        .removeAt(imgIndex),
                              ),
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

          const SizedBox(height: 8),

          // ── Qty & Price ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _products[index]['quantity']!,
                  label: 'Quantity',
                  icon: Icons.numbers_rounded,
                  iconColor: Colors.blue.shade600,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                  onChanged: (_) =>
                      setState(() => _products[index]['userEdited'] = true),
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
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (_) =>
                      setState(() => _products[index]['userEdited'] = true),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildTextField(
            controller: _products[index]['remarks']!,
            label: 'Remarks (Optional)',
            icon: Icons.comment_rounded,
            iconColor: Colors.blue.shade600,
            maxLines: 2,
          ),

          const SizedBox(height: 8),

          // ── Add Images ────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _pickProductImages(index),
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 22),
            label: Text(
              _products[index]['images'].isEmpty
                  ? 'Add Product Images'
                  : 'Add More Images',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
              side: BorderSide(color: Colors.blue.shade600, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),

          // ── Picked Images ─────────────────────────────────────────────
          if (_products[index]['images'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_products[index]['images'].length, (
                imgIndex,
              ) {
                final image = _products[index]['images'][imgIndex];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: InteractiveViewer(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: kIsWeb
                                  ? Image.network(image.path)
                                  : Image.file(File(image.path)),
                            ),
                          ),
                        ),
                      ),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: kIsWeb
                                ? NetworkImage(image.path)
                                : FileImage(File(image.path)) as ImageProvider,
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
                            colors: [Colors.red.shade400, Colors.red.shade700],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => _removeProductImage(index, imgIndex),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],

          const SizedBox(height: 10),

          // ── Per-product GST breakdown card ────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: (isMdf || isLadduPaper)
                        ? [Colors.orange.shade400, Colors.orange.shade600]
                        : [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isMdf || isLadduPaper)
                          ? Colors.orange.shade200
                          : Colors.green.shade200,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Subtotal : ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${subAmt.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GST @ ${gstPct.toInt()}% : ',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${gstAmt.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white38, height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total : ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${totalAmt.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRAND TOTAL CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGrandTotalCard() {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Order Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white30),
          const SizedBox(height: 5),
          _summaryRow(
            'Subtotal (before GST)',
            '₹${_subTotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 1),
          _summaryRow('Total GST', '₹${_totalGstAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 2),

          // Delivery Charges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Delivery Charges',
                    style: TextStyle(
                      fontSize: 15,
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
                        horizontal: 10,
                        vertical: 2,
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
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showDeliveryCharges ? 'Remove' : 'Add',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
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
                  width: 120,
                  child: TextField(
                    controller: _deliveryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    onChanged: (v) => setState(
                      () => _deliveryCharges = double.tryParse(v) ?? 0,
                    ),
                  ),
                )
              else
                Text(
                  '₹${_deliveryCharges.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 5),

          // Advance Paid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Advance Paid',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      if (_advanceAmount > 0) {
                        setState(() {
                          _advanceAmount = 0;
                          _advanceController.clear();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
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
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _advanceAmount > 0 ? 'Remove' : 'Add',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _advanceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  onChanged: (v) =>
                      setState(() => _advanceAmount = double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white, thickness: 1.5),
          const SizedBox(height: 5),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${_finalTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool small = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: small ? Colors.white70 : Colors.white,
              fontSize: small ? 13 : 15,
              fontWeight: small ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: small ? Colors.white70 : Colors.white,
            fontSize: small ? 13 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
