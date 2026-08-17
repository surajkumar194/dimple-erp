import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/challan/DispatchFullPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class DispatchEditorScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final String jobDocId;

  const DispatchEditorScreen({
    super.key,
    required this.jobData,
    required this.jobDocId,
  });

  @override
  State<DispatchEditorScreen> createState() => _DispatchEditorScreenState();
}

class _DispatchEditorScreenState extends State<DispatchEditorScreen> {
  List<DispatchItem> _items = [];
  List<TextEditingController> _qtyControllers = [];
  List<TextEditingController> _packetControllers = [];

  String _autoChallNo = '';
  int _challNumericId = 1;

  final TextEditingController _driverNameCtrl = TextEditingController();
  final TextEditingController _signatureCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingChallNo = true;
  bool _isLoadingItems = true;

@override
void initState() {
  super.initState();

  _driverNameCtrl.text =
      widget.jobData['driverName']?.toString() ?? '';

  _signatureCtrl.text =
      widget.jobData['signature']?.toString() ?? '';

  _remarksCtrl.text =
      widget.jobData['remarks']?.toString() ?? '';

  _loadItemsWithDispatchHistory();
  _fetchNextChallanNumber();
}
Future<void> _loadItemsWithDispatchHistory() async {
  final List products = widget.jobData['products'] ?? [];

  final prevDispatches = await FirebaseFirestore.instance
      .collection('dispatchSales')
      .where('jobDocId', isEqualTo: widget.jobDocId)
      .get();

  final Map<String, int> dispatchedMap = {};
  for (final doc in prevDispatches.docs) {
    final dispItems = doc.data()['items'] as List<dynamic>? ?? [];
    for (final di in dispItems) {
      final name = di['productName']?.toString() ?? '';
      final qty = int.tryParse(di['quantity']?.toString() ?? '0') ?? 0;
      dispatchedMap[name] = (dispatchedMap[name] ?? 0) + qty;
    }
  }

  final items = products.map<DispatchItem>((p) {
    final int totalQty = int.tryParse(p['quantity']?.toString() ?? '0') ?? 0;
    final double rate = double.tryParse(p['price']?.toString() ?? '0') ?? 0;
    final int packets = int.tryParse(p['packets']?.toString() ?? '0') ?? 0;
    final String name = p['productName'] ?? p['name'] ?? 'Product';
    final String detail = p['remarks'] ?? p['detail'] ?? '';
    final int dispatched = dispatchedMap[name] ?? 0;

    // ★★★ YE HAI ASLI FIX — order ke product se images nikalna ★★★
    final List<String> images = (p['images'] is List)
        ? List<String>.from(p['images'].map((e) => e.toString()))
        : <String>[];

    return DispatchItem(
      productName: name,
      detail: detail,
      totalQuantity: totalQty,
      rate: rate,
      dispatchedQty: dispatched,
      currentPackets: packets,
      jobDocId: widget.jobDocId,
      jobNo:
          widget.jobData['jobCardNumber'] ??
          widget.jobData['jobNo'] ??
          widget.jobDocId,
      images: images, // ★★★ YE PASS KARNA ZAROORI HAI ★★★
    );
  }).toList();

  final qtyCtrl = items.map((e) => TextEditingController(text: '')).toList();
  final pktCtrl = items.map((e) => TextEditingController(text: '')).toList();

  setState(() {
    _items = items;
    _qtyControllers = qtyCtrl;
    _packetControllers = pktCtrl;
    _isLoadingItems = false;
  });
}

  Future<void> _fetchNextChallanNumber() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('dispatchSales')
          .orderBy('challNumericId', descending: true)
          .limit(1)
          .get();

