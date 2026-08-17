import 'package:dimple_erp/all%20screen/SelectSalesOrderTab.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:flutter/services.dart';

class JobCardScreen extends StatefulWidget {
  const JobCardScreen({super.key});

  @override
  State<JobCardScreen> createState() => _JobCardScreenState();
}

class _JobCardScreenState extends State<JobCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF169a8d),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/dpl.png', height: 32),
            const SizedBox(width: 10),
            const Text(
              'Created Job Card',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SelectSalesOrderTab(),
          // JobCardHistoryTab(),
        ],
      ),
    );
  }
}

class CreateJobCardTab extends StatefulWidget {
  const CreateJobCardTab({super.key});

  @override
  State<CreateJobCardTab> createState() => _CreateJobCardTabState();
}

class _CreateJobCardTabState extends State<CreateJobCardTab> {
  final _formKey = GlobalKey<FormState>();

  // Core fields
  final _jobNoController = TextEditingController();
  final _customerController = TextEditingController();
  final _locationController = TextEditingController();

  // Section controllers
  final _trayController = TextEditingController();
  final _salophinController = TextEditingController();
  final _boxCoverController = TextEditingController();
  final _innerController = TextEditingController();
  final _bottomController = TextEditingController();
  final _dieController = TextEditingController();
  final _otherController = TextEditingController();

  final _extraInstructionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  // 🔥 Price controllers for each section
  final _trayPriceController = TextEditingController();
  final _salophinPriceController = TextEditingController();
  final _boxCoverPriceController = TextEditingController();
  final _innerPriceController = TextEditingController();
  final _bottomPriceController = TextEditingController();
  final _diePriceController = TextEditingController();
  final _otherPriceController = TextEditingController();

  String _priority = 'High';
  bool _isSaving = false;
  String? _selectedSalesPerson;
  String? _customSalesPerson;

  // 🔥 Product List - Each product has name, quantity, price and images
  final List<Map<String, dynamic>> _products = [
    {
      'nameController': TextEditingController(),
      'quantityController': TextEditingController(),
      'priceController': TextEditingController(),
      'images': <XFile>[],
    },
  ];

  // 🔥 Partial Dispatch List - Dynamic fields
  final List<Map<String, dynamic>> _partialDispatches = [
    {
      'nameController': TextEditingController(),
      'qtyController': TextEditingController(),
      'dateController': TextEditingController(),
      'selectedDate': null,
    },
  ];

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
  final Map<String, bool> _sectionSelected = {
    'Tray': false,
    'Salophin': false,
    'Box Cover': false,
    'Inner': false,
    'Bottom': false,
    'Die': false,
    'Others': false,
  };

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  // 🔥 Add new product
  void _addProduct() {
    setState(() {
      _products.add({
        'nameController': TextEditingController(),
        'quantityController': TextEditingController(),
        'priceController': TextEditingController(),
        'images': <XFile>[],
      });
    });
  }

  // 🔥 Remove product
  void _removeProduct(int index) {
    if (_products.length > 1) {
      setState(() {
        _products[index]['nameController'].dispose();
        _products[index]['quantityController'].dispose();
        _products[index]['priceController'].dispose();
        _products.removeAt(index);
      });
    }
  }

  // 🔥 Add new partial dispatch
  void _addPartialDispatch() {
    setState(() {
      _partialDispatches.add({
        'nameController': TextEditingController(),
        'qtyController': TextEditingController(),
        'dateController': TextEditingController(),
        'selectedDate': null,
      });
    });
  }

  // 🔥 Remove partial dispatch
  void _removePartialDispatch(int index) {
    if (_partialDispatches.length > 1) {
      setState(() {
        _partialDispatches[index]['nameController'].dispose();
        _partialDispatches[index]['qtyController'].dispose();
        _partialDispatches[index]['dateController'].dispose();
        _partialDispatches.removeAt(index);
      });
    }
  }

