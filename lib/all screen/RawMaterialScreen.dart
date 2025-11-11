// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class RawMaterialScreen extends StatefulWidget {
//   const RawMaterialScreen({super.key});

//   @override
//   State<RawMaterialScreen> createState() => _RawMaterialScreenState();
// }

// class _RawMaterialScreenState extends State<RawMaterialScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String searchQuery = '';

//   void _showAddMaterialDialog() {
//     final nameController = TextEditingController();
//     final categoryController = TextEditingController();
//     final quantityController = TextEditingController();
//     final unitController = TextEditingController();
//     final priceController = TextEditingController();
//     final minStockController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Add Raw Material'),
//         content: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(
//                   controller: nameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Material Name',
//                     prefixIcon: Icon(Icons.inventory),
//                   ),
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: categoryController,
//                   decoration: const InputDecoration(
//                     labelText: 'Category',
//                     prefixIcon: Icon(Icons.category),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: quantityController,
//                   decoration: const InputDecoration(
//                     labelText: 'Quantity',
//                     prefixIcon: Icon(Icons.numbers),
//                   ),
//                   keyboardType: TextInputType.number,
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: unitController,
//                   decoration: const InputDecoration(
//                     labelText: 'Unit (kg, ltr, pcs)',
//                     prefixIcon: Icon(Icons.scale),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: priceController,
//                   decoration: const InputDecoration(
//                     labelText: 'Price per Unit',
//                     prefixIcon: Icon(Icons.currency_rupee),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: minStockController,
//                   decoration: const InputDecoration(
//                     labelText: 'Minimum Stock Alert',
//                     prefixIcon: Icon(Icons.warning),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (_formKey.currentState!.validate()) {
//                 await FirebaseFirestore.instance.collection('rawMaterials').add({
//                   'name': nameController.text,
//                   'category': categoryController.text,
//                   'quantity': double.parse(quantityController.text),
//                   'unit': unitController.text,
//                   'pricePerUnit': double.parse(priceController.text),
//                   'minStock': double.parse(minStockController.text),
//                   'createdAt': FieldValue.serverTimestamp(),
//                 });
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Material added successfully')),
//                 );
//               }
//             },
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Raw Material'),
//         backgroundColor: const Color(0xFF4CAF50),
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.white,
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search materials...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 filled: true,
//                 fillColor: Colors.grey[100],
//               ),
//               onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance.collection('rawMaterials').snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 var materials = snapshot.data!.docs.where((doc) {
//                   var data = doc.data() as Map<String, dynamic>;
//                   String name = data['name']?.toString().toLowerCase() ?? '';
//                   return name.contains(searchQuery);
//                 }).toList();

//                 if (materials.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
//                         const SizedBox(height: 16),
//                         const Text('No materials found', style: TextStyle(fontSize: 18)),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: materials.length,
//                   itemBuilder: (context, index) {
//                     var material = materials[index].data() as Map<String, dynamic>;
//                     bool lowStock = material['quantity'] < material['minStock'];

//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 12),
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: lowStock ? Colors.red : const Color(0xFF4CAF50),
//                           child: Icon(
//                             lowStock ? Icons.warning : Icons.inventory,
//                             color: Colors.white,
//                           ),
//                         ),
//                         title: Text(
//                           material['name'],
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Text(
//                           '${material['quantity']} ${material['unit']} | ₹${material['pricePerUnit']}/unit',
//                         ),
//                         trailing: lowStock
//                             ? const Chip(
//                                 label: Text('Low Stock', style: TextStyle(fontSize: 10)),
//                                 backgroundColor: Colors.red,
//                                 labelStyle: TextStyle(color: Colors.white),
//                               )
//                             : null,
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _showAddMaterialDialog,
//         icon: const Icon(Icons.add),
//         label: const Text('Add Material'),
//         backgroundColor: const Color(0xFF4CAF50),
//       ),
//     );
//   }
// }