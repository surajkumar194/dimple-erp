import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/all%20screen/MasterViewScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class _C {
  static const primary = Color(0xFF169a8d);
  static const primaryDark = Color(0xFF0d7c70);
  static const bg = Color(0xFFF0F4F8);
  static const card = Colors.white;
  static const muted = Color(0xFF8896A5);
  static const mutedLight = Color(0xFFCDD5DE);
  static const danger = Color(0xFFE74C3C);
  static const success = Color(0xFF2ECC71);
  static const amber = Color(0xFFE67E22);
  static const surface = Color(0xFFFAFBFD);

  static const grad = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const amberGrad = LinearGradient(
    colors: [Color(0xFFE67E22), Color(0xFFCA6F1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

const _kFixedSections = [
  'Tray',
  'Salophin',
  'Box Cover',
  'Inner',
  'Bottom',
  'Die',
  'Others',
];

// Icons for each fixed section chip
const _kSectionIcons = <String, IconData>{
  'Tray': Icons.grid_view_rounded,
  'Salophin': Icons.layers_outlined,
  'Box Cover': Icons.inventory_2_outlined,
  'Inner': Icons.open_in_full_rounded,
  'Bottom': Icons.vertical_align_bottom_rounded,
  'Die': Icons.cut_outlined,
  'Others': Icons.more_horiz_rounded,
};

// Collection used purely as a fast "does this product name already exist"
// lookup index. Document ID = normalized product name.//masterProductNameIndex
const String _kNameIndexCollection = 'masterProducts';

String _normalizeName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class _SectionRow {
  final TextEditingController detail = TextEditingController();
  final TextEditingController qty = TextEditingController();
  final TextEditingController price = TextEditingController();

  void dispose() {
    detail.dispose();
    qty.dispose();
    price.dispose();
  }

  Map<String, dynamic> toMap() => {
    'detail': detail.text.trim(),
    'qty': int.tryParse(qty.text.trim()) ?? 0,
    'price': price.text.trim(),
  };
}

class _PackagingSection {
  final String name;
  final bool isCustom;
  final TextEditingController titleCtrl;
  final List<_SectionRow> rows;

  _PackagingSection({
    required this.name,
    this.isCustom = false,
    String? titleOverride,
  }) : titleCtrl = TextEditingController(text: titleOverride ?? name),
       rows = [_SectionRow()];

  void addRow() => rows.add(_SectionRow());

  void dispose() {
    titleCtrl.dispose();
    for (final r in rows) r.dispose();
  }

  Map<String, dynamic> toMap() => {
    'sectionName': titleCtrl.text.trim().isEmpty ? name : titleCtrl.text.trim(),
    'isCustom': isCustom,
    'rows': rows.map((r) => r.toMap()).toList(),
  };
}

class MasterProductEntryScreen extends StatefulWidget {
  const MasterProductEntryScreen({super.key});

  @override
  State<MasterProductEntryScreen> createState() =>
      _MasterProductEntryScreenState();
}

class _MasterProductEntryScreenState extends State<MasterProductEntryScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _isSaving = false;

  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _products.add(_emptyProduct());
  }

  // ── Product factory ───────────────────────────────────────────────────────
  Map<String, dynamic> _emptyProduct() => {
    'id': DateTime.now().microsecondsSinceEpoch.toString(),
    'name': TextEditingController(),
    'qty': TextEditingController(),
    'price': TextEditingController(),
    'details': TextEditingController(),
    'images': <XFile>[],
    'fixedActive': <String, bool>{for (final s in _kFixedSections) s: false},
    'fixedSections': <String, _PackagingSection>{},
    'customSections': <_PackagingSection>[],
    // ── duplicate-name check state ──
    'nameExists': false,
    'checkingName': false,
    'nameCheckTimer': null,
  };

  void _addProduct() => setState(() => _products.add(_emptyProduct()));

  void _removeProduct(int i) {
    if (_products.length == 1) return;
    setState(() {
      _disposeProduct(_products[i]);
      _products.removeAt(i);
    });
  }

  void _disposeProduct(Map<String, dynamic> p) {
    (p['nameCheckTimer'] as Timer?)?.cancel();
    (p['name'] as TextEditingController).dispose();
    (p['qty'] as TextEditingController).dispose();
    (p['price'] as TextEditingController).dispose();
    (p['details'] as TextEditingController).dispose();
    for (final s
        in (p['fixedSections'] as Map<String, _PackagingSection>).values) {
      s.dispose();
    }
    for (final s in (p['customSections'] as List<_PackagingSection>)) {
      s.dispose();
    }
  }

  // ── Duplicate product-name check ─────────────────────────────────────────
  // Debounced check against a lightweight Firestore index collection so we
  // don't hammer Firestore on every keystroke.
  void _onNameChanged(Map<String, dynamic> p, String value) {
    (p['nameCheckTimer'] as Timer?)?.cancel();

    final key = _normalizeName(value);
    if (key.isEmpty) {
      setState(() {
        p['nameExists'] = false;
        p['checkingName'] = false;
      });
      return;
    }

    setState(() => p['checkingName'] = true);

    p['nameCheckTimer'] = Timer(const Duration(milliseconds: 500), () async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(_kNameIndexCollection)
            .doc(key)
            .get();
        if (!mounted) return;
        setState(() {
          p['nameExists'] = doc.exists;
          p['checkingName'] = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => p['checkingName'] = false);
      }
    });
  }

  // ── Toggle fixed chip ─────────────────────────────────────────────────────
  void _toggleFixed(Map<String, dynamic> p, String key) {
    final active = p['fixedActive'] as Map<String, bool>;
    final sections = p['fixedSections'] as Map<String, _PackagingSection>;
    setState(() {
      if (active[key] == true) {
        active[key] = false;
        sections[key]?.dispose();
        sections.remove(key);
      } else {
        active[key] = true;
        sections[key] = _PackagingSection(name: key);
      }
    });
  }

  // ── Add Extra section ─────────────────────────────────────────────────────
  // void _addCustomSection(Map<String, dynamic> p) {
  //   setState(() {
  //     (p['customSections'] as List<_PackagingSection>).add(
  //       _PackagingSection(name: 'Extra', isCustom: true, titleOverride: ''),
  //     );
  //   });
  // }

  // void _removeCustomSection(Map<String, dynamic> p, int i) {
  //   setState(() {
  //     final list = p['customSections'] as List<_PackagingSection>;
  //     list[i].dispose();
  //     list.removeAt(i);
  //   });
  // }

  // ── Images ────────────────────────────────────────────────────────────────
  Future<void> _pickImages(int index) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ImagePickerSheet(
        onGallery: () async {
          Navigator.pop(context);
          final files = await _picker.pickMultiImage(imageQuality: 80);
          if (files.isNotEmpty) {
            setState(
              () => (_products[index]['images'] as List<XFile>).addAll(files),
            );
          }
        },
        onCamera: () async {
          Navigator.pop(context);
          final f = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );
          if (f != null) {
            setState(() => (_products[index]['images'] as List<XFile>).add(f));
          }
        },
      ),
    );
  }

  // ── Duplicate confirmation dialog ───────────────────────────────────────
  Future<bool> _showDuplicateConfirmDialog(
    List<Map<String, dynamic>> dupes,
  ) async {
    final names = dupes
        .map((p) => (p['name'] as TextEditingController).text.trim())
        .join(', ');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _C.danger),
            SizedBox(width: 8),
            Text(
              'Naam pehle se maujood hai',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Ye product naam pehle se Firebase me save hai:\n\n$names\n\nKya aap phir bhi save karna chahte hain?',
          style: const TextStyle(color: _C.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Haan, Save Karo'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // If any product name was flagged as a duplicate, confirm before proceeding.
    final dupes = _products.where((p) => p['nameExists'] == true).toList();
    if (dupes.isNotEmpty) {
      final proceed = await _showDuplicateConfirmDialog(dupes);
      if (!proceed) return;
    }

    setState(() => _isSaving = true);
    try {
      final col = FirebaseFirestore.instance.collection('masterProducts');
      final saveId = DateTime.now().millisecondsSinceEpoch.toString();
      final List<Map<String, dynamic>> productsData = [];

      for (int i = 0; i < _products.length; i++) {
        final p = _products[i];

        // upload images
        final imgs = p['images'] as List<XFile>;
        final List<String> urls = [];
        for (int j = 0; j < imgs.length; j++) {
          final ref = FirebaseStorage.instance.ref().child(
            'masterProducts/$saveId/p${i}_img$j.jpg',
          );
          if (kIsWeb) {
            await ref.putData(
              await imgs[j].readAsBytes(),
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else {
            await ref.putFile(File(imgs[j].path));
          }
          urls.add(await ref.getDownloadURL());
        }

        final fixedData = (p['fixedSections'] as Map<String, _PackagingSection>)
            .map((k, v) => MapEntry(k, v.toMap()));

        final customData = (p['customSections'] as List<_PackagingSection>)
            .map((s) => s.toMap())
            .toList();

        final productName = (p['name'] as TextEditingController).text.trim();

        productsData.add({
          'productName': productName,
          'quantity':
              double.tryParse(
                (p['qty'] as TextEditingController).text.trim(),
              ) ??
              0,
          'price':
              double.tryParse(
                (p['price'] as TextEditingController).text.trim(),
              ) ??
              0,
          'details': (p['details'] as TextEditingController).text.trim(),
          'images': urls,
          'fixedSections': fixedData,
          'customSections': customData,
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Update / create the name-index entry so future entries with the
        // same name can be detected instantly.
        final nameKey = _normalizeName(productName);
        if (nameKey.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection(_kNameIndexCollection)
              .doc(nameKey)
              .set({
                'productName': productName,
                'lastEntryId': saveId,
                'lastSavedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }

      await col.doc(saveId).set({
        'entryId': saveId,
        'products': productsData,
        'count': productsData.length,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      // Dispose old products and create fresh ones BEFORE any UI update
      for (var p in _products) _disposeProduct(p);
      final fresh = [_emptyProduct()];
      setState(() {
        _products = fresh;
      });
      _showSnack('Saved successfully!', ok: true);
    } catch (e) {
      _showSnack('Error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: ok ? _C.success : _C.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
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
                // ── LEFT SIDE — Back button ──
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
                        'Master Product Entry',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage Master Products & Packaging Sections',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // ── RIGHT SIDE — Master View button ──
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MasterViewScreen(),
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
                      Icons.list_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
          children: [
            _headerBanner(),
            const SizedBox(height: 20),
            ...List.generate(_products.length, (i) => _buildProductCard(i)),
            const SizedBox(height: 4),
          //  _addProductBtn(),
            const SizedBox(height: 24),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _headerBanner() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: _C.grad,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _C.primary.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_box_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Product Entry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Fill in product details & packaging sections below',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_products.length} Product(s)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );

  // ── Product Card ──────────────────────────────────────────────────────────
  Widget _buildProductCard(int idx) {
    final p = _products[idx];
    final images = p['images'] as List<XFile>;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.primary.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _C.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Card Header ─
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.primary.withOpacity(0.08),
                  _C.primary.withOpacity(0.02),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: _C.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: _C.grad,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Product ${idx + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: _C.primary,
                  ),
                ),
                const Spacer(),
                if (_products.length > 1) ...[
                  GestureDetector(
                    onTap: () => _showDeleteDialog(idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _C.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _C.danger.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: _C.danger,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Remove',
                            style: TextStyle(
                              color: _C.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─ Section: Basic Info ─
                _dividerLabel('Basic Information', Icons.info_outline),
                const SizedBox(height: 14),

                _field(
                  p['name'] as TextEditingController,
                  'Product Name',
                  Icons.shopping_bag_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Product name is required'
                      : null,
                  onChanged: (v) => _onNameChanged(p, v),
                ),
                // ── duplicate-name status badge ──
                _nameStatusBadge(p),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _field(
                        p['qty'] as TextEditingController,
                        'Quantity',
                        Icons.format_list_numbered,
                        keyboardType: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        p['price'] as TextEditingController,
                        'Price (₹)',
                        Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _field(
                  p['details'] as TextEditingController,
                  'Details / Description',
                  Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),

                _AmountChip(
                  qtyCtrl: p['qty'] as TextEditingController,
                  priceCtrl: p['price'] as TextEditingController,
                ),

                const SizedBox(height: 22),

                // ─ Section: Packaging ─
                // _dividerLabel('Packaging Sections', Icons.category_outlined),
                // const SizedBox(height: 6),
                // _packagingHint(),
                // const SizedBox(height: 12),

                // _buildFixedChips(p),

                // // ─ Fixed section forms ─
                // ...(p['fixedSections'] as Map<String, _PackagingSection>)
                //     .entries
                //     .map((e) => _SectionForm(section: e.value)),

                // const SizedBox(height: 20),

                // // ─ Section: Extra Custom ─
                // _dividerLabel(
                //   'Extra Sections',
                //   Icons.add_box_outlined,
                //   color: _C.amber,
                // ),
                // const SizedBox(height: 12),

                // _addExtraSectionBtn(() => _addCustomSection(p)),
                // const SizedBox(height: 8),

                // ...List.generate(
                //   (p['customSections'] as List<_PackagingSection>).length,
                //   (ci) {
                //     final sec =
                //         (p['customSections'] as List<_PackagingSection>)[ci];
                //     return _SectionForm(
                //       section: sec,
                //       isCustom: true,
                //       onRemoveSection: () => _removeCustomSection(p, ci),
                //     );
                //   },
                // ),

                // const SizedBox(height: 20),

                // ─ Section: Images ─
                _dividerLabel('Product Images', Icons.photo_library_outlined),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...images.asMap().entries.map(
                      (entry) => _ImageThumb(
                        xfile: entry.value,
                        allImages: images,
                        index: entry.key,
                        onRemove: () =>
                            setState(() => images.remove(entry.value)),
                      ),
                    ),
                    _AddImageBtn(onTap: () => _pickImages(idx)),
                  ],
                ),

                if (images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${images.length} image(s) selected',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _C.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Duplicate-name status badge (below Product Name field) ────────────────
  Widget _nameStatusBadge(Map<String, dynamic> p) {
    final name = (p['name'] as TextEditingController).text.trim();
    if (name.isEmpty) return const SizedBox.shrink();

    final checking = p['checkingName'] == true;
    final exists = p['nameExists'] == true;

    if (checking) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: Row(
          children: const [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: _C.muted),
            ),
            SizedBox(width: 8),
            Text(
              'Checking availability...',
              style: TextStyle(fontSize: 12, color: _C.muted),
            ),
          ],
        ),
      );
    }

    if (exists) {
      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _C.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.danger.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _C.danger, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This product name is already saved!',
                style: TextStyle(
                  fontSize: 12,
                  color: _C.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _C.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.success.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: _C.success, size: 16),
          SizedBox(width: 8),
          Text(
            'Name is available (new)',
            style: TextStyle(
              fontSize: 12,
              color: _C.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Fixed chips ───────────────────────────────────────────────────────────
  Widget _buildFixedChips(Map<String, dynamic> p) {
    final active = p['fixedActive'] as Map<String, bool>;
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: _kFixedSections.map((key) {
        final on = active[key] == true;
        final icon = _kSectionIcons[key] ?? Icons.label_outline;
        return GestureDetector(
          onTap: () => _toggleFixed(p, key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              gradient: on ? _C.grad : null,
              color: on ? null : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: on ? _C.primary : _C.mutedLight,
                width: 1.5,
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: _C.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  on ? Icons.check_circle : icon,
                  size: 14,
                  color: on ? Colors.white : _C.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: on ? Colors.white : const Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _dividerLabel(
    String text,
    IconData icon, {
    Color color = _C.primary,
  }) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
      const SizedBox(width: 10),
      Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Divider(color: color.withOpacity(0.2), thickness: 1)),
    ],
  );

  Widget _packagingHint() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _C.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _C.primary.withOpacity(0.15)),
    ),
    child: Row(
      children: [
        const Icon(Icons.touch_app_outlined, color: _C.primary, size: 14),
        const SizedBox(width: 8),
        Text(
          'Tap any section chip to expand its form',
          style: TextStyle(
            fontSize: 12,
            color: _C.primary.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );

  Widget _addExtraSectionBtn(VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.amber.withOpacity(0.5), width: 1.5),
        color: _C.amber.withOpacity(0.04),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _C.amber.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: _C.amber, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'Add Extra Section',
            style: TextStyle(
              color: _C.amber,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  // Widget _addProductBtn() => InkWell(
  //   onTap: _addProduct,
  //   borderRadius: BorderRadius.circular(12),
  //   child: Container(
  //     padding: const EdgeInsets.symmetric(vertical: 14),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: _C.primary.withOpacity(0.4), width: 1.8),
  //       color: _C.primary.withOpacity(0.03),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(6),
  //           decoration: BoxDecoration(
  //             color: _C.primary.withOpacity(0.1),
  //             shape: BoxShape.circle,
  //           ),
  //           child: const Icon(Icons.add, color: _C.primary, size: 18),
  //         ),
  //         const SizedBox(width: 10),
  //         const Text(
  //           'Add Another Product',
  //           style: TextStyle(
  //             color: _C.primary,
  //             fontWeight: FontWeight.w700,
  //             fontSize: 14,
  //           ),
  //         ),
  //       ],
  //     ),
  //   ),
  // );

  void _showDeleteDialog(int idx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: _C.danger),
            SizedBox(width: 8),
            Text(
              'Remove Product?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Product ${idx + 1} and all its data will be removed.',
          style: const TextStyle(color: _C.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _removeProduct(idx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    maxLines: maxLines,
    inputFormatters: formatters,
    onChanged: onChanged,
    validator: validator,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    decoration: _dec(label, icon),
  );

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _C.primary, size: 20),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.danger, width: 2),
    ),
    filled: true,
    fillColor: _C.surface,
    contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
    labelStyle: const TextStyle(fontSize: 13, color: _C.muted),
    errorStyle: const TextStyle(fontSize: 11),
  );

  Widget _saveButton() => Container(
    decoration: BoxDecoration(
      gradient: _C.grad,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: _C.primary.withOpacity(0.45),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 17),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: _isSaving
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 22),
                SizedBox(width: 10),
                Text(
                  'Save to Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
    ),
  );

  @override
  void dispose() {
    for (var p in _products) _disposeProduct(p);
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION FORM
// ─────────────────────────────────────────────────────────────────────────────
class _SectionForm extends StatefulWidget {
  final _PackagingSection section;
  final bool isCustom;
  final VoidCallback? onRemoveSection;

  const _SectionForm({
    required this.section,
    this.isCustom = false,
    this.onRemoveSection,
  });

  @override
  State<_SectionForm> createState() => _SectionFormState();
}

class _SectionFormState extends State<_SectionForm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sec = widget.section;
    final isCustom = widget.isCustom;
    final color = isCustom ? _C.amber : _C.primary;
    final bgColor = isCustom
        ? const Color(0xFFFFF8F0)
        : const Color(0xFFF0FAFA);
    final icon = isCustom
        ? Icons.tune_rounded
        : (_kSectionIcons[sec.name] ?? Icons.label_outline);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Section Header ─
            Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: color.withOpacity(0.18)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 10),
                  isCustom
                      ? Expanded(
                          child: TextField(
                            controller: sec.titleCtrl,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: color,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter section name...',
                              hintStyle: TextStyle(
                                color: color.withOpacity(0.4),
                                fontSize: 13,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: color.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: color.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: color,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        )
                      : Expanded(
                          child: Text(
                            sec.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: color,
                            ),
                          ),
                        ),
                  if (widget.onRemoveSection != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onRemoveSection,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _C.danger.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: _C.danger,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // ─ Column Labels ─
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Qty',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Price (₹)',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ─ Rows ─
                  ...List.generate(sec.rows.length, (ri) {
                    final row = sec.rows[ri];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _miniField(
                              row.detail,
                              'e.g. Red Tray',
                              color: color,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _miniField(
                              row.qty,
                              'Qty',
                              color: color,
                              keyboardType: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _miniField(
                              row.price,
                              '0.00',
                              color: color,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniField(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
    Color color = _C.primary,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    maxLines: maxLines,
    inputFormatters: formatters,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: _C.muted),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AMOUNT CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _AmountChip extends StatefulWidget {
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  const _AmountChip({required this.qtyCtrl, required this.priceCtrl});

  @override
  State<_AmountChip> createState() => _AmountChipState();
}

class _AmountChipState extends State<_AmountChip> {
  @override
  void initState() {
    super.initState();
    widget.qtyCtrl.addListener(_r);
    widget.priceCtrl.addListener(_r);
  }

  void _r() => setState(() {});

  @override
  void dispose() {
    widget.qtyCtrl.removeListener(_r);
    widget.priceCtrl.removeListener(_r);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qty = double.tryParse(widget.qtyCtrl.text) ?? 0;
    final price = double.tryParse(widget.priceCtrl.text) ?? 0;
    final total = qty * price;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.primary.withOpacity(0.1), _C.primary.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calculate_outlined,
              color: _C.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 11, color: _C.muted),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: _C.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$qty × ₹$price',
              style: const TextStyle(
                fontSize: 11,
                color: _C.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE THUMBNAIL
// ─────────────────────────────────────────────────────────────────────────────
class _ImageThumb extends StatelessWidget {
  final XFile xfile;
  final List<XFile> allImages;
  final int index;
  final VoidCallback onRemove;

  const _ImageThumb({
    required this.xfile,
    required this.allImages,
    required this.index,
    required this.onRemove,
  });

  void _openPreview(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) =>
            _ImagePreviewScreen(images: allImages, initialIndex: index),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _openPreview(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb
                        ? Image.network(xfile.path, fit: BoxFit.cover)
                        : Image.file(File(xfile.path), fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Icon(
                          Icons.zoom_in_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _C.danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _C.danger.withOpacity(0.4), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE PREVIEW SCREEN  (fullscreen, swipeable, pinch-to-zoom)
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePreviewScreen extends StatefulWidget {
  final List<XFile> images;
  final int initialIndex;
  const _ImagePreviewScreen({required this.images, required this.initialIndex});

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen> {
  late final PageController _page;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _page = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─ Swipeable zoomable images ─
          PageView.builder(
            controller: _page,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final img = widget.images[i];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: kIsWeb
                      ? Image.network(img.path, fit: BoxFit.contain)
                      : Image.file(File(img.path), fit: BoxFit.contain),
                ),
              );
            },
          ),

          // ─ Top bar ─
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_current + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─ Hint text ─
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pinch to zoom  •  Swipe to navigate',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
          ),

          // ─ Dot indicators ─
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

          // ─ Prev arrow ─
          if (_current > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _page.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

          // ─ Next arrow ─
          if (_current < widget.images.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _page.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD IMAGE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _AddImageBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddImageBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        border: Border.all(color: _C.primary, width: 1.8),
        borderRadius: BorderRadius.circular(12),
        color: _C.primary.withOpacity(0.04),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo_outlined,
              color: _C.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add Photo',
            style: TextStyle(
              fontSize: 10,
              color: _C.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePickerSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  const _ImagePickerSheet({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14),
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
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose a source to upload from',
              style: TextStyle(fontSize: 13, color: _C.muted),
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _C.grad,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              title: const Text(
                'Photo Gallery',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Select one or multiple photos'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: _C.muted,
              ),
              onTap: onGallery,
            ),
            const Divider(indent: 20, endIndent: 20),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              title: const Text(
                'Camera',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Take a new photo instantly'),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: _C.muted,
              ),
              onTap: onCamera,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.grey.shade100,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: _C.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
