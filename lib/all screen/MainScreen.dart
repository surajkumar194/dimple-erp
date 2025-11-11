import 'package:dimple_erp/AdminDashboard/AdminDashboard.dart';
import 'package:dimple_erp/EngineeringDashboard/EngineeringDashboard.dart';
import 'package:dimple_erp/FinanceDashboard/FinanceDashboard.dart';
import 'package:dimple_erp/QCQADashboard/QCQADashboard.dart';
import 'package:dimple_erp/material/MaterialDashboard.dart';
import 'package:dimple_erp/operation/OperationDashboard.dart';
import 'package:dimple_erp/ppc/PPCDashboard.dart';
import 'package:dimple_erp/all%20screen/SalesDashboard.dart';
import 'package:dimple_erp/ready%20stock/DashboardScreen.dart';
import 'package:dimple_erp/ready%20stock/storestock.dart';
import 'package:flutter/material.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<String> _tabs = [
    'Stock',
    'Sales',
    'Material',
    'PPC',
    'Operation',
    'QC/QA',
    'Engineering',
    'Finance',
    'Admin',
  ];

  final List<Widget> _screens = [
DashboardScreen (),
    const SalesDashboard(),
    const MaterialDashboard(),
     const PPCDashboard(),
   const OperationDashboard(),
    const QCQADashboard(),
    const EngineeringDashboard(),
    const FinanceDashboard(),
    const AdminDashboard(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dimple Packaging Pvt Ltd',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Ludhiana, Punjab',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: const Color(0xFF42A5F5),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _screens,
      ),
    );
  }
}