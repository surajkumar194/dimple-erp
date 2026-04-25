import 'package:dimple_erp/AdminDashboard/ContractorReportScreen.dart';
import 'package:dimple_erp/AdminDashboard/ContractorReportScreendetails.dart';
import 'package:dimple_erp/AdminDashboard/client.dart';
import 'package:dimple_erp/AdminDashboard/clienthistory.dart';
import 'package:dimple_erp/AdminDashboard/constrctlist.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class Clientdashboard extends StatefulWidget {
  const Clientdashboard({super.key});

  @override
  State<Clientdashboard> createState() => _ClientdashboardState();
}

class _ClientdashboardState extends State<Clientdashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_header(), const SizedBox(height: 30), _grid()],
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
          colors: [Colors.blue.shade700, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Customer Dashboard",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                "Manage Customer",
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
            ],
          ),
          Image.asset("assets/dpl.png", scale: 3.5),
        ],
      ),
    );
  }

  // ================= GRID =================
  Widget _grid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.85;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 3;
          childAspectRatio = 0.95;
        } else {
          crossAxisCount = 4;
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
            _firestoreCard(
              title: "Add Customer Details",
              subtitle: "Customer Management system",
              icon: Icons.description,
              gradient: [const Color.fromARGB(255, 239, 138, 14), const Color.fromARGB(255, 239, 138, 14)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientFormPage(),
                  ),
                );
              },
            ),

            _firestoreCard(
              title: "Customer History",
              subtitle: "Customer history details",
              icon: Icons.description,
              gradient: [const Color.fromARGB(255, 239, 29, 10), const Color.fromARGB(255, 239, 29, 10)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HistoryPage()),
                );
              },
            ),

            // _firestoreCard(
            //   title: "Contractor dashboard",
            //   subtitle: "Contractor all details",
            //   icon: Icons.description,
            //   gradient: [const Color.fromARGB(255, 244, 78, 216), const Color.fromARGB(255, 244, 78, 216)],
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => ConstructionProductionDashboard()),
            //     );
            //   },
            // ),
          ],
        );
      },
    );
  }
  Widget _firestoreCard({
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
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22.sp, color: Colors.white),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),

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
