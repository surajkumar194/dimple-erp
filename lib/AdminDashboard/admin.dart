import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/AdminDashboard/AdminDashboard.dart';
import 'package:dimple_erp/AdminDashboard/AdminUsersScreen.dart';
import 'package:dimple_erp/AdminDashboard/MigrateOrdersScreen.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
                    childAspectRatio: 1.0,
                    children: [
                      _adminCard(
                        title: "Users",
                        subtitle: "Manage users & roles",
                        icon: Icons.people,
                        gradient: [Colors.blue[600]!, Colors.blue[400]!],
                        collection: "users",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminUsersScreen(),
                            ),
                          );
                        },
                      ),

                      _adminCard(
                        title: "Orders",
                        subtitle: "All sales orders",
                        icon: Icons.shopping_cart,
                        gradient: [Colors.green[600]!, Colors.green[400]!],
                        collection: "orders",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                 AdminCollectionsScreen(),
                            ),
                          );
                        },
                      ),

                      _adminCard(
                        title: "Job Cards",
                        subtitle: "Production job cards",
                        icon: Icons.assignment,
                        gradient: [Colors.orange[600]!, Colors.orange[400]!],
                        collection: "jobCards",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminCollectionsScreen(),
                            ),
                          );
                        },
                      ),

                      // _adminCard(
                      //   title: "Firestore",
                      //   subtitle: "Collections & documents",
                      //   icon: Icons.storage,
                      //   gradient: [Colors.purple[600]!, Colors.purple[400]!],
                      //   collection: "meta",
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (_) => AdminDocumentDetailScreen(collection: 'meta', docId: 'meta', data: {},),
                      //       ),
                      //     );
                      //   },
                      // ),

                      _adminCard(
                        title: "Sales order",
                        subtitle: "Admin data tools",
                        icon: Icons.sync,
                        gradient: [Colors.red[600]!, Colors.red[400]!],
                        collection: "orders",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminDocumentsScreen(collection: 'orders',),
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
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[700]!, Colors.blue[600]!],
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
                "Admin Panel 👑",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Control everything from one place",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Icon(Icons.admin_panel_settings,
              size: 48, color: Colors.white),
        ],
      ),
    );
  }

  // ================= ADMIN CARD =================
  Widget _adminCard({
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
