import 'dart:async';
import 'dart:convert';
import 'package:dimple_erp/AdminDashboard/admin.dart';
import 'package:dimple_erp/AdminDashboard/clientdashbord.dart';
import 'package:dimple_erp/AdminDashboard/constrcutiondashboard.dart';
import 'package:dimple_erp/UNIT%202/unit2.dart';
import 'package:dimple_erp/UNIT%202/unit2_sales.dart';
import 'package:dimple_erp/challan/DispatchFullPage.dart';
import 'package:dimple_erp/extra.dart/PaymentApprovalScreen.dart';
import 'package:dimple_erp/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:dimple_erp/ready stock/DashboardScreen.dart';
import 'package:dimple_erp/all screen/SalesDashboard.dart';
import 'package:dimple_erp/PRODUCTION/DashboardScreen.dart';
import 'package:dimple_erp/all screen/MOMScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController? _tabController;

  String _role = '';
  Map<String, dynamic> _permissions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString('role') ?? '';
    final rawPermissions = prefs.getString('permissions');

    final permissions = rawPermissions != null
        ? jsonDecode(rawPermissions)
        : {};

    setState(() {
      _role = role;

      // ✅ ADMIN → ALL ACCESS
      _permissions = role == 'admin'
          ? {
              'stock': true,
              'sales': true,
              'production': true,
              // 'purchase': true,
              // 'quality': true,
              'mom': true,
              'master': true,
              'unit2 stock': true,
              'unit2 sales': true,
              'contractor': true,
              'customer': true,
              'paymentapproval': true,
              'challan': true,
            }
          : Map<String, dynamic>.from(permissions);

      final tabs = _buildTabs();

      if (tabs.isNotEmpty) {
        _tabController?.dispose();
        _tabController = TabController(length: tabs.length, vsync: this);
      }

      _loading = false;
    });

    debugPrint('ROLE => $_role');
    debugPrint('PERMISSIONS => $_permissions');
  }

  // ================= BUILD TABS =================
  List<Tab> _buildTabs() {
    return [
      if (_permissions['stock'] == true) const Tab(text: 'Stock'),
      if (_permissions['sales'] == true) const Tab(text: 'Sales'),
      if (_permissions['production'] == true) const Tab(text: 'Production'),
      // if (_permissions['purchase'] == true) const Tab(text: 'Purchase Order'),
      // if (_permissions['quality'] == true) const Tab(text: 'Quality Check'),
      if (_permissions['mom'] == true) const Tab(text: 'MOM'),
      if (_permissions['master'] == true) const Tab(text: 'Master'),
      if (_permissions['unit2 stock'] == true) const Tab(text: 'Unit 2 Stock'),
      if (_permissions['unit2 sales'] == true) const Tab(text: 'Unit 2 Sales'),
      if (_permissions['contractor'] == true) const Tab(text: 'Contractor'),
      if (_permissions['customer'] == true) const Tab(text: 'Customer'),
      if (_permissions['paymentapproval'] == true)
        const Tab(text: 'PaymentApproval'),
      if (_permissions['challan'] == true) const Tab(text: 'Challan'),
    ];
  }

  // ================= BUILD SCREENS =================
  List<Widget> _buildScreens() {
    return [
      if (_permissions['stock'] == true) DashboardScreen(),
      if (_permissions['sales'] == true) const SalesDashboard(),
      if (_permissions['production'] == true) ProductionDashboard(),
      // if (_permissions['purchase'] == true) PurchaseOrderScreen(),
      //if (_permissions['quality'] == true) QualityCheckScreen(),
      if (_permissions['mom'] == true) MinutesOfMeetingScreen(),
      if (_permissions['master'] == true) AdminDashboardScreen(),
      if (_permissions['unit2 stock'] == true) Unit2(),
      if (_permissions['unit2 sales'] == true) const Unit2Sales(),
      if (_permissions['contractor'] == true) const contractordashboard(),
      if (_permissions['customer'] == true) const Clientdashboard(),
      if (_permissions['paymentapproval'] == true)
        const PaymentApprovalScreen(),
      if (_permissions['challan'] == true) const DispatchScreen(),
    ];
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppModeHandler()),
      (_) => false,
    );
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController?.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (_loading || _tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = _buildTabs();
    final screens = _buildScreens();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,

        body: Column(
          children: [
            Container(
              color: const Color(0xFFafcb1f),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: tabs,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(controller: _tabController, children: screens),
            ),
          ],
        ),
      ),
    );
  }
}
