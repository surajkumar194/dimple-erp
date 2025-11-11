import 'package:dimple_erp/QCQADashboard/ComplianceScreen.dart';
import 'package:dimple_erp/QCQADashboard/DefectTrackingScreen.dart';
import 'package:dimple_erp/QCQADashboard/QualityInspectionScreen.dart';
import 'package:dimple_erp/QCQADashboard/TestReportsScreen.dart';
import 'package:flutter/material.dart';


class QCQADashboard extends StatelessWidget {
  const QCQADashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildSubcategoryItem(
            context,
            'Quality Inspection',
            Icons.verified,
            const Color(0xFF9C27B0),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QualityInspectionScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Defect Tracking',
            Icons.bug_report,
            const Color(0xFF9C27B0),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DefectTrackingScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Test Reports',
            Icons.assessment,
            const Color(0xFF9C27B0),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestReportsScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Compliance Records',
            Icons.gavel,
            const Color(0xFF9C27B0),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ComplianceScreen()),
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