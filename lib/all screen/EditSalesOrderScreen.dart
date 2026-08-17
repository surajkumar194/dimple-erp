import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

String _hsnForCategory(String? category) {
  if (category == 'MDF') return '44111200';
  if (category == 'Laddu Paper') return '48062000';
  return '48192090';
}

double _gstPctForCategory(String? category) {
  if (category == 'MDF') return 18.0;
  if (category == 'Laddu Paper') return 18.0;
  return 5.0;
}

class AppColors {
  static const Color primary = Color(0xFF169a8d);
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFFFFA500);
  static const Color success = Color(0xFF2ECC71);
  static const Color info = Color(0xFF3498DB);
  static const Color warning = Color(0xFFE74C3C);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF2C3E50);

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient successGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

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

class _EditSalesOrderScreenState extends State<EditSalesOrderScreen>
    with SingleTickerProviderStateMixin {
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
  final ImagePicker _picker = ImagePicker();
  String _selectedUnit = 'Unit 1';
  String? _dispatchType;
  final List<String> _dispatchOptions = ['Transport', 'Vehicle'];
  late AnimationController _animationController;
  final List<String> _units = [
    'Unit 1',
    'Unit 2',
    'Meena Bazar',
    'College Road',
  ];
  bool _showPartialDispatch = false;

  // ─── UPDATED: Added Laddu Paper ───────────────────────────────────────────
  final List<String> _productCategories = [
    'MDF',
    'Kappa Box (Gora)',
    'Packaging',
    'Shagun Envelope',
    'Rigid Box (unit 2 Hussainpura)',
    'Laddu Paper',
    'Others',
  ];

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

  void _openFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                child: const Icon(Icons.download, color: Colors.black),
                onPressed: () => downloadImage(imageUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> downloadImage(String url) async {
    try {
      if (kIsWeb) {
        await launchUrl(Uri.parse(url));
      } else {
        var status = await Permission.storage.request();
        if (!status.isGranted) return;
        final response = await http.get(Uri.parse(url));
        final result = await ImageGallerySaver.saveImage(
          response.bodyBytes,
          quality: 100,
          name: "ERP_${DateTime.now().millisecondsSinceEpoch}",
        );
        debugPrint("Saved: $result");
      }
    } catch (e) {
      debugPrint("Download error: $e");
    }
  }

  Map<String, String> _splitQuantityAndRemark(String input) {
    final number = RegExp(r'\d+').stringMatch(input) ?? '';
    final text = input.replaceAll(RegExp(r'\d+'), '').trim();
    return {'qty': number, 'remark': text};
  }

  bool hasValue(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is num) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _dispatchType = widget.orderData['dispatchType'];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

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

    final savedSalesPerson = widget.orderData['salesPerson'];
    if (_salesPersons.contains(savedSalesPerson)) {
      _selectedSalesPerson = savedSalesPerson;
      _customSalesPerson = null;
    } else if (savedSalesPerson != null &&
        savedSalesPerson.toString().isNotEmpty) {
      _selectedSalesPerson = 'Others';
      _customSalesPerson = savedSalesPerson;
      _otherSalesPersonController.text = savedSalesPerson;
    } else {
      _selectedSalesPerson = null;
    }

    _selectedUnit = widget.orderData['unit'] ?? 'Unit 1';

    final rawProducts = widget.orderData['products'];
    List productsList = [];
    if (rawProducts is List) {
      productsList = rawProducts;
    } else if (rawProducts is Map) {
      productsList = [rawProducts];
    }

    _products = productsList.map((p) {
      final sections = p['sections'] as Map<String, dynamic>? ?? {};
      final extraSections = p['customExtraSections'] as List? ?? [];
      final rawQty = safeText(p['quantity']);
      final split = _splitQuantityAndRemark(rawQty);
      final category = p['productCategory'] ?? p['category'] ?? 'MDF';

      // ── Load saved gstPercent or derive from category ─────────────────
      final savedGst = p['gstPercent'];
      final double gstPct = savedGst != null
          ? (savedGst as num).toDouble()
          : _gstPctForCategory(category);

      // ── Load saved hsnCode or derive from category ────────────────────
      final String hsnCode = (p['hsnCode']?.toString().isNotEmpty == true)
          ? p['hsnCode'].toString()
          : _hsnForCategory(category);

      return {
        'id': p['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'sections': sections,
        'category': category,
        'gstPercent': gstPct,
        'hsnCode': hsnCode,
        'nameController': TextEditingController(text: p['productName'] ?? ''),
        'quantityController': TextEditingController(text: split['qty']),
        'remarkController': TextEditingController(
          text: (p['remarks']?.toString().isNotEmpty == true)
              ? p['remarks']
              : split['remark'],
        ),
        'lengthController': TextEditingController(text: p['length'] ?? ''),
        'heightController': TextEditingController(text: p['height'] ?? ''),
        'widthController': TextEditingController(text: p['width'] ?? ''),
        'priceController': TextEditingController(text: safeText(p['price'])),
        'productCategory': category,
        'images': List<String>.from(p['images'] ?? []),
        'newImages': <XFile>[],
        'sectionSelected': {
          'Tray':
              hasValue(sections['trayDetail']) ||
              hasValue(sections['trayQty']) ||
              hasValue(sections['trayPrice']) ||
              hasValue(sections['tray']),
          'Salophin':
              hasValue(sections['salophinDetail']) ||
              hasValue(sections['salophinQty']) ||
              hasValue(sections['salophinPrice']) ||
              hasValue(sections['salophin']),
          'Box Cover':
              hasValue(sections['boxCoverDetail']) ||
              hasValue(sections['boxCoverQty']) ||
              hasValue(sections['boxCoverPrice']) ||
              hasValue(sections['boxCover']),
          'Inner':
              hasValue(sections['innerDetail']) ||
              hasValue(sections['innerQty']) ||
              hasValue(sections['innerPrice']) ||
              hasValue(sections['inner']),
          'Bottom':
              hasValue(sections['bottomDetail']) ||
              hasValue(sections['bottomQty']) ||
              hasValue(sections['bottomPrice']) ||
              hasValue(sections['bottom']),
          'Die':
              hasValue(sections['dieDetail']) ||
              hasValue(sections['dieQty']) ||
              hasValue(sections['diePrice']) ||
              hasValue(sections['die']),
          'Others':
              hasValue(sections['otherDetail']) ||
              hasValue(sections['otherQty']) ||
              hasValue(sections['otherPrice']) ||
              extraSections.isNotEmpty,
        },
        'trayDetailController': TextEditingController(
          text: sections['trayDetail'] ?? sections['tray'] ?? '',
        ),
        'trayQtyController': TextEditingController(
          text: sections['trayQty']?.toString() ?? '',
        ),
        'trayPriceController': TextEditingController(
          text: sections['trayPrice'] ?? '',
        ),
        'salophinDetailController': TextEditingController(
          text: sections['salophinDetail'] ?? sections['salophin'] ?? '',
        ),
        'salophinQtyController': TextEditingController(
          text: sections['salophinQty']?.toString() ?? '',
        ),
        'salophinPriceController': TextEditingController(
          text: sections['salophinPrice'] ?? '',
        ),
        'boxCoverDetailController': TextEditingController(
          text: sections['boxCoverDetail'] ?? sections['boxCover'] ?? '',
        ),
        'boxCoverQtyController': TextEditingController(
          text: sections['boxCoverQty']?.toString() ?? '',
        ),
        'boxCoverPriceController': TextEditingController(
          text: sections['boxCoverPrice'] ?? '',
        ),
        'innerDetailController': TextEditingController(
          text: sections['innerDetail'] ?? sections['inner'] ?? '',
        ),
        'innerQtyController': TextEditingController(
          text: sections['innerQty']?.toString() ?? '',
        ),
        'innerPriceController': TextEditingController(
          text: sections['innerPrice'] ?? '',
        ),
        'bottomDetailController': TextEditingController(
          text: sections['bottomDetail'] ?? sections['bottom'] ?? '',
        ),
        'bottomQtyController': TextEditingController(
          text: sections['bottomQty']?.toString() ?? '',
        ),
        'bottomPriceController': TextEditingController(
          text: sections['bottomPrice'] ?? '',
        ),
        'dieDetailController': TextEditingController(
          text: sections['dieDetail'] ?? '',
        ),
        'dieQtyController': TextEditingController(
          text: sections['dieQty']?.toString() ?? '',
        ),
        'diePriceController': TextEditingController(
          text: sections['diePrice'] ?? '',
        ),
        'otherDetailController': TextEditingController(
          text: sections['otherDetail'] ?? '',
        ),
        'otherQtyController': TextEditingController(
          text: sections['otherQty']?.toString() ?? '',
        ),
        'otherPriceController': TextEditingController(
          text: sections['otherPrice'] ?? '',
        ),
        'customExtraSections': extraSections
            .map<Map<String, TextEditingController>>((sec) {
              return {
                'title': TextEditingController(text: sec['title'] ?? ''),
                'detail': TextEditingController(text: sec['detail'] ?? ''),
                'qty': TextEditingController(
                  text: sec['qty']?.toString() ?? '',
                ),
                'price': TextEditingController(text: sec['price'] ?? ''),
              };
            })
            .toList(),
      };
    }).toList();

    if (_products.isEmpty) {
      _products = [_createEmptyProduct()];
    }

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
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'category': 'MDF',
      'gstPercent': 18.0,
      'hsnCode': '44111200',
      'nameController': TextEditingController(),
      'quantityController': TextEditingController(),
      'lengthController': TextEditingController(),
      'heightController': TextEditingController(),
      'widthController': TextEditingController(),
      'priceController': TextEditingController(),
      'remarkController': TextEditingController(),
      'productCategory': 'MDF',
      'images': <String>[],
      'newImages': <XFile>[],
      'sections': <String, dynamic>{},
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
    setState(() => _products.add(_createEmptyProduct()));
  }

  void _removeProduct(int index) {
    if (_products.length > 1) {
      setState(() {
        _disposeProductControllers(_products[index]);
        _products.removeAt(index);
      });
    }
  }

  void _disposeProductControllers(Map<String, dynamic> product) {
    (product['nameController'] as TextEditingController).dispose();
    (product['quantityController'] as TextEditingController).dispose();
    (product['lengthController'] as TextEditingController).dispose();
    (product['heightController'] as TextEditingController).dispose();
    (product['widthController'] as TextEditingController).dispose();
    (product['remarkController'] as TextEditingController).dispose();
    (product['priceController'] as TextEditingController).dispose();
    (product['trayDetailController'] as TextEditingController).dispose();
    (product['trayQtyController'] as TextEditingController).dispose();
    (product['trayPriceController'] as TextEditingController).dispose();
    (product['salophinDetailController'] as TextEditingController).dispose();
    (product['salophinQtyController'] as TextEditingController).dispose();
    (product['salophinPriceController'] as TextEditingController).dispose();
    (product['boxCoverDetailController'] as TextEditingController).dispose();
    (product['boxCoverQtyController'] as TextEditingController).dispose();
    (product['boxCoverPriceController'] as TextEditingController).dispose();
    (product['innerDetailController'] as TextEditingController).dispose();
    (product['innerQtyController'] as TextEditingController).dispose();
    (product['innerPriceController'] as TextEditingController).dispose();
    (product['bottomDetailController'] as TextEditingController).dispose();
    (product['bottomQtyController'] as TextEditingController).dispose();
    (product['bottomPriceController'] as TextEditingController).dispose();
    (product['dieDetailController'] as TextEditingController).dispose();
    (product['dieQtyController'] as TextEditingController).dispose();
    (product['diePriceController'] as TextEditingController).dispose();
    (product['otherDetailController'] as TextEditingController).dispose();
    (product['otherQtyController'] as TextEditingController).dispose();
    (product['otherPriceController'] as TextEditingController).dispose();
    final extraSections =
        product['customExtraSections']
            as List<Map<String, TextEditingController>>?;
    if (extraSections != null) {
      for (final sec in extraSections) {
        sec['title']?.dispose();
        sec['detail']?.dispose();
        sec['qty']?.dispose();
        sec['price']?.dispose();
      }
    }
  }

  void _addPartialDispatch() {
    setState(() => _partialDispatches.add(_createEmptyDispatch()));
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Pick from Gallery'),
              subtitle: const Text('Choose multiple images'),
              onTap: () async {
                Navigator.pop(ctx);
                final files = await _picker.pickMultiImage(imageQuality: 85);
                if (files.isNotEmpty) {
                  setState(
                    () => (_products[productIndex]['newImages'] as List<XFile>)
                        .addAll(files),
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white),
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
                  setState(
                    () => (_products[productIndex]['newImages'] as List<XFile>)
                        .add(file),
                  );
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
    List<Map<String, dynamic>> partialDispatchesData,
  ) async {
    try {
      final jobDoc = FirebaseFirestore.instance
          .collection('jobCards')
          .doc(widget.orderId);
      await jobDoc.set({
        'linkedOrderId': widget.orderId,
        'jobCardNumber': widget.orderId,
        'customerName': _customerController.text.trim(),
        'companyName': _companyController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'location': _locationController.text.trim(),
        'products': productsData,
        'partialDispatches': partialDispatchesData,
        'priority': _priority,
        'salesPerson': _selectedSalesPerson == 'Others'
            ? _customSalesPerson
            : _selectedSalesPerson,
        'unit': _selectedUnit,
        'deliveryDate': Timestamp.fromDate(_deliveryDate),
        'orderDate': Timestamp.fromDate(_orderDate),
        'dispatchType': _dispatchType,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("✅ JobCard upserted safely");
    } catch (e) {
      debugPrint("🔥 JobCard update error: $e");
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      List<Map<String, dynamic>> productsData = [];

      for (int i = 0; i < _products.length; i++) {
        final product = _products[i];
        final nameController =
            product['nameController'] as TextEditingController;
        final quantityController =
            product['quantityController'] as TextEditingController;
        final lengthController =
            product['lengthController'] as TextEditingController;
        final heightController =
            product['heightController'] as TextEditingController;
        final widthController =
            product['widthController'] as TextEditingController;
        final priceController =
            product['priceController'] as TextEditingController;
        final remarkController =
            product['remarkController'] as TextEditingController;
        final existingImages = List<String>.from(product['images'] as List);
        final newImages = product['newImages'] as List<XFile>;

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

        final allImages = [...existingImages, ...newImageUrls];
        final sectionSelected = product['sectionSelected'] as Map<String, bool>;
        final oldSections = product['sections'] ?? {};
        final Map<String, dynamic> sections = Map<String, dynamic>.from(
          oldSections,
        );

        if (sectionSelected['Tray'] == true) {
          sections['trayDetail'] =
              (product['trayDetailController'] as TextEditingController).text
                  .trim();
          sections['trayQty'] =
              int.tryParse(
                (product['trayQtyController'] as TextEditingController).text
                    .trim(),
              ) ??
              0;
          sections['trayPrice'] =
              (product['trayPriceController'] as TextEditingController).text
                  .trim();
        }
        if (sectionSelected['Salophin'] == true) {
          sections['salophinDetail'] =
              (product['salophinDetailController'] as TextEditingController)
                  .text
                  .trim();
          sections['salophinQty'] =
              int.tryParse(
                (product['salophinQtyController'] as TextEditingController).text
                    .trim(),
              ) ??
              0;
          sections['salophinPrice'] =
              (product['salophinPriceController'] as TextEditingController).text
                  .trim();
        }
        if (sectionSelected['Box Cover'] == true) {
          sections['boxCoverDetail'] =
              (product['boxCoverDetailController'] as TextEditingController)
                  .text
                  .trim();
          sections['boxCoverQty'] =
              int.tryParse(
                (product['boxCoverQtyController'] as TextEditingController).text
                    .trim(),
              ) ??
              0;
          sections['boxCoverPrice'] =
              (product['boxCoverPriceController'] as TextEditingController).text
                  .trim();
        }
        if (sectionSelected['Inner'] == true) {
          sections['innerDetail'] =
              (product['innerDetailController'] as TextEditingController).text
                  .trim();
          sections['innerQty'] =
              int.tryParse(
                (product['innerQtyController'] as TextEditingController).text
                    .trim(),
              ) ??
              0;
          sections['innerPrice'] =
              (product['innerPriceController'] as TextEditingController).text
                  .trim();
        }
        if (sectionSelected['Bottom'] == true) {
          sections['bottomDetail'] =
              (product['bottomDetailController'] as TextEditingController).text
                  .trim();
          sections['bottomQty'] =
              int.tryParse(
                (product['bottomQtyController'] as TextEditingController).text
                    .trim(),
              ) ??
              0;
          sections['bottomPrice'] =
              (product['bottomPriceController'] as TextEditingController).text
                  .trim();
        }
        if (sectionSelected['Die'] == true) {
          sections['dieDetail'] =
              (product['dieDetailController'] as TextEditingController).text
                  .trim();
          sections['dieQty'] =
              int.tryParse(
                (product['dieQtyController'] as TextEditingController).text
                    .trim(),
              ) ??
              0;
          sections['diePrice'] =
              (product['diePriceController'] as TextEditingController).text
                  .trim();
        }
        if (sectionSelected['Others'] == true) {
          sections['otherDetail'] =
              (product['otherDetailController'] as TextEditingController).text
                  .trim();
          sections['otherQty'] =
              int.tryParse(
                (product['otherQtyController'] as TextEditingController).text
                    .trim(),
              ) ??
              0;
          sections['otherPrice'] =
              (product['otherPriceController'] as TextEditingController).text
                  .trim();
        }

        final List<Map<String, dynamic>> extraSectionsData = [];
        for (final sec
            in product['customExtraSections']
                as List<Map<String, TextEditingController>>) {
          final title = sec['title']!.text.trim();
          final detail = sec['detail']!.text.trim();
          final qtyText = sec['qty']!.text.trim();
          final price = sec['price']!.text.trim();
          if (title.isNotEmpty ||
              detail.isNotEmpty ||
              qtyText.isNotEmpty ||
              price.isNotEmpty) {
            extraSectionsData.add({
              'title': title,
              'detail': detail,
              'qty': int.tryParse(qtyText) ?? 0,
              'price': price,
            });
          }
        }

        final selectedCategory = (product['productCategory'] ?? '')
            .toString()
            .trim();
        final double gstPct =
            (product['gstPercent'] as double?) ??
            _gstPctForCategory(selectedCategory);
        final String hsnCode =
            (product['hsnCode']?.toString().isNotEmpty == true)
            ? product['hsnCode'].toString()
            : _hsnForCategory(selectedCategory);
        final qty = double.tryParse(quantityController.text.trim()) ?? 0;
        final price = double.tryParse(priceController.text.trim()) ?? 0;
        final subAmount = qty * price;
        final gstAmt = subAmount * gstPct / 100;

        productsData.add({
          'id': product['id'],
          'productName': nameController.text.trim(),
          'productCategory': selectedCategory,
          'hsnCode': hsnCode,
          'quantity': qty,
          'price': price,
          'subAmount': subAmount,
          'gstPercent': gstPct,
          'gstAmount': gstAmt,
          'amount': subAmount + gstAmt,
          'length': lengthController.text.trim(),
          'height': heightController.text.trim(),
          'width': widthController.text.trim(),
          'remarks': remarkController.text.trim(),
          'images': allImages,
          'sections': sections,
          'customExtraSections': extraSectionsData,
        });
      }

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
            'quantity': int.tryParse(qty) ?? 0,
            'date': dateStr,
            'timestamp': dispatch['selectedDate'],
          });
        }
      }

      // Backup original order
      await FirebaseFirestore.instance
          .collection('orders_backup')
          .doc(widget.orderId)
          .set(widget.orderData);

      // Calculate totals
      double subTotal = productsData.fold(
        0.0,
        (s, p) => s + (p['subAmount'] as double),
      );
      double totalGst = productsData.fold(
        0.0,
        (s, p) => s + (p['gstAmount'] as double),
      );
      double grandTotal = subTotal + totalGst;

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'customerName': _customerController.text.trim(),
            'companyName': _companyController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'location': _locationController.text.trim(),
            'products': productsData,
            'partialDispatches': partialDispatchesData,
            'priority': _priority,
            'salesPerson': _selectedSalesPerson == 'Others'
                ? _customSalesPerson
                : _selectedSalesPerson,
            'dispatchType': _dispatchType,
            'unit': _selectedUnit,
            'deliveryDate': Timestamp.fromDate(_deliveryDate),
            'orderDate': Timestamp.fromDate(_orderDate),
            'subTotal': subTotal,
            'totalGstAmount': totalGst,
            'grandTotal': grandTotal,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _updateLinkedJobCard(productsData, partialDispatchesData);
      await _saveToUnit2IfRigid(productsData);

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
            backgroundColor: AppColors.success,
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
          backgroundColor: AppColors.warning,
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

  Future<void> _saveToUnit2IfRigid(
    List<Map<String, dynamic>> productsData,
  ) async {
    try {
      final rigidProducts = productsData.where((p) {
        final cat = (p['productCategory'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        return cat == 'rigid box (unit 2 hussainpura)';
      }).toList();

      if (rigidProducts.isEmpty) {
        await FirebaseFirestore.instance
            .collection('unit2JobCards')
            .doc(widget.orderId)
            .delete();
        return;
      }

      await FirebaseFirestore.instance
          .collection('unit2JobCards')
          .doc(widget.orderId)
          .set({
            'orderId': widget.orderId,
            'isJobCardCreated': false,
            'customerName': _customerController.text.trim(),
            'companyName': _companyController.text.trim(),
            'phone': _phoneController.text.trim(),
            'location': _locationController.text.trim(),
            'salesPerson': _selectedSalesPerson == 'Others'
                ? _customSalesPerson
                : _selectedSalesPerson,
            'priority': _priority,
            'deliveryDate': Timestamp.fromDate(_deliveryDate),
            'createdDate': Timestamp.fromDate(_orderDate),
            'products': rigidProducts,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      debugPrint("✅ Unit2 synced properly");
    } catch (e) {
      debugPrint("🔥 unit2 save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset('assets/dpl.png', height: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Edit Job Card',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
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
            _buildSection(
              title: 'Customer Details',
              icon: Icons.person_outline,
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.cyan.shade100],
              ),
              children: [
                _buildTextField(
                  controller: _customerController,
                  label: 'Customer Name',
                  icon: Icons.person,
                  validator: _req,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _companyController,
                  label: 'Company Name',
                  icon: Icons.business,
                  validator: _req,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Dispatch Type',
              icon: Icons.local_shipping,
              gradient: LinearGradient(
                colors: [Colors.green.shade100, Colors.teal.shade100],
              ),
              children: [
                DropdownButtonFormField<String>(
                  value: _dispatchOptions.contains(_dispatchType)
                      ? _dispatchType
                      : null,
                  decoration: _buildInputDecoration(
                    'Select Dispatch Type',
                    Icons.local_shipping,
                  ),
                  items: _dispatchOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _dispatchType = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Order Location',
              icon: Icons.location_on,
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.amber.shade100],
              ),
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: _buildInputDecoration(
                    'Order Location (Unit)',
                    Icons.factory_outlined,
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
              ],
            ),
            const SizedBox(height: 20),
            _buildProductsSection(),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Sales Person',
              icon: Icons.badge_outlined,
              gradient: LinearGradient(
                colors: [Colors.purple.shade100, Colors.pink.shade100],
              ),
              children: [
                DropdownButtonFormField<String>(
                  value: _salesPersons.contains(_selectedSalesPerson)
                      ? _selectedSalesPerson
                      : null,
                  decoration: _buildInputDecoration(
                    'Select Sales Person',
                    Icons.person_pin,
                  ),
                  items: _salesPersons
                      .map(
                        (p) =>
                            DropdownMenuItem<String>(value: p, child: Text(p)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedSalesPerson = value;
                    _customSalesPerson = null;
                    _otherSalesPersonController.clear();
                  }),
                  validator: (value) =>
                      value == null ? 'Please select a sales person' : null,
                ),
                if (_selectedSalesPerson == 'Others') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherSalesPersonController,
                    decoration: _buildInputDecoration(
                      'Enter Sales Person Name',
                      Icons.edit,
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
            _buildSection(
              title: 'Partial Dispatch',
              icon: Icons.local_shipping_outlined,
              gradient: LinearGradient(
                colors: [Colors.green.shade100, Colors.teal.shade100],
              ),
              children: [
                DropdownButtonFormField<String>(
                  value: _showPartialDispatch ? 'Yes' : 'No',
                  decoration: _buildInputDecoration(
                    'Any Partial Dispatch?',
                    Icons.help_outline,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'No', child: Text('No')),
                    DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                  ],
                  onChanged: (val) => setState(() {
                    _showPartialDispatch = val == 'Yes';
                    if (_showPartialDispatch && _partialDispatches.isEmpty) {
                      _partialDispatches.add(_createEmptyDispatch());
                    }
                  }),
                ),
                if (_showPartialDispatch) ...[
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _partialDispatches.length,
                    itemBuilder: (context, index) => _buildDispatchItem(index),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _addPartialDispatch,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Dispatch'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Schedule & Priority',
              icon: Icons.schedule,
              gradient: LinearGradient(
                colors: [Colors.red.shade100, Colors.orange.shade100],
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDateCard(
                        label: 'Order Date',
                        date: _orderDate,
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateCard(
                        label: 'Delivery Date',
                        date: _deliveryDate,
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Additional Notes',
              icon: Icons.note_outlined,
              gradient: LinearGradient(
                colors: [Colors.indigo.shade100, Colors.blue.shade100],
              ),
              children: [
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  icon: Icons.notes,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text(
              'Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return KeyedSubtree(
                    key: ValueKey(product['id']),
                    child: _buildProductCard(index),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Another Product'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── UPDATED: Product card with Laddu Paper + HSN/GST support ──────────────
  Widget _buildProductCard(int index) {
    final product = _products[index];
    final nameController = product['nameController'] as TextEditingController;
    final quantityController =
        product['quantityController'] as TextEditingController;
    final lengthController =
        product['lengthController'] as TextEditingController;
    final heightController =
        product['heightController'] as TextEditingController;
    final widthController = product['widthController'] as TextEditingController;
    final priceController = product['priceController'] as TextEditingController;
    final remarkController =
        product['remarkController'] as TextEditingController;
    final existingImages = product['images'] as List<String>;
    final newImages = product['newImages'] as List<XFile>;
    final sectionSelected = product['sectionSelected'] as Map<String, bool>;
    final productCategory = product['productCategory'] ?? 'Others';
    final double gstPct =
        (product['gstPercent'] as double?) ??
        _gstPctForCategory(productCategory);
    final bool isLadduPaper = productCategory == 'Laddu Paper';
    final bool isMdf = productCategory == 'MDF';
    final bool isOthers = productCategory == 'Others';
    final bool isHighGst = isMdf || isLadduPaper;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product header row ──────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Product ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_products.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeProduct(index),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Category Dropdown ───────────────────────────────────────────
          DropdownButtonFormField<String>(
            value: _productCategories.contains(productCategory)
                ? productCategory
                : 'Others',
            decoration: _buildInputDecoration(
              'Product Category',
              Icons.category,
            ),
            items: _productCategories
                .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() {
              product['productCategory'] = v;
              product['category'] = v;
              // Auto-set GST and HSN on category change
              product['gstPercent'] = _gstPctForCategory(v);
              if (v == 'Laddu Paper') {
                product['hsnCode'] = '48062000';
              } else if (v == 'MDF') {
                product['hsnCode'] = '44111200';
              } else if (v != 'Others') {
                product['hsnCode'] = '48192090';
              }
              // For Others, keep existing hsnCode or empty
            }),
            validator: (v) => v == null ? 'Select category' : null,
          ),

          // ── Laddu Paper: fixed info banner ──────────────────────────────
          if (isLadduPaper) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HSN Code: 48062000',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'GST: 18% — Fixed for Laddu Paper',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── MDF: fixed info banner ──────────────────────────────────────
          if (isMdf) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HSN Code: 44111200',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'GST: 18% — Fixed for MDF',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── Others: custom HSN + GST selector ──────────────────────────
          if (isOthers) ...[
            const SizedBox(height: 10),
            TextFormField(
              initialValue: product['hsnCode'] ?? '',
              decoration: const InputDecoration(
                labelText: 'HSN Code (Optional)',
                hintText: 'e.g. 48062000',
                prefixIcon: Icon(Icons.tag_rounded),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  setState(() => product['hsnCode'] = val.trim()),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select GST Rate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [5.0, 18.0].map((pct) {
                      final isActive = gstPct == pct;
                      final btnColor = pct == 18.0
                          ? Colors.orange.shade600
                          : Colors.blue.shade600;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => product['gstPercent'] = pct),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive ? Colors.transparent : btnColor,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${pct.toInt()}%',
                                style: TextStyle(
                                  color: isActive ? Colors.white : btnColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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

          // ── For other known categories (not MDF/Laddu/Others): show HSN ─
          if (!isLadduPaper && !isMdf && !isOthers) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tag_rounded,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'HSN: ${_hsnForCategory(productCategory)}  |  GST: ${_gstPctForCategory(productCategory).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // ── Autocomplete Product Name ────────────────────────────────────
          Autocomplete<Map<String, dynamic>>(
            initialValue: TextEditingValue(text: nameController.text),
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
                    final name = (p['productName'] ?? '')
                        .toString()
                        .toLowerCase();
                    if (name.contains(value.text.toLowerCase())) {
                      results.add(Map<String, dynamic>.from(p));
                    }
                  }
                }
              }
              return results;
            },
            displayStringForOption: (o) => o['productName'] ?? '',
           fieldViewBuilder: (context, controller, focusNode, onSubmit) {

  if (controller.text != nameController.text) {
    controller.value = TextEditingValue(
      text: nameController.text,
      selection: TextSelection.collapsed(
        offset: nameController.text.length,
      ),
    );
  }

  return TextFormField(
    controller: controller,
    focusNode: focusNode,
    decoration: _buildInputDecoration(
      'Product Name',
      Icons.shopping_bag,
    ),
    validator: _req,
    onChanged: (val) {
      nameController.text = val;
    },
  );
},
            onSelected: (data) {
              setState(() {
                nameController.text = data['productName'] ?? '';
                priceController.text = (data['price'] ?? '').toString();
                final rawQty = (data['quantity'] ?? '').toString();
                final split = _splitQuantityAndRemark(rawQty);
                quantityController.text = split['qty'] ?? '';
                if (remarkController.text.isEmpty) {
                  remarkController.text = split['remark'] ?? '';
                }
                product['images'] = List<String>.from(data['images'] ?? []);
                // Load category & GST/HSN from autocomplete data
                final autoCategory =
                    data['productCategory'] ?? data['category'] ?? '';
                if (autoCategory.isNotEmpty &&
                    _productCategories.contains(autoCategory)) {
                  product['productCategory'] = autoCategory;
                  product['category'] = autoCategory;
                  product['gstPercent'] = _gstPctForCategory(autoCategory);
                  product['hsnCode'] =
                      (data['hsnCode']?.toString().isNotEmpty == true)
                      ? data['hsnCode'].toString()
                      : _hsnForCategory(autoCategory);
                }
                // Load sections
                final sections =
                    data['sections'] as Map<String, dynamic>? ?? {};
                sectionSelected['Tray'] =
                    hasValue(sections['trayDetail']) ||
                    hasValue(sections['tray']);
                (product['trayDetailController'] as TextEditingController)
                        .text =
                    sections['trayDetail'] ?? sections['tray'] ?? '';
                (product['trayQtyController'] as TextEditingController).text =
                    sections['trayQty']?.toString() ?? '';
                (product['trayPriceController'] as TextEditingController).text =
                    sections['trayPrice'] ?? '';
                sectionSelected['Salophin'] =
                    hasValue(sections['salophinDetail']) ||
                    hasValue(sections['salophin']);
                (product['salophinDetailController'] as TextEditingController)
                        .text =
                    sections['salophinDetail'] ?? sections['salophin'] ?? '';
                (product['salophinQtyController'] as TextEditingController)
                        .text =
                    sections['salophinQty']?.toString() ?? '';
                (product['salophinPriceController'] as TextEditingController)
                        .text =
                    sections['salophinPrice'] ?? '';
                sectionSelected['Box Cover'] =
                    hasValue(sections['boxCoverDetail']) ||
                    hasValue(sections['boxCover']);
                (product['boxCoverDetailController'] as TextEditingController)
                        .text =
                    sections['boxCoverDetail'] ?? sections['boxCover'] ?? '';
                (product['boxCoverQtyController'] as TextEditingController)
                        .text =
                    sections['boxCoverQty']?.toString() ?? '';
                (product['boxCoverPriceController'] as TextEditingController)
                        .text =
                    sections['boxCoverPrice'] ?? '';
                sectionSelected['Inner'] =
                    hasValue(sections['innerDetail']) ||
                    hasValue(sections['inner']);
                (product['innerDetailController'] as TextEditingController)
                        .text =
                    sections['innerDetail'] ?? sections['inner'] ?? '';
                (product['innerQtyController'] as TextEditingController).text =
                    sections['innerQty']?.toString() ?? '';
                (product['innerPriceController'] as TextEditingController)
                        .text =
                    sections['innerPrice'] ?? '';
                sectionSelected['Bottom'] =
                    hasValue(sections['bottomDetail']) ||
                    hasValue(sections['bottom']);
                (product['bottomDetailController'] as TextEditingController)
                        .text =
                    sections['bottomDetail'] ?? sections['bottom'] ?? '';
                (product['bottomQtyController'] as TextEditingController).text =
                    sections['bottomQty']?.toString() ?? '';
                (product['bottomPriceController'] as TextEditingController)
                        .text =
                    sections['bottomPrice'] ?? '';
                sectionSelected['Die'] =
                    hasValue(sections['dieDetail']) ||
                    hasValue(sections['die']);
                (product['dieDetailController'] as TextEditingController).text =
                    sections['dieDetail'] ?? sections['die'] ?? '';
                (product['dieQtyController'] as TextEditingController).text =
                    sections['dieQty']?.toString() ?? '';
                (product['diePriceController'] as TextEditingController).text =
                    sections['diePrice'] ?? '';
                sectionSelected['Others'] =
                    hasValue(sections['otherDetail']) ||
                    (data['customExtraSections'] as List?)?.isNotEmpty == true;
                (product['otherDetailController'] as TextEditingController)
                        .text =
                    sections['otherDetail'] ?? sections['other'] ?? '';
                (product['otherQtyController'] as TextEditingController).text =
                    sections['otherQty']?.toString() ?? '';
                (product['otherPriceController'] as TextEditingController)
                        .text =
                    sections['otherPrice'] ?? '';
                final extraSections =
                    data['customExtraSections'] as List? ?? [];
                product['customExtraSections'].clear();
                for (final sec in extraSections) {
                  if (sec is Map<String, dynamic>) {
                    product['customExtraSections'].add({
                      'title': TextEditingController(
                        text: sec['title']?.toString() ?? '',
                      ),
                      'detail': TextEditingController(
                        text: sec['detail'] ?? sec['details'] ?? '',
                      ),
                      'qty': TextEditingController(
                        text: sec['qty']?.toString() ?? '',
                      ),
                      'price': TextEditingController(
                        text: sec['price']?.toString() ?? '',
                      ),
                    });
                  }
                }
              });
            },
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _req,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: priceController,
                  label: 'Price',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: remarkController,
            label: 'Product Remark',
            icon: Icons.comment_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildSizeSection(product),
          const SizedBox(height: 12),
          _buildPackagingSection(product, sectionSelected),
          const SizedBox(height: 12),
          _buildExtraSection(product),
          const SizedBox(height: 12),
          _buildImagesSection(index, existingImages, newImages),

          // ── GST Summary chip ────────────────────────────────────────────
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final qty = double.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;
              final sub = qty * price;
              final gst = sub * gstPct / 100;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isHighGst
                        ? [Colors.orange.shade400, Colors.orange.shade600]
                        : [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sub: Rs${sub.toStringAsFixed(0)} + GST ${gstPct.toInt()}%: Rs${gst.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Total: Rs${(sub + gst).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSection(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Size (L × H × W)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller:
                    product['lengthController'] as TextEditingController,
                label: 'Length',
                icon: Icons.straighten,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller:
                    product['heightController'] as TextEditingController,
                label: 'Height',
                icon: Icons.height,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: product['widthController'] as TextEditingController,
                label: 'Width',
                icon: Icons.width_normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPackagingSection(
    Map<String, dynamic> product,
    Map<String, bool> sectionSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Packaging Sections',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sectionSelected.keys.map((key) {
            return FilterChip(
              label: Text(
                key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: sectionSelected[key]!,
              onSelected: (val) => setState(() => sectionSelected[key] = val),
              selectedColor: AppColors.primary.withOpacity(0.3),
              backgroundColor: Colors.grey.shade200,
              side: BorderSide(
                color: sectionSelected[key]!
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
        if (sectionSelected['Tray'] == true) ...[
          const SizedBox(height: 12),
          _buildPackagingRow(product, 'tray', 'Tray Details', Icons.inbox),
        ],
        if (sectionSelected['Salophin'] == true) ...[
          const SizedBox(height: 12),
          _buildPackagingRow(
            product,
            'salophin',
            'Salophin',
            Icons.local_shipping,
          ),
        ],
        if (sectionSelected['Box Cover'] == true) ...[
          const SizedBox(height: 12),
          _buildPackagingRow(
            product,
            'boxCover',
            'Box Cover Details',
            Icons.cases_outlined,
          ),
        ],
        if (sectionSelected['Inner'] == true) ...[
          const SizedBox(height: 12),
          _buildPackagingRow(
            product,
            'inner',
            'Inner Details',
            Icons.table_rows,
          ),
        ],
        if (sectionSelected['Bottom'] == true) ...[
          const SizedBox(height: 12),
          _buildPackagingRow(
            product,
            'bottom',
            'Bottom Details',
            Icons.align_vertical_bottom,
          ),
        ],
        if (sectionSelected['Die'] == true) ...[
          const SizedBox(height: 12),
          _buildPackagingRow(product, 'die', 'Die Details', Icons.cut),
        ],
        if (sectionSelected['Others'] == true) ...[
          const SizedBox(height: 12),
          _buildPackagingRow(
            product,
            'other',
            'Other Details',
            Icons.more_horiz,
          ),
        ],
      ],
    );
  }

  Widget _buildPackagingRow(
    Map<String, dynamic> product,
    String prefix,
    String label,
    IconData icon,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildTextField(
            controller:
                product['${prefix}DetailController'] as TextEditingController,
            label: '$label Details',
            icon: icon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: _buildTextField(
            controller:
                product['${prefix}QtyController'] as TextEditingController,
            label: 'Qty',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: _buildTextField(
            controller:
                product['${prefix}PriceController'] as TextEditingController,
            label: 'Price',
            icon: Icons.currency_rupee,
          ),
        ),
      ],
    );
  }

  Widget _buildExtraSection(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extra Sections (Custom)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Extra Section'),
          onPressed: () => setState(() {
            product['customExtraSections'].add({
              'title': TextEditingController(),
              'detail': TextEditingController(),
              'qty': TextEditingController(),
              'price': TextEditingController(),
            });
          }),
        ),
        ...((product['customExtraSections']
                as List<Map<String, TextEditingController>>)
            .asMap()
            .entries
            .map((entry) {
              final i = entry.key;
              final sec = entry.value;
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade50, Colors.orange.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: sec['title']!,
                      label: 'Section Header',
                      icon: Icons.title,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: sec['detail']!,
                            label: '${sec['title']!.text} Details',
                            icon: Icons.description,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: sec['qty']!,
                            label: 'Qty',
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: sec['price']!,
                            label: 'Price',
                            icon: Icons.currency_rupee,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() {
                          sec['title']!.dispose();
                          sec['detail']!.dispose();
                          sec['qty']!.dispose();
                          sec['price']!.dispose();
                          product['customExtraSections'].removeAt(i);
                        }),
                      ),
                    ),
                  ],
                ),
              );
            })),
      ],
    );
  }

  Widget _buildImagesSection(
    int productIndex,
    List<String> existingImages,
    List<XFile> newImages,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...existingImages.map(
              (url) => Stack(
                children: [
                  GestureDetector(
                    onTap: () => _openFullScreenImage(url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => existingImages.remove(url)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...newImages.map(
              (x) => Stack(
                children: [
                  GestureDetector(
                    onTap: () => _openFullScreenImage(x.path),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: kIsWeb
                            ? Image.network(x.path, fit: BoxFit.cover)
                            : Image.file(File(x.path), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => newImages.remove(x)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDispatchItem(int index) {
    final dispatch = _partialDispatches[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.amber.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Dispatch ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (_partialDispatches.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePartialDispatch(index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: dispatch['nameController'] as TextEditingController,
            label: 'Dispatch Name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: dispatch['qtyController'] as TextEditingController,
            label: 'Dispatch Quantity',
            icon: Icons.confirmation_number_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: dispatch['dateController'] as TextEditingController,
            readOnly: true,
            decoration: _buildInputDecoration(
              'Dispatch Date',
              Icons.calendar_today,
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                (dispatch['dateController'] as TextEditingController).text =
                    '${picked.day}/${picked.month}/${picked.year}';
                dispatch['selectedDate'] = picked;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade50, Colors.orange.shade50],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
      decoration: _buildInputDecoration(label, icon),
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shadowColor: Colors.transparent,
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  String? _req(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;

  @override
  void dispose() {
    _animationController.dispose();
    _customerController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _otherSalesPersonController.dispose();
    for (var product in _products) {
      _disposeProductControllers(product);
    }
    for (var dispatch in _partialDispatches) {
      (dispatch['nameController'] as TextEditingController).dispose();
      (dispatch['qtyController'] as TextEditingController).dispose();
      (dispatch['dateController'] as TextEditingController).dispose();
    }
    super.dispose();
  }
}
