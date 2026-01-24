import 'package:dimple_erp/all screen/CustomerAllOrderScreen.dart';
import 'package:dimple_erp/all screen/DeliverySchedulingScreen.dart';
import 'package:dimple_erp/all screen/OrderBookingScreen.dart';
import 'package:dimple_erp/all screen/JobCardScreen.dart';
import 'package:dimple_erp/all screen/IssueInventoryScreen.dart';
import 'package:dimple_erp/all screen/ProductionTrackingScreen.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 32),

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
                  childAspectRatio: 1,
                  children: [
                    _dashboardCard(
                      title: "Tracking",
                      subtitle: "Monitor production & delivery status",
                      icon: Icons.auto_graph,
                      gradient: [Colors.red[400]!, Colors.red[300]!],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductionTrackingScreen(),
                          ),
                        );
                      },
                    ),
                    _dashboardCard(
                      title: "Order Booking",
                      subtitle: "Create and manage orders",
                      icon: Icons.book_online,
                      gradient: [Colors.indigo[600]!, Colors.indigo[400]!],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderBookingScreen(),
                          ),
                        );
                      },
                    ),
                    _dashboardCard(
                      title: "Customer Orders",
                      subtitle: "View all customer orders",
                      icon: Icons.list_alt,
                      gradient: [Colors.teal[600]!, Colors.teal[400]!],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomerAllOrderScreen(),
                          ),
                        );
                      },
                    ),
                    _dashboardCard(
                      title: "Job Card",
                      subtitle: "Manage production job cards",
                      icon: Icons.assignment,
                      gradient: [
                        Colors.deepPurple[600]!,
                        Colors.deepPurple[400]!
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
                    _dashboardCard(
                      title: "Issue Inventory",
                      subtitle: "Issue raw material from stock",
                      icon: Icons.inventory_2_outlined,
                      gradient: [Colors.pink[600]!, Colors.pink[400]!],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IssueInventoryScreen(),
                          ),
                        );
                      },
                    ),
//                     _dashboardCard(
//   title: "MIGRATE ORDERS",
//   subtitle: "Run once only (DPL numbering)",
//   icon: Icons.warning_amber,
//   gradient: [Colors.black, Colors.grey],
//   onTap: () async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Run Migration?'),
//         content: const Text(
//           '⚠️ This should be run ONLY ONCE.\nDo you want to continue?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('RUN'),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       await migrateOldOrdersToDPL(context);
//     }
//   },
// ),

                    _dashboardCard(
                      title: "Delivery Schedule",
                      subtitle: "Plan & manage deliveries",
                      icon: Icons.local_shipping,
                      gradient: [Colors.orange[600]!, Colors.orange[400]!],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DeliveryManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink[700]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Sales Dashboard 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Manage orders, production & delivery",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Image.asset("assets/dpl.png", scale: 3.5),
        ],
      ),
    );
  }

  // ================= DASHBOARD CARD =================
  Widget _dashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22.sp, color: Colors.white),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style:
                        TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 15.sp,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.arrow_forward,
                      size: 17.sp,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
