import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

class PaymentCollectionScreen extends StatefulWidget {
  const PaymentCollectionScreen({super.key});
  @override
  State<PaymentCollectionScreen> createState() =>
      _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void _receivePayment(String docId, Map<String, dynamic> data) {
    final amountController = TextEditingController();
    final animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    animCtrl.forward();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animCtrl, curve: Curves.easeOutBack),
          child: _PaymentDialog(
            title: "Receive Payment",
            subtitle: data['customerName'] ?? '',
            orderNo: data['salesOrderNo'] ?? '',
            amountController: amountController,
            total: (data['grandTotal'] ?? 0).toDouble(),
            advance: (data['advanceAmount'] ?? 0).toDouble(),
            paid: (data['paidAmount'] ?? 0).toDouble(),
            confirmLabel: "Confirm Payment",
            confirmColors: [Colors.green.shade400, Colors.green.shade700],
            onConfirm:
                (
                  String receivedBy,
                  String? customName,
                  double extraAmount,
                  String remark,
                ) async {
                  try {
  final amount = double.tryParse(amountController.text) ?? 0;

  if (amount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter valid amount")),
    );
    return;
  }

  final total = (data['grandTotal'] ?? 0).toDouble();
  final paid = (data['paidAmount'] ?? 0).toDouble();
final advance = (data['advanceAmount'] ?? 0).toDouble();
  // ✅ IMPORTANT CHANGE
final finalAmount = advance + amount + extraAmount;
  final newPaid = paid + amount;

  // ✅ validation
  if (newPaid > total) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment cannot exceed total amount")),
    );
    return;
  }

  final pending = total - newPaid;
  final now = DateTime.now();
  final formattedDateTime =
      DateFormat('dd MMM yyyy, hh:mm a').format(now);

  final String finalReceivedBy = receivedBy == 'Other'
      ? (customName ?? 'Other')
      : receivedBy;

  print("Saving payment...");

  // ✅ SAVE PAYMENT
  await FirebaseFirestore.instance.collection("payments").add({
    "orderId": docId,
    "salesOrderNo": data['salesOrderNo'],
    "customerName": data['customerName'],
    "location": data['unit'],
    "advanceAmount": advance, 
    "amount": amount,
    "extraAmount": extraAmount, // sirf store hoga
    "finalAmount": finalAmount,
    "remark": remark,
    "receivedBy": finalReceivedBy,
    "receivedAt": formattedDateTime,
    "createdAt": FieldValue.serverTimestamp(),
  });

  // ✅ UPDATE ORDER
  await FirebaseFirestore.instance
      .collection("orders")
      .doc(docId)
      .update({
    "paidAmount": newPaid,
    "pendingAmount": pending,
    "lastReceivedBy": finalReceivedBy,
    "lastReceivedAt": formattedDateTime,
  });

  print("Saved successfully ✅");

