// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class UserPermissionScreen extends StatefulWidget {
//   const UserPermissionScreen({super.key});

//   @override
//   State<UserPermissionScreen> createState() => _UserPermissionScreenState();
// }

// class _UserPermissionScreenState extends State<UserPermissionScreen> {
//   String? _selectedUserId;
//   Map<String, dynamic> _permissions = {};
//   bool _saving = false;

//   final List<Map<String, String>> permissionList = [
//     {'key': 'stock', 'label': 'Stock'},
//     {'key': 'sales', 'label': 'Sales'},
//     {'key': 'production', 'label': 'Production'},
//     {'key': 'purchase', 'label': 'Purchase Order'},
//     {'key': 'quality', 'label': 'Quality Check'},
//     {'key': 'mom', 'label': 'MOM'},
//     {'key': 'master', 'label': 'Master Screen'},
//   ];

//   // ================= LOAD USER PERMISSIONS =================
//   Future<void> _loadPermissions(String uid) async {
//     final doc =
//         await FirebaseFirestore.instance.collection('users').doc(uid).get();

//     setState(() {
//       _permissions = Map<String, dynamic>.from(
//         doc.data()?['permissions'] ?? {},
//       );
//     });
//   }

//   // ================= SAVE PERMISSIONS =================
//   Future<void> _savePermissions() async {
//     if (_selectedUserId == null) return;

//     setState(() => _saving = true);

//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(_selectedUserId)
//         .update({'permissions': _permissions});

//     setState(() => _saving = false);

//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('✅ Permissions updated successfully'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('User Permission Management'),
//         backgroundColor: Colors.indigo,
//       ),
//       body: Row(
//         children: [
//           // ================= USER LIST =================
//           Expanded(
//             flex: 2,
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .orderBy('name')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 return ListView(
//                   children: snapshot.data!.docs.map((doc) {
//                     final isSelected = doc.id == _selectedUserId;

//                     return ListTile(
//                       title: Text(doc['name'] ?? 'No Name'),
//                       subtitle: Text(doc['role'] ?? ''),
//                       selected: isSelected,
//                       selectedTileColor: Colors.indigo.withOpacity(0.1),
//                       onTap: () {
//                         setState(() {
//                           _selectedUserId = doc.id;
//                         });
//                         _loadPermissions(doc.id);
//                       },
//                     );
//                   }).toList(),
//                 );
//               },
//             ),
//           ),

//           const VerticalDivider(),

//           // ================= PERMISSION PANEL =================
//           Expanded(
//             flex: 3,
//             child: _selectedUserId == null
//                 ? const Center(
//                     child: Text(
//                       '👈 Select a user to manage permissions',
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   )
//                 : Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Permissions',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 16),

//                         Expanded(
//                           child: ListView(
//                             children: permissionList.map((perm) {
//                               final key = perm['key']!;
//                               final label = perm['label']!;

//                               return CheckboxListTile(
//                                 title: Text(label),
//                                 value: _permissions[key] == true,
//                                 onChanged: (val) {
//                                   setState(() {
//                                     _permissions[key] = val ?? false;
//                                   });
//                                 },
//                               );
//                             }).toList(),
//                           ),
//                         ),

//                         const SizedBox(height: 16),

//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: _saving ? null : _savePermissions,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.indigo,
//                               padding:
//                                   const EdgeInsets.symmetric(vertical: 14),
//                             ),
//                             child: _saving
//                                 ? const CircularProgressIndicator(
//                                     color: Colors.white,
//                                   )
//                                 : const Text(
//                                     'Save Permissions',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
