// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// class AppColors {
//   static const Color primary = Color(0xFF169a8d);
//   static const Color accent = Color(0xFFFFA500);
//   static const Color warning = Color(0xFFE74C3C);
//   static const Color success = Color(0xFF2ECC71);
//   static const Color lightBg = Color(0xFFF8F9FA);
//   static const Color darkText = Color(0xFF2C3E50);
//   static const Gradient primaryGradient = LinearGradient(
//     colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
//   static const Gradient accentGradient = LinearGradient(
//     colors: [Color(0xFFFF6B6B), Color(0xFFFF8E72)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
// }

// class MdfContractorScreen extends StatefulWidget {
//   final String orderId;
//   final Map<String, dynamic> orderData;
//   final Map<String, dynamic> productData;

//   const MdfContractorScreen({
//     super.key,
//     required this.orderId,
//     required this.orderData,
//     required this.productData,
//   });

//   @override
//   State<MdfContractorScreen> createState() => _MdfContractorScreenState();
// }

// class _MdfContractorScreenState extends State<MdfContractorScreen> {
//   bool _isSaving = false;

//   final TextEditingController _trayOtherController = TextEditingController();

//   final TextEditingController _cuttingOtherController = TextEditingController();

//   final TextEditingController _pastingOtherController = TextEditingController();
//   Map<String, dynamic>? orderData;
//   Map<String, dynamic>? productData;
//   bool loading = true;
//   final List<String> _trayContractors = [
//     'MDF Box (HR, Bhaji Box, Wedding Box Plain)',
//     'Trays',
//     'Double Door Box',
//     'Flap Down',
//     'ARC Box',
//     'One Slant',
//     'Mandir Box / TV Box',
//     'Plater (without handle)',
//     'Doom Box',
//     'File Box',
//     'Two Side Tapper Box',
//     'Chocunki Box',
//     'Farme Box',
//     'Window Box',
//     'Other',
//   ];
//   String? _selectedTrayContractor;

//   final List<String> _cuttingContractors = [
//     'Mehfos',
//     'Sadiq',
//     'Shoaib',
//     'Other',
//   ];
//   String? _selectedCuttingContractor;
//   final TextEditingController _cuttingPriceController = TextEditingController();

//   final List<String> _pastingContractors = [
//     'Shahnawaz',
//     'Ankush',
//     'Danish',
//     'Karan',
//     'Pappu',
//     'Tohid',
//     'Nandu',
//     'Sadiq / Shahnawaz',
//     'Azam',
//     'Anil',
//     'Other',
//   ];
//   String? _selectedPastingContractor;
//   final TextEditingController _pastingPriceController = TextEditingController();
//   @override
//   void initState() {
//     super.initState();
//     fetchOrder();
//   }

//   Future<void> fetchOrder() async {
//     final doc = await FirebaseFirestore.instance
//         .collection("orders")
//         .doc(widget.orderId)
//         .get();

//     if (!doc.exists) return;

//     final data = doc.data()!;

//     final products = data['products'] ?? [];

//     Map<String, dynamic>? mdfProduct;

//     for (var p in products) {
//       if ((p['productCategory'] ?? '') == 'MDF') {
//         mdfProduct = Map<String, dynamic>.from(p);
//         break;
//       }
//     }

//     setState(() {
//       orderData = data;
//       productData = mdfProduct;
//       loading = false;
//     });
//   }

//   // ─────────────────────────────────────────────
//   //  SAVE TO FIREBASE
//   // ─────────────────────────────────────────────
//   Future<void> _saveContractors() async {
//     setState(() => _isSaving = true);
//     try {
//       await FirebaseFirestore.instance
//           .collection('contractors')
//           .doc(widget.orderId)
//           .set({
//             // ── Order Info ──
//             'orderId': widget.orderId,
//             'customerName': widget.orderData['customerName'] ?? '',
//             'companyName': widget.orderData['companyName'] ?? '',
//             'phone': widget.orderData['phone'] ?? '',
//             'location': widget.orderData['location'] ?? '',
//             'priority': widget.orderData['priority'] ?? '',
//             'salesPerson': widget.orderData['salesPerson'] ?? '',
//             'unit': widget.orderData['unit'] ?? '',
//             'orderDate': widget.orderData['orderDate'],
//             'deliveryDate': widget.orderData['deliveryDate'],
//             'productId': widget.productData['id'] ?? '',
//             'productName': widget.productData['productName'] ?? '',
//             'productCategory': widget.productData['productCategory'] ?? '',
//             'quantity': widget.productData['quantity'] ?? 0,
//             'length': widget.productData['length'] ?? '',
//             'height': widget.productData['height'] ?? '',
//             'width': widget.productData['width'] ?? '',
//             'price': widget.productData['price'] ?? 0,
//             'remarks': widget.productData['remarks'] ?? '',

//             'mdfTraysContractor': _selectedTrayContractor == "Other"
//                 ? _trayOtherController.text.trim()
//                 : _selectedTrayContractor ?? '',

