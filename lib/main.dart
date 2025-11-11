import 'package:dimple_erp/all%20pages/firebase_optional.dart';
import 'package:dimple_erp/all%20screen/MainScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sizer/sizer.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }
  
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Wrap the MaterialApp inside Sizer
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Professional Inventory System',
          theme: ThemeData(
            primarySwatch: Colors.indigo,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//         if (snapshot.hasData) {
//           return Dashboard();
//         }
//         return const LoginPage();
//       },
//     );
//   }
// }




// import 'package:dimple_erp/all%20screen/main.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// void main() {
//   runApp(const DimpleErpApp());
// }

// class DimpleErpApp extends StatelessWidget {
//   const DimpleErpApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dimple Packaging ERP',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorSchemeSeed: const Color(0xFF1EA7E1),
//       ),
//       home: const MainScreen(),
//     );
//   }
// }

// class Module {
//   final String header;
//   final List<String> subcategories;
//   final IconData icon;
//   final Color color;
  
//   const Module({
//     required this.header,
//     required this.subcategories,
//     required this.icon,
//     required this.color,
//   });
// }

// const List<Module> kModules = [
//   Module(
//     header: 'Production & Manufacturing',
//     icon: Icons.precision_manufacturing,
//     color: Color(0xFF4CAF50),
//     subcategories: [
//       'Printing Job Scheduling',
//       'Die Cutting / Folding',
//       'Lamination & Finishing',
//       'Work in Progress (WIP) Tracking',
//       'Machine Utilization & Downtime',
//     ],
//   ),
//   Module(
//     header: 'Inventory & Material Management',
//     icon: Icons.inventory_2,
//     color: Color(0xFF2196F3),
//     subcategories: [
//       'Raw Material Inventory (Paper/Board)',
//       'Packaging Consumables Tracking',
//       'Batch / Lot Number Management',
//       'Barcode Integration',
//       'Reorder Alerts & Safety Stock',
//     ],
//   ),
//   Module(
//     header: 'Procurement & Vendor Management',
//     icon: Icons.shopping_cart,
//     color: Color(0xFFFF9800),
//     subcategories: [
//       'Supplier Database',
//       'Purchase Order Management',
//       'Material Sourcing',
//       'Vendor Invoice & Payments',
//       'Quality Check on Incoming Material',
//     ],
//   ),
//   Module(
//     header: 'Quality & Compliance',
//     icon: Icons.verified_user,
//     color: Color(0xFF9C27B0),
//     subcategories: [
//       'Stage-Wise Quality Inspection',
//       'Defect / Rejection Records',
//       'Batch Traceability',
//       'Compliance & ISO Reports',
//     ],
//   ),
//   Module(
//     header: 'Sales & Order Management',
//     icon: Icons.point_of_sale,
//     color: Color(0xFFE91E63),
//     subcategories: [
//       // 'Quotation & Pricing',
//       'Order Booking',
//       'Customer All order',
//       'Delivery Scheduling',
//     ],
//   ),
//   Module(
//     header: 'Logistics & Distribution',
//     icon: Icons.local_shipping,
//     color: Color(0xFF00BCD4),
//     subcategories: [
//       'Dispatch Planning',
//       'Transport & Fleet Management',
//       'Real-Time Shipment Tracking',
//       'Delivery Proof (POD)',
//     ],
//   ),
//   Module(
//     header: 'Finance & Accounting',
//     icon: Icons.account_balance,
//     color: Color(0xFF009688),
//     subcategories: [
//       'General Ledger',
//       'Job Costing & Profitability',
//       'Accounts Payable / Receivable',
//       'GST / Tax Compliance',
//     ],
//   ),
//   Module(
//     header: 'Human Resources & Payroll',
//     icon: Icons.people,
//     color: Color(0xFF3F51B5),
//     subcategories: [
//       'Employee Records',
//       'Attendance & Shifts',
//       'Payroll & Salary Processing',
//     ],
//   ),
//   Module(
//     header: 'Maintenance & Asset Management',
//     icon: Icons.build,
//     color: Color(0xFF795548),
//     subcategories: [
//       'Machine Maintenance Scheduling',
//       'Breakdown & Repair Records',
//       'Spare Parts Inventory',
//       'Preventive Maintenance Alerts',
//     ],
//   ),
// ];

// const List<String> kTopMenus = [
//   'Sales',
//   'Material',
//   'PPC',
//   'Operation',
//   'QC/QA',
//   'Engineering',
//   'Finance',
//   'Admin',
// ];

// class ErpModulesScreen extends StatefulWidget {
//   const ErpModulesScreen({super.key});

//   @override
//   State<ErpModulesScreen> createState() => _ErpModulesScreenState();
// }

// class _ErpModulesScreenState extends State<ErpModulesScreen> {
//   String _query = '';
//   String _activeMenu = 'Sales';

//   List<Module> get _filteredModules {
//     final all = kModules;
//     final q = _query.trim().toLowerCase();
//     final base = all.where((m) {
//       if (q.isEmpty) return true;
//       final inHeader = m.header.toLowerCase().contains(q);
//       final inSubs = m.subcategories.any((s) => s.toLowerCase().contains(q));
//       return inHeader || inSubs;
//     }).toList();

//     switch (_activeMenu) {
//       case 'Sales':
//         return base.where((m) => m.header.contains('Sales')).toList();
//       case 'PPC':
//         return base.where((m) => m.header.contains('Production')).toList();
//       case 'Material':
//         return base.where((m) => m.header.contains('Inventory')).toList();
//       case 'Operation':
//         return base.where((m) => m.header.contains('Logistics') || m.header.contains('Production')).toList();
//       case 'QC/QA':
//         return base.where((m) => m.header.contains('Quality')).toList();
//       case 'Engineering':
//         return base.where((m) => m.header.contains('Maintenance')).toList();
//       case 'Finance':
//         return base.where((m) => m.header.contains('Finance')).toList();
//       case 'Admin':
//         return base.where((m) => m.header.contains('Human Resources')).toList();
//       default:
//         return base;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFF1EA7E1), Color(0xFF61C6F0)],
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(Icons.business, color: Colors.white, size: 24),
//             ),
//             const SizedBox(width: 12),
//             Center(child: const Text('Dimple Packaging ERP', style: TextStyle(fontWeight: FontWeight.bold))),
//           ],
//         ),
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.settings_outlined),
//             onPressed: () {},
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           const SizedBox(height: 12),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: _BlueTopBar(
//               items: kTopMenus,
//               active: _activeMenu,
//               onTap: (label) {
//                 setState(() => _activeMenu = label);
//                 HapticFeedback.selectionClick();
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search modules or subcategories...',
//                   hintStyle: TextStyle(color: Colors.grey[400]),
//                   prefixIcon: const Icon(Icons.search, color: Color(0xFF1EA7E1)),
//                   suffixIcon: _query.isNotEmpty
//                       ? IconButton(
//                           icon: const Icon(Icons.clear),
//                           onPressed: () => setState(() => _query = ''),
//                         )
//                       : null,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: BorderSide.none,
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 1, vertical: 14),
//                 ),
//                 onChanged: (v) => setState(() => _query = v),
//               ),
//             ),
//           ),
//           Expanded(
//             child: _filteredModules.isEmpty
//                 ? const _EmptyState()
//                 : ListView.separated(
//                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//                     itemCount: _filteredModules.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 11),
//                     itemBuilder: (context, index) {
//                       final module = _filteredModules[index];
//                       return _ModuleCard(module: module);
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _BlueTopBar extends StatelessWidget {
//   final List<String> items;
//   final String active;
//   final ValueChanged<String> onTap;

//   const _BlueTopBar({
//     required this.items,
//     required this.active,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 52,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF1EA7E1), Color(0xFF61C6F0)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF1EA7E1).withOpacity(0.3),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           )
//         ],
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             for (final label in items)
//               _BlueTopItem(
//                 label: label,
//                 isActive: label == active,
//                 onTap: () => onTap(label),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _BlueTopItem extends StatefulWidget {
//   final String label;
//   final bool isActive;
//   final VoidCallback onTap;

//   const _BlueTopItem({
//     required this.label,
//     required this.isActive,
//     required this.onTap,
//   });

//   @override
//   State<_BlueTopItem> createState() => _BlueTopItemState();
// }

// class _BlueTopItemState extends State<_BlueTopItem> {
//   bool _hovering = false;

//   @override
//   Widget build(BuildContext context) {
//     final bg = (widget.isActive || _hovering)
//         ? Colors.white.withOpacity(0.18)
//         : Colors.transparent;

//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       onEnter: (_) => setState(() => _hovering = true),
//       onExit: (_) => setState(() => _hovering = false),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(10),
//           onTap: widget.onTap,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 180),
//             curve: Curves.easeOut,
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
//             decoration: BoxDecoration(
//               color: bg,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.label,
//                   maxLines: 1,
//                   overflow: TextOverflow.clip,
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight:
//                         widget.isActive ? FontWeight.w700 : FontWeight.w600,
//                     color: Colors.white,
//                     letterSpacing: 0.2,
//                   ),
//                 ),
//                 // underline indicator
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 180),
//                   curve: Curves.easeOut,
//                   margin: const EdgeInsets.only(top: 6),
//                   height: 3,
//                   width: widget.isActive ? 28 : 0,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

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
//             tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
//                   moduleHeader: module.header, // Pass moduleHeader for navigation
//                   onTap: () {
//                     // Updated navigation logic
//                     if (module.subcategories[i] == 'Order Booking') {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const OrderBookingScreen(),
//                         ),
//                       );
//                     } else {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => SubcategoryDetailPage(
//                             subcategoryName: module.subcategories[i],
//                             moduleHeader: module.header,
//                             color: module.color,
//                             icon: module.icon,
//                           ),
//                         ),
//                       );
//                     }
//                   },
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SubcategoryItem extends StatefulWidget {
//   final String title;
//   final Color color;
//   final IconData icon;
//   final String moduleHeader; // Added for navigation
//   final VoidCallback onTap;

//   const _SubcategoryItem({
//     required this.title,
//     required this.color,
//     required this.icon,
//     required this.moduleHeader,
//     required this.onTap,
//   });

//   @override
//   State<_SubcategoryItem> createState() => _SubcategoryItemState();
// }

// class _SubcategoryItemState extends State<_SubcategoryItem> {
//   bool _isHovered = false;

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovered = true),
//       onExit: (_) => setState(() => _isHovered = false),
//       child: GestureDetector(
//         onTap: () {
//           HapticFeedback.lightImpact();
//           widget.onTap();
//         },
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           margin: const EdgeInsets.only(bottom: 8),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: _isHovered
//                 ? widget.color.withOpacity(0.08)
//                 : Colors.grey[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: _isHovered
//                   ? widget.color.withOpacity(0.3)
//                   : Colors.grey[200]!,
//               width: 1.5,
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(6),
//                 decoration: BoxDecoration(
//                   color: widget.color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   Icons.arrow_forward_ios,
//                   size: 14,
//                   color: widget.color,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   widget.title,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ),
//               Icon(
//                 Icons.open_in_new,
//                 size: 16,
//                 color: widget.color,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   const _EmptyState();
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.search_off_outlined, size: 64, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'No matches found',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Try a different keyword',
//             style: TextStyle(color: Colors.grey[500]),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Generic subcategory page (unchanged)
// class SubcategoryDetailPage extends StatelessWidget {
//   final String subcategoryName;
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const SubcategoryDetailPage({
//     super.key,
//     required this.subcategoryName,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: Text(subcategoryName),
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Card
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [color.withOpacity(0.1), Colors.white],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: color.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Icon(icon, color: color, size: 32),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 moduleHeader,
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.grey[600],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 subcategoryName,
//                                 style: const TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Quick Actions
//             Text(
//               'Quick Actions',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             const SizedBox(height: 12),
//             GridView.count(
//               crossAxisCount: 2,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               mainAxisSpacing: 12,
//               crossAxisSpacing: 12,
//               childAspectRatio: 1.5,
//               children: [
//                 _ActionCard(
//                   title: 'Create New',
//                   icon: Icons.add_circle_outline,
//                   color: color,
//                   onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Create New in $subcategoryName'),
//                         backgroundColor: color,
//                       ),
//                     );
//                   },
//                 ),
//                 _ActionCard(
//                   title: 'View All',
//                   icon: Icons.list_alt,
//                   color: color,
//                   onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('View All $subcategoryName'),
//                         backgroundColor: color,
//                       ),
//                     );
//                   },
//                 ),
//                 _ActionCard(
//                   title: 'Reports',
//                   icon: Icons.analytics_outlined,
//                   color: color,
//                   onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('View $subcategoryName Reports'),
//                         backgroundColor: color,
//                       ),
//                     );
//                   },
//                 ),
//                 _ActionCard(
//                   title: 'Settings',
//                   icon: Icons.settings_outlined,
//                   color: color,
//                   onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('$subcategoryName Settings'),
//                         backgroundColor: color,
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Recent Activity
//             Text(
//               'Recent Activity',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             const SizedBox(height: 12),
//             _ActivityCard(
//               title: 'No recent activity',
//               subtitle: 'Activity in this module will appear here',
//               icon: Icons.info_outline,
//               color: color,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // New Order Booking Screen
// class OrderBookingScreen extends StatefulWidget {
//   const OrderBookingScreen({super.key});

//   @override
//   State<OrderBookingScreen> createState() => _OrderBookingScreenState();
// }

// class _OrderBookingScreenState extends State<OrderBookingScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   final Color _color = const Color(0xFFE91E63); // Sales color
//   final IconData _icon = Icons.point_of_sale;

//   // Sample data for recent orders
//   final List<Map<String, dynamic>> _orders = [
//     {
//       'id': 'ORD-001',
//       'customer': 'ABC Corp',
//       'date': '2025-10-05',
//       'status': 'Pending',
//       'amount': '₹45,000',
//     },
//     {
//       'id': 'ORD-002',
//       'customer': 'XYZ Ltd',
//       'date': '2025-10-04',
//       'status': 'Approved',
//       'amount': '₹28,500',
//     },
//     {
//       'id': 'ORD-003',
//       'customer': 'Demo Client',
//       'date': '2025-10-03',
//       'status': 'In Progress',
//       'amount': '₹12,000',
//     },
//   ];

//   List<Map<String, dynamic>> get _filteredOrders {
//     if (_searchQuery.isEmpty) return _orders;
//     return _orders.where((order) =>
//         order['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
//         order['customer'].toLowerCase().contains(_searchQuery.toLowerCase())
//     ).toList();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Order Booking'),
//         backgroundColor: _color,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               setState(() {}); // Refresh placeholder
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Card
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [_color.withOpacity(0.1), Colors.white],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: _color.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Icon(_icon, color: _color, size: 32),
//                         ),
//                         const SizedBox(width: 16),
//                         const Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Sales & Order Management',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Color(0xFF9E9E9E),
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 'Order Booking',
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Search Bar
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: 'Search orders by ID or Customer...',
//                   hintStyle: TextStyle(color: Colors.grey[400]),
//                   prefixIcon: const Icon(Icons.search, color: Color(0xFFE91E63)),
//                   suffixIcon: _searchQuery.isNotEmpty
//                       ? IconButton(
//                           icon: const Icon(Icons.clear),
//                           onPressed: () {
//                             _searchController.clear();
//                             setState(() => _searchQuery = '');
//                           },
//                         )
//                       : null,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: BorderSide.none,
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 ),
//                 onChanged: (v) => setState(() => _searchQuery = v),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Quick Actions
//             Text(
//               'Quick Actions',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             const SizedBox(height: 12),
//             GridView.count(
//               crossAxisCount: 2,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               mainAxisSpacing: 12,
//               crossAxisSpacing: 12,
//               childAspectRatio: 1.5,
//               children: [
//                 _ActionCard(
//                   title: 'New Order',
//                   icon: Icons.add_circle_outline,
//                   color: _color,
//                   onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Open New Order Form'),
//                         backgroundColor: Color(0xFFE91E63),
//                       ),
//                     );
//                   },
//                 ),
//                 _ActionCard(
//                   title: 'View All Orders',
//                   icon: Icons.list_alt,
//                   color: _color,
//                   onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('View All Orders'),
//                         backgroundColor: Color(0xFFE91E63),
//                       ),
//                     );
//                   },
//                 ),
//                 _ActionCard(
//                   title: 'Pending Approvals',
//                   icon: Icons.pending_actions,
//                   color: _color,
//                   onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('View Pending Approvals'),
//                         backgroundColor: Color(0xFFE91E63),
//                       ),
//                     );
//                   },
//                 ),
//                 _ActionCard(
//                   title: 'Reports',
//                   icon: Icons.analytics_outlined,
//                   color: _color,
//                   onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Order Reports'),
//                         backgroundColor: Color(0xFFE91E63),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),

//             // Recent Orders
//             Text(
//               'Recent Orders',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             const SizedBox(height: 12),
//             if (_filteredOrders.isEmpty)
//               _ActivityCard(
//                 title: 'No orders found',
//                 subtitle: 'No recent orders match your search',
//                 icon: Icons.search_off,
//                 color: _color,
//               )
//             else
//               ..._filteredOrders.map((order) => _OrderCard(
//                     order: order,
//                     color: _color,
//                     onTap: () {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('Open Order ${order['id']} Details'),
//                           backgroundColor: _color,
//                         ),
//                       );
//                     },
//                   )),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // New Order Card Widget
// class _OrderCard extends StatelessWidget {
//   final Map<String, dynamic> order;
//   final Color color;
//   final VoidCallback onTap;

//   const _OrderCard({
//     required this.order,
//     required this.color,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     Color getStatusColor(String status) {
//       switch (status) {
//         case 'Pending':
//           return Colors.orange;
//         case 'Approved':
//           return Colors.green;
//         case 'In Progress':
//           return Colors.blue;
//         default:
//           return Colors.grey;
//       }
//     }

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: color.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Icon(Icons.point_of_sale, color: color, size: 20),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           order['id'],
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                         Text(
//                           order['customer'],
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: getStatusColor(order['status']).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       order['status'],
//                       style: TextStyle(
//                         color: getStatusColor(order['status']),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Date: ${order['date']}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                   Text(
//                     order['amount'],
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                       color: Color(0xFFE91E63),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ActionCard extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   final Color color;
//   final VoidCallback onTap;

//   const _ActionCard({
//     required this.title,
//     required this.icon,
//     required this.color,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             gradient: LinearGradient(
//               colors: [color.withOpacity(0.05), Colors.white],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: color, size: 32),
//               const SizedBox(height: 8),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 14,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ActivityCard extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final Color color;

//   const _ActivityCard({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 1,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: color),
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//         subtitle: Text(subtitle),
//       ),
//     );
//   }
// }





// // import 'package:dimple_erp/all%20pages/firebase_optional.dart';
// // import 'package:dimple_erp/all%20screen/main.dart';
// // import 'package:flutter/material.dart';
// // import 'package:firebase_core/firebase_core.dart';

// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
  
// //   try {
// //     await Firebase.initializeApp(
// //       options: DefaultFirebaseOptions.currentPlatform,
// //     );
// //     print("✅ Firebase initialized successfully");
// //   } catch (e) {
// //     print("❌ Firebase initialization error: $e");
// //   }
  
// //   runApp(const DimplePackagingERP());
// // }

// // class DimplePackagingERP extends StatelessWidget {
// //   const DimplePackagingERP({Key? key}) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Dimple Packaging Pvt Ltd',
// //       debugShowCheckedModeBanner: false,
// //       theme: ThemeData(
// //         primarySwatch: Colors.blue,
// //         primaryColor: const Color(0xFF42A5F5),
// //         scaffoldBackgroundColor: const Color(0xFFF5F5F5),
// //         appBarTheme: const AppBarTheme(
// //           elevation: 0,
// //           backgroundColor: Colors.white,
// //           iconTheme: IconThemeData(color: Colors.black),
// //           titleTextStyle: TextStyle(
// //             color: Colors.black,
// //             fontSize: 20,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         // cardTheme: CardTheme(
// //         //   elevation: 2,
// //         //   shape: RoundedRectangleBorder(
// //         //     borderRadius: BorderRadius.circular(12),
// //         //   ),
// //         //   color: Colors.white,
// //         // ),
// //       ),
// //       home: const MainScreen(),
// //     );
// //   }
// // }