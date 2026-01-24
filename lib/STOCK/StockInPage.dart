import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StockInPage extends StatefulWidget {
  const StockInPage({super.key});

  @override
  _StockInPageState createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
  String? selectedProductId; // store productId
  final qtyCtrl = TextEditingController();
  final remarkCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Color scheme
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF43A047);
  static const Color accentColor = Color(0xFFFF7043);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53E3E);

  Future<void> saveStockIn() async {
    if (!_formKey.currentState!.validate() || selectedProductId == null) return;

    setState(() => isLoading = true);
    try {
      final qty = int.parse(qtyCtrl.text);
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

      final prodRef = FirebaseFirestore.instance.collection('products').doc(selectedProductId);
      final stockColl = FirebaseFirestore.instance.collection('stock');

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(prodRef);
        if (!snap.exists) throw Exception('Selected product not found');

        final d = snap.data() ?? {};
        final name = (d['name'] ?? '').toString();
        final category = (d['category'] ?? '').toString();

        final int currentStock = (d['currentStock'] is num)
            ? (d['currentStock'] as num).toInt()
            : int.tryParse('${d['currentStock'] ?? 0}') ?? 0;
        final int totalStockIn = (d['totalStockIn'] is num)
            ? (d['totalStockIn'] as num).toInt()
            : int.tryParse('${d['totalStockIn'] ?? 0}') ?? 0;

        final newCurrent = currentStock + qty;
        final newTotalIn = totalStockIn + qty;

        tx.update(prodRef, {
          'currentStock': newCurrent,
          'totalStockIn': newTotalIn,
          'updatedAt': Timestamp.now(),
          'updatedBy': userEmail,
        });

        tx.set(stockColl.doc(), {
          'productId': prodRef.id,
          'product': name,     
          'category': category,
          'qty': qty,
          'type': 'IN',
          'remarks': remarkCtrl.text.trim(),
          'date': Timestamp.now(),
          'user': userEmail,
          'balanceAfter': newCurrent,
        });
      });

      qtyCtrl.clear();
      remarkCtrl.clear();
      setState(() => selectedProductId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Stock IN recorded successfully!'),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _formatDate(Timestamp t) {
    final d = t.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
  String _formatTime(Timestamp t) {
    final d = t.toDate();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Stock Management - IN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_box, size: 18),
                SizedBox(width: 6),
                Text('Add Stock', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
              child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Layouts ----------------
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildStockInForm()),
        const SizedBox(width: 24),
        Expanded(flex: 7, child: _buildRecentStockList()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildStockInForm(),
        const SizedBox(height: 20),
        _buildRecentStockList(),
      ],
    );
  }

  // ---------------- Form ----------------
  Widget _buildStockInForm() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add_box, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Add New Stock', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary)),
                      Text('Record incoming inventory', style: TextStyle(color: textSecondary, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Product Selection
              const Text('Product Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 12),
              _buildProductDropdown(),

              const SizedBox(height: 24),

              // Quantity Details + inline totals
              Row(
                children: [
                  const Text('Quantity Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                  const Spacer(),
                  if (selectedProductId != null) _InlineQtyChips(productId: selectedProductId!),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'Enter Quantity',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add, color: successColor, size: 20),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: primaryColor, width: 2)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) {
                  if (v?.isEmpty == true) return 'Quantity is required';
                  final n = int.tryParse(v!);
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Quantity must be positive';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              const Text('Additional Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 12),
              TextFormField(
                controller: remarkCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Add any additional notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: primaryColor, width: 2)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveStockIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                            SizedBox(width: 12),
                            Text('Recording...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.save, size: 22),
                            SizedBox(width: 12),
                            Text('Record Stock IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Product Dropdown (overflow-safe) ----------------
  Widget _buildProductDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 56,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: accentColor),
              borderRadius: BorderRadius.circular(12),
              color: accentColor.withOpacity(0.05),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: accentColor, size: 24),
                SizedBox(width: 12),
                Expanded(child: Text('No products found. Please add products first.',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500))),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: selectedProductId,
          isExpanded: true,
          menuMaxHeight: 360,
          decoration: InputDecoration(
            labelText: 'Select Product',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.inventory_2, color: primaryColor, size: 20),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: primaryColor, width: 2)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),

          // compact selected renderer -> avoids overflow
          selectedItemBuilder: (context) {
            return docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final name = (d['name'] ?? 'Unknown').toString();
              final category = (d['category'] ?? '').toString();
              final text = category.isNotEmpty ? '$name  •  $category' : name;
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            }).toList();
          },

          items: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final name = (d['name'] ?? 'Unknown').toString();
            final category = (d['category'] ?? '').toString();
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (category.isNotEmpty)
                          Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => selectedProductId = v),
          validator: (v) => v == null ? 'Please select a product' : null,
        );
      },
    );
  }

  Widget _buildRecentStockList() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.history, color: successColor, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Recent Stock IN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary)),
                  Text('Latest 10 entries', style: TextStyle(color: textSecondary, fontSize: 14)),
                ],
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              height: 400,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stock')
                    .where('type', isEqualTo: 'IN')
                    .orderBy('date', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(50)),
                            child: Icon(Icons.add_box_outlined, size: 48, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 16),
                          const Text('No Stock IN Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary)),
                          const SizedBox(height: 8),
                          const Text('Start adding stock to see records here', style: TextStyle(fontSize: 14, color: textSecondary)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final s = docs[i].data() as Map<String, dynamic>;
                      final name = (s['product'] ?? s['productName'] ?? 'Unknown Product').toString();
                      final category = (s['category'] ?? '').toString();
                      final qty = (s['qty'] ?? 0).toString();
                      final ts = s['date'] as Timestamp?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 24, backgroundColor: successColor, child: Icon(Icons.add, color: Colors.white, size: 20)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textPrimary)),
                                    ),
                                    if (category.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blueGrey.shade100),
                                        ),
                                        child: Text(category, style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 11)),
                                      ),
                                  ]),
                                  const SizedBox(height: 4),
                                  if (ts != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: textSecondary),
                                        const SizedBox(width: 4),
                                        Text('${_formatDate(ts)} at ${_formatTime(ts)}', style: const TextStyle(color: textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  if (s['remarks'] != null && '${s['remarks']}'.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('${s['remarks']}', style: const TextStyle(fontStyle: FontStyle.italic, color: textSecondary, fontSize: 12)),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text('+$qty', style: const TextStyle(fontWeight: FontWeight.bold, color: successColor, fontSize: 14)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    qtyCtrl.dispose();
    remarkCtrl.dispose();
    super.dispose();
  }
}

// -------- inline chips used in Quantity Details --------
class _InlineQtyChips extends StatelessWidget {
  final String productId;
  const _InlineQtyChips({required this.productId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('products').doc(productId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final d = (snap.data!.data() as Map<String, dynamic>?) ?? {};
        final int current = (d['currentStock'] is num) ? (d['currentStock'] as num).toInt() : int.tryParse('${d['currentStock'] ?? 0}') ?? 0;
        final int totalIn = (d['totalStockIn'] is num) ? (d['totalStockIn'] as num).toInt() : int.tryParse('${d['totalStockIn'] ?? 0}') ?? 0;

        return Wrap(
          spacing: 8,
          children: [
            _chip('Available', current, Colors.indigo),
            _chip('Total In', totalIn, Colors.teal),
          ],
        );
      },
    );
  }

  static Widget _chip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(width: 6),
          const Text('Qty', style: TextStyle(color: _StockInPageState.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: _StockInPageState.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
