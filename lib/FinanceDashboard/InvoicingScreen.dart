import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoicingScreen extends StatefulWidget {
  const InvoicingScreen({super.key});

  @override
  State<InvoicingScreen> createState() => _InvoicingScreenState();
}

class _InvoicingScreenState extends State<InvoicingScreen> {
  void _showAddInvoiceDialog() {
    final customerController = TextEditingController();
    final productController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final gstController = TextEditingController(text: '18');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Invoice'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: customerController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: productController,
                decoration: const InputDecoration(
                  labelText: 'Product/Service',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per Unit',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: gstController,
                decoration: const InputDecoration(
                  labelText: 'GST %',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              double quantity = double.parse(quantityController.text);
              double price = double.parse(priceController.text);
              double gst = double.parse(gstController.text);
              double subtotal = quantity * price;
              double gstAmount = subtotal * (gst / 100);
              double total = subtotal + gstAmount;

              await FirebaseFirestore.instance.collection('invoices').add({
                'customer': customerController.text,
                'product': productController.text,
                'quantity': quantity,
                'pricePerUnit': price,
                'subtotal': subtotal,
                'gstPercent': gst,
                'gstAmount': gstAmount,
                'total': total,
                'status': 'Unpaid',
                'invoiceDate': DateTime.now(),
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice created successfully')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoicing'),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invoices')
            .orderBy('invoiceDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No invoices', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var invoice = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String invoiceId = snapshot.data!.docs[index].id;
              String status = invoice['status'] ?? 'Unpaid';
              Color statusColor = status == 'Paid' ? Colors.green : Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF009688),
                    child: const Icon(Icons.receipt, color: Colors.white),
                  ),
                  title: Text(
                    invoice['customer'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(invoice['product']),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${invoice['total'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF009688),
                        ),
                      ),
                      Chip(
                        label: Text(status, style: const TextStyle(fontSize: 9)),
                        backgroundColor: statusColor.withOpacity(0.2),
                        labelStyle: TextStyle(color: statusColor),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildRow('Quantity', '${invoice['quantity']}'),
                          _buildRow('Price/Unit', '₹${invoice['pricePerUnit']}'),
                          _buildRow('Subtotal', '₹${invoice['subtotal'].toStringAsFixed(2)}'),
                          _buildRow('GST (${invoice['gstPercent']}%)', '₹${invoice['gstAmount'].toStringAsFixed(2)}'),
                          const Divider(),
                          _buildRow('Total', '₹${invoice['total'].toStringAsFixed(2)}', bold: true),
                          const SizedBox(height: 12),
                          if (status == 'Unpaid')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('invoices')
                                      .doc(invoiceId)
                                      .update({'status': 'Paid', 'paidDate': DateTime.now()});
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Mark as Paid'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddInvoiceDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
        backgroundColor: const Color(0xFF009688),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}