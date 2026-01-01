import 'package:dimple_erp/all%20screen/CustomerAllOrderScreen.dart';
import 'package:dimple_erp/all%20screen/DeliverySchedulingScreen.dart';
import 'package:dimple_erp/PRODUCTION/MachineFormScreen.dart';
import 'package:dimple_erp/all%20screen/OrderBookingScreen.dart';
import 'package:dimple_erp/all%20screen/JobCardScreen.dart';
import 'package:dimple_erp/all%20screen/IssueInventoryScreen.dart'; // 👈 new import
import 'package:dimple_erp/all%20screen/ProductionTrackingScreen.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

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
                  colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withOpacity(0.3),
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
                        "Sales Dashboard 👋",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Manage all orders and delivery efficiently",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Image.asset("assets/dpl.png", scale: 3.5),

                  // Container(
                  //   padding: const EdgeInsets.all(20),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white.withOpacity(0.2),
                  //     shape: BoxShape.circle,
                  //   ),
                  //   child:
                  //       const Icon(Icons.trending_up, color: Colors.white, size: 40),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Dashboard cards grid
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
                      title: "Tracking",
                      subtitle: "Monitor and manage deliveries efficiently",
                      icon: Icons.auto_graph_sharp,
                      gradientColors: [
                        const Color.fromARGB(255, 231, 121, 104)!,
                        const Color.fromARGB(255, 231, 121, 104)!,
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductionTrackingScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "Order Booking",
                      subtitle: "Create and manage new orders",
                      icon: Icons.book_online,
                      gradientColors: [
                        Colors.indigo[600]!,
                        Colors.indigo[400]!,
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderBookingScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "Customer All Orders",
                      subtitle: "View and track customer orders",
                      icon: Icons.list_alt,
                      gradientColors: [Colors.teal[600]!, Colors.teal[400]!],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomerAllOrderScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "Job Card",
                      subtitle: "Create and manage production job cards",
                      icon: Icons.assignment,
                      gradientColors: [
                        Colors.deepPurple[600]!,
                        Colors.deepPurple[400]!,
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JobCardScreen(),
                          ),
                        );
                      },
                    ),

                    // ✅ New Added Card — Issue Inventory
                    _buildDashboardCard(
                      context,
                      title: "Issue Inventory",
                      subtitle: "Fetch JDF data and manage stock issue",
                      icon: Icons.inventory_2_outlined,
                      gradientColors: [Colors.pink[600]!, Colors.pink[400]!],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IssueInventoryScreen(),
                          ),
                        );
                      },
                    ),

                    _buildDashboardCard(
                      context,
                      title: "Delivery Scheduling",
                      subtitle: "Plan and manage deliveries",
                      icon: Icons.local_shipping,
                      gradientColors: [
                        Colors.orange[600]!,
                        Colors.orange[400]!,
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeliveryManagementScreen(),
                          ),
                        );
                      },
                    ),

                    // _buildDashboardCard(
                    //   context,
                    //   title: "Production",
                    //   subtitle: "Plan and manage production",
                    //   icon: Icons.local_shipping,
                    //   gradientColors: [
                    //     Colors.orange[600]!,
                    //     Colors.orange[400]!,
                    //   ],
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const MachineProductionScreen(),
                    //       ),
                    //     );
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
