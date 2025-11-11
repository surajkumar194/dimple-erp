// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';


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
//       'Order Booking',
//       'Quotation & Pricing',
//       'Customer CRM Database',
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
//   'PPC',
//   'Material',
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
//         return base
//             .where(
//               (m) =>
//                   m.header.contains('Logistics') ||
//                   m.header.contains('Production'),
//             )
//             .toList();
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

//   Widget _getSubcategoryScreen(String subcategoryName, String moduleHeader, Color color, IconData icon) {
//   return switch (subcategoryName) {
//     'Printing Job Scheduling' => PrintingJobSchedulingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Die Cutting / Folding' => DieCuttingFoldingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Lamination & Finishing' => Lamination&FinishingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Work in Progress (WIP) Tracking' => WorkInProgressWipTrackingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Machine Utilization & Downtime' => MachineUtilization&DowntimeScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Raw Material Inventory (Paper/Board)' => RawMaterialInventoryPaperBoardScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Packaging Consumables Tracking' => PackagingConsumablesTrackingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Batch / Lot Number Management' => BatchLotNumberManagementScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Barcode Integration' => BarcodeIntegrationScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Reorder Alerts & Safety Stock' => ReorderAlerts&SafetyStockScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Supplier Database' => SupplierDatabaseScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Purchase Order Management' => PurchaseOrderManagementScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Material Sourcing' => MaterialSourcingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Vendor Invoice & Payments' => VendorInvoice&PaymentsScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Quality Check on Incoming Material' => QualityCheckOnIncomingMaterialScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Stage-Wise Quality Inspection' => Stage-wiseQualityInspectionScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Defect / Rejection Records' => DefectRejectionRecordsScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Batch Traceability' => BatchTraceabilityScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Compliance & ISO Reports' => Compliance&IsoReportsScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Order Booking' => OrderBookingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Quotation & Pricing' => Quotation&PricingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Customer CRM Database' => CustomerCrmDatabaseScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Delivery Scheduling' => DeliverySchedulingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Dispatch Planning' => DispatchPlanningScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Transport & Fleet Management' => Transport&FleetManagementScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Real-Time Shipment Tracking' => Real-timeShipmentTrackingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Delivery Proof (POD)' => DeliveryProofPodScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'General Ledger' => GeneralLedgerScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Job Costing & Profitability' => JobCosting&ProfitabilityScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Accounts Payable / Receivable' => AccountsPayableReceivableScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'GST / Tax Compliance' => GstTaxComplianceScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Employee Records' => EmployeeRecordsScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Attendance & Shifts' => Attendance&ShiftsScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Payroll & Salary Processing' => Payroll&SalaryProcessingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Machine Maintenance Scheduling' => MachineMaintenanceSchedulingScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Breakdown & Repair Records' => Breakdown&RepairRecordsScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Spare Parts Inventory' => SparePartsInventoryScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     'Preventive Maintenance Alerts' => PreventiveMaintenanceAlertsScreen(moduleHeader: moduleHeader, color: color, icon: icon),
//     _ => const SizedBox(), // fallback
//   };
// }

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
//             Center(
//               child: const Text(
//                 'Dimple Packaging ERP',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
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
//                   prefixIcon: const Icon(
//                     Icons.search,
//                     color: Color(0xFF1EA7E1),
//                   ),
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
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 1,
//                     vertical: 14,
//                   ),
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
//           ),
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
//                     fontSize: 10, // ← requested size
//                     fontWeight: widget.isActive
//                         ? FontWeight.w700
//                         : FontWeight.w600,
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

// class _SubcategoryItem extends StatefulWidget {
//   final String title;
//   final Color color;
//   final IconData icon;
//   final VoidCallback onTap;

//   const _SubcategoryItem({
//     required this.title,
//     required this.color,
//     required this.icon,
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
//               Icon(Icons.open_in_new, size: 16, color: widget.color),
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
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//         subtitle: Text(subtitle),
//       ),
//     );
//   }
// }

// class PrintingJobSchedulingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const PrintingJobSchedulingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Printing Job Scheduling'),
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
//                               const Text(
//                                 'Printing Job Scheduling',
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
//                         content: Text('Create New in Printing Job Scheduling'),
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
//                         content: Text('View All Printing Job Scheduling'),
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
//                         content: Text('View Printing Job Scheduling Reports'),
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
//                         content: Text('Printing Job Scheduling Settings'),
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

