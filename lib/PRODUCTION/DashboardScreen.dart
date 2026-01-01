import 'package:dimple_erp/PRODUCTION/ProductionDashobard.dart';
import 'package:dimple_erp/PRODUCTION/MachineFormScreen.dart';
import 'package:dimple_erp/PRODUCTION/allprodctiondata.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ProductionDashboard extends StatelessWidget {
  const ProductionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Production Dashboard ⚙️",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Monitor machines, efficiency & output in real-time",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Image.asset("assets/dpl.png", scale: 3.5),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Dashboard Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 1200
                    ? 4
                    : constraints.maxWidth > 800
                        ? 3
                        : 2;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.0,
                  children: [
                    _buildDashboardCard(
                      context,
                      title: "Production",
                      subtitle: "machine performance & efficiency",
                      icon: Icons.precision_manufacturing,
                      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UltraFlowProductionDashboard(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "Machine production",
                      subtitle: "Add or configure machines & operators",
                      icon: Icons.settings_suggest,
                      gradientColors: [Colors.cyan[700]!, Colors.cyan[500]!],
                      onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductionScreen()));
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "ALL production Data",
                      subtitle: "Manage production jobs & scheduling",
                      icon: Icons.assignment_turned_in,
                      gradientColors: [Colors.deepOrange[600]!, Colors.deepOrange[400]!],
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProductionScreen()));
                      },
                    ),
                    // _buildDashboardCard(
                    //   context,
                    //   title: "Production Report",
                    //   subtitle: "Daily, weekly & monthly analytics",
                    //   icon: Icons.bar_chart,
                    //   gradientColors: [Colors.green[700]!, Colors.green[500]!],
                    //   onTap: () {
                    //     // Navigate to reports screen
                    //   },
                    // ),
                    // _buildDashboardCard(
                    //   context,
                    //   title: "Issue Inventory",
                    //   subtitle: "Issue raw materials to production",
                    //   icon: Icons.inventory_2,
                    //   gradientColors: [Colors.pink[600]!, Colors.pink[400]!],
                    //   onTap: () {
                    //     // Navigator.push(context, MaterialPageRoute(builder: (_) => IssueInventoryScreen()));
                    //   },
                    // ),
                    // _buildDashboardCard(
                    //   context,
                    //   title: "OEE Tracking",
                    //   subtitle: "Overall Equipment Effectiveness",
                    //   icon: Icons.speed,
                    //   gradientColors: [Colors.purple[700]!, Colors.purple[500]!],
                    //   onTap: () {
                    //     // Navigate to OEE screen
                    //   },
                    // ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shadowColor: gradientColors.first.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 40, color: Colors.white),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}