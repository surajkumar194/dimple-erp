import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/ready stock/DispatchSweetsStockScreen.dart';
import 'package:dimple_erp/ready stock/Readystock.dart';
import 'package:dimple_erp/ready stock/storestock.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
                  int crossAxisCount;
                  double childAspectRatio;

                  if (constraints.maxWidth < 600) {
                    crossAxisCount = 2; // Mobile
                    childAspectRatio = 0.78;
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
                      _firestoreCard(
                        title: "Wedding / Boxes Raw Material",
                        subtitle: "Manage wedding material stock",
                        icon: Icons.inventory_2,
                        gradient: [Colors.orange[600]!, Colors.orange[400]!],
                        collection: "stock_items",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoreStockScreen(),
                            ),
                          );
                        },
                      ),

                      //    _firestoreCard(
                      //   title: "Paper / Stock",
                      //   subtitle: "Manage Paper Stock",
                      //   icon: Icons.shopping_cart_checkout_sharp,
                      //   gradient: [const Color.fromARGB(255, 87, 147, 232)!, const Color.fromARGB(255, 94, 143, 211)!],
                      //   collection: "paper_stock_items",
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (_) => const PaperStockScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      _firestoreCard(
                        title: "Mdf / Boxes Ready Stock",
                        subtitle: "Ready stock dashboard",
                        icon: Icons.dashboard,
                        gradient: [Colors.purple[600]!, Colors.purple[400]!],
                        collection: "stock",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReadyStockScreen(),
                            ),
                          );
                        },
                      ),

                      _firestoreCard(
                        title: "Dispatch Sweets Stock",
                        subtitle: "Sweets stock management",
                        icon: Icons.shopping_basket,
                        gradient: [Colors.green[600]!, Colors.green[400]!],
                        collection: "dispatchedOrders",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DispatchSweetsStockScreen(),
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
          colors: [Colors.blue[700]!, Colors.purple[600]!],
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
            children: [
              Text(
                "Stock Store 👋",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                "Manage your store stock",
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
            ],
          ),
          Image.asset("assets/dpl.png", scale: 3.5),
        ],
      ),
    );
  }

  // ================= CARD WITH FIRESTORE COUNT =================
  Widget _firestoreCard({
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
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 22.sp, color: Colors.white),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
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