      int nextNum = 1;
      if (snap.docs.isNotEmpty) {
        final last = snap.docs.first.data()['challNumericId'] as int? ?? 0;
        nextNum = last + 1;
      }
      if (mounted) {
        setState(() {
          _challNumericId = nextNum;
          _autoChallNo = 'CH$nextNum';
          _isLoadingChallNo = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _challNumericId = 1;
          _autoChallNo = 'CH1';
          _isLoadingChallNo = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var c in _qtyControllers) c.dispose();
    for (var c in _packetControllers) c.dispose();
    _driverNameCtrl.dispose();
    _signatureCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _addManualProduct() async {
    final jobNo =
        widget.jobData['jobCardNumber'] ??
        widget.jobData['jobNo'] ??
        widget.jobDocId;
    final newItem = await showAddProductDialog(
      context,
      jobDocId: widget.jobDocId,
      jobNo: jobNo.toString(),
    );
    if (newItem == null) return;
    setState(() {
      _items.add(newItem);
      _qtyControllers.add(TextEditingController(text: ''));
      _packetControllers.add(
        TextEditingController(
          text: newItem.currentPackets > 0
              ? newItem.currentPackets.toString()
              : '',
        ),
      );
    });
  }

  List<DispatchItem> get _selectedItems =>
      _items.where((e) => e.isSelected && !e.isFullyDispatched).toList();

  int get _totalQty => _selectedItems.fold(0, (s, e) => s + e.inputQty);
  int get _totalPackets =>
      _selectedItems.fold(0, (s, e) => s + e.currentPackets);
  bool get _hasOverDispatched => _selectedItems.any((e) => e.isOverDispatched);

  String? _validate() {
    if (_selectedItems.isEmpty) return 'No items selected for dispatch.';
    for (final item in _selectedItems) {
      if (item.inputQty <= 0)
        return '${item.productName}: Quantity not entered or invalid';
    }
    return null;
  }

Future<bool?> _showOverDispatchDialog() {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),

      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Over Dispatch Warning',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Some products exceed the remaining order quantity.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.orange.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange.shade800,
                  size: 20,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'The following items contain extra dispatch quantities. These products will be highlighted as EXTRA in the generated PDF.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ..._selectedItems
              .where((e) => e.isOverDispatched)
              .map(
                (e) {

                  final extraQty = e.inputQty - e.remainingQty;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      children: [

                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: Colors.red.shade700,
                              size: 22,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                e.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Dispatch Qty: ${e.inputQty}   |   Remaining Qty: ${e.remainingQty}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+$extraQty',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

          const SizedBox(height: 6),

          Text(
            'Do you want to continue and save this dispatch?',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),

      actions: [

        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
          ),
          label: const Text(
            'Continue & Save',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

  Future<void> _saveDispatch() async {
    for (int i = 0; i < _items.length; i++) {
      _items[i].inputQty = int.tryParse(_qtyControllers[i].text) ?? 0;
      _items[i].currentPackets =
          int.tryParse(_packetControllers[i].text) ?? _items[i].currentPackets;
    }

    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange.shade700),
      );
      return;
    }

    if (_isLoadingChallNo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challan number loading...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hasOverDispatched) {
      final confirmed = await _showOverDispatchDialog();
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final customerName =
          widget.jobData['customerName'] ?? widget.jobData['customer'] ?? 'N/A';
      final jobNo =
          widget.jobData['jobCardNumber'] ??
          widget.jobData['jobNo'] ??
          widget.jobDocId;

      final dispatchItemsList = _selectedItems.map((e) => e.toMap()).toList();

      final dispatchData = <String, dynamic>{
        'challNo': _autoChallNo,
        'challNumericId': _challNumericId,
        'jobDocId': widget.jobDocId,
        'jobCardNumber': jobNo,
        'customerName': customerName,
        'companyName':
            widget.jobData['companyName'] ?? widget.jobData['company'] ?? '',
        'phone': widget.jobData['phone'] ?? '',
        'location': widget.jobData['location'] ?? '',
        'signature': _signatureCtrl.text.trim(),
        'driverName': _driverNameCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
        'date': Timestamp.now(),
        'totalQty': _totalQty,
        'totalPackets': _totalPackets,
        'items': dispatchItemsList,
        'status': 'Dispatched',
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('dispatchSales')
          .add(dispatchData);

      bool allDone = _items.every((item) {
        if (item.isSelected) {
          return (item.dispatchedQty + item.inputQty) >= item.totalQuantity;
        }
        return item.isFullyDispatched;
      });

  await FirebaseFirestore.instance
    .collection('orders')
    .doc(widget.jobDocId)
    .update({
  'dispatchCreated': allDone,
    'hasDispatch': true,          // ✅ Nayi field add karo

  'dispatchChallNo': _autoChallNo,
  'lastDispatchAt': Timestamp.now(),

  'driverName': _driverNameCtrl.text.trim(),
  'signature': _signatureCtrl.text.trim(),
  'remarks': _remarksCtrl.text.trim(),
});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved! Challan No: $_autoChallNo'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      if (!mounted) return;
      final bool? withRate = await showPdfTypeDialog(context);
      if (withRate == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      await generateChallanPDF(dispatchData, showRate: withRate);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName =
        widget.jobData['customerName'] ?? widget.jobData['customer'] ?? 'N/A';
    final jobNo =
        widget.jobData['jobCardNumber'] ??
        widget.jobData['jobNo'] ??
        widget.jobDocId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                  Color(0xFF0277BD),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Dispatch: $jobNo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: _isLoadingChallNo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _autoChallNo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoadingItems
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challan Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF283593)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auto Challan Number',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoadingChallNo
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _autoChallNo,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ],
                        ),
                        const Spacer(),
                        const Column(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Auto',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _sectionCard(
                    title: 'Dispatch Details',
                    icon: Icons.local_shipping_rounded,
                    color: const Color(0xFF0D47A1),
                    child: Column(
                      children: [
                        _inputRow(
                          'Driver Name',
                          _driverNameCtrl,
                          hint: 'Driver ka naam',
                        ),
                        const SizedBox(height: 12),
                        _inputRow(
                          'Signature',
                          _signatureCtrl,
                          hint: 'Hastaakshar / Naam',
                        ),
                        const SizedBox(height: 12),
                        _inputRow(
                          'Remarks',
                          _remarksCtrl,
                          hint: 'Optional remarks',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _sectionCard(
                    title: 'Items — Select & Quantity added',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF1B5E20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          // child: Row(
                          //   children: [
                          //     Icon(
                          //       Icons.info_outline,
                          //       size: 15,
                          //       color: Colors.blue.shade700,
                          //     ),
                          //     const SizedBox(width: 8),
                          //     Expanded(
                          //       child: Text(
                          //         'Item tap karein select/deselect ke liye. Order se zyada quantity allowed hai.',
                          //         style: TextStyle(
                          //           fontSize: 11,
                          //           color: Colors.blue.shade700,
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ),
                        const SizedBox(height: 5),
                        ..._items.asMap().entries.map(
                          (e) => _buildProductCard(e.key, e.value),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _addManualProduct,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.amber.shade400,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade600,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Extra Product Added',
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                // const SizedBox(width: 6),
                                // Text(
                                //   '(PDF mein show hoga)',
                                //   style: TextStyle(
                                //     color: Colors.amber.shade600,
                                //     fontSize: 11,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_hasOverDispatched)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.red.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Over-Dispatch Alert',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'No item selected',
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Summary
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedItems.isEmpty
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : [
                                const Color(0xFF1A237E),
                                const Color(0xFF1565C0),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.summarize_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Summary',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _selectedItems.isEmpty
                                  ? 'No items selected'
                                  : 'Total Qty: $_totalQty   |   Total Packets: $_totalPackets',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _selectedItems.isEmpty
                              ? [Colors.grey.shade400, Colors.grey.shade600]
                              : [
                                  const Color(0xFF1B5E20),
                                  const Color(0xFF388E3C),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: (_isSaving || _selectedItems.isEmpty)
                            ? null
                            : _saveDispatch,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_alt_rounded, size: 22),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          disabledForegroundColor: Colors.white60,
                          disabledBackgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }

  Widget _buildProductCard(int i, DispatchItem item) {
    final bool locked = item.isFullyDispatched;
    final bool selected = item.isSelected && !locked;
    final bool isManual = item.isManuallyAdded;
    final bool liveOver =
        !isManual &&
        selected &&
        _items[i].inputQty > item.remainingQty &&
        item.remainingQty > 0;

    Color cardBg;
    Color cardBorder;
    if (locked) {
      cardBg = Colors.green.shade50;
      cardBorder = Colors.green.shade300;
    } else if (isManual && selected) {
      cardBg = Colors.amber.shade50;
      cardBorder = Colors.amber.shade400;
    } else if (liveOver) {
      cardBg = Colors.red.shade50;
      cardBorder = Colors.red.shade400;
    } else if (selected) {
      cardBg = const Color(0xFFE8EAF6);
      cardBorder = const Color(0xFF1A237E);
    } else {
      cardBg = Colors.white;
      cardBorder = Colors.grey.shade200;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorder,
          width: (selected || locked || liveOver) ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: locked
                ? null
                : () {
                    setState(() {
                      _items[i].isSelected = !_items[i].isSelected;
                      if (!_items[i].isSelected) {
                        _qtyControllers[i].text = '';
                        _packetControllers[i].text = '';
                        _items[i].inputQty = 0;
                      }
                    });
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: locked
                    ? Colors.green.shade100
                    : isManual && selected
                    ? Colors.amber.shade100
                    : liveOver
                    ? Colors.red.shade100
                    : selected
                    ? const Color(0xFF1A237E).withOpacity(0.08)
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: locked
                          ? Colors.green
                          : isManual && selected
                          ? Colors.amber.shade600
                          : liveOver
                          ? Colors.red.shade600
                          : selected
                          ? const Color(0xFF1A237E)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      locked
                          ? Icons.lock_rounded
                          : isManual
                          ? Icons.add_rounded
                          : liveOver
                          ? Icons.warning_rounded
                          : selected
                          ? Icons.check_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: locked || selected
                          ? Colors.white
                          : Colors.grey.shade500,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.productName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: locked
                                      ? Colors.green.shade800
                                      : liveOver
                                      ? Colors.red.shade700
                                      : isManual
                                      ? Colors.amber.shade800
                                      : const Color(0xFF1A237E),
                                ),
                              ),
                            ),
                            if (isManual) ...[
                              const SizedBox(width: 6),
                              _badge('EXTRA', Colors.amber.shade600),
                            ],
                            if (liveOver) ...[
                              const SizedBox(width: 6),
                              _badge('OVER', Colors.red.shade600),
                            ],
                          ],
                        ),
                        if (item.detail.isNotEmpty)
                          Text(
                            item.detail,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (locked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'FULLY\nDISPATCHED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isManual)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Manual Item',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'No limit',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total: ${item.totalQuantity}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          'Done: ${item.dispatchedQty}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Left: ${item.remainingQty}',
                          style: TextStyle(
                            fontSize: 12,
                            color: liveOver
                                ? Colors.red.shade700
                                : Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (item.rate > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Price: ${item.rate.toStringAsFixed(2)}/-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: liveOver
                                      ? [
                                          Colors.red.shade600,
                                          Colors.red.shade800,
                                        ]
                                      : [
                                          const Color(0xFF1565C0),
                                          const Color(0xFF1A237E),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        liveOver
                                            ? Icons.warning_rounded
                                            : Icons.numbers_rounded,
                                        color: Colors.white70,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        liveOver ? 'QTY (OVER!)' : 'QUANTITY',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      controller: _qtyControllers[i],
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (v) => setState(
                                        () => _items[i].inputQty =
                                            int.tryParse(v) ?? 0,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isManual
                                  ? 'No limit (manual)'
                                  : liveOver
                                  ? '⚠ Max: ${item.remainingQty}'
                                  : 'Max: ${item.remainingQty}',
                              style: TextStyle(
                                fontSize: 10,
                                color: liveOver
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.white70,
                                    size: 13,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'PACKETS',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _packetControllers[i],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (v) => setState(
                                    () => _items[i].currentPackets =
                                        int.tryParse(v) ?? 0,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (isManual)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _items.removeAt(i);
                  _qtyControllers.removeAt(i);
                  _packetControllers.removeAt(i);
                });
              },
              icon: Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.red.shade400,
              ),
              label: Text(
                'Remove',
                style: TextStyle(fontSize: 12, color: Colors.red.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _inputRow(
    String label,
    TextEditingController ctrl, {
    String hint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF4F6FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
