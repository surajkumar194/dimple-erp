// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class KrishnaHistoryPage extends StatelessWidget {
//   const KrishnaHistoryPage({super.key});

//   static const Color primary = Color(0xFF4F46E5);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FF),
//       appBar: AppBar(
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           "Krishna Arora Records",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color(0xFF4F46E5),
//                 Color(0xFF7C3AED),
//               ],
//             ),
//           ),
//         ),
//       ),
//     body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//   stream: FirebaseFirestore.instance
//       .collection('followups')
//       .where('client', isEqualTo: 'Krishna Arora')
//       .snapshots(),
//   builder: (context, snapshot) {

//     if (snapshot.hasError) {
//       return Center(
//         child: Text(
//           "Error: ${snapshot.error}",
//           style: const TextStyle(
//             color: Colors.red,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       );
//     }

//     if (snapshot.connectionState == ConnectionState.waiting) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
//         snapshot.data?.docs ?? [];

//     // A TO Z SORT
//     docs.sort((a, b) {
//       final aName =
//           (a.data()['customer'] ?? '').toString().toLowerCase();

//       final bName =
//           (b.data()['customer'] ?? '').toString().toLowerCase();

//       return aName.compareTo(bName);
//     });

//     if (docs.isEmpty) {
//       return const Center(
//         child: Text(
//           "No Krishna Records Found",
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       );
//     }

//     return Column(
//       children: [

//         Container(
//           margin: const EdgeInsets.all(16),
//           padding: const EdgeInsets.all(15),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [
//                 Color(0xFF4F46E5),
//                 Color(0xFF7C3AED),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Row(
//             children: [
//               const Icon(
//                 Icons.people,
//                 color: Colors.white,
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 "Total Records : ${docs.length}",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         Expanded(
//           child: ListView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: docs.length,
//             itemBuilder: (context, index) {

//               final data = docs[index].data();

//               final customer =
//                   data['customer']?.toString() ?? '';

//               final phone =
//                   data['phone']?.toString() ?? '';

//               final description =
//                   data['description']?.toString() ?? '';

//               final problem =
//                   data['problem']?.toString() ?? '';

//               final followups =
//                   data['followupCount'] ?? 0;

//               return Card(
//                 elevation: 3,
//                 margin: const EdgeInsets.only(bottom: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(15),
//                   child: Column(
//                     crossAxisAlignment:
//                         CrossAxisAlignment.start,
//                     children: [

//                       Row(
//                         children: [

//                           CircleAvatar(
//                             radius: 25,
//                             backgroundColor:
//                                 const Color(0xFF4F46E5)
//                                     .withOpacity(.1),
//                             child: Text(
//                               customer.isNotEmpty
//                                   ? customer[0]
//                                       .toUpperCase()
//                                   : "?",
//                               style: const TextStyle(
//                                 color: Color(0xFF4F46E5),
//                                 fontWeight:
//                                     FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                           ),

//                           const SizedBox(width: 12),

//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment:
//                                   CrossAxisAlignment.start,
//                               children: [

//                                 Text(
//                                   customer,
//                                   style:
//                                       const TextStyle(
//                                     fontSize: 17,
//                                     fontWeight:
//                                         FontWeight.bold,
//                                   ),
//                                 ),

//                                 const SizedBox(height: 4),

//                                 Text(
//                                   phone,
//                                   style:
//                                       const TextStyle(
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           Container(
//                             padding:
//                                 const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color:
//                                   Colors.green.shade100,
//                               borderRadius:
//                                   BorderRadius.circular(
//                                       30),
//                             ),
//                             child: Text(
//                               "$followups",
//                               style:
//                                   const TextStyle(
//                                 color: Colors.green,
//                                 fontWeight:
//                                     FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       if (description.isNotEmpty) ...[
//                         const SizedBox(height: 12),
//                         Text(
//                           "Description",
//                           style: TextStyle(
//                             fontWeight:
//                                 FontWeight.bold,
//                             color:
//                                 Colors.blue.shade700,
//                           ),
//                         ),
//                         Text(description),
//                       ],

//                       if (problem.isNotEmpty) ...[
//                         const SizedBox(height: 12),
//                         Text(
//                           "Problem",
//                           style: TextStyle(
//                             fontWeight:
//                                 FontWeight.bold,
//                             color:
//                                 Colors.orange.shade700,
//                           ),
//                         ),
//                         Text(problem),
//                       ],
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   },
// )
//     );
//   }
// }