// class DieCuttingFoldingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const DieCuttingFoldingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Die Cutting / Folding'),
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
//                               const Text(
//                                 'Die Cutting / Folding',
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
//                         content: Text('Create New in Die Cutting / Folding'),
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
//                         content: Text('View All Die Cutting / Folding'),
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
//                         content: Text('View Die Cutting / Folding Reports'),
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
//                         content: Text('Die Cutting / Folding Settings'),
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

// class Lamination&FinishingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const Lamination&FinishingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Lamination & Finishing'),
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
//                               const Text(
//                                 'Lamination & Finishing',
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
//                         content: Text('Create New in Lamination & Finishing'),
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
//                         content: Text('View All Lamination & Finishing'),
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
//                         content: Text('View Lamination & Finishing Reports'),
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
//                         content: Text('Lamination & Finishing Settings'),
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

// class WorkInProgressWipTrackingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const WorkInProgressWipTrackingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Work in Progress (WIP) Tracking'),
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
//                               const Text(
//                                 'Work in Progress (WIP) Tracking',
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
//                         content: Text('Create New in Work in Progress (WIP) Tracking'),
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
//                         content: Text('View All Work in Progress (WIP) Tracking'),
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
//                         content: Text('View Work in Progress (WIP) Tracking Reports'),
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
//                         content: Text('Work in Progress (WIP) Tracking Settings'),
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

// class MachineUtilization&DowntimeScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const MachineUtilization&DowntimeScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Machine Utilization & Downtime'),
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
//                               const Text(
//                                 'Machine Utilization & Downtime',
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
//                         content: Text('Create New in Machine Utilization & Downtime'),
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
//                         content: Text('View All Machine Utilization & Downtime'),
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
//                         content: Text('View Machine Utilization & Downtime Reports'),
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
//                         content: Text('Machine Utilization & Downtime Settings'),
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

// class RawMaterialInventoryPaperBoardScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const RawMaterialInventoryPaperBoardScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Raw Material Inventory (Paper/Board)'),
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
//                               const Text(
//                                 'Raw Material Inventory (Paper/Board)',
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
//                         content: Text('Create New in Raw Material Inventory (Paper/Board)'),
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
//                         content: Text('View All Raw Material Inventory (Paper/Board)'),
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
//                         content: Text('View Raw Material Inventory (Paper/Board) Reports'),
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
//                         content: Text('Raw Material Inventory (Paper/Board) Settings'),
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

// class PackagingConsumablesTrackingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const PackagingConsumablesTrackingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Packaging Consumables Tracking'),
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
//                               const Text(
//                                 'Packaging Consumables Tracking',
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
//                         content: Text('Create New in Packaging Consumables Tracking'),
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
//                         content: Text('View All Packaging Consumables Tracking'),
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
//                         content: Text('View Packaging Consumables Tracking Reports'),
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
//                         content: Text('Packaging Consumables Tracking Settings'),
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

// class BatchLotNumberManagementScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const BatchLotNumberManagementScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Batch / Lot Number Management'),
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
//                               const Text(
//                                 'Batch / Lot Number Management',
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
//                         content: Text('Create New in Batch / Lot Number Management'),
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
//                         content: Text('View All Batch / Lot Number Management'),
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
//                         content: Text('View Batch / Lot Number Management Reports'),
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
//                         content: Text('Batch / Lot Number Management Settings'),
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

// class BarcodeIntegrationScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const BarcodeIntegrationScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Barcode Integration'),
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
//                               const Text(
//                                 'Barcode Integration',
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
//                         content: Text('Create New in Barcode Integration'),
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
//                         content: Text('View All Barcode Integration'),
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
//                         content: Text('View Barcode Integration Reports'),
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
//                         content: Text('Barcode Integration Settings'),
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

// class ReorderAlerts&SafetyStockScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const ReorderAlerts&SafetyStockScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Reorder Alerts & Safety Stock'),
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
//                               const Text(
//                                 'Reorder Alerts & Safety Stock',
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
//                         content: Text('Create New in Reorder Alerts & Safety Stock'),
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
//                         content: Text('View All Reorder Alerts & Safety Stock'),
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
//                         content: Text('View Reorder Alerts & Safety Stock Reports'),
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
//                         content: Text('Reorder Alerts & Safety Stock Settings'),
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

