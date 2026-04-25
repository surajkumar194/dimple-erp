import 'package:dimple_erp/PRODUCTION/KappaProductionListScreen.dart';
import 'package:dimple_erp/PRODUCTION/MDFStockScreen.dart';
import 'package:dimple_erp/PRODUCTION/ReadyForDispatchScreen.dart';
// import 'package:dimple_erp/PRODUCTION/MdfProductionScreen.dart';
// import 'package:dimple_erp/PRODUCTION/ProductionDashobard.dart';
// import 'package:dimple_erp/PRODUCTION/MachineFormScreen.dart';
// import 'package:dimple_erp/PRODUCTION/allprodctiondata.dart';
import 'package:dimple_erp/PRODUCTION/mdfproductionlist.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class ProductionDashboard extends StatefulWidget {
  const ProductionDashboard({super.key});

  @override
  State<ProductionDashboard> createState() => _ProductionDashboardState();
}

class _ProductionDashboardState extends State<ProductionDashboard> {
  @override
  void initState() {
    super.initState();
  }

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
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: childAspectRatio,
                  children: [
                    //  if (isAdmin || hasProductionAccess)
                    //   _dashboardCard(
                    //     title: "Production",
                    //     subtitle: "Machine performance & efficiency",
                    //     icon: Icons.precision_manufacturing,
                    //     gradient: [Colors.indigo[700]!, Colors.indigo[400]!],
                    //     onTap: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (_) =>
                    //               const UltraFlowProductionDashboard(),
                    //         ),
                    //       );
                    //     },
                    //   ),

                    // if (isAdmin || hasProductionAccess)
                    //   _dashboardCard(
                    //     title: "Machine Production",
                    //     subtitle: "Configure machines & operators",
                    //     icon: Icons.settings_suggest,
                    //     gradient: [Colors.cyan[700]!, Colors.cyan[400]!],
                    //     onTap: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (_) => AddProductionScreen(),
                    //         ),
                    //       );
                    //     },
                    //   ),

                    // if (isAdmin || hasProductionAccess)
                    //   _dashboardCard(
                    //     title: "All Production Data",
                    //     subtitle: "View & manage production records",
                    //     icon: Icons.assignment_turned_in,
                    //     gradient: [
                    //       Colors.deepOrange[600]!,
                    //       Colors.deepOrange[400]!,
                    //     ],
                    //     onTap: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (_) => ViewProductionScreen(),
                    //         ),
                    //       );
                    //     },
                    //   ),
                    _dashboardCard(
                      title: "MDF Production",
                      subtitle: "View & manage production records",
                      icon: Icons.assignment_turned_in,
                      gradient: [
                        Colors.deepOrange[600]!,
                        Colors.deepOrange[400]!,
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MdfProductionListScreen(),
                          ),
                        );
                      },
                    ),

                    _dashboardCard(
                      title: "KAPPA Production",
                      subtitle: "View & manage production records",
                      icon: Icons.assignment_turned_in,
                      gradient: [
                        const Color.fromARGB(255, 140, 242, 73)!,
                        const Color.fromARGB(255, 140, 242, 73)!,
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KappaProductionListScreen(),
                          ),
                        );
                      },
                    ),

                    _dashboardCard(
                      title: "Ready for Dispatched",
                      subtitle: "View & manage ready for dispatch records",
                      icon: Icons.assignment_turned_in,
                      gradient: [
                        const Color.fromARGB(255, 81, 84, 247)!,
                        const Color.fromARGB(255, 81, 84, 247)!,
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DispatchManagerScreen(),
                          ),
                        );
                      },
                    ),

                    _dashboardCard(
                      title: "Material for Ready MDF Stocking (Stock Area)",
                      subtitle: "View & manage ready for dispatch common records",
                      icon: Icons.assignment_turned_in,
                      gradient: [
                        const Color.fromARGB(255, 79, 203, 249)!,
                        const Color.fromARGB(255, 79, 203, 249)!,
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MDFCommonScreen()),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[700]!, Colors.purple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// TEXT (FLEXIBLE)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Production Dashboard ⚙️",
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Monitor machines, output & efficiency",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              /// LOGO
              Image.asset(
                "assets/dpl.png",
                height: isMobile ? 40 : 55,
                fit: BoxFit.contain,
              ),
            ],
          ),
        );
      },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20.sp, color: Colors.white),

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
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.bottomRight,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: Colors.black,
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
