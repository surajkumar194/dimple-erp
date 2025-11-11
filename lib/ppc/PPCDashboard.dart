import 'package:dimple_erp/ppc/CapacityPlanningScreen.dart';
import 'package:dimple_erp/ppc/MachineScheduleScreen%20.dart';
import 'package:dimple_erp/ppc/ProductionPlanScreen.dart';
import 'package:dimple_erp/ppc/WorkOrderScreen.dart';
import 'package:flutter/material.dart';


class PPCDashboard extends StatelessWidget {
  const PPCDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildSubcategoryItem(
            context,
            'Production Planning',
            Icons.factory,
            const Color(0xFFFF9800),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductionPlanScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Machine Scheduling',
            Icons.precision_manufacturing,
            const Color(0xFFFF9800),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MachineScheduleScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Work Orders',
            Icons.assignment,
            const Color(0xFFFF9800),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  WorkOrderScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Capacity Planning',
            Icons.analytics,
            const Color(0xFFFF9800),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CapacityPlanningScreen()),
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