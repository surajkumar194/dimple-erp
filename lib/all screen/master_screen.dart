import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';

class MasterDashboardScreen extends StatefulWidget {
  const MasterDashboardScreen({super.key});

  @override
  State<MasterDashboardScreen> createState() => _MasterDashboardScreenState();
}

class _MasterDashboardScreenState extends State<MasterDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> _getCount(String collection) async {
    final snap = await _firestore.collection(collection).get();
    return snap.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
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
                      _masterCard(
                        title: "Departments",
                        subtitle: "Manage departments",
                        icon: Icons.apartment,
                        gradient: [Colors.blue, Colors.blueAccent],
                        collection: "departments",
                        onTap: () {},
                      ),

                      _masterCard(
                        title: "Sub Departments",
                        subtitle: "Department hierarchy",
                        icon: Icons.account_tree,
                        gradient: [Colors.teal, Colors.tealAccent],
                        collection: "subDepartments",
                        onTap: () {},
                      ),

                      _masterCard(
                        title: "Quality Check",
                        subtitle: "QC parameters",
                        icon: Icons.verified,
                        gradient: [Colors.orange, Colors.deepOrangeAccent],
                        collection: "qualityCheck",
                        onTap: () {},
                      ),

                      _masterCard(
                        title: "MOM",
                        subtitle: "Meeting records",
                        icon: Icons.meeting_room,
                        gradient: [Colors.indigo, Colors.indigoAccent],
                        collection: "mom",
                        onTap: () {},
                      ),

                      _masterCard(
                        title: "Dispatch",
                        subtitle: "Dispatch masters",
                        icon: Icons.local_shipping,
                        gradient: [Colors.green, Colors.greenAccent],
                        collection: "dispatchedOrders",
                        onTap: () {},
                      ),

                      _masterCard(
                        title: "Users / Roles",
                        subtitle: "User access control",
                        icon: Icons.people,
                        gradient: [Colors.red, Colors.redAccent],
                        collection: "users",
                        onTap: () {},
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

  // ================= HEADER =================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.blue],
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
                "Master Control 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Manage master data",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Icon(Icons.dashboard_customize,
              size: 50, color: Colors.white),
        ],
      ),
    );
  }

  // ================= MASTER CARD =================
  Widget _masterCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required String collection,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<int>(
      future: _getCount(collection),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

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
              padding: const EdgeInsets.all(18),
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
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Total: $count",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

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
      },
    );
  }
}
