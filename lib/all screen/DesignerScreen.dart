import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DesignerScreen extends StatefulWidget {
  const DesignerScreen({super.key});

  @override
  State<DesignerScreen> createState() => _DesignerScreenState();
}

class _DesignerScreenState extends State<DesignerScreen> {
  Map<String, bool> expandedMap = {};
  String formatDate(dynamic date) {
    if (date == null) return "-";
    try {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    } catch (e) {
      return "-";
    }
  }

  String formatDateTime(dynamic date) {
    if (date == null) return "-";
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(date.toDate());
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        'Designer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Create and manage new designer orders',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('designerRequired', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Designer Orders"));
          }
          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {

              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final products = List<Map<String, dynamic>>.from(data['products']);

              bool isExpanded = expandedMap[doc.id] ?? false;
              bool isCompleted = data['designStatus'] == 'done';

              return GestureDetector(
                onTap: () {
                  setState(() {
                    expandedMap[doc.id] = !isExpanded;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Colors.white],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🔥 HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['customerName'] ?? '',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data['salesOrderNo'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              )
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 6),

                      // 🔥 STATUS
                      Text(
                        isCompleted
                            ? "✅ Completed"
                            : "⏳ Pending",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : Colors.orange,
                        ),
                      ),

                      if (isExpanded) ...[

                        const SizedBox(height: 10),

                        // 🔥 INFO BOX
                        Wrap(
                          spacing: 10,
                          children: [
                            _box("Order", formatDate(data['orderDate'])),
                            _box("Dispatch", formatDate(data['deliveryDate'])),
                            _box("Sales", data['salesPerson'] ?? "-"),
                          ],
                        ),

                        const Divider(height: 20),

                        // 🔥 PRODUCTS
                        for (int i = 0; i < products.length; i++)
                          _productCard(context, doc.id, products, i),

                        const SizedBox(height: 10),

                        // 🔥 COMPLETE BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isCompleted ? Colors.grey : Colors.green,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          onPressed: isCompleted
                              ? null
                              : () async {

                                  final updatedProducts =
                                      products.map((p) {
                                    return {...p, 'designStatus': 'done'};
                                  }).toList();

                                  await FirebaseFirestore.instance
                                      .collection('orders')
                                      .doc(doc.id)
                                      .update({
                                    'products': updatedProducts,
                                    'designStatus': 'done',
                                    'completedAt':
                                        FieldValue.serverTimestamp(),
                                  });
                                },
                          child: Text(
                            isCompleted
                                ? "✅ Completed"
                                : "Complete & Ready for Production",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,color: Colors.white),
                          ),
                        ),

                        // 🔥 COMPLETED DATE + TIME
                        if (data['completedAt'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Completed on: ${formatDateTime(data['completedAt'])}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _productCard(
      BuildContext context, String docId, List products, int i) {

    final p = products[i];

    final List<String> statusList = [
      'pending',
      'in_progress',
      'done',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text("Product: ${p['productName']}",
              style: const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 5),

          Text("Qty: ${p['quantity']}"),

          if ((p['remarks'] ?? "").toString().isNotEmpty)
            Text("Remark: ${p['remarks']}"),

          const SizedBox(height: 8),

          // 🔥 IMAGE ZOOM
          if (p['images'] != null && (p['images'] as List).isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: (p['images'] as List).map<Widget>((img) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: Image.network(img),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          img,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Text(
                p['designStatus'] == 'done'
                    ? "✅ Done"
                    : p['designStatus'] == 'in_progress'
                        ? "🛠 In Progress"
                        : "⏳ Pending",
              ),

              DropdownButton<String>(
                value: p['designStatus'] ?? 'pending',
                items: statusList.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) async {

                  final updated = List.from(products);
                  updated[i]['designStatus'] = value;

                  bool allDone = updated.every(
                      (item) => item['designStatus'] == 'done');

                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(docId)
                      .update({
                    'products': updated,
                    'designStatus': allDone ? 'done' : 'in_progress',
                  });
                },
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _box(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}