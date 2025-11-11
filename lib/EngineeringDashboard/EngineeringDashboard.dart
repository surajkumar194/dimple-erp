import 'package:dimple_erp/EngineeringDashboard/ChangeRequestsScreen.dart';
import 'package:dimple_erp/EngineeringDashboard/DesignFilesScreen.dart' show DesignFilesScreen;
import 'package:dimple_erp/EngineeringDashboard/ProductSpecificationsScreen.dart';
import 'package:dimple_erp/EngineeringDashboard/TechnicalDrawingsScreen.dart';
import 'package:flutter/material.dart';
// import 'product_specifications_screen.dart';
// import 'design_files_screen.dart';
// import 'technical_drawings_screen.dart';
// import 'change_requests_screen.dart';

class EngineeringDashboard extends StatelessWidget {
  const EngineeringDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildSubcategoryItem(
            context,
            'Product Specifications',
            Icons.description,
            const Color(0xFF00BCD4),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductSpecificationsScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Design Files',
            Icons.folder_open,
            const Color(0xFF00BCD4),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DesignFilesScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Technical Drawings',
            Icons.architecture,
            const Color(0xFF00BCD4),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TechnicalDrawingsScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Change Requests',
            Icons.edit_note,
            const Color(0xFF00BCD4),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangeRequestsScreen()),
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