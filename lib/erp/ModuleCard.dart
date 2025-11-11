// import 'package:dimple_erp/main.dart';
// import 'package:flutter/material.dart';

// class _ModuleCard extends StatelessWidget {
//   final Module module;
//   const _ModuleCard({required this.module});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 3,
//       shadowColor: module.color.withOpacity(0.2),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             colors: [Colors.white, module.color.withOpacity(0.02)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Theme(
//           data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
//           child: ExpansionTile(
//             tilePadding: const EdgeInsets.symmetric(
//               horizontal: 20,
//               vertical: 8,
//             ),
//             childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
//             leading: Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: module.color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(module.icon, color: module.color, size: 24),
//             ),
//             title: Text(
//               module.header,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 0.2,
//               ),
//             ),
//             subtitle: Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Text(
//                 '${module.subcategories.length} subcategories',
//                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//               ),
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: module.color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     '${module.subcategories.length}',
//                     style: TextStyle(
//                       color: module.color,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 const Icon(Icons.keyboard_arrow_down),
//               ],
//             ),
//             children: [
//               const Divider(height: 1),
//               const SizedBox(height: 8),
//               for (int i = 0; i < module.subcategories.length; i++)
//                 _SubcategoryItem(
//                   title: module.subcategories[i],
//                   color: module.color,
//                   icon: module.icon,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => _getSubcategoryScreen(
//                           module.subcategories[i],
//                           module.header,
//                           module.color,
//                           module.icon,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }