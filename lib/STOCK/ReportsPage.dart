import 'package:dimple_erp/STOCK/CurrentStockReport.dart';
import 'package:dimple_erp/STOCK/LowStockReport.dart';
import 'package:dimple_erp/STOCK/ProductReport.dart';
import 'package:dimple_erp/STOCK/StockMovementReport%20.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Reports Dashboard',
          style: TextStyle(
            fontSize: isWeb ? 24 : 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: isWeb ? 80 : 56,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF1F5F9),
              const Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 40 : 16,
            vertical: isWeb ? 32 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                margin: EdgeInsets.only(bottom: isWeb ? 32 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Reports',
                      style: TextStyle(
                        fontSize: isWeb ? 32 : 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Monitor your inventory and business performance with comprehensive reports',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Reports Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount;
                  double childAspectRatio;
                  
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 4;
                    childAspectRatio = 0.85;
                  } else if (constraints.maxWidth > 800) {
                    crossAxisCount = 3;
                    childAspectRatio = 0.9;
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 2;
                    childAspectRatio = 1.0;
                  } else {
                    crossAxisCount = 1;
                    childAspectRatio = 1.2;
                  }
                  
                  return GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: isWeb ? 24 : 16,
                    mainAxisSpacing: isWeb ? 24 : 16,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _buildReportCard(
                        'Current Stock',
                        Icons.inventory_2_outlined,
                        const Color(0xFF3B82F6),
                        const Color(0xFFEFF6FF),
                        'Monitor real-time inventory levels and stock availability',
                        '245 Items',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => CurrentStockReport())),
                        isWeb,
                      ),
                      _buildReportCard(
                        'Stock Movement',
                        Icons.trending_up_outlined,
                        const Color(0xFF10B981),
                        const Color(0xFFECFDF5),
                        'Track all stock transactions and movement history',
                        '89 Transactions',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockMovementReport())),
                        isWeb,
                      ),
                      _buildReportCard(
                        'Low Stock Alert',
                        Icons.warning_amber_outlined,
                        const Color(0xFFF59E0B),
                        const Color(0xFFFEF3C7),
                        'View items running low and need restocking',
                        '12 Items',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => LowStockReport())),
                        isWeb,
                      ),
                      _buildReportCard(
                        'Product Report',
                        Icons.assessment_outlined,
                        const Color(0xFF8B5CF6),
                        const Color(0xFFF3E8FF),
                        'Complete product analysis and performance metrics',
                        '156 Products',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductReport())),
                        isWeb,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    IconData icon,
    Color primaryColor,
    Color backgroundColor,
    String description,
    String stats,
    VoidCallback onTap,
    bool isWeb,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          child: Card(
            elevation: 2,
            shadowColor: primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
            ),
            child: Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isWeb ? 12 : 10),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: isWeb ? 28 : 24,
                          color: primaryColor,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          stats,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isWeb ? 20 : 16),
                  
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isWeb ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.25,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Description
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                      maxLines: isWeb ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  SizedBox(height: isWeb ? 16 : 12),
                  
                  // Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'View Report',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}