  if (ctx.mounted) Navigator.pop(ctx);

} catch (e) {
  print("Error: $e");

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Error: $e")),
  );
}
                },
          ),
        );
      },
    );
  }

  void _editPayment(String docId, Map<String, dynamic> data) {
    final animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    animCtrl.forward();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animCtrl, curve: Curves.easeOutBack),
          child: _EditPaymentDialog(docId: docId, data: data),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
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
                          'Payment Collection',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Manage & track payments',
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
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildOrderList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: "Search by order no or customer...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("orders")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.blue.shade400],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.purple.shade700, Colors.blue.shade700],
                  ).createShader(bounds),
                  child: const Text(
                    'Loading Orders...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        var orders = snapshot.data!.docs;

        if (_searchQuery.isNotEmpty) {
          orders = orders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final orderNo = (data['salesOrderNo'] ?? '')
                .toString()
                .toLowerCase();
            final customer = (data['customerName'] ?? '')
                .toString()
                .toLowerCase();
            return orderNo.contains(_searchQuery) ||
                customer.contains(_searchQuery);
          }).toList();
        }

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade100.withOpacity(0.5),
                        Colors.blue.shade100.withOpacity(0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.grey.shade400,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.purple.shade700, Colors.blue.shade700],
                  ).createShader(bounds),
                  child: const Text(
                    "No Orders Found",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try adjusting your search",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final data = doc.data() as Map<String, dynamic>;
            return _OrderCard(
              data: data,
              docId: doc.id,
              onReceive: () => _receivePayment(doc.id, data),
              onEdit: () => _editPayment(doc.id, data),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ORDER CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onReceive;
  final VoidCallback onEdit;

  const _OrderCard({
    required this.data,
    required this.docId,
    required this.onReceive,
    required this.onEdit,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final orderNo = data['salesOrderNo'] ?? "";
    final customer = data['customerName'] ?? "";
    final location = data['unit'] ?? "N/A";

    final total = (data['grandTotal'] ?? 0).toDouble();
    final advance = (data['advanceAmount'] ?? 0).toDouble();
    final paid = (data['paidAmount'] ?? 0).toDouble();
    final pending = total - paid;

    final lastReceivedBy = data['lastReceivedBy'] ?? '';
    final lastReceivedAt = data['lastReceivedAt'] ?? '';

    final double paidPercent = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0;
    final bool isFullyPaid = pending <= 0;

    final String statusLabel = isFullyPaid
        ? "Paid"
        : (paid > 0 ? "Partial" : "Unpaid");

    List<Color> statusColors;
    if (isFullyPaid) {
      statusColors = [Colors.green.shade400, Colors.green.shade700];
    } else if (paid > 0) {
      statusColors = [Colors.orange.shade400, Colors.orange.shade700];
    } else {
      statusColors = [Colors.red.shade400, Colors.red.shade700];
    }

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.purple.shade50.withOpacity(0.3),
                Colors.blue.shade50.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.blue.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          customer.isNotEmpty ? customer[0].toUpperCase() : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_outlined,
                                color: Colors.grey.shade500,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                orderNo,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey.shade500,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                        gradient: LinearGradient(colors: statusColors),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: statusColors[0].withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Payment Progress",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: statusColors,
                          ).createShader(bounds),
                          child: Text(
                            "${(paidPercent * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: paidPercent,
                        minHeight: 7,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          statusColors[0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Amount Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _AmountChip(
                      label: "Total",
                      amount: total,
                      colors: [Colors.grey.shade500, Colors.grey.shade700],
                    ),
                    const SizedBox(width: 8),
                    if (advance > 0) ...[
                      _AmountChip(
                        label: "Advance",
                        amount: advance,
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade600,
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                    _AmountChip(
                      label: "Paid",
                      amount: paid,
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    const SizedBox(width: 8),
                    _AmountChip(
                      label: "Pending",
                      amount: pending,
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                  ],
                ),
              ),

              // ── Last Received By
              if (lastReceivedBy.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade50, Colors.blue.shade50],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.purple.shade100,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade400,
                                Colors.blue.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Last Received by: $lastReceivedBy",
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (lastReceivedAt.isNotEmpty)
                                Text(
                                  lastReceivedAt,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.access_time_rounded,
                          color: Colors.grey.shade400,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.shade300,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // ── Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onEdit,
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: Colors.grey.shade600,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Advance / Edit",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: isFullyPaid ? null : widget.onReceive,
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: isFullyPaid
                                ? null
                                : LinearGradient(
                                    colors: [
                                      Colors.purple.shade500,
                                      Colors.blue.shade600,
                                      Colors.teal.shade500,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            color: isFullyPaid ? Colors.grey.shade200 : null,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isFullyPaid
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFullyPaid
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: isFullyPaid
                                    ? Colors.grey.shade400
                                    : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isFullyPaid ? "Fully Paid" : "Receive Payment",
                                style: TextStyle(
                                  color: isFullyPaid
                                      ? Colors.grey.shade400
                                      : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AMOUNT CHIP
// ═══════════════════════════════════════════════════════════════════════════════
class _AmountChip extends StatelessWidget {
  final String label;
  final double amount;
  final List<Color> colors;

  const _AmountChip({
    required this.label,
    required this.amount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors[0].withOpacity(0.12), colors[1].withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors[0].withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors[0],
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            ShaderMask(
              shaderCallback: (bounds) =>
                  LinearGradient(colors: colors).createShader(bounds),
              child: Text(
                "₹${amount.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECEIVER NAMES
// ═══════════════════════════════════════════════════════════════════════════════
const List<String> kReceiverNames = [
  'Pankaj Sir',
  'Komal Sir',
  'Bhavesh Sir',
  'Sonali Mam',
  'Other',
];

// ═══════════════════════════════════════════════════════════════════════════════
// PAYMENT DIALOG — Receive Payment with Extra Amount & Final Amount preview
// ═══════════════════════════════════════════════════════════════════════════════
class _PaymentDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String orderNo;
  final double total;
  final double advance;
  final double paid;
  final TextEditingController amountController;
  final String confirmLabel;
  final List<Color> confirmColors;
  final Future<void> Function(
    String receivedBy,
    String? customName,
    double extraAmount,
    String remark,
  )
  onConfirm;

  const _PaymentDialog({
    required this.title,
    required this.subtitle,
    required this.orderNo,
    required this.amountController,
    required this.total,
    required this.advance,
    required this.paid,
    required this.confirmLabel,
    required this.confirmColors,
    required this.onConfirm,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  String _selectedReceiver = kReceiverNames[0];
  final TextEditingController _otherNameController = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();
  final TextEditingController _extraCtrl = TextEditingController();
  bool _isLoading = false;
  String get _nowFormatted =>
      DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

  // Live final amount calculation
  double get _enteredAmount =>
      double.tryParse(widget.amountController.text) ?? 0;
  double get _extraAmount => double.tryParse(_extraCtrl.text) ?? 0;
  double get _finalAmount => _enteredAmount + _extraAmount;

  @override
  void dispose() {
    _otherNameController.dispose();
    _remarkCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = (widget.total - widget.paid)
        .clamp(0, double.infinity)
        .toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.purple.shade50.withOpacity(0.4),
                Colors.blue.shade50.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade50.withOpacity(0.5),
                      Colors.blue.shade50.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: widget.confirmColors),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.confirmColors[0].withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.purple.shade700,
                                Colors.blue.shade700,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "${widget.subtitle} · ${widget.orderNo}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _summaryRow(
                            "Grand Total",
                            "₹${widget.total.toStringAsFixed(0)}",
                          ),
                          _summaryRow(
                            "Already Paid",
                            "₹${widget.paid.toStringAsFixed(0)}",
                          ),
                          _summaryRow(
                            "Pending",
                            "₹${pending.toStringAsFixed(0)}",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Main Amount field
                    Text(
                      "Amount (₹)",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: widget.amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) {
                        final entered = double.tryParse(val) ?? 0;
                        final pendingAmt = widget.total - widget.paid;
                        if (entered > pendingAmt) {
                          widget.amountController.text = pendingAmt
                              .toStringAsFixed(0);
                          widget.amountController.selection =
                              TextSelection.fromPosition(
                                TextPosition(
                                  offset: widget.amountController.text.length,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: Colors.white,
                              content: Text( 
                                "Amount cannot exceed pending payment",
                              ),
                            ),
                          );
                        }
                        setState(() {});
                      },
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: "0",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        prefixText: "₹ ",
                        prefixStyle: TextStyle(
                          color: widget.confirmColors[0],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: widget.confirmColors[0],
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Extra Amount field
                    Text(
                      "Extra Amount (Optional)",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _extraCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: "0",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 20,
                        ),
                        prefixText: "₹ ",
                        prefixStyle: TextStyle(
                          color: Colors.orange.shade400,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.orange.shade400,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Final Amount Preview Box (live update)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400.withOpacity(0.12),
                            Colors.teal.shade400.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.teal.shade500,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calculate_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Final Amount",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _extraAmount > 0
                                        ? "₹${_enteredAmount.toStringAsFixed(0)} + ₹${_extraAmount.toStringAsFixed(0)}"
                                        : "Amount entered above",
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 14, 32, 237),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 245, 2, 2),
                                const Color.fromARGB(255, 251, 1, 1),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              "₹${_finalAmount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Remark field
                    Text(
                      "Remark",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarkCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Enter remark...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.confirmColors[0],
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Received By
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.confirmColors,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Received By",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kReceiverNames.map((name) {
                        final bool isSelected = _selectedReceiver == name;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedReceiver = name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(colors: widget.confirmColors)
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: widget.confirmColors[0]
                                            .withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_selectedReceiver == 'Other') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _otherNameController,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter name...",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.edit_outlined,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.confirmColors[0],
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // ── Date-Time
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: widget.confirmColors[0],
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Date & Time: ",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _nowFormatted,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () async {
                                    setState(() => _isLoading = true);
                                    await widget.onConfirm(
                                      _selectedReceiver,
                                      _selectedReceiver == 'Other'
                                          ? _otherNameController.text.trim()
                                          : null,
                                      _extraAmount,
                                      _remarkCtrl.text.trim(),
                                    );
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isLoading
                                      ? [
                                          Colors.grey.shade400,
                                          Colors.grey.shade500,
                                        ]
                                      : widget.confirmColors,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isLoading
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: widget.confirmColors[0]
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        widget.confirmLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDIT PAYMENT DIALOG — Advance + Remark
// ═══════════════════════════════════════════════════════════════════════════════
class _EditPaymentDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _EditPaymentDialog({required this.docId, required this.data});

  @override
  State<_EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<_EditPaymentDialog> {
  late TextEditingController _advanceCtrl;
  final TextEditingController _remarkCtrl = TextEditingController();
  String _receivedBy = 'Pankaj Sir';

  final List<String> _names = [
    'Pankaj Sir',
    'Komal Sir',
    'Bhavesh Sir',
    'Sonali Mam',
    'Other',
  ];

  final TextEditingController _otherNameCtrl = TextEditingController();
  bool _isLoading = false;
  final List<Color> _colors = [Colors.purple.shade400, Colors.blue.shade600];

  @override
  void initState() {
    super.initState();
    _remarkCtrl.text = widget.data['remark'] ?? '';
    final advanceVal = (widget.data['advanceAmount'] ?? 0).toDouble();
    _advanceCtrl = TextEditingController(
      text: advanceVal > 0 ? advanceVal.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _advanceCtrl.dispose();
    _remarkCtrl.dispose();
    _otherNameCtrl.dispose();
    super.dispose();
  }

  String get _nowFormatted =>
      DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final finalName = _receivedBy == 'Other'
        ? _otherNameCtrl.text.trim()
        : _receivedBy;
    final advance = double.tryParse(_advanceCtrl.text) ?? 0;
    final total = (widget.data['grandTotal'] ?? 0).toDouble();
    final oldPaid = (widget.data['paidAmount'] ?? 0).toDouble();
    final oldAdvance = (widget.data['advanceAmount'] ?? 0).toDouble();
    final newPaid = oldPaid - oldAdvance + advance;
    final pending = total - newPaid;

    await FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.docId)
        .update({
          "advanceAmount": advance,
          "paidAmount": newPaid,
          "pendingAmount": pending,
          "receivedBy": finalName,
          "editedAt": _nowFormatted,
          "remark": _remarkCtrl.text.trim(),
        });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.data['customerName'] ?? '';
    final orderNo = widget.data['salesOrderNo'] ?? '';
    final total = (widget.data['grandTotal'] ?? 0).toDouble();
    final advance = double.tryParse(_advanceCtrl.text) ?? 0;
    final oldPaid = (widget.data['paidAmount'] ?? 0).toDouble();
    final oldAdvance = (widget.data['advanceAmount'] ?? 0).toDouble();
    final newPaid = oldPaid - oldAdvance + advance;
    final pending = total - newPaid;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.purple.shade50.withOpacity(0.4),
                Colors.blue.shade50.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade50.withOpacity(0.6),
                      Colors.blue.shade50.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _colors),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _colors[0].withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.purple.shade700,
                                Colors.blue.shade700,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              "Advance Payment",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "$customer · $orderNo",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grand Total read-only
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade50],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: Colors.grey.shade500,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Grand Total",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: _colors,
                            ).createShader(bounds),
                            child: Text(
                              "₹${total.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildFieldLabel(
                      icon: Icons.currency_rupee_rounded,
                      label: "Advance Amount",
                      color: Colors.orange.shade500,
                    ),
                    const SizedBox(height: 8),
                    _buildAmountField(
                      controller: _advanceCtrl,
                      hint: "Enter advance amount",
                      accentColor: Colors.orange.shade400,
                      onChanged: (val) {
                        final value = double.tryParse(val) ?? 0;
                        if (value > total) {
                          _advanceCtrl.text = total.toStringAsFixed(0);
                          _advanceCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: _advanceCtrl.text.length),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Advance cannot be greater than Grand Total",
                              ),
                            ),
                          );
                        }
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 14),

                    _buildFieldLabel(
                      icon: Icons.note_alt_outlined,
                      label: "Remark",
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarkCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Enter remark...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.purple,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildFieldLabel(
                      icon: Icons.person,
                      label: "Received By",
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _receivedBy,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: _names.map((name) {
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _receivedBy = value!),
                    ),
                    if (_receivedBy == 'Other') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _otherNameCtrl,
                        decoration: InputDecoration(
                          hintText: "Enter name...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Pending preview
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (pending > 0
                                    ? Colors.red.shade400
                                    : Colors.green.shade400)
                                .withOpacity(0.08),
                            (pending > 0
                                    ? Colors.red.shade300
                                    : Colors.green.shade300)
                                .withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pending > 0
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                pending > 0
                                    ? Icons.hourglass_bottom_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: pending > 0
                                    ? Colors.red.shade400
                                    : Colors.green.shade500,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                pending > 0
                                    ? "Remaining Pending"
                                    : "Fully Paid ✓",
                                style: TextStyle(
                                  color: pending > 0
                                      ? Colors.red.shade500
                                      : Colors.green.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "₹${pending.clamp(0, double.infinity).toStringAsFixed(0)}",
                            style: TextStyle(
                              color: pending > 0
                                  ? Colors.red.shade500
                                  : Colors.green.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Date-time
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: _colors[0],
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Advance Edit Date: ",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _nowFormatted,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _save,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isLoading
                                      ? [
                                          Colors.grey.shade400,
                                          Colors.grey.shade500,
                                        ]
                                      : _colors,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isLoading
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: _colors[0].withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "Save Changes",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 13),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String hint,
    required Color accentColor,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
        prefixText: "₹ ",
        prefixStyle: TextStyle(
          color: accentColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
