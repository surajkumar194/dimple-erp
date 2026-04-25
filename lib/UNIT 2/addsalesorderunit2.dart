import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ─── Color Theme ────────────────────────────────────────────────────────────
class _AppColors {
  static const Color primary = Color(0xFF6A1B9A);
  static const Color primaryLight = Color(0xFF9C4DCC);
  static const Color primaryDark = Color(0xFF38006B);
  static const Color accent = Color(0xFFFF6D00);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color bg = Color(0xFFF3E5F5);
  static const Gradient headerGradient = LinearGradient(
    colors: [Color(0xFF6A1B9A), Color(0xFF9C4DCC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient cardGradient = LinearGradient(
    colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Unit2 Sales Order Screen (New Booking) ─────────────────────────────────
class Unit2SalesOrderScreen extends StatefulWidget {
  const Unit2SalesOrderScreen({super.key});

  @override
  State<Unit2SalesOrderScreen> createState() => _Unit2SalesOrderScreenState();
}

class _Unit2SalesOrderScreenState extends State<Unit2SalesOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _advanceController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _otherSalesPersonController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now();
  String _selectedPriority = 'Medium';
  String? _selectedSalesPerson;
  String? _customSalesPerson;
  double _advanceAmount = 0.0;
  double _deliveryCharges = 0.0;
  bool _showDeliveryCharges = false;
  double _gstPercent = 18.0;
  bool _isLoading = false;

  final List<double> _gstOptions = [5.0, 12.0, 18.0];
  final List<String> _productCategories = ['Rigid Box (unit 2)'];
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

  final List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _addProduct();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _generateCode(int index) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String code = '';
    int i = index;
    while (i >= 0) {
      code = letters[i % 26] + code;
      i = (i ~/ 26) - 1;
    }
    return code;
  }

  void _addProduct() {
    final p = {
      'code': _generateCode(_products.length),
      'category': 'Rigid Box (unit 2)',
      'name': TextEditingController(),
      'quantity': TextEditingController(),
      'price': TextEditingController(),
      'remarks': TextEditingController(),
      'length': TextEditingController(),
      'height': TextEditingController(),
      'width': TextEditingController(),
      'images': <XFile>[],
      'fetchedImages': <String>[],
      'sectionSelected': {
        'Tray': false,
        'Salophin': false,
        'Box Cover': false,
        'Inner': false,
        'Bottom': false,
        'Die': false,
        'Others': false,
      },
      'trayDetailController': TextEditingController(),
      'trayQtyController': TextEditingController(),
      'trayPriceController': TextEditingController(),
      'salophinDetailController': TextEditingController(),
      'salophinQtyController': TextEditingController(),
      'salophinPriceController': TextEditingController(),
      'boxCoverDetailController': TextEditingController(),
      'boxCoverQtyController': TextEditingController(),
      'boxCoverPriceController': TextEditingController(),
      'innerDetailController': TextEditingController(),
      'innerQtyController': TextEditingController(),
      'innerPriceController': TextEditingController(),
      'bottomDetailController': TextEditingController(),
      'bottomQtyController': TextEditingController(),
      'bottomPriceController': TextEditingController(),
      'dieDetailController': TextEditingController(),
      'dieQtyController': TextEditingController(),
      'diePriceController': TextEditingController(),
      'otherDetailController': TextEditingController(),
      'otherQtyController': TextEditingController(),
      'otherPriceController': TextEditingController(),
      'customExtraSections': <Map<String, TextEditingController>>[],
    };
    (p['quantity'] as TextEditingController).addListener(() {
      setState(() {});
    });

    (p['price'] as TextEditingController).addListener(() {
      setState(() {});
    });
    setState(() => _products.add(p));
  }

  void _removeProduct(int index) {
    if (index == 0) {
      _showSnack('At least one product is required', isError: false);
      return;
    }
    setState(() {
      _disposeProduct(_products[index]);
      _products.removeAt(index);
      for (int i = 0; i < _products.length; i++) {
        _products[i]['code'] = _generateCode(i);
      }
    });
  }

  void _disposeProduct(Map<String, dynamic> p) {
    for (final key in [
      'name',
      'quantity',
      'price',
      'remarks',
      'length',
      'height',
      'width',
      'trayDetailController',
      'trayQtyController',
      'trayPriceController',
      'salophinDetailController',
      'salophinQtyController',
      'salophinPriceController',
      'boxCoverDetailController',
      'boxCoverQtyController',
      'boxCoverPriceController',
      'innerDetailController',
      'innerQtyController',
      'innerPriceController',
      'bottomDetailController',
      'bottomQtyController',
      'bottomPriceController',
      'dieDetailController',
      'dieQtyController',
      'diePriceController',
      'otherDetailController',
      'otherQtyController',
      'otherPriceController',
    ]) {
      (p[key] as TextEditingController?)?.dispose();
    }
    for (final sec
        in (p['customExtraSections']
            as List<Map<String, TextEditingController>>)) {
      sec['title']?.dispose();
      sec['detail']?.dispose();
      sec['qty']?.dispose();
      sec['price']?.dispose();
    }
  }

  double get _subTotal {
    double total = 0;
    for (var p in _products) {
      total +=
          (double.tryParse(p['quantity'].text) ?? 0) *
          (double.tryParse(p['price'].text) ?? 0);
    }
    return total;
  }

  double get _gstAmount => _subTotal * _gstPercent / 100;
  double get _grossTotal => _subTotal + _gstAmount + _deliveryCharges;
  double get _finalTotal =>
      (_grossTotal - _advanceAmount).clamp(0, double.infinity);

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? _AppColors.error : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _validateBasicDetails() {
    if (_customerNameController.text.trim().isEmpty) {
      _showSnack('Please enter customer name');
      return false;
    }
    if (_locationController.text.trim().isEmpty) {
      _showSnack('Please enter location');
      return false;
    }
    if (_selectedSalesPerson == null || _selectedSalesPerson!.isEmpty) {
      _showSnack('Please select sales person');
      return false;
    }
    if (_selectedSalesPerson == 'Others' &&
        (_customSalesPerson == null || _customSalesPerson!.trim().isEmpty)) {
      _showSnack('Please enter sales person name');
      return false;
    }
    return true;
  }

  bool _validateProducts() {
    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];
      if ((p['name'] as TextEditingController).text.trim().isEmpty) {
        _showSnack('Enter product name for Product ${i + 1}');
        return false;
      }
      if ((int.tryParse((p['quantity'] as TextEditingController).text) ?? 0) <=
          0) {
        _showSnack('Enter valid quantity for Product ${i + 1}');
        return false;
      }
    }
    return true;
  }

  Future<String?> _uploadImage(XFile img, String productName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'unit2_order_products/$productName/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (kIsWeb) {
        await ref.putData(
          await img.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        await ref.putFile(File(img.path));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload failed: $e');
      return null;
    }
  }

  Future<void> _submitOrder() async {
    if (!_validateBasicDetails()) return;
    if (!_validateProducts()) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Generate order number from counter
      final counterRef = FirebaseFirestore.instance
          .collection('meta')
          .doc('unit2SalesOrderCounter');
      String orderNo = '';

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        final last = (snap.data()?['last'] ?? 0) as int;
        final next = last + 1;
        tx.set(counterRef, {'last': next}, SetOptions(merge: true));
        orderNo = 'U2-DPL$next';
      });

