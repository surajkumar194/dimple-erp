import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class EditSalesOrderScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  const EditSalesOrderScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<EditSalesOrderScreen> createState() => _EditSalesOrderScreenState();
}

class _EditSalesOrderScreenState extends State<EditSalesOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
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
  final _trayController = TextEditingController();
  final _salophinController = TextEditingController();
  final _boxCoverController = TextEditingController();
  final _innerController = TextEditingController();
  final _bottomController = TextEditingController();
  final _dieController = TextEditingController();
  final _otherController = TextEditingController();

  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  String _selectedUnit = 'Unit 1';
  String _selectedProductCategory = 'MDF';

  final List<String> _units = [
    'Unit 1',
    'Unit 2',
    'Meena Bazar',
    'College Road',
  ];

  final List<String> _productCategories = ['MDF', 'Kappa Box', 'Other'];

  final Map<String, bool> _sectionSelected = {
    'Tray': false,
    'Salophin': false,
    'Box Cover': false,
    'Inner': false,
    'Bottom': false,
    'Die': false,
    'Others': false,
  };

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

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController(
      text: widget.orderData['customerName'] ?? '',
    );
    _companyController = TextEditingController(
      text: widget.orderData['companyName'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.orderData['phone'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.orderData['email'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.orderData['location'] ?? '',
    );
    _notesController = TextEditingController(
      text: widget.orderData['notes'] ?? '',
    );

    final sections = widget.orderData['sections'] as Map<String, dynamic>?;

    if (sections != null) {
      if (sections['tray'] != null) {
        _sectionSelected['Tray'] = true;
        _trayController.text = sections['tray'];
      }
      if (sections['salophin'] != null) {
        _sectionSelected['Salophin'] = true;
        _salophinController.text = sections['salophin'];
      }
      if (sections['boxCover'] != null) {
        _sectionSelected['Box Cover'] = true;
        _boxCoverController.text = sections['boxCover'];
      }
      if (sections['inner'] != null) {
        _sectionSelected['Inner'] = true;
        _innerController.text = sections['inner'];
      }
      if (sections['bottom'] != null) {
        _sectionSelected['Bottom'] = true;
        _bottomController.text = sections['bottom'];
      }
      if (sections['die'] != null) {
        _sectionSelected['Die'] = true;
        _dieController.text = sections['die'];
      }
      if (sections['other'] != null) {
        _sectionSelected['Others'] = true;
        _otherController.text = sections['other'];
      }
    }
    String safeText(dynamic v) {
      if (v == null) return '';
      if (v is num) return v.toString();
      if (v is String) return v;
      return '';
    }

    _orderDate =
        (widget.orderData['orderDate'] as Timestamp?)?.toDate() ??
        DateTime.now();
    _deliveryDate =
        (widget.orderData['deliveryDate'] as Timestamp?)?.toDate() ??
        DateTime.now();
    _priority = widget.orderData['priority'] ?? 'Medium';
    _selectedSalesPerson = widget.orderData['salesPerson'];
    // ✅ LOAD UNIT & PRODUCT CATEGORY
    _selectedUnit = widget.orderData['unit'] ?? 'Unit 1';
    _selectedProductCategory = widget.orderData['productCategory'] ?? 'MDF';

    // Load products with proper structure
    _products =
        (widget.orderData['products'] as List?)?.map((p) {
          return {
            'nameController': TextEditingController(
              text: p['productName'] ?? '',
            ),
            'quantityController': TextEditingController(
              text: safeText(p['quantity']),
            ),
            'sizeController': TextEditingController(text: p['size'] ?? ''),
            'priceController': TextEditingController(
              text: safeText(p['price']),
            ),
            'remarkController': TextEditingController(
              text: p['remarks'] ?? '',
            ), // ✅

            'images': List<String>.from(p['images'] ?? []),
            'newImages': <XFile>[],
          };
        }).toList() ??
        [_createEmptyProduct()];

    // Load partial dispatches
    _partialDispatches =
        (widget.orderData['partialDispatches'] as List?)?.map((d) {
          return {
            'nameController': TextEditingController(text: d['name'] ?? ''),
            'qtyController': TextEditingController(text: d['quantity'] ?? ''),
            'dateController': TextEditingController(text: d['date'] ?? ''),
            'selectedDate': d['timestamp'] != null
                ? (d['timestamp'] as Timestamp).toDate()
                : null,
          };
        }).toList() ??
        [_createEmptyDispatch()];
  }

  Map<String, dynamic> _createEmptyProduct() {
    return {
      'nameController': TextEditingController(),
      'quantityController': TextEditingController(),
      'sizeController': TextEditingController(),
      'priceController': TextEditingController(),
      'remarkController': TextEditingController(), // ✅
      'images': <String>[],
      'newImages': <XFile>[],
    };
  }

  Map<String, dynamic> _createEmptyDispatch() {
    return {
      'nameController': TextEditingController(),
      'qtyController': TextEditingController(),
      'dateController': TextEditingController(),
      'selectedDate': null,
    };
  }

  void _addProduct() {
    setState(() {
      _products.add(_createEmptyProduct());
    });
  }

  void _removeProduct(int index) {
    if (_products.length > 1) {
      setState(() {
        (_products[index]['nameController'] as TextEditingController).dispose();
        (_products[index]['quantityController'] as TextEditingController)
            .dispose();
        (_products[index]['sizeController'] as TextEditingController).dispose();
        (_products[index]['remarkController'] as TextEditingController)
            .dispose();
        _products.removeAt(index);
      });
    }
  }

  void _addPartialDispatch() {
    setState(() {
      _partialDispatches.add(_createEmptyDispatch());
    });
  }

  void _removePartialDispatch(int index) {
    if (_partialDispatches.length > 1) {
      setState(() {
        (_partialDispatches[index]['nameController'] as TextEditingController)
            .dispose();
        (_partialDispatches[index]['qtyController'] as TextEditingController)
            .dispose();
        (_partialDispatches[index]['dateController'] as TextEditingController)
            .dispose();
        _partialDispatches.removeAt(index);
      });
    }
  }

  Future<void> _chooseImageForProduct(int productIndex) async {
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
              'Add Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF169a8d).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF169a8d),
                ),
              ),
              title: const Text('Pick from Gallery'),
              subtitle: const Text('Choose multiple images'),
              onTap: () async {
                Navigator.pop(ctx);
                final files = await _picker.pickMultiImage(imageQuality: 85);
                if (files.isNotEmpty) {
                  setState(() {
                    (_products[productIndex]['newImages'] as List<XFile>)
                        .addAll(files);
                  });
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF169a8d).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF169a8d)),
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
                    (_products[productIndex]['newImages'] as List<XFile>).add(
                      file,
                    );
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

  Future<void> _updateLinkedJobCard(
    List<Map<String, dynamic>> productsData,
    Map<String, dynamic> sections,
    List<Map<String, dynamic>> partialDispatchesData,
  ) async {
    final snap = await FirebaseFirestore.instance
        .collection('jobCards')
        .where('linkedOrderId', isEqualTo: widget.orderId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    final jobDoc = snap.docs.first;

    await FirebaseFirestore.instance
        .collection('jobCards')
        .doc(jobDoc.id)
        .update({
          'customerName': _customerController.text.trim(), // ✅ ADD THIS
          'products': productsData,
          'sections': sections,
          'partialDispatches': partialDispatchesData,
          'priority': _priority,
          'salesPerson': _selectedSalesPerson == 'Others'
              ? _customSalesPerson
              : _selectedSalesPerson,
          'location': _locationController.text.trim(),
          'date': _orderDate, // ✅ ADD

          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Process products with image uploads
      List<Map<String, dynamic>> productsData = [];

      for (int i = 0; i < _products.length; i++) {
        final product = _products[i];
        final nameController =
            product['nameController'] as TextEditingController;
        final quantityController =
            product['quantityController'] as TextEditingController;
        final sizeController =
            product['sizeController'] as TextEditingController;
              final priceController =
      product['priceController'] as TextEditingController; 
        final existingImages = List<String>.from(product['images'] as List);
        final newImages = product['newImages'] as List<XFile>;
        final remarkController =
            product['remarkController'] as TextEditingController;

        // Upload new images
        List<String> newImageUrls = [];
        for (final image in newImages) {
          final ref = FirebaseStorage.instance.ref().child(
            'sales_orders/${widget.orderId}/product_$i/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            await ref.putData(
              bytes,
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else {
            await ref.putFile(File(image.path));
          }
          newImageUrls.add(await ref.getDownloadURL());
        }

        // Combine existing and new images
        final allImages = [...existingImages, ...newImageUrls];

        productsData.add({
          'productName': nameController.text.trim(),
          'quantity': int.tryParse(quantityController.text.trim()) ?? 0,
          'size': sizeController.text.trim(),
            'price': double.tryParse(priceController.text.trim()) ?? 0, // ✅ ADD
          'remarks': remarkController.text.trim(), // ✅ ADD THIS
          'images': allImages,
        });
      }

      // Process partial dispatches
      List<Map<String, dynamic>> partialDispatchesData = [];
      for (var dispatch in _partialDispatches) {
        final name = (dispatch['nameController'] as TextEditingController).text
            .trim();
        final qty = (dispatch['qtyController'] as TextEditingController).text
            .trim();
        final dateStr = (dispatch['dateController'] as TextEditingController)
            .text
            .trim();

        if (name.isNotEmpty || qty.isNotEmpty || dateStr.isNotEmpty) {
          partialDispatchesData.add({
            'name': name,
            'quantity': int.tryParse(qty) ?? 0, // ✅ FIX
            'date': dateStr,
            'timestamp': dispatch['selectedDate'],
          });
        }
      }
      final Map<String, dynamic> sections = {};

      if (_sectionSelected['Tray'] == true) {
        sections['tray'] = _trayController.text.trim();
      }
      if (_sectionSelected['Salophin'] == true) {
        sections['salophin'] = _salophinController.text.trim();
      }
      if (_sectionSelected['Box Cover'] == true) {
        sections['boxCover'] = _boxCoverController.text.trim();
      }
      if (_sectionSelected['Inner'] == true) {
        sections['inner'] = _innerController.text.trim();
      }
      if (_sectionSelected['Bottom'] == true) {
        sections['bottom'] = _bottomController.text.trim();
      }
      if (_sectionSelected['Die'] == true) {
        sections['die'] = _dieController.text.trim();
      }
      if (_sectionSelected['Others'] == true) {
        sections['other'] = _otherController.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'customerName': _customerController.text.trim(),
            'companyName': _companyController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'location': _locationController.text.trim(),
            'unit': _selectedUnit,
            'productCategory': _selectedProductCategory,
            'orderDate': _orderDate,
            'deliveryDate': _deliveryDate,
            'priority': _priority,
            'salesPerson': _selectedSalesPerson == 'Others'
                ? _customSalesPerson
                : _selectedSalesPerson,
            'sections': sections,
            'products': productsData,
          //  'partialDispatches': partialDispatchesData,
            'notes': _notesController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _updateLinkedJobCard(productsData, sections, partialDispatchesData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Sales Order updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Edit Sales Order',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF169a8d),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF169a8d), Color(0xFF8E24AA)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF169a8d).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.edit, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Text(
                    'Edit Sales Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customer Details
            _buildSection(
              title: 'Customer Details',
              icon: Icons.person_outline,
              children: [
                _buildTextField(
                  controller: _customerController,
                  label: 'Customer Name',
                  icon: Icons.person,
                  validator: _req,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Order Location & Category',
              icon: Icons.location_on,
              children: [
                // ✅ ORDER LOCATION (UNIT)
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Order Location (Unit)',
                    prefixIcon: const Icon(Icons.factory_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _units
                      .map(
                        (u) =>
                            DropdownMenuItem<String>(value: u, child: Text(u)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v!),
                  validator: (v) => v == null ? 'Select unit' : null,
                ),

                const SizedBox(height: 16),

                // ✅ PRODUCT CATEGORY
                DropdownButtonFormField<String>(
                  value: _selectedProductCategory,
                  decoration: InputDecoration(
                    labelText: 'Product Category',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _productCategories
                      .map(
                        (c) =>
                            DropdownMenuItem<String>(value: c, child: Text(c)),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedProductCategory = v!),
                  validator: (v) => v == null ? 'Select category' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Products Section
            _buildSection(
              title: 'Products',
              icon: Icons.inventory_2,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final nameController =
                        product['nameController'] as TextEditingController;
                    final quantityController =
                        product['quantityController'] as TextEditingController;
                    final sizeController =
                        product['sizeController'] as TextEditingController;
                    final priceController =
                        product['priceController'] as TextEditingController;
                    final remarkController =
                        product['remarkController'] as TextEditingController;
                    final existingImages = product['images'] as List<String>;
                    final newImages = product['newImages'] as List<XFile>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Product ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (_products.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeProduct(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: nameController,
                            label: 'Product Name',
                            icon: Icons.shopping_bag,
                            validator: _req,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: quantityController,
                                  label: 'Quantity',
                                  icon: Icons.numbers,
                                  keyboardType: TextInputType.number,
                                  validator: _req,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: sizeController,
                                  label: 'Size',
                                  icon: Icons.straighten,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: priceController,
                            label: 'Price',
                            icon: Icons.shopping_cart_outlined,
                            keyboardType: TextInputType.number,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 12),

                          _buildTextField(
                            controller: remarkController,
                            label: 'Product Remark',
                            icon: Icons.comment_outlined,
                            maxLines: 1,
                          ),

                          const SizedBox(height: 12),
                          const Text(
                            'Product Images',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildProductImagesGrid(
                            index,
                            existingImages,
                            newImages,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Product'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF169a8d),
                    side: const BorderSide(color: Color(0xFF169a8d)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Packaging Sections',
              icon: Icons.dashboard_customize,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _sectionSelected.keys.map((key) {
                    return FilterChip(
                      label: Text(key),
                      selected: _sectionSelected[key]!,
                      onSelected: (val) {
                        setState(() {
                          _sectionSelected[key] = val;
                        });
                      },
                      selectedColor: Colors.teal.shade200,
                    );
                  }).toList(),
                ),

                // 🔽 Conditional Fields
                if (_sectionSelected['Tray'] == true) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _trayController,
                    label: 'Tray Details',
                    icon: Icons.view_agenda,
                  ),
                ],
                if (_sectionSelected['Salophin'] == true) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _salophinController,
                    label: 'Salophin Details',
                    icon: Icons.layers,
                  ),
                ],
                if (_sectionSelected['Box Cover'] == true) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _boxCoverController,
                    label: 'Box Cover Details',
                    icon: Icons.cases_outlined,
                  ),
                ],
                if (_sectionSelected['Inner'] == true) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _innerController,
                    label: 'Inner Details',
                    icon: Icons.table_rows,
                  ),
                ],
                if (_sectionSelected['Bottom'] == true) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bottomController,
                    label: 'Bottom Details',
                    icon: Icons.align_vertical_bottom,
                  ),
                ],
                if (_sectionSelected['Die'] == true) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _dieController,
                    label: 'Die Details',
                    icon: Icons.cut,
                  ),
                ],
                if (_sectionSelected['Others'] == true) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _otherController,
                    label: 'Other Details',
                    icon: Icons.more_horiz,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Sales Person
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
                  const SizedBox(height: 10),
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
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) =>
                        setState(() => _customSalesPerson = val),
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

            // // Partial Dispatch
            // _buildSection(
            //   title: 'Partially Dispatch of Quantity (if any)',
            //   icon: Icons.local_shipping_outlined,
            //   children: [
            //     ListView.builder(
            //       shrinkWrap: true,
            //       physics: const NeverScrollableScrollPhysics(),
            //       itemCount: _partialDispatches.length,
            //       itemBuilder: (context, index) {
            //         final dispatch = _partialDispatches[index];
            //         final nameController =
            //             dispatch['nameController'] as TextEditingController;
            //         final qtyController =
            //             dispatch['qtyController'] as TextEditingController;
            //         final dateController =
            //             dispatch['dateController'] as TextEditingController;

            //         return Container(
            //           margin: const EdgeInsets.only(bottom: 16),
            //           padding: const EdgeInsets.all(16),
            //           decoration: BoxDecoration(
            //             color: Colors.orange[50],
            //             borderRadius: BorderRadius.circular(12),
            //             border: Border.all(color: Colors.orange.shade200),
            //           ),
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Row(
            //                 children: [
            //                   Expanded(
            //                     child: Text(
            //                       'Dispatch ${index + 1}',
            //                       style: const TextStyle(
            //                         fontWeight: FontWeight.bold,
            //                         fontSize: 16,
            //                         color: Colors.orange,
            //                       ),
            //                     ),
            //                   ),
            //                   if (_partialDispatches.length > 1)
            //                     IconButton(
            //                       icon: const Icon(
            //                         Icons.delete,
            //                         color: Colors.red,
            //                       ),
            //                       onPressed: () =>
            //                           _removePartialDispatch(index),
            //                     ),
            //                 ],
            //               ),
            //               const SizedBox(height: 12),
            //               _buildTextField(
            //                 controller: nameController,
            //                 label: 'Dispatch Name',
            //                 icon: Icons.person_outline,
            //               ),
            //               const SizedBox(height: 12),
            //               _buildTextField(
            //                 controller: qtyController,
            //                 label: 'Dispatch Quantity',
            //                 icon: Icons.confirmation_number_outlined,
            //                 keyboardType: TextInputType.number,
            //                 inputFormatters: [
            //                   FilteringTextInputFormatter.digitsOnly,
            //                 ],
            //               ),
            //               const SizedBox(height: 12),
            //               TextFormField(
            //                 controller: dateController,
            //                 readOnly: true,
            //                 decoration: InputDecoration(
            //                   labelText: 'Dispatch Date',
            //                   prefixIcon: const Icon(
            //                     Icons.calendar_today,
            //                     color: Color(0xFF169a8d),
            //                   ),
            //                   border: OutlineInputBorder(
            //                     borderRadius: BorderRadius.circular(12),
            //                   ),
            //                   filled: true,
            //                   fillColor: Colors.white,
            //                 ),
            //                 onTap: () async {
            //                   final picked = await showDatePicker(
            //                     context: context,
            //                     initialDate: DateTime.now(),
            //                     firstDate: DateTime(2020),
            //                     lastDate: DateTime(2035),
            //                   );
            //                   if (picked != null) {
            //                     dateController.text =
            //                         '${picked.day}/${picked.month}/${picked.year}';
            //                     dispatch['selectedDate'] = picked;
            //                   }
            //                 },
            //               ),
            //             ],
            //           ),
            //         );
            //       },
            //     ),
            //     const SizedBox(height: 12),
            //     OutlinedButton.icon(
            //       onPressed: _addPartialDispatch,
            //       icon: const Icon(Icons.add),
            //       label: const Text('Add Another Dispatch'),
            //       style: OutlinedButton.styleFrom(
            //         foregroundColor: Colors.orange,
            //         side: const BorderSide(color: Colors.orange),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         padding: const EdgeInsets.symmetric(vertical: 12),
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 20),

            // Date & Priority
            _buildSection(
              title: 'Schedule & Priority',
              icon: Icons.schedule,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _orderDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null)
                            setState(() => _orderDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF169a8d),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_orderDate.day}/${_orderDate.month}/${_orderDate.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _deliveryDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null)
                            setState(() => _deliveryDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_shipping,
                                    color: Color(0xFF169a8d),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
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
                const SizedBox(height: 16),
              ],
            ),
            const SizedBox(height: 20),

            // Notes
            _buildSection(
              title: 'Additional Notes',
              icon: Icons.note_outlined,
              children: [
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  icon: Icons.notes,
                  maxLines: 1,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF169a8d),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 30),
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
            Icon(icon, color: const Color(0xFF169a8d)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
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
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF169a8d)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF169a8d), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildProductImagesGrid(
    int productIndex,
    List<String> existingImages,
    List<XFile> newImages,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Existing images from server
        ...existingImages.map(
          (url) => Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.network(url, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => setState(() => existingImages.remove(url)),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        // New images selected
        ...newImages.map(
          (x) => Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: kIsWeb
                      ? Image.network(x.path, fit: BoxFit.cover)
                      : Image.file(File(x.path), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => setState(() => newImages.remove(x)),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Add button
        GestureDetector(
          onTap: () => _chooseImageForProduct(productIndex),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF169a8d).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF169a8d), width: 2),
            ),
            child: const Icon(
              Icons.add_a_photo,
              size: 40,
              color: Color(0xFF169a8d),
            ),
          ),
        ),
      ],
    );
  }

  String? _req(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;

  @override
  void dispose() {
    _customerController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _otherSalesPersonController.dispose();
    for (var product in _products) {
      (product['nameController'] as TextEditingController).dispose();
      (product['quantityController'] as TextEditingController).dispose();
      (product['sizeController'] as TextEditingController).dispose();
      (product['priceController'] as TextEditingController).dispose();
      (product['remarkController'] as TextEditingController).dispose(); // ✅
    }
    for (var dispatch in _partialDispatches) {
      (dispatch['nameController'] as TextEditingController).dispose();
      (dispatch['qtyController'] as TextEditingController).dispose();
      (dispatch['dateController'] as TextEditingController).dispose();
    }

    super.dispose();
  }
}
