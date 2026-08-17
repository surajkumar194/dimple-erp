import 'package:dimple_erp/all screen/OrderBookingScreen.dart';
import 'package:dimple_erp/all%20screen/BackupManagerScreen.dart';
import 'package:dimple_erp/all%20screen/DesignerScreen.dart';
import 'package:dimple_erp/challan/DispatchFullPage.dart';
import 'package:dimple_erp/all%20screen/JobCardHistoryTab.dart'show JobCardHistoryTab;
import 'package:dimple_erp/all%20screen/MasterProductEntryScreen.dart';
import 'package:dimple_erp/all%20screen/SelectSalesOrderTab.dart';
import 'package:dimple_erp/all%20screen/ViewSalesOrderPdfTab.dart';
import 'package:dimple_erp/extra.dart/PaymentCollectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 30),

            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount;
                double childAspectRatio;

                if (constraints.maxWidth < 600) {
                  crossAxisCount = 2; // Mobile
                  childAspectRatio = 0.75;
                } else if (constraints.maxWidth < 1100) {
                  crossAxisCount = 3; // Tablet
                  childAspectRatio = 0.9;
                } else {
                  crossAxisCount = 4; // Web
                  childAspectRatio = 1.1;
                }
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 28,
                  mainAxisSpacing: 28,
                  childAspectRatio: childAspectRatio,
                  children: [
                    // _dashboardCard(
                    //   title: "Tracking",
                    //   subtitle: "Monitor production & delivery status",
                    //   icon: Icons.auto_graph,
                    //   gradient: [
                    //     const Color(0xFFFF6B9D),
                    //     const Color(0xFFFFA07A),
                    //   ],
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => ProductionTrackingScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    _dashboardCard(
                      title: "Order Booking",
                      subtitle: "Create and manage orders",
                      icon: Icons.book_online,
                      gradient: [
                        const Color(0xFF667EEA),
                        const Color(0xFF764BA2),
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
                    _dashboardCard(
                      title: "All Sales Orders",
                      subtitle: "View all customer orders",
                      icon: Icons.list_alt,
                      gradient: [
                        const Color(0xFF11998E),
                        const Color(0xFF38EF7D),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobCardHistoryTab(),
                          ),
                        );
                      },
                    ),
                    _dashboardCard(
                      title: "Job Card",
                      subtitle: "Manage production job cards",
                      icon: Icons.assignment,
                      gradient: [
                        const Color(0xFF8E2DE2),
                        const Color(0xFF4A00E0),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectSalesOrderTab(),
                          ),
                        );
                      },
                    ),

                    _dashboardCard(
                      title: "Product Master",
                      subtitle: "Issue raw material from stock",
                      icon: Icons.inventory_2_outlined,
                      gradient: [
                        const Color(0xFFEC008C),
                        const Color(0xFFFC6767),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MasterProductEntryScreen(),
                          ),
                        );
                      },
                    ),
                    // _dashboardCard(
                    //   title: "Delivery Schedule",
                    //   subtitle: "Plan & manage deliveries",
                    //   icon: Icons.local_shipping,
                    //   gradient: [
                    //     const Color(0xFFF46B45),
                    //     const Color(0xFFEEA849),
                    //   ],
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const DeliveryManagementScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    _dashboardCard(
                      title: "Payment Collection",
                      subtitle: "Record customer payments",
                      icon: Icons.local_shipping,
                      gradient: [
                        const Color(0xFFF46B45),
                        const Color(0xFFEEA849),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentCollectionScreen(),
                          ),
                        );
                      },
                    ),
                    _dashboardCard(
                      title: "Designer",
                      subtitle: "Approve or decline payment requests",
                      icon: Icons.local_shipping,
                      gradient: [
                        const Color.fromARGB(255, 242, 54, 2),
                        const Color(0xFFEEA849),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DesignerScreen(),
                          ),
                        );
                      },
                    ),

                  

                    _dashboardCard(
                      title: "Backup Manager",
                      subtitle: "Approve dispatches and manage deliveries",
                      icon: Icons.local_shipping,
                      gradient: [
                        const Color.fromARGB(255, 226, 139, 114),
                        const Color.fromARGB(255, 234, 143, 14),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BackupOrdersTab(),
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

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2575FC).withOpacity(0.3),
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
                "Sales Dashboard",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                "Manage your sales orders",
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
            ],
          ),
          Image.asset("assets/dpl.png", scale: 3.5),
        ],
      ),
    );
  }

  Widget _dashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22.sp, color: Colors.white),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: gradient[0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
