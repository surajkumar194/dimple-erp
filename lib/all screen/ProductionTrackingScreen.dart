import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductionTrackingScreen extends StatelessWidget {
  const ProductionTrackingScreen({super.key});

  static const List<String> departments = [
    'Paper cutting instructions',
    'Mdf cutting instructions',
    'Art Department',
    'Material Required',
    'Dark Room',
    'Offset printing',
    'Digital printing',
    'Lamination',
    'Scodix',
    'Screen',
    'lesser',
    'Letter press Die',
    'Binding',
    'Quality checking',
    'Dispatch',
  ];

  static const Map<String, Color> departmentColors = {
    'Paper cutting instructions': Color(0xFF8B4513), // Brown
    'Mdf cutting instructions': Color(0xFF6D4C41), // Dark Brown
    'Art Department': Color(0xFF1976D2), // Blue
    'Material Required': Color(0xFF00796B), // Teal
    'Dark Room': Color(0xFF424242), // Dark Grey
    'Offset printing': Color(0xFFD32F2F), // Red
    'Digital printing': Color(0xFFF57C00), // Orange
    'Lamination': Color(0xFF0097A7), // Cyan
    'Scodix': Color(0xFF7B1FA2), // Purple
    'Screen': Color(0xFF455A64), // Blue Grey
    'lesser': Color(0xFF9E9E9E), // Grey
    'Letter press Die': Color(0xFF5E35B1), // Deep Purple
    'Binding': Color(0xFF388E3C), // Green
    'Quality checking': Color(0xFFFBC02D), // Yellow
    'Dispatch': Color(0xFF00695C), // Dark Teal
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Production Tracking',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobCards')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF667eea),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading job cards...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Job Cards Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Job cards will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: snap.data!.docs.length,
            itemBuilder: (_, index) {
              final data =
                  snap.data!.docs[index].data() as Map<String, dynamic>;
              final jobNo = data['jobNo'] ?? '-';
              final customer = data['customer'] ?? '-';
              final salesPerson = data['salesPerson'] ?? '-';

              final orderDate = data['createdAt'] is Timestamp
                  ? DateFormat(
                      'dd MMM yyyy',
                    ).format((data['createdAt'] as Timestamp).toDate())
                  : '-';

              final products = data['products'] ?? [];
              int totalQty = 0;
              for (var p in products) {
                totalQty += int.tryParse(p['quantity']?.toString() ?? '0') ?? 0;
              }

              final Map<String, dynamic> deptTracking =
                  data['departmentTracking'] ?? {};
              final bool hasIssued = deptTracking.values.any(
                (e) => e is Map && e['completed'] == true,
              );
              final bool hasDispatched = data['status'] == 'Dispatched';
              final progress =
                  (([
                                true,
                                true,
                                hasIssued,
                                hasDispatched,
                              ].where((e) => e).length /
                              4) *
                          100)
                      .toInt();

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      // decoration: BoxDecoration(
                      //   gradient: const LinearGradient(
                      //     colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      //   ),
                      //   borderRadius: BorderRadius.circular(15),
                      //   boxShadow: [
                      //     BoxShadow(
                      //       color: const Color(0xFF667eea).withOpacity(.3),
                      //       blurRadius: 8,
                      //       offset: const Offset(0, 4),
                      //     ),
                      //   ],
                      // ),
                      child: Center(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 60,
                          height: 60,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business_center_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'Customer Name: $customer',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Text(
                            'Job No: $jobNo',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: _statusChip(hasDispatched, progress),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _infoRow(
                              Icons.person_outline,
                              'Sales Person',
                              salesPerson,
                            ),
                            const SizedBox(height: 12),
                            _infoRow(
                              Icons.calendar_today_outlined,
                              'Order Date',
                              orderDate,
                            ),
                            const SizedBox(height: 12),
                            _infoRow(
                              Icons.inventory_2_outlined,
                              'Total Quantity',
                              '$totalQty pcs',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...products.map<Widget>((p) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.blue.shade50.withOpacity(.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF667eea,
                                  ).withOpacity(.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  size: 20,
                                  color: Color(0xFF667eea),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  p['name'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF667eea,
                                  ).withOpacity(.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${p['quantity']} pcs',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      _MainFlow(
                        issueDone: hasIssued,
                        dispatchDone: hasDispatched,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Department Flow',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: List.generate(departments.length, (i) {
                            final dept = departments[i];
                            final done =
                                deptTracking[dept]?['completed'] == true;
                            return _DepartmentTile(
                              index: i + 1,
                              name: dept,
                              done: done,
                              color: departmentColors[dept] ?? Colors.grey,
                              isLast: i == departments.length - 1,
                            );
                          }),
                        ),
                      ),
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

  Widget _statusChip(bool dispatched, int progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dispatched
              ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
              : [const Color(0xFFf093fb), const Color(0xFFF5576c)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                (dispatched ? const Color(0xFF11998e) : const Color(0xFFf093fb))
                    .withOpacity(.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dispatched ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$progress%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF667eea)),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _MainFlow extends StatelessWidget {
  final bool issueDone;
  final bool dispatchDone;

  const _MainFlow({required this.issueDone, required this.dispatchDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50.withOpacity(.5),
            Colors.purple.shade50.withOpacity(.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _step('Order', true, Icons.shopping_cart_rounded),
          _line(true),
          _step('Job Card', true, Icons.description_rounded),
          _line(issueDone),
          _step('Issue', issueDone, Icons.assignment_turned_in_rounded),
          _line(dispatchDone),
          _step('Dispatch', dispatchDone, Icons.local_shipping_rounded),
        ],
      ),
    );
  }

  Widget _step(String label, bool done, IconData icon) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: done
                ? const LinearGradient(
                    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                  ),
            shape: BoxShape.circle,
            boxShadow: done
                ? [
                    BoxShadow(
                      color: const Color(0xFF11998e).withOpacity(.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: done ? const Color(0xFF11998e) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _line(bool done) => Expanded(
    child: Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: done
            ? const LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              )
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade300],
              ),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _DepartmentTile extends StatelessWidget {
  final int index;
  final String name;
  final bool done;
  final Color color;
  final bool isLast;

  const _DepartmentTile({
    required this.index,
    required this.name,
    required this.done,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: done
                        ? LinearGradient(colors: [color.withOpacity(.8), color])
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade400,
                            ],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: done
                        ? [
                            BoxShadow(
                              color: color.withOpacity(.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : Icons.circle,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      gradient: done
                          ? LinearGradient(
                              colors: [color, color.withOpacity(.3)],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade300,
                                Colors.grey.shade200,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: done ? color.withOpacity(.08) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: done ? color.withOpacity(.3) : Colors.grey.shade200,
                ),
              ),
              child: Text(
                '$index. $name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: done ? color : Colors.grey.shade700,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: color,
                  decorationThickness: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
