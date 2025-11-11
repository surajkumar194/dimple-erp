// import 'package:dimple_erp/main.dart';
// import 'package:flutter/material.dart';

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