//             'mdfCutting': {
//               'contractor': _selectedCuttingContractor == "Other"
//                   ? _cuttingOtherController.text.trim()
//                   : _selectedCuttingContractor ?? '',
//               'price':
//                   double.tryParse(_cuttingPriceController.text.trim()) ?? 0,
//             },

//             'mdfPasting': {
//               'contractor': _selectedPastingContractor == "Other"
//                   ? _pastingOtherController.text.trim()
//                   : _selectedPastingContractor ?? '',
//               'price':
//                   double.tryParse(_pastingPriceController.text.trim()) ?? 0,
//             },

//             'updatedAt': FieldValue.serverTimestamp(),
//           }, SetOptions(merge: true));

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Row(
//               children: [
//                 Icon(Icons.check_circle_outline, color: Colors.white),
//                 SizedBox(width: 10),
//                 Text('Contractors saved successfully!'),
//               ],
//             ),
//             backgroundColor: AppColors.success,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: AppColors.warning,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.lightBg,
//       appBar: AppBar(
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         title: const Text(
//           'MDF Contractor Assignment',
//           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
//         ),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // ── Order Details Card (READ ONLY) ──
//           _buildOrderDetailsCard(),
//           const SizedBox(height: 20),

//           // ── Product Details Card (READ ONLY) ──
//           _buildProductDetailsCard(),
//           const SizedBox(height: 20),

//           // ── MDF Trays / Double Box Contractor ──
//           _buildSectionCard(
//             title: 'Box Description & For Contractor',
//             icon: Icons.inbox_outlined,
//             gradient: LinearGradient(
//               colors: [Colors.teal.shade50, Colors.green.shade50],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             children: [
//               _buildDropdown(
//                 label: 'Select Contractor',
//                 icon: Icons.person_pin,
//                 value: _selectedTrayContractor,
//                 items: _trayContractors,
//                 onChanged: (v) => setState(() => _selectedTrayContractor = v),
//               ),

//               if (_selectedTrayContractor == "Other") ...[
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _trayOtherController,
//                   decoration: InputDecoration(
//                     labelText: "Enter Contractor Name",
//                     prefixIcon: const Icon(Icons.edit),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     filled: true,
//                     fillColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//           const SizedBox(height: 16),

//           // ── MDF Cutting ──
//           _buildSectionCard(
//             title: 'MDF Cutting',
//             icon: Icons.cut_outlined,
//             gradient: LinearGradient(
//               colors: [Colors.blue.shade50, Colors.cyan.shade50],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             children: [
//               _buildDropdown(
//                 label: 'Select Cutting Contractor',
//                 icon: Icons.person_pin,
//                 value: _selectedCuttingContractor,
//                 items: _cuttingContractors,
//                 onChanged: (v) =>
//                     setState(() => _selectedCuttingContractor = v),
//               ),
//               if (_selectedCuttingContractor == "Other") ...[
//                 const SizedBox(height: 12),

//                 TextFormField(
//                   controller: _cuttingOtherController,
//                   decoration: InputDecoration(
//                     labelText: "Enter Contractor Name",
//                     prefixIcon: const Icon(Icons.edit),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     filled: true,
//                     fillColor: Colors.white,
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 12),
//               _buildPriceField(
//                 controller: _cuttingPriceController,
//                 label: 'Cutting Price (₹)',
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // ── MDF Pasting ──
//           _buildSectionCard(
//             title: 'MDF Pasting',
//             icon: Icons.layers_outlined,
//             gradient: LinearGradient(
//               colors: [Colors.purple.shade50, Colors.pink.shade50],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             children: [
//               _buildDropdown(
//                 label: 'Select Pasting Contractor',
//                 icon: Icons.person_pin,
//                 value: _selectedPastingContractor,
//                 items: _pastingContractors,
//                 onChanged: (v) =>
//                     setState(() => _selectedPastingContractor = v),
//               ),
//               if (_selectedPastingContractor == "Other") ...[
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _pastingOtherController,
//                   decoration: InputDecoration(
//                     labelText: "Enter Contractor Name",
//                     prefixIcon: const Icon(Icons.edit),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     filled: true,
//                     fillColor: Colors.white,
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 12),
//               _buildPriceField(
//                 controller: _pastingPriceController,
//                 label: 'Pasting Price (₹)',
//               ),
//             ],
//           ),
//           const SizedBox(height: 30),

//           // ── Save Button ──
//           _buildSaveButton(),
//           const SizedBox(height: 30),
//         ],
//       ),
//     );
//   }
//   Widget _buildOrderDetailsCard() {
//     final order = orderData!;
//     String formatDate(dynamic ts) {
//       if (ts == null) return '-';
//       if (ts is Timestamp) {
//         final d = ts.toDate();
//         return '${d.day}/${d.month}/${d.year}';
//       }
//       return '-';
//     }