      // Build products list
      List<Map<String, dynamic>> productList = [];
      for (var p in _products) {
        List<String> imageUrls = [];
        for (var img in (p['images'] as List<XFile>)) {
          final url = await _uploadImage(
            img,
            (p['name'] as TextEditingController).text,
          );
          if (url != null) imageUrls.add(url);
        }

        final sectionSelected = p['sectionSelected'] as Map<String, bool>;
        final Map<String, dynamic> sections = {};
        void addSection(String key, String prefix) {
          if (sectionSelected[key] == true) {
            sections['${prefix}Detail'] =
                (p['${prefix}DetailController'] as TextEditingController).text
                    .trim();
            sections['${prefix}Qty'] =
                int.tryParse(
                  (p['${prefix}QtyController'] as TextEditingController).text
                      .trim(),
                ) ??
                0;
            sections['${prefix}Price'] =
                (p['${prefix}PriceController'] as TextEditingController).text
                    .trim();
          }
        }

        addSection('Tray', 'tray');
        addSection('Salophin', 'salophin');
        addSection('Box Cover', 'boxCover');
        addSection('Inner', 'inner');
        addSection('Bottom', 'bottom');
        addSection('Die', 'die');
        addSection('Others', 'other');

        final extraSections = <Map<String, dynamic>>[];
        for (final sec
            in (p['customExtraSections']
                as List<Map<String, TextEditingController>>)) {
          final title = sec['title']!.text.trim();
          if (title.isNotEmpty) {
            extraSections.add({
              'title': title,
              'detail': sec['detail']!.text.trim(),
              'qty': int.tryParse(sec['qty']!.text.trim()) ?? 0,
              'price': sec['price']!.text.trim(),
            });
          }
        }

        productList.add({
          'productCode': p['code'],
          'productCategory': p['category'],
          'productName': (p['name'] as TextEditingController).text.trim(),
          'quantity':
              int.tryParse((p['quantity'] as TextEditingController).text) ?? 0,
          'price':
              double.tryParse((p['price'] as TextEditingController).text) ?? 0,
          'amount':
              (double.tryParse((p['quantity'] as TextEditingController).text) ??
                  0) *
              (double.tryParse((p['price'] as TextEditingController).text) ??
                  0),
          'remarks': (p['remarks'] as TextEditingController).text.trim(),
          'length': (p['length'] as TextEditingController).text.trim(),
          'height': (p['height'] as TextEditingController).text.trim(),
          'width': (p['width'] as TextEditingController).text.trim(),
          'images': imageUrls,
          'sections': sections,
          'customExtraSections': extraSections,
        });
      }

