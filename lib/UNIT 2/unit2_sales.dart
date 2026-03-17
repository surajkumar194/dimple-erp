import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/UNIT%202/unit2inventary.dart';
import 'package:dimple_erp/UNIT%202/MachineScreen.dart';
import 'package:dimple_erp/UNIT%202/addsalesorderunit2.dart';
import 'package:dimple_erp/UNIT%202/constracts.dart';
import 'package:dimple_erp/UNIT%202/disptachscreen.dart';
import 'package:dimple_erp/UNIT%202/packaginscreen.dart';
import 'package:dimple_erp/UNIT%202/production_unit_2_screen.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class Unit2Sales extends StatefulWidget {
  const Unit2Sales({super.key});

  @override
  State<Unit2Sales> createState() => _Unit2SalesState();
}

class _Unit2SalesState extends State<Unit2Sales> {
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
          children: [_header(), const SizedBox(height: 30), _grid()],
        ),
      ),
    );
  }

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
                "Unit 2 Dashboard",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                "Manage Production & Inventory",
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
            ],
          ),
          Image.asset("assets/dpl.png", scale: 3.5),
        ],
      ),
    );
  }

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
              title: "Add a sales order for Unit 2",
              subtitle: "New Orders in unit 2",
              icon: Icons.factory,
              gradient: [
                const Color.fromARGB(255, 114, 23, 233),
                const Color.fromARGB(255, 13, 199, 223),
              ],
              future: _getCount('unit2JobCards'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Unit2SalesOrderScreen(),
                ),
              ),
            ),

            _firestoreCard(
              title: "All Details for Production Unit 2",
              subtitle: "Orders in Production",
              icon: Icons.factory,
              gradient: [Colors.green.shade700, Colors.green.shade500],
              future: _getCount('unit2JobCards'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductionUnit2Screen(),
                ),
              ),
            ),

            // ✅ FIXED: JobCardsListScreen use karo
            _firestoreCard(
              title: "Production Planning & Inventory",
              subtitle: "Issue / Track Materials",
              icon: Icons.dashboard,
              gradient: [Colors.cyan.shade700, Colors.teal.shade500],
              future: _getCount('unit2JobCards'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Unit2InventoryScreen()),
              ),
            ),

            _firestoreCard(
              title: "Add Machine Name Screen",
              subtitle: "Manage Machines Names",
              icon: Icons.factory,
              gradient: [
                const Color.fromARGB(255, 80, 72, 232),
                const Color.fromARGB(255, 76, 87, 175),
              ],
              future: _getProductionUnit2Count(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Unit2MachineScreen()),
              ),
            ),
            _firestoreCard(
              title: "Packaging Screen",
              subtitle: "Manage Packaging Items",
              icon: Icons.inventory_2,
              gradient: [
                const Color.fromARGB(255, 220, 68, 68),
                const Color.fromARGB(255, 231, 9, 9),
              ],
              future: _getProductionUnit2Count(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PackagingScreen()),
              ),
            ),
            _firestoreCard(
              title: "Ready Dispatch Screen",
              subtitle: "Manage Dispatch Items",
              icon: Icons.inventory_2,
              gradient: [
                const Color.fromARGB(255, 181, 62, 214),
                const Color.fromARGB(255, 205, 71, 217),
              ],
              future: _getProductionUnit2Count(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DispatchScreen()),
              ),
            ),

            //    _firestoreCard(
            //   title: "MDF Contractor Assignment",
            //   subtitle: "Assign Contractors for MDF Products",
            //   icon: Icons.person,
            //   gradient: [
            //     const Color.fromARGB(255, 181, 62, 214),
            //     const Color.fromARGB(255, 205, 71, 217),
            //   ],
            //   future: _getProductionUnit2Count(),
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => const MdfContractorScreen(orderId: '', orderData: {}, productData: {})),
            //   ),
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