// class SupplierDatabaseScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const SupplierDatabaseScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Supplier Database'),
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
//                               const Text(
//                                 'Supplier Database',
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
//                         content: Text('Create New in Supplier Database'),
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
//                         content: Text('View All Supplier Database'),
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
//                         content: Text('View Supplier Database Reports'),
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
//                         content: Text('Supplier Database Settings'),
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

// class PurchaseOrderManagementScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const PurchaseOrderManagementScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Purchase Order Management'),
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
//                               const Text(
//                                 'Purchase Order Management',
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
//                         content: Text('Create New in Purchase Order Management'),
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
//                         content: Text('View All Purchase Order Management'),
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
//                         content: Text('View Purchase Order Management Reports'),
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
//                         content: Text('Purchase Order Management Settings'),
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

// class MaterialSourcingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const MaterialSourcingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Material Sourcing'),
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
//                               const Text(
//                                 'Material Sourcing',
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
//                         content: Text('Create New in Material Sourcing'),
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
//                         content: Text('View All Material Sourcing'),
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
//                         content: Text('View Material Sourcing Reports'),
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
//                         content: Text('Material Sourcing Settings'),
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

// class VendorInvoice&PaymentsScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const VendorInvoice&PaymentsScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Vendor Invoice & Payments'),
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
//                               const Text(
//                                 'Vendor Invoice & Payments',
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
//                         content: Text('Create New in Vendor Invoice & Payments'),
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
//                         content: Text('View All Vendor Invoice & Payments'),
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
//                         content: Text('View Vendor Invoice & Payments Reports'),
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
//                         content: Text('Vendor Invoice & Payments Settings'),
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

// class QualityCheckOnIncomingMaterialScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const QualityCheckOnIncomingMaterialScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Quality Check on Incoming Material'),
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
//                               const Text(
//                                 'Quality Check on Incoming Material',
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
//                         content: Text('Create New in Quality Check on Incoming Material'),
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
//                         content: Text('View All Quality Check on Incoming Material'),
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
//                         content: Text('View Quality Check on Incoming Material Reports'),
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
//                         content: Text('Quality Check on Incoming Material Settings'),
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

// class Stage-wiseQualityInspectionScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const Stage-wiseQualityInspectionScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Stage-Wise Quality Inspection'),
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
//                               const Text(
//                                 'Stage-Wise Quality Inspection',
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
//                         content: Text('Create New in Stage-Wise Quality Inspection'),
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
//                         content: Text('View All Stage-Wise Quality Inspection'),
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
//                         content: Text('View Stage-Wise Quality Inspection Reports'),
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
//                         content: Text('Stage-Wise Quality Inspection Settings'),
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

// class DefectRejectionRecordsScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const DefectRejectionRecordsScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Defect / Rejection Records'),
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
//                               const Text(
//                                 'Defect / Rejection Records',
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
//                         content: Text('Create New in Defect / Rejection Records'),
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
//                         content: Text('View All Defect / Rejection Records'),
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
//                         content: Text('View Defect / Rejection Records Reports'),
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
//                         content: Text('Defect / Rejection Records Settings'),
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

// class BatchTraceabilityScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const BatchTraceabilityScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Batch Traceability'),
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
//                               const Text(
//                                 'Batch Traceability',
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
//                         content: Text('Create New in Batch Traceability'),
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
//                         content: Text('View All Batch Traceability'),
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
//                         content: Text('View Batch Traceability Reports'),
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
//                         content: Text('Batch Traceability Settings'),
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

// class Compliance&IsoReportsScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const Compliance&IsoReportsScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Compliance & ISO Reports'),
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
//                               const Text(
//                                 'Compliance & ISO Reports',
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
//                         content: Text('Create New in Compliance & ISO Reports'),
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
//                         content: Text('View All Compliance & ISO Reports'),
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
//                         content: Text('View Compliance & ISO Reports Reports'),
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
//                         content: Text('Compliance & ISO Reports Settings'),
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

