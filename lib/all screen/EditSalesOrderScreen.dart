import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  final List<String> _units = [
    'Unit 1',
    'Unit 2',
    'Meena Bazar',
    'College Road',
  ];
  void _openFullScreenImage(ImageProvider imageProvider) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image(image: imageProvider, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  final List<String> _productCategories = ['MDF', 'Kappa Box', 'Other'];
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
  void _syncQuantityToRemark(
    TextEditingController quantityController,
    TextEditingController remarkController,
  ) {
    quantityController.addListener(() {
      final qty = quantityController.text.trim();

      if (qty.isNotEmpty &&
          (remarkController.text.isEmpty ||
              remarkController.text.startsWith('Qty '))) {
        remarkController.text = 'Qty $qty';
      }
    });
  }

  Map<String, String> _splitQuantityAndRemark(String input) {
    final number = RegExp(r'\d+').stringMatch(input) ?? '';
    final text = input.replaceAll(RegExp(r'\d+'), '').trim();
    return {'qty': number, 'remark': text};
  }

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
    _products =
        (widget.orderData['products'] as List?)?.map((p) {
          final sections = p['sections'] as Map<String, dynamic>? ?? {};
          final extraSections = p['customExtraSections'] as List? ?? [];
          final rawQty = safeText(p['quantity']);
          final split = _splitQuantityAndRemark(rawQty); // ✅ HERE

          return {
            'nameController': TextEditingController(
              text: p['productName'] ?? '',
            ),
            'quantityController': TextEditingController(
              text: split['qty'], // ✅ only number
            ),
            'remarkController': TextEditingController(
              text: (p['remarks']?.toString().isNotEmpty == true)
                  ? p['remarks']
                  : split['remark'], // ✅ only text
            ),
            'lengthController': TextEditingController(text: p['length'] ?? ''),
            'heightController': TextEditingController(text: p['height'] ?? ''),
            'widthController': TextEditingController(text: p['width'] ?? ''),
            'priceController': TextEditingController(
              text: safeText(p['price']),
            ),
            'productCategory': p['productCategory'] ?? 'MDF',
            'images': List<String>.from(p['images'] ?? []),
            'newImages': <XFile>[],
            'sectionSelected': {
              'Tray':
                  sections['trayDetail'] != null ||
                  sections['trayQty'] != null ||
                  sections['trayPrice'] != null ||
                  sections['tray'] != null, // 🔥 old data

              'Salophin':
                  sections['salophinDetail'] != null ||
                  sections['salophinQty'] != null ||
                  sections['salophinPrice'] != null ||
                  sections['salophin'] != null, // backward support

              'Box Cover':
                  sections['boxCoverDetail'] != null ||
                  sections['boxCoverQty'] != null ||
                  sections['boxCoverPrice'] != null ||
                  sections['boxCover'] != null, // 🔥 old data
              // ================= Inner =================
              'Inner':
                  sections['innerDetail'] != null ||
                  sections['innerQty'] != null ||
                  sections['innerPrice'] != null ||
                  sections['inner'] != null, // 🔥 old data
              // ================= Bottom =================
              'Bottom':
                  sections['bottomDetail'] != null ||
                  sections['bottomQty'] != null ||
                  sections['bottomPrice'] != null ||
                  sections['bottom'] != null, // 🔥 old data
              // ================= Die =================
              'Die':
                  sections['dieDetail'] != null ||
                  sections['dieQty'] != null ||
                  sections['diePrice'] != null ||
                  sections['die'] != null, // 🔥 old data
              // ================= Others =================
              'Others':
                  sections['otherDetail'] != null ||
                  sections['otherQty'] != null ||
                  sections['otherPrice'] != null ||
                  sections['other'] != null, // 🔥 old data
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

            // ================= Inner =================
            'innerDetailController': TextEditingController(
              text: sections['innerDetail'] ?? sections['inner'] ?? '',
            ),
            'innerQtyController': TextEditingController(
              text: sections['innerQty']?.toString() ?? '',
            ),
            'innerPriceController': TextEditingController(
              text: sections['innerPrice'] ?? '',
            ),

            // ================= Bottom =================
            'bottomDetailController': TextEditingController(
              text: sections['bottomDetail'] ?? sections['bottom'] ?? '',
            ),
            'bottomQtyController': TextEditingController(
              text: sections['bottomQty']?.toString() ?? '',
            ),
            'bottomPriceController': TextEditingController(
              text: sections['bottomPrice'] ?? '',
            ),

            // ================= Die =================
            'dieDetailController': TextEditingController(
              text: sections['dieDetail'] ?? sections['die'] ?? '',
            ),
            'dieQtyController': TextEditingController(
              text: sections['dieQty']?.toString() ?? '',
            ),
            'diePriceController': TextEditingController(
              text: sections['diePrice'] ?? '',
            ),

            // ================= Others =================
            'otherDetailController': TextEditingController(
              text: sections['otherDetail'] ?? sections['other'] ?? '',
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
                    'detail': TextEditingController(
                      text: sec['detail'] ?? sec['details'] ?? '',
                    ),

                    // 🔹 QTY
                    'qty': TextEditingController(
                      text: sec['qty']?.toString() ?? '',
                    ),

                    // 🔹 PRICE
                    'price': TextEditingController(text: sec['price'] ?? ''),
                  };
                })
                .toList(),
          };
        }).toList() ??
        [_createEmptyProduct()];
    for (final product in _products) {
      _syncQuantityToRemark(
        product['quantityController'] as TextEditingController,
        product['remarkController'] as TextEditingController,
      );
    }

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
      'lengthController': TextEditingController(),
      'heightController': TextEditingController(),
      'widthController': TextEditingController(),
      'priceController': TextEditingController(),
      'remarkController': TextEditingController(),
      'productCategory': 'MDF',
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

      // ================= Inner =================
      'innerDetailController': TextEditingController(),
      'innerQtyController': TextEditingController(),
      'innerPriceController': TextEditingController(),

      // ================= Bottom =================
      'bottomDetailController': TextEditingController(),
      'bottomQtyController': TextEditingController(),
      'bottomPriceController': TextEditingController(),

      // ================= Die =================
      'dieDetailController': TextEditingController(),
      'dieQtyController': TextEditingController(),
      'diePriceController': TextEditingController(),

      // ================= Others =================
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
    setState(() {
      final product = _createEmptyProduct();

      _syncQuantityToRemark(
        product['quantityController'] as TextEditingController,
        product['remarkController'] as TextEditingController,
      );

      _products.add(product);
    });
  }

  void _removeProduct(int index) {
    if (_products.length > 1) {
      setState(() {
        final product = _products[index];

        (_products[index]['nameController'] as TextEditingController).dispose();
        (_products[index]['quantityController'] as TextEditingController)
            .dispose();
        (_products[index]['lengthController'] as TextEditingController)
            .dispose();
        (_products[index]['heightController'] as TextEditingController)
            .dispose();
        (_products[index]['widthController'] as TextEditingController)
            .dispose();
        (_products[index]['remarkController'] as TextEditingController)
            .dispose();
        (_products[index]['priceController'] as TextEditingController)
            .dispose();
        (product['trayDetailController'] as TextEditingController).dispose();
        (product['trayQtyController'] as TextEditingController).dispose();
        (product['trayPriceController'] as TextEditingController).dispose();

        // ---------- SALOPHIN ----------
        (product['salophinDetailController'] as TextEditingController)
            .dispose();
        (product['salophinQtyController'] as TextEditingController).dispose();
        (product['salophinPriceController'] as TextEditingController).dispose();

        // ---------- BOX COVER ----------
        (product['boxCoverDetailController'] as TextEditingController)
            .dispose();
        (product['boxCoverQtyController'] as TextEditingController).dispose();
        (product['boxCoverPriceController'] as TextEditingController).dispose();

        // ---------- INNER ----------
        (product['innerDetailController'] as TextEditingController).dispose();
        (product['innerQtyController'] as TextEditingController).dispose();
        (product['innerPriceController'] as TextEditingController).dispose();

        // ---------- BOTTOM ----------
        (product['bottomDetailController'] as TextEditingController).dispose();
        (product['bottomQtyController'] as TextEditingController).dispose();
        (product['bottomPriceController'] as TextEditingController).dispose();

        // ---------- DIE ----------
        (product['dieDetailController'] as TextEditingController).dispose();
        (product['dieQtyController'] as TextEditingController).dispose();
        (product['diePriceController'] as TextEditingController).dispose();

        // ---------- OTHERS ----------
        (product['otherDetailController'] as TextEditingController).dispose();
        (product['otherQtyController'] as TextEditingController).dispose();
        (product['otherPriceController'] as TextEditingController).dispose();

        // ---------- CUSTOM EXTRA SECTIONS ----------
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

        // ---------- REMOVE PRODUCT ----------
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

  pw.TableRow _buildPdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.grey200,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  Future<void> _updateLinkedJobCard(
    List<Map<String, dynamic>> productsData,
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
          'customerName': _customerController.text.trim(),
          'products': productsData,
          'partialDispatches': partialDispatchesData,
          'priority': _priority,
          'salesPerson': _selectedSalesPerson == 'Others'
              ? _customSalesPerson
              : _selectedSalesPerson,
          'location': _locationController.text.trim(),
          'date': _orderDate,
          'updatedAt': FieldValue.serverTimestamp(),
        });
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

        final allImages = [...existingImages, ...newImageUrls];

        // Build sections for this product
        final sectionSelected = product['sectionSelected'] as Map<String, bool>;
        final Map<String, dynamic> sections = {};

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

        // ================= Inner =================
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

        // ================= Bottom =================
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

        // ================= Die =================
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

        // ================= Others =================
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
        productsData.add({
          'productName': nameController.text.trim(), // must not be empty
          'quantity': quantityController.text.trim(),
          'length': lengthController.text.trim(),
          'height': heightController.text.trim(),
          'width': widthController.text.trim(),
          'price': double.tryParse(priceController.text.trim()) ?? 0,
          'remarks': remarkController.text.trim(),
          'productCategory': product['productCategory'],
          'images': allImages,
          'sections': sections,
          'customExtraSections': extraSectionsData, // 🔥 THIS LINE MUST BE HERE
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
            'orderDate': _orderDate,
            'deliveryDate': _deliveryDate,
            'priority': _priority,
            'salesPerson': _selectedSalesPerson == 'Others'
                ? _customSalesPerson
                : _selectedSalesPerson,
            'products': productsData,
            'notes': _notesController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _updateLinkedJobCard(productsData, partialDispatchesData);

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
            const SizedBox(height: 15),

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
                const SizedBox(height: 8),

                _buildTextField(
                  controller: _companyController,
                  label: 'Company Name',
                  icon: Icons.business,
                  validator: _req,
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on,
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Order Location',
              icon: Icons.location_on,
              children: [
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
              ],
            ),
            const SizedBox(height: 16),

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
                    final existingImages = product['images'] as List<String>;
                    final newImages = product['newImages'] as List<XFile>;
                    final sectionSelected =
                        product['sectionSelected'] as Map<String, bool>;
                    final productCategory =
                        product['productCategory'] as String;

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
                              // PDF Button
                              IconButton(
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                ),
                                onPressed: () => null,
                                tooltip: 'Generate PDF',
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

                          // Product Category Dropdown for each product
                          DropdownButtonFormField<String>(
                            value: productCategory,
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
                                  (c) => DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => product['productCategory'] = v!),
                            validator: (v) =>
                                v == null ? 'Select category' : null,
                          ),
                          const SizedBox(height: 12),

                          Autocomplete<Map<String, dynamic>>(
                            initialValue: TextEditingValue(
                              text:
                                  (product['nameController']
                                          as TextEditingController)
                                      .text,
                            ),
                            optionsBuilder: (TextEditingValue value) async {
                              if (value.text.length < 2) return const [];

                              final snap = await FirebaseFirestore.instance
                                  .collection('orders')
                                  .orderBy('createdAt', descending: true)
                                  .limit(100)
                                  .get();

                              final Map<String, Map<String, dynamic>> unique =
                                  {};

                              for (final doc in snap.docs) {
                                final products = doc['products'];
                                if (products is List) {
                                  for (final p in products) {
                                    final name = (p['productName'] ?? '')
                                        .toString()
                                        .toLowerCase();

                                    if (name.contains(
                                      value.text.toLowerCase(),
                                    )) {
                                      unique[name] = Map<String, dynamic>.from(
                                        p,
                                      );
                                    }
                                  }
                                }
                              }
                              return unique.values.toList();
                            },

                            displayStringForOption: (o) =>
                                o['productName'] ?? '',

                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                                  controller.text =
                                      (product['nameController']
                                              as TextEditingController)
                                          .text;

                                  controller.addListener(() {
                                    (product['nameController']
                                                as TextEditingController)
                                            .text =
                                        controller.text;
                                  });
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Product Name',
                                      prefixIcon: const Icon(
                                        Icons.shopping_bag,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: _req,
                                    onChanged: (val) {
                                      (product['nameController']
                                                  as TextEditingController)
                                              .text =
                                          val;
                                    },
                                  );
                                },

                            onSelected: (data) {
                              setState(() {
                                (product['nameController']
                                            as TextEditingController)
                                        .text =
                                    data['productName'] ?? '';
                                (product['priceController']
                                        as TextEditingController)
                                    .text = (data['price'] ?? '')
                                    .toString();

                                final rawQty = (data['quantity'] ?? '')
                                    .toString();
                                final split = _splitQuantityAndRemark(rawQty);

                                (product['quantityController']
                                            as TextEditingController)
                                        .text =
                                    split['qty'] ?? '';

                                if ((product['remarkController']
                                        as TextEditingController)
                                    .text
                                    .isEmpty) {
                                  (product['remarkController']
                                              as TextEditingController)
                                          .text =
                                      split['remark'] ?? '';
                                }

                                // ✅ Images
                                product['images'] = List<String>.from(
                                  data['images'] ?? [],
                                );

                                final sections =
                                    data['sections'] as Map<String, dynamic>? ??
                                    {};

                                // ================= TRAY =================
                                sectionSelected['Tray'] =
                                    sections['trayDetail'] != null ||
                                    sections['trayQty'] != null ||
                                    sections['trayPrice'] != null ||
                                    sections['tray'] !=
                                        null; // backward support

                                (product['trayDetailController']
                                            as TextEditingController)
                                        .text =
                                    sections['trayDetail'] ??
                                    sections['tray'] ??
                                    '';
                                (product['trayQtyController']
                                            as TextEditingController)
                                        .text =
                                    sections['trayQty']?.toString() ?? '';
                                (product['trayPriceController']
                                            as TextEditingController)
                                        .text =
                                    sections['trayPrice'] ?? '';

                                // ================= SALOPHIN =================
                                sectionSelected['Salophin'] =
                                    sections['salophinDetail'] != null ||
                                    sections['salophinQty'] != null ||
                                    sections['salophinPrice'] != null ||
                                    sections['salophin'] != null;

                                (product['salophinDetailController']
                                            as TextEditingController)
                                        .text =
                                    sections['salophinDetail'] ??
                                    sections['salophin'] ??
                                    '';
                                (product['salophinQtyController']
                                            as TextEditingController)
                                        .text =
                                    sections['salophinQty']?.toString() ?? '';
                                (product['salophinPriceController']
                                            as TextEditingController)
                                        .text =
                                    sections['salophinPrice'] ?? '';

                                // ================= BOX COVER =================
                                sectionSelected['Box Cover'] =
                                    sections['boxCoverDetail'] != null ||
                                    sections['boxCoverQty'] != null ||
                                    sections['boxCoverPrice'] != null ||
                                    sections['boxCover'] != null;

                                (product['boxCoverDetailController']
                                            as TextEditingController)
                                        .text =
                                    sections['boxCoverDetail'] ??
                                    sections['boxCover'] ??
                                    '';
                                (product['boxCoverQtyController']
                                            as TextEditingController)
                                        .text =
                                    sections['boxCoverQty']?.toString() ?? '';
                                (product['boxCoverPriceController']
                                            as TextEditingController)
                                        .text =
                                    sections['boxCoverPrice'] ?? '';

                                // ================= INNER =================
                                sectionSelected['Inner'] =
                                    sections['innerDetail'] != null ||
                                    sections['innerQty'] != null ||
                                    sections['innerPrice'] != null ||
                                    sections['inner'] != null;

                                (product['innerDetailController']
                                            as TextEditingController)
                                        .text =
                                    sections['innerDetail'] ??
                                    sections['inner'] ??
                                    '';
                                (product['innerQtyController']
                                            as TextEditingController)
                                        .text =
                                    sections['innerQty']?.toString() ?? '';
                                (product['innerPriceController']
                                            as TextEditingController)
                                        .text =
                                    sections['innerPrice'] ?? '';

                                // ================= BOTTOM =================
                                sectionSelected['Bottom'] =
                                    sections['bottomDetail'] != null ||
                                    sections['bottomQty'] != null ||
                                    sections['bottomPrice'] != null ||
                                    sections['bottom'] != null;

                                (product['bottomDetailController']
                                            as TextEditingController)
                                        .text =
                                    sections['bottomDetail'] ??
                                    sections['bottom'] ??
                                    '';
                                (product['bottomQtyController']
                                            as TextEditingController)
                                        .text =
                                    sections['bottomQty']?.toString() ?? '';
                                (product['bottomPriceController']
                                            as TextEditingController)
                                        .text =
                                    sections['bottomPrice'] ?? '';

                                // ================= DIE =================
                                sectionSelected['Die'] =
                                    sections['dieDetail'] != null ||
                                    sections['dieQty'] != null ||
                                    sections['diePrice'] != null ||
                                    sections['die'] != null;

                                (product['dieDetailController']
                                            as TextEditingController)
                                        .text =
                                    sections['dieDetail'] ??
                                    sections['die'] ??
                                    '';
                                (product['dieQtyController']
                                            as TextEditingController)
                                        .text =
                                    sections['dieQty']?.toString() ?? '';
                                (product['diePriceController']
                                            as TextEditingController)
                                        .text =
                                    sections['diePrice'] ?? '';

                                // ================= OTHERS =================
                                sectionSelected['Others'] =
                                    sections['otherDetail'] != null ||
                                    sections['otherQty'] != null ||
                                    sections['otherPrice'] != null ||
                                    sections['other'] != null;

                                (product['otherDetailController']
                                            as TextEditingController)
                                        .text =
                                    sections['otherDetail'] ??
                                    sections['other'] ??
                                    '';
                                (product['otherQtyController']
                                            as TextEditingController)
                                        .text =
                                    sections['otherQty']?.toString() ?? '';
                                (product['otherPriceController']
                                            as TextEditingController)
                                        .text =
                                    sections['otherPrice'] ?? '';

                                // ================= CUSTOM EXTRA SECTIONS =================
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
                                        text:
                                            sec['detail'] ??
                                            sec['details'] ??
                                            '',
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
                                  keyboardType:
                                      TextInputType.number, // ✅ number keyboard
                                  inputFormatters: [
                                    FilteringTextInputFormatter
                                        .digitsOnly, // ✅ only numbers
                                  ],
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
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: remarkController,
                            label: 'Product Remark',
                            icon: Icons.comment_outlined,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Size (L x H x W)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF169a8d),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: lengthController,
                                  label: 'Length',
                                  icon: Icons.straighten,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                  controller: heightController,
                                  label: 'Height',
                                  icon: Icons.height,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                  controller: widthController,
                                  label: 'Width',
                                  icon: Icons.width_normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ================= PACKAGING SECTIONS =================
                          const Text(
                            'Packaging Sections',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF169a8d),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // -------- Fixed Sections Chips (Tray / Die / Others etc.)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: sectionSelected.keys.map((key) {
                              return FilterChip(
                                label: Text(
                                  key,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: sectionSelected[key]!,
                                onSelected: (val) {
                                  setState(() {
                                    sectionSelected[key] = val;
                                  });
                                },
                                selectedColor: Colors.teal.shade200,
                              );
                            }).toList(),
                          ),

                          // -------- Fixed Section Fields
                          if (sectionSelected['Tray'] == true) ...[
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                // 🔹 DETAILS (BIG)
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    controller:
                                        product['trayDetailController']
                                            as TextEditingController,
                                    label: 'Tray Details',
                                    icon: Icons.description,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // 🔹 QUANTITY (SMALL)
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller:
                                        product['trayQtyController']
                                            as TextEditingController,
                                    label: 'Qty',
                                    icon: Icons.numbers,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // 🔹 PRICE (SMALL)
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller:
                                        product['trayPriceController']
                                            as TextEditingController,
                                    label: 'Price',
                                    icon: Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (sectionSelected['Salophin'] == true) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // 🔹 DETAILS (BIG)
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    controller:
                                        product['salophinDetailController']
                                            as TextEditingController,
                                    label: 'Salophin',
                                    icon: Icons.description,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // 🔹 QUANTITY (SMALL)
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller:
                                        product['salophinQtyController']
                                            as TextEditingController,
                                    label: 'Qty',
                                    icon: Icons.numbers,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // 🔹 PRICE (SMALL)
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller:
                                        product['salophinPriceController']
                                            as TextEditingController,
                                    label: 'Price',
                                    icon: Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (sectionSelected['Box Cover'] == true) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    controller:
                                        product['boxCoverDetailController']
                                            as TextEditingController,
                                    label: 'Box Cover Details',
                                    icon: Icons.cases_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller:
                                        product['boxCoverQtyController']
                                            as TextEditingController,
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
                                    controller:
                                        product['boxCoverPriceController']
                                            as TextEditingController,
                                    label: 'Price',
                                    icon: Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // ================= Inner =================
                          if (sectionSelected['Inner'] == true) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    controller:
                                        product['innerDetailController']
                                            as TextEditingController,
                                    label: 'Inner Details',
                                    icon: Icons.table_rows,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller:
                                        product['innerQtyController']
                                            as TextEditingController,
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
                                    controller:
                                        product['innerPriceController']
                                            as TextEditingController,
                                    label: 'Price',
                                    icon: Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // ================= Bottom =================
                          if (sectionSelected['Bottom'] == true) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    controller:
                                        product['bottomDetailController']
                                            as TextEditingController,
                                    label: 'Bottom Details',
                                    icon: Icons.align_vertical_bottom,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller:
                                        product['bottomQtyController']
                                            as TextEditingController,
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
                                    controller:
                                        product['bottomPriceController']
                                            as TextEditingController,
                                    label: 'Price',
                                    icon: Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // ================= Die =================
                          if (sectionSelected['Die'] == true) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    controller:
                                        product['dieDetailController']
                                            as TextEditingController,
                                    label: 'Die Details',
                                    icon: Icons.cut,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller:
                                        product['dieQtyController']
                                            as TextEditingController,
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
                                    controller:
                                        product['diePriceController']
                                            as TextEditingController,
                                    label: 'Price',
                                    icon: Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (sectionSelected['Others'] == true) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    controller:
                                        product['otherDetailController']
                                            as TextEditingController,
                                    label: 'Other Details',
                                    icon: Icons.more_horiz,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller:
                                        product['otherQtyController']
                                            as TextEditingController,
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
                                    controller:
                                        product['otherPriceController']
                                            as TextEditingController,
                                    label: 'Price',
                                    icon: Icons.currency_rupee,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),

                          const Text(
                            'Extra Sections (Custom)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF169a8d),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ➕ Add Extra Section Button
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Extra Section'),
                            onPressed: () {
                              setState(() {
                                product['customExtraSections'].add({
                                  'title': TextEditingController(),
                                  'detail': TextEditingController(), // ✅ sahi
                                  'qty': TextEditingController(),
                                  'price': TextEditingController(),
                                });
                              });
                            },
                          ),

                          ...((product['customExtraSections']
                                      as List<
                                        Map<String, TextEditingController>
                                      >)
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final i = entry.key;
                                    final sec = entry.value;

                                    return Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blueGrey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // 🔹 SECTION HEADER (SEPARATE – MUST STAY)
                                          _buildTextField(
                                            controller: sec['title']!,
                                            label: 'Section Header',
                                            icon: Icons.title,
                                          ),

                                          const SizedBox(height: 10),

                                          // 🔹 DETAILS + QTY + PRICE (SAME ROW LIKE BOTTOM)
                                          Row(
                                            children: [
                                              // DETAILS (FULL WIDTH STYLE)
                                              Expanded(
                                                flex: 3,
                                                child: _buildTextField(
                                                  controller: sec['detail']!,
                                                  label:
                                                      sec['title']!
                                                          .text
                                                          .isNotEmpty
                                                      ? '${sec['title']!.text} Details'
                                                      : 'Section Details',
                                                  icon: Icons.description,
                                                  maxLines: 1,
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // QTY
                                              Expanded(
                                                flex: 1,
                                                child: _buildTextField(
                                                  controller: sec['qty']!,
                                                  label: 'Qty',
                                                  icon: Icons.numbers,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // PRICE
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

                                          // 🗑 DELETE
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  sec['title']!.dispose();
                                                  sec['detail']!.dispose();
                                                  sec['qty']!.dispose();
                                                  sec['price']!.dispose();
                                                  product['customExtraSections']
                                                      .removeAt(i);
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }))
                              .toList(),

                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
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
            // Partial Dispatch
            _buildSection(
              title: 'Partially Dispatch of Quantity (if any)',
              icon: Icons.local_shipping_outlined,
              children: [
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
                                  onPressed: () =>
                                      _removePartialDispatch(index),
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
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
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
        ...existingImages.map(
          (url) => Stack(
            children: [
              GestureDetector(
                onTap: () => _openFullScreenImage(NetworkImage(url)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Image.network(url, fit: BoxFit.fill),
                  ),
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
        ...newImages.map(
          (x) => Stack(
            children: [
              GestureDetector(
                onTap: () {
                  _openFullScreenImage(
                    kIsWeb
                        ? NetworkImage(x.path)
                        : FileImage(File(x.path)) as ImageProvider,
                  );
                },
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
      (product['lengthController'] as TextEditingController).dispose();
      (product['heightController'] as TextEditingController).dispose();
      (product['widthController'] as TextEditingController).dispose();
      (product['priceController'] as TextEditingController).dispose();
      (product['remarkController'] as TextEditingController).dispose();
      // ---------- TRAY ----------
      (product['trayDetailController'] as TextEditingController).dispose();
      (product['trayQtyController'] as TextEditingController).dispose();
      (product['trayPriceController'] as TextEditingController).dispose();

      // ---------- SALOPHIN ----------
      (product['salophinDetailController'] as TextEditingController).dispose();
      (product['salophinQtyController'] as TextEditingController).dispose();
      (product['salophinPriceController'] as TextEditingController).dispose();

      // ---------- BOX COVER ----------
      (product['boxCoverDetailController'] as TextEditingController).dispose();
      (product['boxCoverQtyController'] as TextEditingController).dispose();
      (product['boxCoverPriceController'] as TextEditingController).dispose();

      // ---------- INNER ----------
      (product['innerDetailController'] as TextEditingController).dispose();
      (product['innerQtyController'] as TextEditingController).dispose();
      (product['innerPriceController'] as TextEditingController).dispose();

      // ---------- BOTTOM ----------
      (product['bottomDetailController'] as TextEditingController).dispose();
      (product['bottomQtyController'] as TextEditingController).dispose();
      (product['bottomPriceController'] as TextEditingController).dispose();

      // ---------- DIE ----------
      (product['dieDetailController'] as TextEditingController).dispose();
      (product['dieQtyController'] as TextEditingController).dispose();
      (product['diePriceController'] as TextEditingController).dispose();

      // ---------- OTHERS ----------
      (product['otherDetailController'] as TextEditingController).dispose();
      (product['otherQtyController'] as TextEditingController).dispose();
      (product['otherPriceController'] as TextEditingController).dispose();

      // ---------- CUSTOM EXTRA ----------
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

    for (var dispatch in _partialDispatches) {
      (dispatch['nameController'] as TextEditingController).dispose();
      (dispatch['qtyController'] as TextEditingController).dispose();
      (dispatch['dateController'] as TextEditingController).dispose();
    }

    super.dispose();
  }
}
