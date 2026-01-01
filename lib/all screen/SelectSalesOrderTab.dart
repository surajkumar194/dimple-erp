import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/all%20screen/EditSalesOrderScreen.dart';
import 'package:flutter/material.dart';

class SelectSalesOrderTab extends StatefulWidget {
  const SelectSalesOrderTab({super.key});
  @override
  State<SelectSalesOrderTab> createState() => _SelectSalesOrderTabState();
}

class _SelectSalesOrderTabState extends State<SelectSalesOrderTab> {
  String searchQuery = '';
  bool _isLoading = false;

  Future<bool> _checkIfJobCardExists(String orderId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('jobCards')
        .where('linkedOrderId', isEqualTo: orderId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> _generateJobCardFromOrder(
    Map<String, dynamic> order,
    String orderId,
  ) async {
    final alreadyExists = await _checkIfJobCardExists(orderId);
    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Job Card already created for this Sales Order!'),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final counterRef = FirebaseFirestore.instance
          .collection('meta')
          .doc('jobCardCounter');
      String jobNo = '';
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        final last = (snap.data()?['last'] as int?) ?? 0;
        final next = last + 1;
        tx.set(counterRef, {'last': next}, SetOptions(merge: true));
        jobNo = 'DPL$next';
      });

      // ✅ Extract all products with their details
      List products = order['products'] ?? [];
      List<Map<String, dynamic>> jobCardProducts = [];

      for (var product in products) {
        jobCardProducts.add({
          'name': product['productName'] ?? '',
          'quantity': product['quantity']?.toString() ?? '0',
          'size': product['size'] ?? '',
          'images': List<String>.from(product['images'] ?? []),
        });
      }

      // ✅ Process partial dispatches
      List<Map<String, dynamic>> partialDispatchesData = [];
      final partialDispatches = order['partialDispatches'] as List? ?? [];
      for (var dispatch in partialDispatches) {
        partialDispatchesData.add({
          'name': dispatch['name'] ?? '',
          'quantity': dispatch['quantity'] ?? '',
          'date': dispatch['date'] ?? '',
          'timestamp': dispatch['timestamp'],
        });
      }

      await FirebaseFirestore.instance.collection('jobCards').doc(jobNo).set({
        'jobNo': jobNo,
        'date': order['orderDate'] ?? DateTime.now(),
        'priority': order['priority'] ?? 'Medium',
        'customer': order['customerName'] ?? '',
        'salesPerson': order['salesPerson'] ?? '',
        'products': jobCardProducts,
        'size': products.isNotEmpty ? products[0]['size'] ?? '' : '',
        'partialDispatches': partialDispatchesData,
        'extraInstruction': order['notes'] ?? '',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'sales_order',
        'linkedOrderId': orderId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Job Card created successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openEditAndCreateJobCard(String orderId, Map<String, dynamic> orderData) async {
    // Navigate to edit screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditSalesOrderScreen(orderId: orderId, orderData: orderData),
      ),
    );
    
    // After returning from edit screen, check if we should create job card
    final jobCardExists = await _checkIfJobCardExists(orderId);
    if (!jobCardExists && mounted) {
      // Ask user if they want to create job card now
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assignment_outlined, color: Colors.teal.shade600),
              ),
              const SizedBox(width: 12),
              const Text('Create Job Card?'),
            ],
          ),
          content: const Text(
            'Would you like to create a Job Card from this updated Sales Order?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                // Fetch updated order data
                final updatedDoc = await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .get();
                if (updatedDoc.exists) {
                  await _generateJobCardFromOrder(
                    updatedDoc.data() as Map<String, dynamic>,
                    orderId,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create Job Card'),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'processing':
        return Colors.blue.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red.shade50;
      case 'medium':
        return Colors.orange.shade50;
      case 'low':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Enhanced Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by customer or product...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.teal.shade600,
                    size: 24,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: () => setState(() => searchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.teal.shade600),
                        const SizedBox(height: 16),
                        Text(
                          'Loading orders...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var orders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final customer = (data['customerName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final productMatch = (data['products'] as List?)?.any(
                        (p) => (p['productName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(searchQuery),
                      ) ??
                      false;
                  return customer.contains(searchQuery) || productMatch;
                }).toList();

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No orders found'
                              : 'No matching orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isEmpty
                              ? 'Create your first sales order'
                              : 'Try a different search term',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final doc = orders[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final products = data['products'] as List? ?? [];
                    final priority = data['priority'] ?? 'Medium';
                    final status = data['status'] ?? 'Pending';

                    return FutureBuilder<bool>(
                      future: _checkIfJobCardExists(doc.id),
                      builder: (context, snapshot) {
                        final jobCardExists = snapshot.data ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              childrenPadding: const EdgeInsets.all(20),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.shade400,
                                      Colors.teal.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.shade200,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Customer: ${data['customerName'] ?? 'Unknown'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Sales: ${data['salesPerson'] ?? 'Unknown'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (jobCardExists)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.shade200,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Job Card',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(priority),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: priority.toLowerCase() == 'high'
                                              ? Colors.red.shade200
                                              : priority.toLowerCase() == 'medium'
                                                  ? Colors.orange.shade200
                                                  : Colors.green.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.flag,
                                            size: 12,
                                            color: priority.toLowerCase() == 'high'
                                                ? Colors.red.shade600
                                                : priority.toLowerCase() == 'medium'
                                                    ? Colors.orange.shade600
                                                    : Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            priority,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: priority.toLowerCase() == 'high'
                                                  ? Colors.red.shade600
                                                  : priority.toLowerCase() == 'medium'
                                                      ? Colors.orange.shade600
                                                      : Colors.green.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 18,
                                            color: Colors.teal.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Products:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...products.map((p) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: Colors.teal.shade400,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: RichText(
                                                overflow: TextOverflow.ellipsis,
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: p['productName'] ?? 'Product',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.teal.shade700,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '  •  Qty: ${p['quantity'] ?? '-'}',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.deepOrange.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Single button for Edit & Create Job Card
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _openEditAndCreateJobCard(doc.id, data),
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            jobCardExists
                                                ? Icons.edit_outlined
                                                : Icons.assignment_outlined,
                                            size: 20,
                                          ),
                                    label: Text(
                                      jobCardExists
                                          ? 'Edit Order'
                                          : 'Edit & Create Job Card',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: Colors.teal.shade200,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}