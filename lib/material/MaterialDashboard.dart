import 'package:dimple_erp/material/PurchaseOrderScreen.dart';
import 'package:dimple_erp/material/StockTrackingScreen.dart';
import 'package:dimple_erp/material/SupplierManagementScreen.dart';
import 'package:dimple_erp/material/rawhome.dart';
import 'package:flutter/material.dart';


class MaterialDashboard extends StatelessWidget {
  const MaterialDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildSubcategoryItem(
            context,
            'Raw Material',
            Icons.inventory,
            const Color(0xFF4CAF50),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Purchase Orders',
            Icons.shopping_bag,
            const Color(0xFF4CAF50),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseOrderScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Supplier Management',
            Icons.business_center,
            const Color(0xFF4CAF50),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplierManagementScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Stock Tracking',
            Icons.trending_up,
            const Color(0xFF4CAF50),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StockTrackingScreen()),
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
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(icon, color: color, size: 24),
        onTap: onTap,
      ),
    );
  }
}