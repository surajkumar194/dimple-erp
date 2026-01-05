import 'dart:io';
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
  String _selectedProductCategory = 'MDF';
  final List<String> _productCategories = ['MDF', 'Kappa Box', 'Other'];
  String _selectedUnit = 'Unit 1';

  final List<String> _units = [
    'Unit 1',
    'Unit 2',
    'Meena Bazar',
    'College Road',
  ];

  // Product codes A-Z
  final List<String> _productCodes = List.generate(
    26,
    (index) => String.fromCharCode(65 + index),
  );

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

  List<Map<String, dynamic>> _products = [
    {
      'code': 'A',
      'name': TextEditingController(),
      'quantity': TextEditingController(),
      'price': TextEditingController(),
      'remarks': TextEditingController(),
      'images': <XFile>[],
    },
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickProductImages(int index) async {
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
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF1976D2),
                ),
              ),
              title: const Text('Pick from Gallery'),
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
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF1976D2)),
              ),
              title: const Text('Use Camera'),
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
            const SizedBox(height: 20),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> productList = [];

      for (var item in _products) {
        List<String> imageUrls = [];
        for (var img in item['images']) {
          final url = await _uploadImageToStorage(img, item['name']!.text);
          if (url != null) imageUrls.add(url);
        }

        productList.add({
          'productCode': item['code'],
          'productName': item['name']!.text,
          'quantity': int.tryParse(item['quantity']!.text) ?? 0,
          'price': double.tryParse(item['price']!.text) ?? 0,
          'amount':
              (int.tryParse(item['quantity']!.text) ?? 0) *
              (double.tryParse(item['price']!.text) ?? 0),
          'remarks': item['remarks']!.text,
          'images': imageUrls,
        });
      }
