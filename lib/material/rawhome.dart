import 'package:dimple_erp/material/GoodPurchaseScreen.dart';
import 'package:dimple_erp/material/PurchaseOrderScreen.dart';
import 'package:dimple_erp/material/StockPurchaseScreen.dart';
import 'package:dimple_erp/material/rawmaterial.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // Light Green
              Color(0xFFF1F8E9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppBar(
                  title: const Text(
                    'Raw Material Management',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: const Color(0xFF2E7D32),
                  centerTitle: true,
                ),
              ),

              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView(
                    children: const [
                      SizedBox(height: 32),
                      _MenuCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'HWC',
                        subtitle: 'Raw Material Inventory',
                        color: Color(0xFF4CAF50),
                        route: RawMaterialScreen(),
                      ),
                      SizedBox(height: 20),
                      _MenuCard(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Purchase Order',
                        subtitle: 'Create & Track Orders',
                        color: Color(0xFF2196F3),
                        route: PurchaseOrderScreen(),
                      ),
                      SizedBox(height: 20),
                      _MenuCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Good Purchase Number',
                        subtitle: 'Manage Purchase Entries',
                        color: Color(0xFFFF9800),
                        route: GoodPurchaseScreen(),
                      ),
                      SizedBox(height: 20),
                      _MenuCard(
                        icon: Icons.storage_outlined,
                        title: 'Stock Purchase',
                        subtitle: 'Stock Inward & Reports',
                        color: Color(0xFF9C27B0),
                        route: StockPurchaseScreen(),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PREMIUM GLASS CARD WITH HOVER & ANIMATION
// ============================================================
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget route;

  const _MenuCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => route)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.95),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon with Background
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}