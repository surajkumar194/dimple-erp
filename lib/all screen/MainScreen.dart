import 'dart:async';
import 'package:dimple_erp/PRODUCTION/DashboardScreen.dart';
import 'package:dimple_erp/all screen/SalesDashboard.dart';
import 'package:dimple_erp/all%20screen/MOMScreen.dart';
import 'package:dimple_erp/all%20screen/PurchaseOrderScreen.dart';
import 'package:dimple_erp/all%20screen/QualityCheckScreen.dart';
import 'package:dimple_erp/all%20screen/master_screen.dart';
import 'package:dimple_erp/material/PurchaseOrder.dart';
import 'package:dimple_erp/ready stock/DashboardScreen.dart';
import 'package:dimple_erp/ready stock/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _currentIndex = 0;
  Timer? _sessionTimer;

  static const int sessionDurationMinutes = 60; // ✅ 1 HOUR

  final List<String> _tabs = [
    'Stock',
    'Sales',
    'Production',
    'Purchase Order',
    'Quality Check',
    'Mom',
    'Master Screen',

  ];

  final List<Widget> _screens = [
    DashboardScreen(),
    const SalesDashboard(),
    ProductionDashboard(),
    PurchaseOrderScreen(),
    QualityCheckScreen(),
    MinutesOfMeetingScreen (),
    MasterScreen(),

  ];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });

    _checkSession();

    // 🔁 Auto check every 1 minute
    _sessionTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _checkSession());
  }

  /// 🔹 SESSION CHECK (1 HOUR)
  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt('loginTime');

    if (loginTime == null) {
      _logout();
      return;
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final elapsedMinutes =
        (currentTime - loginTime) / (1000 * 60);

    if (elapsedMinutes >= sessionDurationMinutes) {
      _logout(sessionExpired: true);
    }
  }

  /// 🔹 LOGOUT
  Future<void> _logout({bool sessionExpired = false}) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    if (sessionExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔹 APP RESUME CHECK
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => _logout(),
          ),
        ],
        title: Row(
          children: [
            Image.asset(
              "assets/dpl.png",
              fit: BoxFit.fill,
              scale: 3.5,
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dimple Packaging Pvt Ltd',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Ludhiana, Punjab',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: const Color(0xFFafcb1f),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
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