      // ✅ Save ONLY to unit2JobCards collection
      await FirebaseFirestore.instance.collection('unit2JobCards').add({
        'orderId': orderNo,
        'salesOrderNo': orderNo,
        'customerName': _customerNameController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'customerGstNumber': _gstNumberController.text.trim(),
        'location': _locationController.text.trim(),
        'unit': 'Unit 2',
        'salesPerson': _selectedSalesPerson == 'Others'
            ? _customSalesPerson
            : _selectedSalesPerson,
        'products': productList,
        'advanceAmount': _advanceAmount,
        'deliveryCharges': _deliveryCharges,
        'taxableAmount': _subTotal,
        'totalAmount': _subTotal,
        'gstAmount': _gstAmount,
        'grandTotal': _finalTotal,
        'gstPercent': _gstPercent,
        'deliveryDate': Timestamp.fromDate(_selectedDate),
        'priority': _selectedPriority,
        'notes': _notesController.text.trim(),
        'status': 'Pending',
        'orderDate': Timestamp.fromDate(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Unit 2 Order booked successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages(int index) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Product Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: _AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Pick from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final files = await _picker.pickMultiImage(imageQuality: 85);
                if (files.isNotEmpty)
                  setState(
                    () => (_products[index]['images'] as List<XFile>).addAll(
                      files,
                    ),
                  );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Use Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (file != null)
                  setState(
                    () => (_products[index]['images'] as List<XFile>).add(file),
                  );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
                        'Unit 2 — New Sales Order',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'New Sales Order creation for Unit 2',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // appBar: AppBar(
      //   elevation: 0,
      //   flexibleSpace: Container(decoration: const BoxDecoration(gradient: _AppColors.headerGradient)),
      //   foregroundColor: Colors.white,
      //   centerTitle: true,
      //   title: const Text('Unit 2 — New Sales Order',
      //       style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.history_rounded, size: 26),
      //       tooltip: 'Order History',
      //       onPressed: () => Navigator.push(context,
      //           MaterialPageRoute(builder: (_) => const Unit2OrderHistoryScreen())),
      //     ),
      //     const SizedBox(width: 6),
      //   ],
      // ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              'Customer Information',
              Icons.person_outline_rounded,
              [_AppColors.primaryLight, _AppColors.primary],
              [
                _buildTF(
  _customerNameController,
  'Customer Name *',
  Icons.person_rounded,
  validator: (v) =>
      v == null || v.trim().isEmpty ? 'Customer name is required' : null,
),
               // _buildAutocompleteName(),
                const SizedBox(height: 14),
                _buildTF(
                  _companyNameController,
                  'Company Name (Optional)',
                  Icons.business_rounded,
                ),
                const SizedBox(height: 14),
                _buildTF(
                  _phoneController,
                  'Phone (Optional)',
                  Icons.phone_rounded,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _buildTF(
                  _emailController,
                  'Email (Optional)',
                  Icons.email_rounded,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildTF(
                  _locationController,
                  'Location *',
                  Icons.location_on_rounded,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _buildTF(
                  _gstNumberController,
                  'GST Number (Optional)',
                  Icons.receipt_long_rounded,
                  validator: (v) => v != null && v.isNotEmpty && v.length != 15
                      ? 'GST must be 15 chars'
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSection(
              'Sales Person',
              Icons.badge_rounded,
              [Colors.teal.shade400, Colors.teal.shade700],
              [
                DropdownButtonFormField<String>(
                  value: _salesPersons.contains(_selectedSalesPerson)
                      ? _selectedSalesPerson
                      : null,
                  decoration: _inputDeco(
                    'Select Sales Person',
                    Icons.person_pin_rounded,
                    Colors.teal.shade600,
                  ),
                  items: _salesPersons
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedSalesPerson = v;
                    _customSalesPerson = null;
                    _otherSalesPersonController.clear();
                  }),
                  validator: (v) =>
                      v == null ? 'Please select a sales person' : null,
                ),
                if (_selectedSalesPerson == 'Others') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _otherSalesPersonController,
                    decoration: _inputDeco(
                      'Enter Sales Person Name',
                      Icons.edit_rounded,
                      Colors.teal.shade600,
                    ),
                    onChanged: (v) => _customSalesPerson = v.trim(),
                    validator: (v) =>
                        _selectedSalesPerson == 'Others' &&
                            (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Products
            _buildSection(
              'Products',
              Icons.inventory_2_rounded,
              [Colors.blue.shade400, Colors.blue.shade700],
              [
                ...List.generate(_products.length, (i) => _buildProductCard(i)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add_circle_rounded),
                  label: const Text(
                    'Add Another Product',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _AppColors.primary,
                    side: BorderSide(color: _AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Totals Card
            _buildTotalsCard(),

            const SizedBox(height: 16),

            // Order Details
            _buildSection(
              'Order Details',
              Icons.receipt_long_rounded,
              [Colors.indigo.shade400, Colors.indigo.shade700],
              [
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildPrioritySelector(),
                const SizedBox(height: 16),
                _buildTF(
                  _notesController,
                  'Additional Notes (Optional)',
                  Icons.note_rounded,
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Submit Button
            Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_AppColors.primary, _AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Book Unit 2 Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Product Card ───────────────────────────────────────────────────────────
  Widget _buildProductCard(int index) {
    final p = _products[index];
    final sectionSelected = p['sectionSelected'] as Map<String, bool>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _AppColors.primaryLight.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_AppColors.primary, _AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p['code'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Product ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (_products.length > 1)
                IconButton(
                  icon: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                  onPressed: () => _removeProduct(index),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Category
          DropdownButtonFormField<String>(
            value: p['category'] as String,
            decoration: _inputDeco(
              'Product Category',
              Icons.category_rounded,
              _AppColors.primary,
            ),
            items: _productCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => p['category'] = v!),
          ),
          const SizedBox(height: 14),
_buildTF(
  p['name'] as TextEditingController,
  'Product Name *',
  Icons.shopping_bag_rounded,
  validator: (v) =>
      v == null || v.trim().isEmpty ? 'Product name required' : null,
),
          // Product Name Autocomplete
          // Autocomplete<Map<String, dynamic>>(
          //   optionsBuilder: (TextEditingValue value) async {
          //     if (value.text.length < 2) return const [];
          //     final snap = await FirebaseFirestore.instance
          //         .collection('unit2JobCards')
          //         .orderBy('createdAt', descending: true)
          //         .limit(500)
          //         .get();
          //     final List<Map<String, dynamic>> results = [];
          //     for (final doc in snap.docs) {
          //       final products = doc['products'];
          //       if (products is List) {
          //         for (final prod in products) {
          //           if ((prod['productName'] ?? '')
          //               .toString()
          //               .toLowerCase()
          //               .contains(value.text.toLowerCase())) {
          //             results.add(Map<String, dynamic>.from(prod));
          //           }
          //         }
          //       }
          //     }
          //     return results;
          //   },
          //   displayStringForOption: (o) => o['productName'] ?? '',
          //   fieldViewBuilder: (context, controller, focusNode, onSubmit) {
          //     p['name'] = controller;
          //     return TextFormField(
          //       controller: controller,
          //       focusNode: focusNode,
          //       decoration: _inputDeco(
          //         'Product Name *',
          //         Icons.shopping_bag_rounded,
          //         _AppColors.primary,
          //       ),
          //       validator: (v) => v == null || v.trim().isEmpty
          //           ? 'Product name required'
          //           : null,
          //     );
          //   },
          //   onSelected: (data) {
          //     setState(() {
          //       (p['price'] as TextEditingController).text =
          //           (data['price'] ?? 0).toString();
          //       (p['quantity'] as TextEditingController).text =
          //           (data['quantity'] ?? 0).toString();
          //       (p['remarks'] as TextEditingController).text =
          //           data['remarks'] ?? '';
          //       (p['length'] as TextEditingController).text =
          //           data['length'] ?? '';
          //       (p['height'] as TextEditingController).text =
          //           data['height'] ?? '';
          //       (p['width'] as TextEditingController).text =
          //           data['width'] ?? '';
          //       p['fetchedImages'] = List<String>.from(data['images'] ?? []);
          //       final sections =
          //           data['sections'] as Map<String, dynamic>? ?? {};
          //       void loadSection(String uiKey, String prefix) {
          //         sectionSelected[uiKey] =
          //             (sections['${prefix}Detail']?.toString().isNotEmpty ??
          //                 false) ||
          //             (sections['${prefix}Qty'] != null) ||
          //             (sections['${prefix}Price']?.toString().isNotEmpty ??
          //                 false);
          //         if (sectionSelected[uiKey] == true) {
          //           (p['${prefix}DetailController'] as TextEditingController)
          //                   .text =
          //               sections['${prefix}Detail'] ?? '';
          //           (p['${prefix}QtyController'] as TextEditingController)
          //                   .text =
          //               sections['${prefix}Qty']?.toString() ?? '';
          //           (p['${prefix}PriceController'] as TextEditingController)
          //                   .text =
          //               sections['${prefix}Price'] ?? '';
          //         }
          //       }

          //       loadSection('Tray', 'tray');
          //       loadSection('Salophin', 'salophin');
          //       loadSection('Box Cover', 'boxCover');
          //       loadSection('Inner', 'inner');
          //       loadSection('Bottom', 'bottom');
          //       loadSection('Die', 'die');
          //       loadSection('Others', 'other');
          //     });
          //   },
          // ),
          const SizedBox(height: 14),

          // Size Row
          Row(
            children: [
              Expanded(
                child: _buildTF(
                  p['length'] as TextEditingController,
                  'Length',
                  Icons.straighten,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTF(
                  p['height'] as TextEditingController,
                  'Height',
                  Icons.height,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTF(
                  p['width'] as TextEditingController,
                  'Width',
                  Icons.width_normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Qty & Price
          Row(
            children: [
              Expanded(
                child: _buildTF(
                  p['quantity'] as TextEditingController,
                  'Quantity *',
                  Icons.numbers_rounded,
                  type: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTF(
                  p['price'] as TextEditingController,
                  'Price/Unit',
                  Icons.currency_rupee_rounded,
                  type: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildTF(
            p['remarks'] as TextEditingController,
            'Remarks (Optional)',
            Icons.comment_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 14),

          // Packaging Sections
          _buildPackagingSections(p, sectionSelected),
          const SizedBox(height: 14),

          // Extra Sections
          _buildExtraSections(p),
          const SizedBox(height: 14),

          // Images
          _buildImagesWidget(index, p),
          const SizedBox(height: 10),

          // Product Total
          Align(
            alignment: Alignment.centerRight,
            child: Builder(
              builder: (context) {
                final qty =
                    double.tryParse(
                      (p['quantity'] as TextEditingController).text,
                    ) ??
                    0;
                final price =
                    double.tryParse(
                      (p['price'] as TextEditingController).text,
                    ) ??
                    0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Total: ₹${(qty * price).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagingSections(
    Map<String, dynamic> p,
    Map<String, bool> sectionSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Packaging Sections',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: _AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sectionSelected.keys
              .map(
                (key) => FilterChip(
                  label: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: sectionSelected[key]!,
                  onSelected: (val) =>
                      setState(() => sectionSelected[key] = val),
                  selectedColor: _AppColors.primary.withOpacity(0.25),
                  backgroundColor: Colors.grey.shade200,
                  side: BorderSide(
                    color: sectionSelected[key]!
                        ? _AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
              )
              .toList(),
        ),
        if (sectionSelected['Tray'] == true) ...[
          const SizedBox(height: 10),
          _packRow(p, 'tray', 'Tray', Icons.inbox),
        ],
        if (sectionSelected['Salophin'] == true) ...[
          const SizedBox(height: 10),
          _packRow(p, 'salophin', 'Salophin', Icons.local_shipping),
        ],
        if (sectionSelected['Box Cover'] == true) ...[
          const SizedBox(height: 10),
          _packRow(p, 'boxCover', 'Box Cover', Icons.cases_outlined),
        ],
        if (sectionSelected['Inner'] == true) ...[
          const SizedBox(height: 10),
          _packRow(p, 'inner', 'Inner', Icons.table_rows),
        ],
        if (sectionSelected['Bottom'] == true) ...[
          const SizedBox(height: 10),
          _packRow(p, 'bottom', 'Bottom', Icons.align_vertical_bottom),
        ],
        if (sectionSelected['Die'] == true) ...[
          const SizedBox(height: 10),
          _packRow(p, 'die', 'Die', Icons.cut),
        ],
        if (sectionSelected['Others'] == true) ...[
          const SizedBox(height: 10),
          _packRow(p, 'other', 'Other', Icons.more_horiz),
        ],
      ],
    );
  }

  Widget _packRow(
    Map<String, dynamic> p,
    String prefix,
    String label,
    IconData icon,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildTF(
            p['${prefix}DetailController'] as TextEditingController,
            '$label Details',
            icon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTF(
            p['${prefix}QtyController'] as TextEditingController,
            'Qty',
            Icons.numbers,
            type: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTF(
            p['${prefix}PriceController'] as TextEditingController,
            'Price',
            Icons.currency_rupee,
          ),
        ),
      ],
    );
  }

  Widget _buildExtraSections(Map<String, dynamic> p) {
    final extraSections =
        p['customExtraSections'] as List<Map<String, TextEditingController>>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Extra Sections',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: _AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Extra Section'),
          onPressed: () => setState(
            () => extraSections.add({
              'title': TextEditingController(),
              'detail': TextEditingController(),
              'qty': TextEditingController(),
              'price': TextEditingController(),
            }),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _AppColors.accent,
            side: const BorderSide(color: _AppColors.accent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        ...extraSections.asMap().entries.map((e) {
          final i = e.key;
          final sec = e.value;
          return Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.accent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _buildTF(sec['title']!, 'Section Header', Icons.title),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTF(
                        sec['detail']!,
                        'Details',
                        Icons.description,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTF(
                        sec['qty']!,
                        'Qty',
                        Icons.numbers,
                        type: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTF(
                        sec['price']!,
                        'Price',
                        Icons.currency_rupee,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() {
                      sec['title']!.dispose();
                      sec['detail']!.dispose();
                      sec['qty']!.dispose();
                      sec['price']!.dispose();
                      extraSections.removeAt(i);
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImagesWidget(int index, Map<String, dynamic> p) {
    final newImages = p['images'] as List<XFile>;
    final fetchedImages = p['fetchedImages'] as List<String>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickImages(index),
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: Text(
            newImages.isEmpty ? 'Add Product Images' : 'Add More Images',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _AppColors.primary,
            side: const BorderSide(color: _AppColors.primary, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (fetchedImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fetchedImages
                .asMap()
                .entries
                .map(
                  (e) => _imageThumb(
                    networkUrl: e.value,
                    onRemove: () =>
                        setState(() => fetchedImages.removeAt(e.key)),
                  ),
                )
                .toList(),
          ),
        ],
        if (newImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: newImages
                .asMap()
                .entries
                .map(
                  (e) => _imageThumb(
                    xFile: e.value,
                    onRemove: () => setState(() => newImages.removeAt(e.key)),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _imageThumb({
    String? networkUrl,
    XFile? xFile,
    required VoidCallback onRemove,
  }) {
    ImageProvider image;
    if (networkUrl != null) {
      image = NetworkImage(networkUrl);
    } else {
      image = kIsWeb
          ? NetworkImage(xFile!.path)
          : FileImage(File(xFile!.path)) as ImageProvider;
    }
    return Stack(
      children: [
        GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(image: image),
                ),
              ),
            ),
          ),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AppColors.primaryLight, width: 2),
              image: DecorationImage(image: image, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Totals Card ────────────────────────────────────────────────────────────
  Widget _buildTotalsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_AppColors.primary, _AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', '₹${_subTotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          // GST row with selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'GST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text('${g.toInt()}%'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _gstPercent = v!),
                    ),
                  ),
                ],
              ),
              Text(
                '₹${_gstAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Delivery Charges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Delivery',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => setState(() {
                      _showDeliveryCharges = !_showDeliveryCharges;
                      if (!_showDeliveryCharges) {
                        _deliveryCharges = 0;
                        _deliveryController.clear();
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _showDeliveryCharges ? 'Remove' : 'Add',
                        style: TextStyle(
                          color: _AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
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
                      prefixStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Advance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Advance Paid',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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
                    prefixStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _advanceAmount = double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white54, thickness: 1, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${_finalTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Date & Priority ────────────────────────────────────────────────────────
  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: _AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.indigo.shade200, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: _AppColors.primary),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Planned Dispatch Date',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Level',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['Low', 'Medium', 'High', 'Urgent'].map((priority) {
            final isSelected = _selectedPriority == priority;
            final colors = {
              'Low': Colors.green,
              'Medium': Colors.orange,
              'High': Colors.deepOrange,
              'Urgent': Colors.red,
            };
            final color = colors[priority]!;
            return InkWell(
              onTap: () => setState(() => _selectedPriority = priority),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color.shade600 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.shade600, width: 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color.shade600,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Section Builder ────────────────────────────────────────────────────────
  Widget _buildSection(
    String title,
    IconData icon,
    List<Color> colors,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // ── Autocomplete Customer Name ─────────────────────────────────────────────
  // Widget _buildAutocompleteName() {
  //   return Autocomplete<Map<String, dynamic>>(
  //     optionsBuilder: (TextEditingValue value) async {
  //       if (value.text.length < 2) return [];
  //       final snap = await FirebaseFirestore.instance
  //           .collection('unit2JobCards')
  //           .orderBy('createdAt', descending: true)
  //           .limit(25)
  //           .get();
  //       final Map<String, Map<String, dynamic>> unique = {};
  //       for (final doc in snap.docs) {
  //         final d = doc.data();
  //         final name = (d['customerName'] ?? '').toString();
  //         if (name.toLowerCase().contains(value.text.toLowerCase())) {
  //           unique[name] = {
  //             'customerName': d['customerName'],
  //             'companyName': d['companyName'],
  //             'phone': d['phone'],
  //             'email': d['email'],
  //             'location': d['location'],
  //             'gst': d['customerGstNumber'],
  //           };
  //         }
  //       }
  //       return unique.values.toList();
  //     },
  //     displayStringForOption: (o) => o['customerName'] ?? '',
  //     fieldViewBuilder: (context, controller, focusNode, onSubmit) {
  //       controller.text = _customerNameController.text;
  //       controller.addListener(
  //         () => _customerNameController.text = controller.text,
  //       );
  //       return TextFormField(
  //         controller: controller,
  //         focusNode: focusNode,
  //         decoration: _inputDeco(
  //           'Customer Name *',
  //           Icons.person_rounded,
  //           _AppColors.primary,
  //         ),
  //         validator: (v) => v == null || v.trim().isEmpty
  //             ? 'Customer name is required'
  //             : null,
  //       );
  //     },
  //     onSelected: (c) => setState(() {
  //       _customerNameController.text = c['customerName'] ?? '';
  //       _companyNameController.text = c['companyName'] ?? '';
  //       _phoneController.text = c['phone'] ?? '';
  //       _emailController.text = c['email'] ?? '';
  //       _locationController.text = c['location'] ?? '';
  //       _gstNumberController.text = c['gst'] ?? '';
  //     }),
  //   );
  // }

  // ── TextField Helper ───────────────────────────────────────────────────────
  InputDecoration _inputDeco(String label, IconData icon, Color color) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildTF(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      inputFormatters: formatters,
      onChanged: onChanged,
      decoration: _inputDeco(label, icon, _AppColors.primary),
      validator: validator,
    );
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
    _advanceController.dispose();
    _deliveryController.dispose();
    _otherSalesPersonController.dispose();
    for (var p in _products) {
      _disposeProduct(p);
    }
    super.dispose();
  }
}

// ─── Unit 2 Order History Screen ─────────────────────────────────────────────
class Unit2OrderHistoryScreen extends StatefulWidget {
  const Unit2OrderHistoryScreen({super.key});

  @override
  State<Unit2OrderHistoryScreen> createState() =>
      _Unit2OrderHistoryScreenState();
}

class _Unit2OrderHistoryScreenState extends State<Unit2OrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _AppColors.headerGradient),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Unit 2 — Order History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: _AppColors.headerGradient,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by customer or order no...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                          )
                        : null,
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((s) {
                      final selected = _filterStatus == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            s,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) => setState(() => _filterStatus = s),
                          selectedColor: Colors.white.withOpacity(0.3),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          side: BorderSide(
                            color: selected ? Colors.white : Colors.white30,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('unit2JobCards')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _AppColors.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmpty();
                }

                var docs = snapshot.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final customerName = (d['customerName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final orderId = (d['salesOrderNo'] ?? d['orderId'] ?? '')
                      .toString()
                      .toLowerCase();
                  final status = (d['status'] ?? '').toString();

                  final matchSearch =
                      _searchQuery.isEmpty ||
                      customerName.contains(_searchQuery) ||
                      orderId.contains(_searchQuery);
                  final matchStatus =
                      _filterStatus == 'All' || status == _filterStatus;
                  return matchSearch && matchStatus;
                }).toList();

                if (docs.isEmpty)
                  return _buildEmpty('No orders match your search');

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildOrderCard(doc.id, data, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Unit2SalesOrderScreen()),
        ),
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Order',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    String docId,
    Map<String, dynamic> d,
    BuildContext context,
  ) {
    final status = d['status'] ?? 'Pending';
    final statusColor =
        {
          'Pending': Colors.orange,
          'In Progress': Colors.blue,
          'Completed': Colors.green,
          'Cancelled': Colors.red,
        }[status] ??
        Colors.grey;

    final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
    final deliveryDate = (d['deliveryDate'] as Timestamp?)?.toDate();
    final products = (d['products'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Unit2EditOrderScreen(orderId: docId, orderData: d),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_AppColors.primary, _AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      d['salesOrderNo'] ?? d['orderId'] ?? docId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                d['customerName'] ?? 'Unknown Customer',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if ((d['companyName'] ?? '').isNotEmpty)
                Text(
                  d['companyName'],
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${products.length} product${products.length != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  if (deliveryDate != null) ...[
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ],
              ),
              if ((d['grandTotal'] ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '₹${(d['grandTotal'] as num).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Booked: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty([String msg = 'No Unit 2 orders yet']) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: _AppColors.primaryLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ─── Unit 2 Edit Order Screen ─────────────────────────────────────────────────
class Unit2EditOrderScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const Unit2EditOrderScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<Unit2EditOrderScreen> createState() => _Unit2EditOrderScreenState();
}

class _Unit2EditOrderScreenState extends State<Unit2EditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late DateTime _orderDate;
  late DateTime _deliveryDate;
  late String _priority;
  String? _selectedSalesPerson;
  String? _customSalesPerson;
  late List<Map<String, dynamic>> _products;
  late List<Map<String, dynamic>> _partialDispatches;
  bool _isSaving = false;
  bool _showPartialDispatch = false;
  String _selectedStatus = 'Pending';
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _otherSalesPersonController =
      TextEditingController();

  final List<String> _productCategories = [
    'MDF',
    'Kappa Box',
    'Packaging',
    'Rigid Box (unit 2)',
    'Others',
  ];
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
  final List<String> _statusList = [
    'Pending',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  bool _hasValue(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is num) return true;
    return false;
  }

  String _safeText(dynamic v) {
    if (v == null) return '';
    if (v is num) return v.toString();
    if (v is String) return v;
    return '';
  }

  @override
  void initState() {
    super.initState();
    final d = widget.orderData;
    _customerController = TextEditingController(text: d['customerName'] ?? '');
    _companyController = TextEditingController(text: d['companyName'] ?? '');
    _phoneController = TextEditingController(text: d['phone'] ?? '');
    _emailController = TextEditingController(text: d['email'] ?? '');
    _locationController = TextEditingController(text: d['location'] ?? '');
    _notesController = TextEditingController(text: d['notes'] ?? '');
    _orderDate = (d['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    _deliveryDate =
        (d['deliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    _priority = d['priority'] ?? 'Medium';
    _selectedStatus = d['status'] ?? 'Pending';

    final savedSalesPerson = d['salesPerson'];
    if (_salesPersons.contains(savedSalesPerson)) {
      _selectedSalesPerson = savedSalesPerson;
    } else if (savedSalesPerson != null &&
        savedSalesPerson.toString().isNotEmpty) {
      _selectedSalesPerson = 'Others';
      _customSalesPerson = savedSalesPerson;
      _otherSalesPersonController.text = savedSalesPerson;
    }

    // Load products
    final rawProducts = d['products'];
    List productsList = rawProducts is List
        ? rawProducts
        : rawProducts is Map
        ? [rawProducts]
        : [];

    _products = productsList.map((p) {
      final sections = p['sections'] as Map<String, dynamic>? ?? {};
      final extraSections = p['customExtraSections'] as List? ?? [];
      return {
        'id': p['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'nameController': TextEditingController(text: p['productName'] ?? ''),
        'quantityController': TextEditingController(
          text: _safeText(p['quantity']),
        ),
        'remarkController': TextEditingController(text: p['remarks'] ?? ''),
        'lengthController': TextEditingController(text: p['length'] ?? ''),
        'heightController': TextEditingController(text: p['height'] ?? ''),
        'widthController': TextEditingController(text: p['width'] ?? ''),
        'priceController': TextEditingController(text: _safeText(p['price'])),
        'productCategory': p['productCategory'] ?? 'Rigid Box (unit 2)',
        'images': List<String>.from(p['images'] ?? []),
        'newImages': <XFile>[],
        'sectionSelected': {
          'Tray':
              _hasValue(sections['trayDetail']) ||
              _hasValue(sections['trayQty']),
          'Salophin':
              _hasValue(sections['salophinDetail']) ||
              _hasValue(sections['salophinQty']),
          'Box Cover':
              _hasValue(sections['boxCoverDetail']) ||
              _hasValue(sections['boxCoverQty']),
          'Inner':
              _hasValue(sections['innerDetail']) ||
              _hasValue(sections['innerQty']),
          'Bottom':
              _hasValue(sections['bottomDetail']) ||
              _hasValue(sections['bottomQty']),
          'Die':
              _hasValue(sections['dieDetail']) || _hasValue(sections['dieQty']),
          'Others':
              _hasValue(sections['otherDetail']) ||
              _hasValue(sections['otherQty']) ||
              extraSections.isNotEmpty,
        },
        'trayDetailController': TextEditingController(
          text: sections['trayDetail'] ?? '',
        ),
        'trayQtyController': TextEditingController(
          text: _safeText(sections['trayQty']),
        ),
        'trayPriceController': TextEditingController(
          text: sections['trayPrice'] ?? '',
        ),
        'salophinDetailController': TextEditingController(
          text: sections['salophinDetail'] ?? '',
        ),
        'salophinQtyController': TextEditingController(
          text: _safeText(sections['salophinQty']),
        ),
        'salophinPriceController': TextEditingController(
          text: sections['salophinPrice'] ?? '',
        ),
        'boxCoverDetailController': TextEditingController(
          text: sections['boxCoverDetail'] ?? '',
        ),
        'boxCoverQtyController': TextEditingController(
          text: _safeText(sections['boxCoverQty']),
        ),
        'boxCoverPriceController': TextEditingController(
          text: sections['boxCoverPrice'] ?? '',
        ),
        'innerDetailController': TextEditingController(
          text: sections['innerDetail'] ?? '',
        ),
        'innerQtyController': TextEditingController(
          text: _safeText(sections['innerQty']),
        ),
        'innerPriceController': TextEditingController(
          text: sections['innerPrice'] ?? '',
        ),
        'bottomDetailController': TextEditingController(
          text: sections['bottomDetail'] ?? '',
        ),
        'bottomQtyController': TextEditingController(
          text: _safeText(sections['bottomQty']),
        ),
        'bottomPriceController': TextEditingController(
          text: sections['bottomPrice'] ?? '',
        ),
        'dieDetailController': TextEditingController(
          text: sections['dieDetail'] ?? '',
        ),
        'dieQtyController': TextEditingController(
          text: _safeText(sections['dieQty']),
        ),
        'diePriceController': TextEditingController(
          text: sections['diePrice'] ?? '',
        ),
        'otherDetailController': TextEditingController(
          text: sections['otherDetail'] ?? '',
        ),
        'otherQtyController': TextEditingController(
          text: _safeText(sections['otherQty']),
        ),
        'otherPriceController': TextEditingController(
          text: sections['otherPrice'] ?? '',
        ),
        'customExtraSections': extraSections
            .map<Map<String, TextEditingController>>(
              (sec) => {
                'title': TextEditingController(text: sec['title'] ?? ''),
                'detail': TextEditingController(text: sec['detail'] ?? ''),
                'qty': TextEditingController(text: _safeText(sec['qty'])),
                'price': TextEditingController(text: sec['price'] ?? ''),
              },
            )
            .toList(),
      };
    }).toList();

    if (_products.isEmpty) _products = [_createEmptyProduct()];

    _partialDispatches =
        (d['partialDispatches'] as List?)
            ?.map(
              (disp) => {
                'nameController': TextEditingController(
                  text: disp['name'] ?? '',
                ),
                'qtyController': TextEditingController(
                  text: disp['quantity']?.toString() ?? '',
                ),
                'dateController': TextEditingController(
                  text: disp['date'] ?? '',
                ),
                'selectedDate': disp['timestamp'] != null
                    ? (disp['timestamp'] as Timestamp).toDate()
                    : null,
              },
            )
            .toList() ??
        [_createEmptyDispatch()];

    _showPartialDispatch =
        _partialDispatches.isNotEmpty &&
        (_partialDispatches[0]['nameController'] as TextEditingController)
            .text
            .isNotEmpty;
  }

  Map<String, dynamic> _createEmptyProduct() => {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'nameController': TextEditingController(),
    'quantityController': TextEditingController(),
    'lengthController': TextEditingController(),
    'heightController': TextEditingController(),
    'widthController': TextEditingController(),
    'priceController': TextEditingController(),
    'remarkController': TextEditingController(),
    'productCategory': 'Rigid Box (unit 2)',
    'images': <String>[],
    'newImages': <XFile>[],
    'sectionSelected': {
      'Tray': false,
      'Salophin': false,
      'Box Cover': false,
      'Inner': false,
      'Bottom': false,
      'Die': false,
      'Others': false,
    },
    'trayDetailController': TextEditingController(),
    'trayQtyController': TextEditingController(),
    'trayPriceController': TextEditingController(),
    'salophinDetailController': TextEditingController(),
    'salophinQtyController': TextEditingController(),
    'salophinPriceController': TextEditingController(),
    'boxCoverDetailController': TextEditingController(),
    'boxCoverQtyController': TextEditingController(),
    'boxCoverPriceController': TextEditingController(),
    'innerDetailController': TextEditingController(),
    'innerQtyController': TextEditingController(),
    'innerPriceController': TextEditingController(),
    'bottomDetailController': TextEditingController(),
    'bottomQtyController': TextEditingController(),
    'bottomPriceController': TextEditingController(),
    'dieDetailController': TextEditingController(),
    'dieQtyController': TextEditingController(),
    'diePriceController': TextEditingController(),
    'otherDetailController': TextEditingController(),
    'otherQtyController': TextEditingController(),
    'otherPriceController': TextEditingController(),
    'customExtraSections': <Map<String, TextEditingController>>[],
  };

  Map<String, dynamic> _createEmptyDispatch() => {
    'nameController': TextEditingController(),
    'qtyController': TextEditingController(),
    'dateController': TextEditingController(),
    'selectedDate': null,
  };

  void _disposeProductControllers(Map<String, dynamic> p) {
    for (final key in [
      'nameController',
      'quantityController',
      'lengthController',
      'heightController',
      'widthController',
      'priceController',
      'remarkController',
      'trayDetailController',
      'trayQtyController',
      'trayPriceController',
      'salophinDetailController',
      'salophinQtyController',
      'salophinPriceController',
      'boxCoverDetailController',
      'boxCoverQtyController',
      'boxCoverPriceController',
      'innerDetailController',
      'innerQtyController',
      'innerPriceController',
      'bottomDetailController',
      'bottomQtyController',
      'bottomPriceController',
      'dieDetailController',
      'dieQtyController',
      'diePriceController',
      'otherDetailController',
      'otherQtyController',
      'otherPriceController',
    ]) {
      (p[key] as TextEditingController?)?.dispose();
    }
    for (final sec
        in (p['customExtraSections']
            as List<Map<String, TextEditingController>>)) {
      sec['title']?.dispose();
      sec['detail']?.dispose();
      sec['qty']?.dispose();
      sec['price']?.dispose();
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      List<Map<String, dynamic>> productsData = [];

      for (int i = 0; i < _products.length; i++) {
        final p = _products[i];
        final existingImages = List<String>.from(p['images'] as List);
        final newImages = p['newImages'] as List<XFile>;

        List<String> newUrls = [];
        for (final img in newImages) {
          final ref = FirebaseStorage.instance.ref().child(
            'unit2_orders/${widget.orderId}/product_$i/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          if (kIsWeb) {
            await ref.putData(
              await img.readAsBytes(),
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else {
            await ref.putFile(File(img.path));
          }
          newUrls.add(await ref.getDownloadURL());
        }

        final sectionSelected = p['sectionSelected'] as Map<String, bool>;
        final Map<String, dynamic> sections = {};

        void addSection(String uiKey, String prefix) {
          if (sectionSelected[uiKey] == true) {
            sections['${prefix}Detail'] =
                (p['${prefix}DetailController'] as TextEditingController).text
                    .trim();
            sections['${prefix}Qty'] =
                int.tryParse(
                  (p['${prefix}QtyController'] as TextEditingController).text
                      .trim(),
                ) ??
                0;
            sections['${prefix}Price'] =
                (p['${prefix}PriceController'] as TextEditingController).text
                    .trim();
          }
        }

        addSection('Tray', 'tray');
        addSection('Salophin', 'salophin');
        addSection('Box Cover', 'boxCover');
        addSection('Inner', 'inner');
        addSection('Bottom', 'bottom');
        addSection('Die', 'die');
        addSection('Others', 'other');

        final extraSections = <Map<String, dynamic>>[];
        for (final sec
            in (p['customExtraSections']
                as List<Map<String, TextEditingController>>)) {
          final title = sec['title']!.text.trim();
          if (title.isNotEmpty || sec['detail']!.text.isNotEmpty) {
            extraSections.add({
              'title': title,
              'detail': sec['detail']!.text.trim(),
              'qty': int.tryParse(sec['qty']!.text.trim()) ?? 0,
              'price': sec['price']!.text.trim(),
            });
          }
        }

        productsData.add({
          'id': p['id'],
          'productName': (p['nameController'] as TextEditingController).text
              .trim(),
          'quantity':
              int.tryParse(
                (p['quantityController'] as TextEditingController).text.trim(),
              ) ??
              0,
          'price':
              double.tryParse(
                (p['priceController'] as TextEditingController).text.trim(),
              ) ??
              0,
          'remarks': (p['remarkController'] as TextEditingController).text
              .trim(),
          'length': (p['lengthController'] as TextEditingController).text
              .trim(),
          'height': (p['heightController'] as TextEditingController).text
              .trim(),
          'width': (p['widthController'] as TextEditingController).text.trim(),
          'productCategory': p['productCategory'],
          'images': [...existingImages, ...newUrls],
          'sections': sections,
          'customExtraSections': extraSections,
        });
      }

      List<Map<String, dynamic>> dispatchData = [];
      for (var disp in _partialDispatches) {
        final name = (disp['nameController'] as TextEditingController).text
            .trim();
        final qty = (disp['qtyController'] as TextEditingController).text
            .trim();
        final date = (disp['dateController'] as TextEditingController).text
            .trim();
        if (name.isNotEmpty || qty.isNotEmpty || date.isNotEmpty) {
          dispatchData.add({
            'name': name,
            'quantity': int.tryParse(qty) ?? 0,
            'date': date,
            'timestamp': disp['selectedDate'] != null
                ? Timestamp.fromDate(disp['selectedDate'] as DateTime)
                : null,
          });
        }
      }

      // ✅ Save ONLY to unit2JobCards
      await FirebaseFirestore.instance
          .collection('unit2JobCards')
          .doc(widget.orderId)
          .update({
            'customerName': _customerController.text.trim(),
            'companyName': _companyController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'location': _locationController.text.trim(),
            'notes': _notesController.text.trim(),
            'products': productsData,
            'partialDispatches': dispatchData,
            'priority': _priority,
            'status': _selectedStatus,
            'salesPerson': _selectedSalesPerson == 'Others'
                ? _customSalesPerson
                : _selectedSalesPerson,
            'deliveryDate': Timestamp.fromDate(_deliveryDate),
            'orderDate': Timestamp.fromDate(_orderDate),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Order updated successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildTF(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      inputFormatters: formatters,
      decoration: _inputDeco(label, icon),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _AppColors.headerGradient),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Unit 2 Order',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              widget.orderData['salesOrderNo'] ?? widget.orderId,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Update
            _buildEditSection('Order Status', Icons.track_changes, [
              DropdownButtonFormField<String>(
                value: _statusList.contains(_selectedStatus)
                    ? _selectedStatus
                    : 'Pending',
                decoration: _inputDeco('Status', Icons.flag_rounded),
                items: _statusList.map((s) {
                  final colors = {
                    'Pending': Colors.orange,
                    'In Progress': Colors.blue,
                    'Completed': Colors.green,
                    'Cancelled': Colors.red,
                  };
                  return DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors[s] ?? Colors.grey,
                          ),
                        ),
                        Text(s),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedStatus = v!),
              ),
            ]),
            const SizedBox(height: 16),

            _buildEditSection('Customer Details', Icons.person_outline, [
              _buildTF(
                _customerController,
                'Customer Name *',
                Icons.person,
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTF(_companyController, 'Company Name', Icons.business),
              const SizedBox(height: 12),
              _buildTF(_locationController, 'Location', Icons.location_on),
              const SizedBox(height: 12),
              _buildTF(
                _phoneController,
                'Phone',
                Icons.phone,
                type: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildTF(
                _emailController,
                'Email',
                Icons.email,
                type: TextInputType.emailAddress,
              ),
            ]),
            const SizedBox(height: 16),

            // Products
            _buildEditSection('Products', Icons.inventory_2, [
              ...List.generate(
                _products.length,
                (i) => _buildEditProductCard(i),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _products.add(_createEmptyProduct())),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _AppColors.primary,
                  side: const BorderSide(color: _AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            _buildEditSection('Sales Person', Icons.badge_outlined, [
              DropdownButtonFormField<String>(
                value: _salesPersons.contains(_selectedSalesPerson)
                    ? _selectedSalesPerson
                    : null,
                decoration: _inputDeco('Select Sales Person', Icons.person_pin),
                items: _salesPersons
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedSalesPerson = v;
                  _customSalesPerson = null;
                  _otherSalesPersonController.clear();
                }),
                validator: (v) =>
                    v == null ? 'Please select a sales person' : null,
              ),
              if (_selectedSalesPerson == 'Others') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otherSalesPersonController,
                  decoration: _inputDeco('Enter Sales Person Name', Icons.edit),
                  onChanged: (v) => _customSalesPerson = v.trim(),
                  validator: (v) =>
                      _selectedSalesPerson == 'Others' &&
                          (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
              ],
            ]),
            const SizedBox(height: 16),

            // Partial Dispatch
            _buildEditSection(
              'Partial Dispatch',
              Icons.local_shipping_outlined,
              [
                DropdownButtonFormField<String>(
                  value: _showPartialDispatch ? 'Yes' : 'No',
                  decoration: _inputDeco(
                    'Any Partial Dispatch?',
                    Icons.help_outline,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'No', child: Text('No')),
                    DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                  ],
                  onChanged: (v) => setState(() {
                    _showPartialDispatch = v == 'Yes';
                    if (_showPartialDispatch && _partialDispatches.isEmpty) {
                      _partialDispatches.add(_createEmptyDispatch());
                    }
                  }),
                ),
                if (_showPartialDispatch) ...[
                  const SizedBox(height: 12),
                  ..._partialDispatches.asMap().entries.map(
                    (e) => _buildDispatchItem(e.key),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(
                      () => _partialDispatches.add(_createEmptyDispatch()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Dispatch'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _AppColors.accent,
                      side: const BorderSide(color: _AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            _buildEditSection('Schedule & Priority', Icons.schedule, [
              Row(
                children: [
                  Expanded(
                    child: _buildDateCard('Order Date', _orderDate, () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _orderDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (p != null) setState(() => _orderDate = p);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateCard(
                      'Delivery Date',
                      _deliveryDate,
                      () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _deliveryDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (p != null) setState(() => _deliveryDate = p);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Low', 'Medium', 'High', 'Urgent'].map((pr) {
                  final isSelected = _priority == pr;
                  final colors = {
                    'Low': Colors.green,
                    'Medium': Colors.orange,
                    'High': Colors.deepOrange,
                    'Urgent': Colors.red,
                  };
                  final color = colors[pr]!;
                  return InkWell(
                    onTap: () => setState(() => _priority = pr),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color.shade600 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.shade600, width: 2),
                      ),
                      child: Text(
                        pr,
                        style: TextStyle(
                          color: isSelected ? Colors.white : color.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
            const SizedBox(height: 16),

            _buildEditSection('Additional Notes', Icons.note_outlined, [
              _buildTF(
                _notesController,
                'Notes (Optional)',
                Icons.notes,
                maxLines: 3,
              ),
            ]),
            const SizedBox(height: 24),

            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_AppColors.primary, _AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProductCard(int index) {
    final p = _products[index];
    final sectionSelected = p['sectionSelected'] as Map<String, bool>;
    final existingImages = p['images'] as List<String>;
    final newImages = p['newImages'] as List<XFile>;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _AppColors.primaryLight.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.primary, _AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Product ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_products.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    if (_products.length > 1) {
                      setState(() {
                        _disposeProductControllers(p);
                        _products.removeAt(index);
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _productCategories.contains(p['productCategory'])
                ? p['productCategory']
                : 'Others',
            decoration: _inputDeco('Product Category', Icons.category),
            items: _productCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => p['productCategory'] = v!),
          ),
          const SizedBox(height: 12),
          _buildTF(
            p['nameController'] as TextEditingController,
            'Product Name *',
            Icons.shopping_bag,
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTF(
                  p['lengthController'] as TextEditingController,
                  'Length',
                  Icons.straighten,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTF(
                  p['heightController'] as TextEditingController,
                  'Height',
                  Icons.height,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTF(
                  p['widthController'] as TextEditingController,
                  'Width',
                  Icons.width_normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTF(
                  p['quantityController'] as TextEditingController,
                  'Quantity *',
                  Icons.numbers,
                  type: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTF(
                  p['priceController'] as TextEditingController,
                  'Price',
                  Icons.currency_rupee,
                  type: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTF(
            p['remarkController'] as TextEditingController,
            'Remarks',
            Icons.comment_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          // Packaging Sections
          Text(
            'Packaging Sections',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: sectionSelected.keys
                .map(
                  (key) => FilterChip(
                    label: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: sectionSelected[key]!,
                    onSelected: (val) =>
                        setState(() => sectionSelected[key] = val),
                    selectedColor: _AppColors.primary.withOpacity(0.25),
                    backgroundColor: Colors.grey.shade200,
                    side: BorderSide(
                      color: sectionSelected[key]!
                          ? _AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                )
                .toList(),
          ),

          if (sectionSelected['Tray'] == true) ...[
            const SizedBox(height: 10),
            _packagingEditRow(p, 'tray', 'Tray', Icons.inbox),
          ],
          if (sectionSelected['Salophin'] == true) ...[
            const SizedBox(height: 10),
            _packagingEditRow(p, 'salophin', 'Salophin', Icons.local_shipping),
          ],
          if (sectionSelected['Box Cover'] == true) ...[
            const SizedBox(height: 10),
            _packagingEditRow(p, 'boxCover', 'Box Cover', Icons.cases_outlined),
          ],
          if (sectionSelected['Inner'] == true) ...[
            const SizedBox(height: 10),
            _packagingEditRow(p, 'inner', 'Inner', Icons.table_rows),
          ],
          if (sectionSelected['Bottom'] == true) ...[
            const SizedBox(height: 10),
            _packagingEditRow(
              p,
              'bottom',
              'Bottom',
              Icons.align_vertical_bottom,
            ),
          ],
          if (sectionSelected['Die'] == true) ...[
            const SizedBox(height: 10),
            _packagingEditRow(p, 'die', 'Die', Icons.cut),
          ],
          if (sectionSelected['Others'] == true) ...[
            const SizedBox(height: 10),
            _packagingEditRow(p, 'other', 'Other', Icons.more_horiz),
          ],

          const SizedBox(height: 12),
          // Extra Sections
          _buildEditExtraSections(p),
          const SizedBox(height: 12),

          // Images
          _buildEditImages(index, existingImages, newImages),
        ],
      ),
    );
  }

  Widget _packagingEditRow(
    Map<String, dynamic> p,
    String prefix,
    String label,
    IconData icon,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildTF(
            p['${prefix}DetailController'] as TextEditingController,
            '$label Details',
            icon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTF(
            p['${prefix}QtyController'] as TextEditingController,
            'Qty',
            Icons.numbers,
            type: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTF(
            p['${prefix}PriceController'] as TextEditingController,
            'Price',
            Icons.currency_rupee,
          ),
        ),
      ],
    );
  }

  Widget _buildEditExtraSections(Map<String, dynamic> p) {
    final extraSections =
        p['customExtraSections'] as List<Map<String, TextEditingController>>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Sections',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: _AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Section'),
          onPressed: () => setState(
            () => extraSections.add({
              'title': TextEditingController(),
              'detail': TextEditingController(),
              'qty': TextEditingController(),
              'price': TextEditingController(),
            }),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _AppColors.accent,
            side: const BorderSide(color: _AppColors.accent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        ...extraSections.asMap().entries.map((e) {
          final i = e.key;
          final sec = e.value;
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AppColors.accent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _buildTF(sec['title']!, 'Section Header', Icons.title),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTF(
                        sec['detail']!,
                        'Details',
                        Icons.description,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTF(
                        sec['qty']!,
                        'Qty',
                        Icons.numbers,
                        type: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTF(
                        sec['price']!,
                        'Price',
                        Icons.currency_rupee,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => setState(() {
                      sec['title']!.dispose();
                      sec['detail']!.dispose();
                      sec['qty']!.dispose();
                      sec['price']!.dispose();
                      extraSections.removeAt(i);
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEditImages(
    int productIndex,
    List<String> existingImages,
    List<XFile> newImages,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: _AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...existingImages.asMap().entries.map(
              (e) => Stack(
                children: [
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: InteractiveViewer(child: Image.network(e.value)),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        e.value,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => existingImages.removeAt(e.key)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...newImages.asMap().entries.map(
              (e) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(
                            e.value.path,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(e.value.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => newImages.removeAt(e.key)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final files = await _picker.pickMultiImage(imageQuality: 85);
                if (files.isNotEmpty) setState(() => newImages.addAll(files));
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.primary, _AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDispatchItem(int index) {
    final d = _partialDispatches[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.accent.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dispatch ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_partialDispatches.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => setState(() {
                    (d['nameController'] as TextEditingController).dispose();
                    (d['qtyController'] as TextEditingController).dispose();
                    (d['dateController'] as TextEditingController).dispose();
                    _partialDispatches.removeAt(index);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTF(
            d['nameController'] as TextEditingController,
            'Dispatch Name',
            Icons.person_outline,
          ),
          const SizedBox(height: 8),
          _buildTF(
            d['qtyController'] as TextEditingController,
            'Quantity',
            Icons.numbers,
            type: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: d['dateController'] as TextEditingController,
            readOnly: true,
            decoration: _inputDeco('Dispatch Date', Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                (d['dateController'] as TextEditingController).text =
                    '${picked.day}/${picked.month}/${picked.year}';
                d['selectedDate'] = picked;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _AppColors.primaryLight.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today, color: _AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _customerController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _otherSalesPersonController.dispose();
    for (var p in _products) {
      _disposeProductControllers(p);
    }
    for (var d in _partialDispatches) {
      (d['nameController'] as TextEditingController).dispose();
      (d['qtyController'] as TextEditingController).dispose();
      (d['dateController'] as TextEditingController).dispose();
    }
    super.dispose();
  }
}
