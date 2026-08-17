import 'package:dimple_erp/challan/DispatchFullPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DispatchHistoryScreen extends StatelessWidget {
  final String jobDocId;
  final String jobNo;
  final String customerName;

  const DispatchHistoryScreen({
    super.key,
    required this.jobDocId,
    required this.jobNo,
    required this.customerName,
  });

  String _fmt(dynamic ts) {
    if (ts == null) return 'N/A';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else {
      return 'N/A';
    }
    return DateFormat('dd/MM/yyyy  hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A148C),
                  Color(0xFF7B1FA2),
                  Color(0xFF0D47A1),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dispatch History',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '$jobNo — $customerName',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
         
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
       stream: FirebaseFirestore.instance
    .collection('dispatchSales')
    .where('jobDocId', isEqualTo: jobDocId)
    .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No dispatch history found.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final challNo = data['challNo'] ?? 'N/A';
              final createdAt = _fmt(data['createdAt']);
              final totalQty = data['totalQty'] ?? 0;
              final totalPackets = data['totalPackets'] ?? 0;
              final driverName = data['driverName'] ?? '';
              final List items = data['items'] ?? [];
              final bool hasExtra = items.any(
                (item) =>
                    item['isManuallyAdded'] == true ||
                    item['isOverDispatched'] == true,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: hasExtra
                        ? Colors.orange.shade300
                        : Colors.indigo.shade100,
                    width: hasExtra ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasExtra
                              ? [
                                  Colors.orange.shade700,
                                  Colors.deepOrange.shade600,
                                ]
                              : [
                                  const Color(0xFF1A237E),
                                  const Color(0xFF1565C0),
                                ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  challNo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  createdAt,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasExtra)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'EXTRA ITEMS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Summary chips
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _histChip(
                            Icons.numbers_rounded,
                            'Qty: $totalQty',
                            Colors.blue,
                          ),
                          _histChip(
                            Icons.inventory_2_rounded,
                            'Packets: $totalPackets',
                            Colors.orange,
                          ),
                          if (driverName.isNotEmpty)
                            _histChip(
                              Icons.drive_eta_rounded,
                              driverName,
                              Colors.teal,
                            ),
                          _histChip(
                            Icons.category_rounded,
                            '${items.length} Items',
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),

                    // Items list
                    ...items.map<Widget>((item) {
                      final String name = item['productName'] ?? '';
                      final int qty =
                          int.tryParse(item['quantity']?.toString() ?? '0') ??
                          0;
                      final int totalOrd =
                          int.tryParse(
                            item['totalQuantity']?.toString() ?? '0',
                          ) ??
                          0;
                      final int prevDisp =
                          int.tryParse(
                            item['previouslyDispatched']?.toString() ?? '0',
                          ) ??
                          0;
                      final bool isManual = item['isManuallyAdded'] == true;
                      final bool isOver = item['isOverDispatched'] == true;
                      final String detail = item['detail']?.toString() ?? '';
                      final int pkt =
                          int.tryParse(item['packets']?.toString() ?? '0') ?? 0;

                      int extraQty = 0;
                      if (isOver && !isManual) {
                        final remaining = totalOrd - prevDisp;
                        extraQty = qty - (remaining > 0 ? remaining : 0);
                      }

                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isManual
                              ? Colors.amber.shade50
                              : isOver
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isManual
                                ? Colors.amber.shade300
                                : isOver
                                ? Colors.red.shade300
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isManual
                                    ? Colors.amber.shade600
                                    : isOver
                                    ? Colors.red.shade600
                                    : Colors.indigo.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  qty.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
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
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isManual
                                                ? Colors.amber.shade800
                                                : isOver
                                                ? Colors.red.shade700
                                                : const Color(0xFF1A237E),
                                          ),
                                        ),
                                      ),
                                      if (isManual) ...[
                                        const SizedBox(width: 6),
                                        _badge('EXTRA', Colors.amber.shade600),
                                      ],
                                      if (isOver) ...[
                                        const SizedBox(width: 6),
                                        _badge(
                                          'OVER +$extraQty',
                                          Colors.red.shade600,
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (detail.isNotEmpty)
                                    Text(
                                      detail,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  if (!isManual && totalOrd > 0)
                                    Text(
                                      'Order: $totalOrd | Prev: $prevDisp | This: $qty | Pkt: $pkt',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Re-print button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: GestureDetector(
                        onTap: () async {
                          final bool? withRate = await showPdfTypeDialog(
                            context,
                          );
                          if (withRate == null) return;
                          await generateChallanPDF(data, showRate: withRate);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Re-Print / Download PDF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _histChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade700,
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
        borderRadius: BorderRadius.circular(5),
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
}