// class OrderBookingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const OrderBookingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Order Booking'),
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
//                               const Text(
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
//                         content: Text('Create New in Order Booking'),
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
//                         content: Text('View All Order Booking'),
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
//                         content: Text('View Order Booking Reports'),
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
//                         content: Text('Order Booking Settings'),
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

// class Quotation&PricingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const Quotation&PricingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Quotation & Pricing'),
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
//                               const Text(
//                                 'Quotation & Pricing',
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
//                         content: Text('Create New in Quotation & Pricing'),
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
//                         content: Text('View All Quotation & Pricing'),
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
//                         content: Text('View Quotation & Pricing Reports'),
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
//                         content: Text('Quotation & Pricing Settings'),
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

// class CustomerCrmDatabaseScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const CustomerCrmDatabaseScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Customer CRM Database'),
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
//                               const Text(
//                                 'Customer CRM Database',
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
//                         content: Text('Create New in Customer CRM Database'),
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
//                         content: Text('View All Customer CRM Database'),
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
//                         content: Text('View Customer CRM Database Reports'),
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
//                         content: Text('Customer CRM Database Settings'),
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

// class DeliverySchedulingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const DeliverySchedulingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Delivery Scheduling'),
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
//                               const Text(
//                                 'Delivery Scheduling',
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
//                         content: Text('Create New in Delivery Scheduling'),
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
//                         content: Text('View All Delivery Scheduling'),
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
//                         content: Text('View Delivery Scheduling Reports'),
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
//                         content: Text('Delivery Scheduling Settings'),
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

// class DispatchPlanningScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const DispatchPlanningScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Dispatch Planning'),
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
//                               const Text(
//                                 'Dispatch Planning',
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
//                         content: Text('Create New in Dispatch Planning'),
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
//                         content: Text('View All Dispatch Planning'),
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
//                         content: Text('View Dispatch Planning Reports'),
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
//                         content: Text('Dispatch Planning Settings'),
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

// class Transport&FleetManagementScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const Transport&FleetManagementScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Transport & Fleet Management'),
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
//                               const Text(
//                                 'Transport & Fleet Management',
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
//                         content: Text('Create New in Transport & Fleet Management'),
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
//                         content: Text('View All Transport & Fleet Management'),
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
//                         content: Text('View Transport & Fleet Management Reports'),
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
//                         content: Text('Transport & Fleet Management Settings'),
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

// class Real-timeShipmentTrackingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const Real-timeShipmentTrackingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Real-Time Shipment Tracking'),
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
//                               const Text(
//                                 'Real-Time Shipment Tracking',
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
//                         content: Text('Create New in Real-Time Shipment Tracking'),
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
//                         content: Text('View All Real-Time Shipment Tracking'),
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
//                         content: Text('View Real-Time Shipment Tracking Reports'),
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
//                         content: Text('Real-Time Shipment Tracking Settings'),
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

// class DeliveryProofPodScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const DeliveryProofPodScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Delivery Proof (POD)'),
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
//                               const Text(
//                                 'Delivery Proof (POD)',
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
//                         content: Text('Create New in Delivery Proof (POD)'),
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
//                         content: Text('View All Delivery Proof (POD)'),
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
//                         content: Text('View Delivery Proof (POD) Reports'),
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
//                         content: Text('Delivery Proof (POD) Settings'),
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

// class GeneralLedgerScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const GeneralLedgerScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('General Ledger'),
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
//                               const Text(
//                                 'General Ledger',
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
//                         content: Text('Create New in General Ledger'),
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
//                         content: Text('View All General Ledger'),
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
//                         content: Text('View General Ledger Reports'),
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
//                         content: Text('General Ledger Settings'),
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

// class JobCosting&ProfitabilityScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const JobCosting&ProfitabilityScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Job Costing & Profitability'),
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
//                               const Text(
//                                 'Job Costing & Profitability',
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
//                         content: Text('Create New in Job Costing & Profitability'),
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
//                         content: Text('View All Job Costing & Profitability'),
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
//                         content: Text('View Job Costing & Profitability Reports'),
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
//                         content: Text('Job Costing & Profitability Settings'),
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

