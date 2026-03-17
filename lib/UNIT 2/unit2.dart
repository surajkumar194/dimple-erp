import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/UNIT%202/paperstockscreen.dart';
import 'package:dimple_erp/UNIT%202/readystockhajari.dart';
import 'package:dimple_erp/UNIT%202/readystocksweets.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class Unit2 extends StatefulWidget {
  const Unit2({super.key});

  @override
  State<Unit2> createState() => _Unit2State();
}

class _Unit2State extends State<Unit2> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> _getCount(String collection) async {
    final snap = await _firestore.collection(collection).get();
    return snap.docs.length;
  }

  Future<int> _getProductionUnit2Count() async {
    final snap = await _firestore
        .collection('orders')
        .where('productionUnit', isEqualTo: 'Unit 2')
        .get();
    return snap.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 30),
            _grid(),
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
          colors: [Colors.blue.shade700, Colors.purple.shade600],
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
                "Unit 2 Stock",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                "Manage Stock Unit 2",
                style: TextStyle(fontSize: 14.sp,
                  color: Colors.white70),
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
            // Existing cards
            _firestoreCard(
              title: "Paper / Label Stock",
              subtitle: "Manage Paper & Labels",
              icon: Icons.description,
              gradient: [Colors.teal.shade700, Colors.teal.shade500],
              future: _getCount("paper_stock_items"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaperStockScreen()),
              ),
            ),

            _firestoreCard(
              title: "Ready Stock Sweets",
              subtitle: "Sweets Inventory",
              icon: Icons.cake,
              gradient: [Colors.orange.shade700, Colors.orange.shade500],
              future: _getCount("readystock_sweets_items"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReadyStockSweetsScreen(),
                ),
              ),
            ),

            _firestoreCard(
              title: "Ready Stock Hosiery",
              subtitle: "Hosiery Inventory",
              icon: Icons.inventory_2,
              gradient: [Colors.indigo.shade700, Colors.indigo.shade500],
              future: _getCount("readystock_hajari_items"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReadyStockHajariScreen(),
                ),
              ),
            ),

            // _firestoreCard(
            //   title: "Production – Unit 2",
            //   subtitle: "Orders in Production",
            //   icon: Icons.factory,
            //   gradient: [Colors.green.shade700, Colors.green.shade500],
            //   future: _getProductionUnit2Count(),
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) => const ProductionUnit2Screen(),
            //     ),
            //   ),
            // ),

            // // 🆕 NEW: Production Inventory Dashboard
            // _firestoreCard(
            //   title: "Production & Inventory",
            //   subtitle: "Real-time Dashboard",
            //   icon: Icons.dashboard,
            //   gradient: [Colors.cyan.shade700, Colors.teal.shade500],
            //   future: _getProductionUnit2Count(),
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) => const  AllInventoryScreen() ,
            //     ),
            //   ),
            // ),
            //   _firestoreCard(
            //   title: "machine screen",
            //   subtitle: "Manage Machines",
            //   icon: Icons.factory,
            //   gradient: [Colors.green.shade700, Colors.green.shade500],
            //   future: _getProductionUnit2Count(),
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) =>  MachineScreen(),
            //     ),
            //   ),
            // ),
            //    _firestoreCard(
            //   title: "Packaging",
            //   subtitle: "Manage Packaging Items",
            //   icon: Icons.inventory_2,
            //   gradient: [Colors.green.shade700, Colors.green.shade500],
            //   future: _getProductionUnit2Count(),
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) => const PackagingScreen(),
            //     ),
            //   ),
            // ),
            //     _firestoreCard(
            //   title: "dispatch screen",
            //   subtitle: "Manage Dispatch Items",
            //   icon: Icons.inventory_2,
            //   gradient: [Colors.green.shade700, Colors.green.shade500],
            //   future: _getProductionUnit2Count(),
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) => const dispScreen(),
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }

  // ================= CARD =================
  Widget _firestoreCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Future<int> future,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<int>(
      future: future,
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
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white70,
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