  // 🔥 Choose image for specific product
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
                    (_products[productIndex]['images'] as List<XFile>).addAll(
                      files,
                    );
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
                    (_products[productIndex]['images'] as List<XFile>).add(
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

  // 🔥🔥🔥 TOTAL CALCULATION (Products price*qty + all selected section prices)
  double _calculateProductsTotal() {
    double total = 0;
    for (var product in _products) {
      final qty = int.tryParse(
            (product['quantityController'] as TextEditingController)
                .text
                .trim(),
          ) ??
          0;
      final price = double.tryParse(
            (product['priceController'] as TextEditingController)
                .text
                .trim(),
          ) ??
          0;
      total += qty * price;
    }
    return total;
  }

  double _calculateSectionsTotal() {
    double total = 0;
    if (_sectionSelected['Tray'] == true) {
      total += double.tryParse(_trayPriceController.text.trim()) ?? 0;
    }
    if (_sectionSelected['Salophin'] == true) {
      total += double.tryParse(_salophinPriceController.text.trim()) ?? 0;
    }
    if (_sectionSelected['Box Cover'] == true) {
      total += double.tryParse(_boxCoverPriceController.text.trim()) ?? 0;
    }
    if (_sectionSelected['Inner'] == true) {
      total += double.tryParse(_innerPriceController.text.trim()) ?? 0;
    }
    if (_sectionSelected['Bottom'] == true) {
      total += double.tryParse(_bottomPriceController.text.trim()) ?? 0;
    }
    if (_sectionSelected['Die'] == true) {
      total += double.tryParse(_diePriceController.text.trim()) ?? 0;
    }
    if (_sectionSelected['Others'] == true) {
      total += double.tryParse(_otherPriceController.text.trim()) ?? 0;
    }
    return total;
  }

  double _calculateGrandTotal() {
    return _calculateProductsTotal() + _calculateSectionsTotal();
  }

  Future<void> _saveJobCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Generate job number
      String jobNo = '';
      final counterRef = FirebaseFirestore.instance
          .collection('meta')
          .doc('jobCardCounter');

      DocumentSnapshot snap = await counterRef.get();

      int newNo = 1;

      if (snap.exists && snap.data() != null) {
        final data = snap.data() as Map<String, dynamic>;
        if (data.containsKey('last') && data['last'] is int) {
          newNo = data['last'] + 1;
        }
      }

      await counterRef.set({'last': newNo}, SetOptions(merge: true));

      jobNo = 'DPL$newNo';

      // 🔥 Process products with images
      List<Map<String, dynamic>> productsData = [];

      for (int i = 0; i < _products.length; i++) {
        final product = _products[i];
        final nameController =
            product['nameController'] as TextEditingController;
        final quantityController =
            product['quantityController'] as TextEditingController;
        final priceController =
            product['priceController'] as TextEditingController;
        final images = product['images'] as List<XFile>;

        // Upload images for this product
        List<String> imageUrls = [];
        for (final image in images) {
          final ref = FirebaseStorage.instance.ref().child(
            'job_cards/$jobNo/product_$i/${DateTime.now().millisecondsSinceEpoch}.jpg',
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
          imageUrls.add(await ref.getDownloadURL());
        }

        final qty = int.tryParse(quantityController.text.trim()) ?? 0;
        final price = double.tryParse(priceController.text.trim()) ?? 0;

        // Add product data
        productsData.add({
          'name': nameController.text.trim(),
          'quantity': qty, // ✅ INT
          'price': price, // ✅ DOUBLE
          'amount': qty * price, // ✅ qty * price
          'images': imageUrls,
        });
      }

      // 🔥 Process partial dispatches
      List<Map<String, dynamic>> partialDispatchesData = [];
      for (var dispatch in _partialDispatches) {
        final name = (dispatch['nameController'] as TextEditingController).text
            .trim();
        final qty = (dispatch['qtyController'] as TextEditingController).text
            .trim();
        final dateStr = (dispatch['dateController'] as TextEditingController)
            .text
            .trim();

        // Only add if at least one field is filled
        if (name.isNotEmpty || qty.isNotEmpty || dateStr.isNotEmpty) {
          partialDispatchesData.add({
            'name': name,
            'quantity': qty,
            'date': dateStr,
            'timestamp': dispatch['selectedDate'] != null
                ? Timestamp.fromDate(dispatch['selectedDate'])
                : null,
          });
        }
      }

      final Map<String, dynamic> sections = {};

      if (_sectionSelected['Tray'] == true) {
        sections['tray'] = {
          'details': _trayController.text.trim(),
          'price': double.tryParse(_trayPriceController.text.trim()) ?? 0,
        };
      }
      if (_sectionSelected['Salophin'] == true) {
        sections['salophin'] = {
          'details': _salophinController.text.trim(),
          'price':
              double.tryParse(_salophinPriceController.text.trim()) ?? 0,
        };
      }
      if (_sectionSelected['Box Cover'] == true) {
        sections['boxCover'] = {
          'details': _boxCoverController.text.trim(),
          'price':
              double.tryParse(_boxCoverPriceController.text.trim()) ?? 0,
        };
      }
      if (_sectionSelected['Inner'] == true) {
        sections['inner'] = {
          'details': _innerController.text.trim(),
          'price': double.tryParse(_innerPriceController.text.trim()) ?? 0,
        };
      }
      if (_sectionSelected['Bottom'] == true) {
        sections['bottom'] = {
          'details': _bottomController.text.trim(),
          'price': double.tryParse(_bottomPriceController.text.trim()) ?? 0,
        };
      }
      if (_sectionSelected['Die'] == true) {
        sections['die'] = {
          'details': _dieController.text.trim(),
          'price': double.tryParse(_diePriceController.text.trim()) ?? 0,
        };
      }
      if (_sectionSelected['Others'] == true) {
        sections['other'] = {
          'details': _otherController.text.trim(),
          'price': double.tryParse(_otherPriceController.text.trim()) ?? 0,
        };
      }

      final productsTotal = _calculateProductsTotal();
      final sectionsTotal = _calculateSectionsTotal();
      final grandTotal = productsTotal + sectionsTotal;

      await FirebaseFirestore.instance.collection('jobCards').doc(jobNo).set({
        'jobNo': jobNo,
        'date': Timestamp.fromDate(_selectedDate),
        'priority': _priority,
        'customer': _customerController.text.trim(),
        'salesPerson': _selectedSalesPerson == 'Others'
            ? (_customSalesPerson ?? '')
            : (_selectedSalesPerson ?? ''),
        'products': productsData,
        'location': _locationController.text.trim(),
        'sections': sections,
        'extraInstruction': _extraInstructionController.text.trim(),
        'partialDispatches':
            partialDispatchesData, // 🔥 Save partial dispatches
        'productsTotal': productsTotal, // 🔥 sum of qty*price of products
        'sectionsTotal': sectionsTotal, // 🔥 sum of selected section prices
        'totalAmount': grandTotal, // 🔥 grand total
        'status': 'Pending',
        'deliveryDate': 'deliveryDate',
        'unit': 'unit',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'manual',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job Card created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.assignment, color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Text(
                      'New Job Card',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Job Number',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Auto-generated',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Basic Details
          _buildSection(
            title: 'Basic Details',
            icon: Icons.info_outline,
            children: [
              _buildTextField(
                controller: _customerController,
                label: 'Customer / Company Name',
                icon: Icons.business,
                validator: _req,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.straighten,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 🔥 Products Section
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
                  final priceController =
                      product['priceController'] as TextEditingController;
                  final images = product['images'] as List<XFile>;

                  final qty = int.tryParse(quantityController.text.trim()) ?? 0;
                  final price = double.tryParse(priceController.text.trim()) ?? 0;
                  final productAmount = qty * price;

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
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPriceField(
                                controller: priceController,
                                label: 'Price (per unit)',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Amount: ₹${productAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF169a8d),
                            ),
                          ),
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
                        _buildProductImagesGrid(index, images),
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

          // 🔥 Partial Dispatch Section
          _buildSection(
            title: 'Partially Dispatch of Quantity(if any)',
            icon: Icons.local_shipping_outlined,
            children: [
              const Text(
                'Add multiple partial dispatches if needed',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _partialDispatches.length,
                itemBuilder: (context, index) {
                  final dispatch = _partialDispatches[index];
                  final nameController =
                      dispatch['nameController'] as TextEditingController;
                  final qtyController =
                      dispatch['qtyController'] as TextEditingController;
                  final dateController =
                      dispatch['dateController'] as TextEditingController;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Dispatch ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            if (_partialDispatches.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removePartialDispatch(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: nameController,
                          label: 'Dispatch Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: qtyController,
                          label: 'Dispatch Quantity',
                          icon: Icons.confirmation_number_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Dispatch Date',
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF169a8d),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF169a8d),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF169a8d),
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              dateController.text =
                                  '${picked.day}/${picked.month}/${picked.year}';
                              dispatch['selectedDate'] = picked;
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addPartialDispatch,
                icon: const Icon(Icons.add),
                label: const Text('Add Another Dispatch'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Date & Priority
          _buildSection(
            title: 'Schedule & Priority',
            icon: Icons.schedule,
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF169a8d),
                        ),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF169a8d),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: ['Low', 'High', 'Urgent'].map((p) {
                  final selected = _priority == p;
                  final color = p == 'Low'
                      ? Colors.green
                      : p == 'High'
                      ? Colors.orange
                      : Colors.red;
                  return GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? color : const Color(0xFFE0E0E0),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sections
          _buildSection(
            title: 'Production Sections',
            icon: Icons.layers_outlined,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _sectionSelected.keys.map((k) {
                  final sel = _sectionSelected[k]!;
                  return GestureDetector(
                    onTap: () => setState(() => _sectionSelected[k] = !sel),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF169a8d) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF169a8d)
                              : const Color(0xFFE0E0E0),
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel)
                            const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            ),
                          if (sel) const SizedBox(width: 6),
                          Text(
                            k,
                            style: TextStyle(
                              color: sel ? Colors.white : Colors.black87,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w500,
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

          // Conditional Fields — ab har section me Details + Price dono
          if (_sectionSelected['Tray'] == true) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _trayController,
              label: 'Tray Details',
              icon: Icons.view_agenda,
            ),
            const SizedBox(height: 12),
            _buildPriceField(
              controller: _trayPriceController,
              label: 'Tray Price',
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_sectionSelected['Salophin'] == true) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _salophinController,
              label: 'Salophin Details',
              icon: Icons.layers,
            ),
            const SizedBox(height: 12),
            _buildPriceField(
              controller: _salophinPriceController,
              label: 'Salophin Price',
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_sectionSelected['Box Cover'] == true) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _boxCoverController,
              label: 'Box Cover Details',
              icon: Icons.cases_outlined,
            ),
            const SizedBox(height: 12),
            _buildPriceField(
              controller: _boxCoverPriceController,
              label: 'Box Cover Price',
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_sectionSelected['Inner'] == true) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _innerController,
              label: 'Inner Details',
              icon: Icons.table_rows,
            ),
            const SizedBox(height: 12),
            _buildPriceField(
              controller: _innerPriceController,
              label: 'Inner Price',
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_sectionSelected['Bottom'] == true) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bottomController,
              label: 'Bottom Details',
              icon: Icons.align_vertical_bottom,
            ),
            const SizedBox(height: 12),
            _buildPriceField(
              controller: _bottomPriceController,
              label: 'Bottom Price',
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_sectionSelected['Die'] == true) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _dieController,
              label: 'Die ',
              icon: Icons.align_vertical_bottom,
            ),
            const SizedBox(height: 12),
            _buildPriceField(
              controller: _diePriceController,
              label: 'Die Price',
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_sectionSelected['Others'] == true) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _otherController,
              label: 'Other Details',
              icon: Icons.align_vertical_bottom,
            ),
            const SizedBox(height: 12),
            _buildPriceField(
              controller: _otherPriceController,
              label: 'Other Price',
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 20),

          // Extra Instructions
          _buildSection(
            title: 'Additional Instructions',
            icon: Icons.note_outlined,
            children: [
              _buildTextField(
                controller: _extraInstructionController,
                label: 'Extra Instructions (Optional)',
                icon: Icons.notes,
                maxLines: 4,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 🔥🔥🔥 TOTAL AMOUNT CARD — Products + Sections ka grand total
          _buildTotalAmountCard(),

          const SizedBox(height: 32),

          // Save Button
          ElevatedButton(
            onPressed: _isSaving ? null : _saveJobCard,
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
                    'Save Job Card',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // 🔥 Total Amount Card — Products total + Sections total + Grand total
  Widget _buildTotalAmountCard() {
    final productsTotal = _calculateProductsTotal();
    final sectionsTotal = _calculateSectionsTotal();
    final grandTotal = productsTotal + sectionsTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF169a8d).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF169a8d), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calculate_outlined, color: Color(0xFF169a8d)),
              SizedBox(width: 10),
              Text(
                'Total Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _totalRow('Products Total', productsTotal),
          const SizedBox(height: 6),
          _totalRow('Sections Total (Tray/Bottom/Other/etc.)', sectionsTotal),
          const Divider(height: 24, thickness: 1),
          _totalRow('Grand Total', grandTotal, isGrand: true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool isGrand = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrand ? 16 : 14,
            fontWeight: isGrand ? FontWeight.bold : FontWeight.w500,
            color: isGrand ? const Color(0xFF169a8d) : Colors.black87,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isGrand ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isGrand ? const Color(0xFF169a8d) : Colors.black87,
          ),
        ),
      ],
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
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
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

  // 🔥 Reusable Price Field (₹) — used for products + all sections
  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF169a8d)),
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
    );
  }

  // 🔥 Product Images Grid
  Widget _buildProductImagesGrid(int productIndex, List<XFile> images) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...images.map(
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
                  onTap: () => setState(() => images.remove(x)),
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
    _jobNoController.dispose();
    _customerController.dispose();
    _locationController.dispose();
    _trayController.dispose();
    _salophinController.dispose();
    _boxCoverController.dispose();
    _innerController.dispose();
    _bottomController.dispose();
    _dieController.dispose();
    _otherController.dispose();
    _extraInstructionController.dispose();
    _otherSalesPersonController.dispose();

    // Dispose section price controllers
    _trayPriceController.dispose();
    _salophinPriceController.dispose();
    _boxCoverPriceController.dispose();
    _innerPriceController.dispose();
    _bottomPriceController.dispose();
    _diePriceController.dispose();
    _otherPriceController.dispose();

    // Dispose product controllers
    for (var product in _products) {
      (product['nameController'] as TextEditingController).dispose();
      (product['quantityController'] as TextEditingController).dispose();
      (product['priceController'] as TextEditingController).dispose();
    }
    for (var dispatch in _partialDispatches) {
      (dispatch['nameController'] as TextEditingController).dispose();
      (dispatch['qtyController'] as TextEditingController).dispose();
      (dispatch['dateController'] as TextEditingController).dispose();
    }

    super.dispose();
  }
}