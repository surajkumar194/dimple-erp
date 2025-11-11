import 'package:dimple_erp/operation/DailyProductionScreen.dart';
import 'package:dimple_erp/operation/DowntimeTrackingScreen.dart';
import 'package:dimple_erp/operation/MachineMaintenanceScreen.dart';
import 'package:dimple_erp/operation/ShiftManagementScreen.dart';
import 'package:flutter/material.dart';
// import 'daily_production_screen.dart';
// import 'shift_management_screen.dart';
// import 'machine_maintenance_screen.dart';
// import 'downtime_tracking_screen.dart';

class OperationDashboard extends StatelessWidget {
  const OperationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildSubcategoryItem(
            context,
            'Daily Production Log',
            Icons.article,
            const Color(0xFF2196F3),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DailyProductionScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Shift Management',
            Icons.schedule,
            const Color(0xFF2196F3),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShiftManagementScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Machine Maintenance',
            Icons.build,
            const Color(0xFF2196F3),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MachineMaintenanceScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Downtime Tracking',
            Icons.warning_amber,
            const Color(0xFF2196F3),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DowntimeTrackingScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(Icons.arrow_forward_ios, color: color, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: Icon(icon, color: color, size: 24),
        onTap: onTap,
      ),
    );
  }
}