final orderRef =
    FirebaseFirestore.instance.collection('orders').doc();

    await orderRef.set({

          'orderId': orderRef.id, // 🔥 IMPORTANT
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
        'totalAmount': _calculateTotalAmount(),
        'gstPercent': _gstPercent,
        'grandTotal': _calculateTotalAmount() * (1 + _gstPercent / 100),
        'deliveryDate': _selectedDate,
        'priority': _selectedPriority,
        'notes': _notesController.text,
        'status': 'Pending',
        'orderDate': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addProduct() {
    if (_products.length >= 26) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 26 products allowed (A-Z)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _products.add({
        'code': _productCodes[_products.length],
        'name': TextEditingController(),
        'quantity': TextEditingController(),
        'price': TextEditingController(),
        'remarks': TextEditingController(),
        'images': <XFile>[],
      });
    });
  }

  void _removeProduct(int index) {
    if (_products.length > 1) {
      setState(() {
        _products[index]['name']!.dispose();
        _products[index]['quantity']!.dispose();
        _products[index]['price']!.dispose();
        _products[index]['remarks']!.dispose();
        _products.removeAt(index);

        // Reassign codes after removal
        for (int i = 0; i < _products.length; i++) {
          _products[i]['code'] = _productCodes[i];
        }
      });
    }
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'New Sales Order',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFafcb1f),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Customer Information Section
            _buildSection(
              title: 'Customer Information',
              icon: Icons.person_outline,
              children: [
                _buildTextField(
                  controller: _customerNameController,
                  label: 'Customer Name',
                  icon: Icons.person,
                  validator: (value) =>
                      value!.isEmpty ? 'Customer name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyNameController,
                  label: 'Company Name (Optional)',
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
            
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on,
                  validator: (value) =>
                      value!.isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _gstNumberController,
                  label: 'Customer GST Number (Optional)',
                  icon: Icons.receipt_long,
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

            // Location, Product Category & Unit Section
            _buildSection(
              title: 'Order Location',
              icon: Icons.location_on,
              children: [
                // DropdownButtonFormField<String>(
                //   value: _selectedProductCategory,
                //   decoration: InputDecoration(
                //     labelText: 'Product Category',
                //     prefixIcon: const Icon(
                //       Icons.category,
                //       color: Color(0xFF1976D2),
                //     ),
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     filled: true,
                //     fillColor: Colors.white,
                //   ),
                //   items: _productCategories
                //       .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                //       .toList(),
                //   onChanged: (value) {
                //     setState(() {
                //       _selectedProductCategory = value!;
                //     });
                //   },
                //   validator: (value) {
                //     if (value == null || value == 'Select') {
                //       return 'Please select product category';
                //     }
                //     return null;
                //   },
                // ),
                // const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Select Unit',
                    prefixIcon: const Icon(
                      Icons.factory_outlined,
                      color: Color(0xFF1976D2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
              icon: Icons.badge_outlined,
              children: [
                DropdownButtonFormField<String>(
                  value: _salesPersons.contains(_selectedSalesPerson)
                      ? _selectedSalesPerson
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Select Sales Person',
                    prefixIcon: const Icon(
                      Icons.person_pin,
                      color: Color(0xFF1976D2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF1976D2),
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
                  validator: (value) =>
                      value == null ? 'Please select a sales person' : null,
                ),
                if (_selectedSalesPerson == 'Others') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otherSalesPersonController,
                    decoration: InputDecoration(
                      labelText: 'Enter Sales Person Name',
                      prefixIcon: const Icon(
                        Icons.edit,
                        color: Color(0xFF1976D2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _customSalesPerson = val;
                      });
                    },
                    validator: (val) {
                      if (_selectedSalesPerson == 'Others' &&
                          (val == null || val.trim().isEmpty)) {
                        return 'Please enter sales person name';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Product Category (moved above Products section)
            _buildSection(
              title: 'Product Category',
              icon: Icons.category,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedProductCategory,
                  decoration: InputDecoration(
                    labelText: 'Select Product Category',
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Color(0xFF1976D2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _productCategories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProductCategory = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value == 'Select') {
                      return 'Please select product category';
                    }
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Products Section
            _buildSection(
              title: 'Products',
              icon: Icons.inventory_2_outlined,
              children: [
                ...List.generate(_products.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
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
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1976D2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _products[index]['code'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Product ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                            if (_products.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 22,
                                ),
                                onPressed: () => _removeProduct(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _products[index]['name']!,
                          label: 'Product Name',
                          icon: Icons.shopping_bag,
                          validator: (value) => value!.isEmpty
                              ? 'Product name is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _products[index]['quantity']!,
                                label: 'Qty',
                                icon: Icons.numbers,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                                    return 'Only numbers allowed';
                                  }
                                  if (int.parse(value) <= 0) {
                                    return 'Qty must be greater than 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _products[index]['price']!,
                                label: 'Price/Unit',
                                icon: Icons.currency_rupee,
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    value!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Remarks field
                        _buildTextField(
                          controller: _products[index]['remarks']!,
                          label: 'Remarks (Optional)',
                          icon: Icons.comment_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        // Image Upload Button
                        OutlinedButton.icon(
                          onPressed: () => _pickProductImages(index),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(
                            _products[index]['images'].isEmpty
                                ? 'Add Product Images'
                                : 'Add More Images',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1976D2),
                            side: const BorderSide(color: Color(0xFF1976D2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        // Display Selected Images
                        if (_products[index]['images'].isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              _products[index]['images'].length,
                              (imgIndex) {
                                final image =
                                    _products[index]['images'][imgIndex];
                                return Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE0E0E0),
                                        ),
                                        image: DecorationImage(
                                          image: kIsWeb
                                              ? NetworkImage(image.path)
                                              : FileImage(File(image.path))
                                                    as ImageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        onPressed: () => _removeProductImage(
                                          index,
                                          imgIndex,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
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
                              return Text(
                                'Total: ₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Product'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                    side: const BorderSide(color: Color(0xFF1976D2), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Total Amount Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFafcb1f), Color(0xFFafcb1f)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withOpacity(0.3),
                    blurRadius: 8,
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
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${_calculateTotalAmount().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'GST (%)',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF1976D2),
                              ),
                            ),

                            child: DropdownButton<double>(
                              value: _gstPercent,
                              underline: const SizedBox(),
                              items: _gstOptions.map((gst) {
                                return DropdownMenuItem<double>(
                                  value: gst,
                                  child: Text('${gst.toInt()}%'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _gstPercent = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${(_calculateTotalAmount() * _gstPercent / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                      Text(
                        '₹${(_calculateTotalAmount() * (1 + _gstPercent / 100)).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
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
              icon: Icons.receipt_long_outlined,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Planned Dispatch Date',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 17.sp,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Priority Level',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['Low', 'Medium', 'High', 'Urgent'].map((
                        priority,
                      ) {
                        final isSelected = _selectedPriority == priority;
                        Color priorityColor;
                        switch (priority) {
                          case 'Low':
                            priorityColor = Colors.green;
                            break;
                          case 'Medium':
                            priorityColor = Colors.orange;
                            break;
                          case 'High':
                            priorityColor = Colors.deepOrange;
                            break;
                          case 'Urgent':
                            priorityColor = Colors.red;
                            break;
                          default:
                            priorityColor = Colors.blue;
                        }
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPriority = priority;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? priorityColor : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? priorityColor
                                    : const Color(0xFFE0E0E0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _notesController,
                  label: 'Additional Notes (Optional)',
                  icon: Icons.note_outlined,
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFafcb1f),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20.sp),
                          const SizedBox(width: 10),
                          Text(
                            'Book Order',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF1976D2), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2), size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