// class AccountsPayableReceivableScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const AccountsPayableReceivableScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Accounts Payable / Receivable'),
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
//                               const Text(
//                                 'Accounts Payable / Receivable',
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
//                         content: Text('Create New in Accounts Payable / Receivable'),
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
//                         content: Text('View All Accounts Payable / Receivable'),
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
//                         content: Text('View Accounts Payable / Receivable Reports'),
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
//                         content: Text('Accounts Payable / Receivable Settings'),
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

// class GstTaxComplianceScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const GstTaxComplianceScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('GST / Tax Compliance'),
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
//                               const Text(
//                                 'GST / Tax Compliance',
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
//                         content: Text('Create New in GST / Tax Compliance'),
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
//                         content: Text('View All GST / Tax Compliance'),
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
//                         content: Text('View GST / Tax Compliance Reports'),
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
//                         content: Text('GST / Tax Compliance Settings'),
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

// class EmployeeRecordsScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const EmployeeRecordsScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Employee Records'),
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
//                               const Text(
//                                 'Employee Records',
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
//                         content: Text('Create New in Employee Records'),
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
//                         content: Text('View All Employee Records'),
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
//                         content: Text('View Employee Records Reports'),
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
//                         content: Text('Employee Records Settings'),
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

// class Attendance&ShiftsScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const Attendance&ShiftsScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Attendance & Shifts'),
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
//                               const Text(
//                                 'Attendance & Shifts',
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
//                         content: Text('Create New in Attendance & Shifts'),
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
//                         content: Text('View All Attendance & Shifts'),
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
//                         content: Text('View Attendance & Shifts Reports'),
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
//                         content: Text('Attendance & Shifts Settings'),
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

// class Payroll&SalaryProcessingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const Payroll&SalaryProcessingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Payroll & Salary Processing'),
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
//                               const Text(
//                                 'Payroll & Salary Processing',
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
//                         content: Text('Create New in Payroll & Salary Processing'),
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
//                         content: Text('View All Payroll & Salary Processing'),
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
//                         content: Text('View Payroll & Salary Processing Reports'),
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
//                         content: Text('Payroll & Salary Processing Settings'),
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

// class MachineMaintenanceSchedulingScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const MachineMaintenanceSchedulingScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Machine Maintenance Scheduling'),
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
//                               const Text(
//                                 'Machine Maintenance Scheduling',
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
//                         content: Text('Create New in Machine Maintenance Scheduling'),
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
//                         content: Text('View All Machine Maintenance Scheduling'),
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
//                         content: Text('View Machine Maintenance Scheduling Reports'),
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
//                         content: Text('Machine Maintenance Scheduling Settings'),
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

// class Breakdown&RepairRecordsScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const Breakdown&RepairRecordsScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Breakdown & Repair Records'),
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
//                               const Text(
//                                 'Breakdown & Repair Records',
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
//                         content: Text('Create New in Breakdown & Repair Records'),
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
//                         content: Text('View All Breakdown & Repair Records'),
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
//                         content: Text('View Breakdown & Repair Records Reports'),
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
//                         content: Text('Breakdown & Repair Records Settings'),
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

// class SparePartsInventoryScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const SparePartsInventoryScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Spare Parts Inventory'),
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
//                               const Text(
//                                 'Spare Parts Inventory',
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
//                         content: Text('Create New in Spare Parts Inventory'),
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
//                         content: Text('View All Spare Parts Inventory'),
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
//                         content: Text('View Spare Parts Inventory Reports'),
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
//                         content: Text('Spare Parts Inventory Settings'),
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

// class PreventiveMaintenanceAlertsScreen extends StatelessWidget {
//   final String moduleHeader;
//   final Color color;
//   final IconData icon;

//   const PreventiveMaintenanceAlertsScreen({
//     super.key,
//     required this.moduleHeader,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FB),
//       appBar: AppBar(
//         title: const Text('Preventive Maintenance Alerts'),
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
//                               const Text(
//                                 'Preventive Maintenance Alerts',
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
//                         content: Text('Create New in Preventive Maintenance Alerts'),
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
//                         content: Text('View All Preventive Maintenance Alerts'),
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
//                         content: Text('View Preventive Maintenance Alerts Reports'),
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
//                         content: Text('Preventive Maintenance Alerts Settings'),
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