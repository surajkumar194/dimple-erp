import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// product_specifications_screen.dart
class ProductSpecificationsScreen extends StatefulWidget {
  const ProductSpecificationsScreen({super.key});

  @override
  State<ProductSpecificationsScreen> createState() => _ProductSpecificationsScreenState();
}

class _ProductSpecificationsScreenState extends State<ProductSpecificationsScreen> {
  void _showSpecDialog() {
    final productController = TextEditingController();
    final codeController = TextEditingController();
    final dimensionsController = TextEditingController();
    final materialController = TextEditingController();
    final weightController = TextEditingController();
    final colorController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product Specification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: productController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Product Code',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dimensionsController,
                decoration: const InputDecoration(
                  labelText: 'Dimensions (L x W x H)',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: materialController,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  prefixIcon: Icon(Icons.color_lens),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
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
              await FirebaseFirestore.instance.collection('productSpecs').add({
                'productName': productController.text,
                'productCode': codeController.text,
                'dimensions': dimensionsController.text,
                'material': materialController.text,
                'weight': weightController.text,
                'color': colorController.text,
                'notes': notesController.text,
                'version': '1.0',
                'status': 'Active',
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Specification added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Specifications'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('productSpecs').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No specifications', style: TextStyle(fontSize: 18)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var spec = snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF00BCD4),
                    child: Icon(Icons.description, color: Colors.white),
                  ),
                  title: Text(spec['productName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Code: ${spec['productCode']}'),
                  trailing: Chip(
                    label: Text('v${spec['version']}', style: const TextStyle(fontSize: 10)),
                    backgroundColor: const Color(0xFF00BCD4).withOpacity(0.2),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSpecRow('Dimensions', spec['dimensions']),
                          _buildSpecRow('Material', spec['material']),
                          _buildSpecRow('Weight', spec['weight']),
                          _buildSpecRow('Color', spec['color']),
                          if (spec['notes'].isNotEmpty)
                            _buildSpecRow('Notes', spec['notes']),
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
        onPressed: _showSpecDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Spec'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
