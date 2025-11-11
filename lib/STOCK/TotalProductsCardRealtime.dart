
// import 'package:flutter/material.dart';

// class _TotalProductsCardRealtime extends StatelessWidget {
//   const _TotalProductsCardRealtime({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('products')
//           .snapshots(), // realtime
//       builder: (context, snapshot) {
//         final String value;
//         if (snapshot.connectionState == ConnectionState.waiting) {



//           value = '—';
//         } else if (snapshot.hasError) {
//           value = 'ERR';
//         } else {
//           value = snapshot.data?.size.toString() ?? '0';
//         }

//         // UI same style as _buildStatCard
//         return Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.95),
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Row(
//                 children: [
//                   const Icon(Icons.inventory_2, color: Colors.blue, size: 24),
//                   const Spacer(),
//                   Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(Icons.trending_up, size: 16, color: Colors.blue),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 value, // realtime total products
//                 style: const TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.w800,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Total Products',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