//     return _buildSectionCard(
//       title: 'Order Details',
//       icon: Icons.receipt_long_outlined,
//       gradient: LinearGradient(
//         colors: [Colors.orange.shade50, Colors.amber.shade50],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       children: [
//         _infoRow(Icons.tag, 'Order ID', widget.orderId),
//         _infoRow(Icons.person, 'Customer', order['customerName'] ?? '-'),
//         _infoRow(Icons.business, 'Company', order['companyName'] ?? '-'),
//         _infoRow(Icons.phone, 'Phone', order['phone'] ?? '-'),
//         _infoRow(Icons.location_on, 'Location', order['location'] ?? '-'),
//         _infoRow(Icons.person_pin, 'Sales Person', order['salesPerson'] ?? '-'),
//         _infoRow(Icons.factory_outlined, 'Unit', order['unit'] ?? '-'),
//         _infoRow(Icons.flag_outlined, 'Priority', order['priority'] ?? '-'),
//         _infoRow(
//           Icons.calendar_today,
//           'Order Date',
//           formatDate(order['orderDate']),
//         ),
//         _infoRow(
//           Icons.local_shipping_outlined,
//           'Delivery Date',
//           formatDate(order['deliveryDate']),
//         ),
//       ],
//     );
//   }

//   // ─────────────────────────────────────────────
//   //  PRODUCT DETAILS CARD
//   // ─────────────────────────────────────────────
//   Widget _buildProductDetailsCard() {
//     final p = productData!;
//     final sections = p['sections'] as Map<String, dynamic>? ?? {};

//     return _buildSectionCard(
//       title: 'Product Details',
//       icon: Icons.inventory_2_outlined,
//       gradient: LinearGradient(
//         colors: [Colors.indigo.shade50, Colors.blue.shade50],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       children: [
//         _infoRow(
//           Icons.shopping_bag_outlined,
//           'Product Name',
//           p['productName'] ?? '-',
//         ),
//         _infoRow(
//           Icons.category_outlined,
//           'Category',
//           p['productCategory'] ?? '-',
//         ),
//         _infoRow(Icons.numbers, 'Quantity', '${p['quantity'] ?? 0}'),
//         _infoRow(Icons.currency_rupee, 'Price', '₹${p['price'] ?? 0}'),
//         _infoRow(
//           Icons.straighten,
//           'Size (L×H×W)',
//           '${p['length'] ?? '-'} × ${p['height'] ?? '-'} × ${p['width'] ?? '-'}',
//         ),
//         if ((p['remarks'] ?? '').toString().isNotEmpty)
//           _infoRow(Icons.comment_outlined, 'Remarks', p['remarks']),

//         // Sections
//         if (sections.isNotEmpty) ...[
//           const Divider(height: 20),
//           const Text(
//             'Packaging Sections',
//             style: TextStyle(
//               fontWeight: FontWeight.w700,
//               fontSize: 13,
//               color: AppColors.primary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           ...sections.entries.map((e) {
//             final key = e.key
//                 .replaceAll('Detail', ' Detail')
//                 .replaceAll('Qty', ' Qty')
//                 .replaceAll('Price', ' Price');
//             return _infoRow(Icons.label_outline, key, '${e.value}');
//           }),
//         ],
//       ],
//     );
//   }

//   // ─────────────────────────────────────────────
//   //  WIDGETS
//   // ─────────────────────────────────────────────
//   Widget _buildSectionCard({
//     required String title,
//     required IconData icon,
//     required Gradient gradient,
//     required List<Widget> children,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, color: AppColors.primary, size: 22),
//             const SizedBox(width: 10),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.darkText,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             gradient: gradient,
//             borderRadius: BorderRadius.circular(14),
//             boxShadow: [
//               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: children,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _infoRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 16, color: AppColors.primary),
//           const SizedBox(width: 8),
//           Expanded(
//             child: RichText(
//               text: TextSpan(
//                 style: const TextStyle(fontSize: 13, color: AppColors.darkText),
//                 children: [
//                   TextSpan(
//                     text: '$label: ',
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   TextSpan(text: value),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDropdown({
//     required String label,
//     required IconData icon,
//     required String? value,
//     required List<String> items,
//     required ValueChanged<String?> onChanged,
//   }) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       isExpanded: true,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: AppColors.primary),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.primary, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(
//           vertical: 12,
//           horizontal: 16,
//         ),
//       ),
//       items: items
//           .map(
//             (name) => DropdownMenuItem<String>(value: name, child: Text(name)),
//           )
//           .toList(),
//       onChanged: onChanged,
//     );
//   }

//   Widget _buildPriceField({
//     required TextEditingController controller,
//     required String label,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//       inputFormatters: [
//         FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
//       ],
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.primary),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.primary, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(
//           vertical: 12,
//           horizontal: 16,
//         ),
//       ),
//     );
//   }

//   Widget _buildSaveButton() {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: AppColors.primaryGradient,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.4),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         onPressed: _isSaving ? null : _saveContractors,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           foregroundColor: Colors.white,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           padding: const EdgeInsets.symmetric(vertical: 16),
//         ),
//         child: _isSaving
//             ? const CircularProgressIndicator(color: Colors.white)
//             : const Text(
//                 'Save Contractors',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _cuttingPriceController.dispose();
//     _pastingPriceController.dispose();
//     _trayOtherController.dispose();
//     _cuttingOtherController.dispose();
//     _pastingOtherController.dispose();
//     super.dispose();
//   }
// }
