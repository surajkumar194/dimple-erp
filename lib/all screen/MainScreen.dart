import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

// SCREENS
import 'package:dimple_erp/ready stock/DashboardScreen.dart';
import 'package:dimple_erp/all screen/SalesDashboard.dart';
import 'package:dimple_erp/PRODUCTION/DashboardScreen.dart';
import 'package:dimple_erp/all screen/PurchaseOrderScreen.dart';
import 'package:dimple_erp/all screen/QualityCheckScreen.dart';
import 'package:dimple_erp/all screen/MOMScreen.dart';
import 'package:dimple_erp/all screen/master_screen.dart';
import 'package:dimple_erp/ready stock/LoginScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController? _tabController;
  Timer? _sessionTimer;

  String _role = '';
  Map<String, dynamic> _permissions = {};
  bool _loading = true;

  static const int sessionDurationMinutes = 60;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _checkSession();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSession(),
    );
  }

  // ================= LOAD ROLE + PERMISSIONS =================
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
              'purchase': true,
              'quality': true,
              'mom': true,
              'master': true,
            }
          : Map<String, dynamic>.from(permissions);

      _tabController?.dispose();
      _tabController = TabController(length: _buildTabs().length, vsync: this);

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
      if (_permissions['purchase'] == true) const Tab(text: 'Purchase Order'),
      if (_permissions['quality'] == true) const Tab(text: 'Quality Check'),
      if (_permissions['mom'] == true) const Tab(text: 'MOM'),
      if (_permissions['master'] == true) const Tab(text: 'Master'),
    ];
  }

  // ================= BUILD SCREENS =================
  List<Widget> _buildScreens() {
    return [
      if (_permissions['stock'] == true) DashboardScreen(),
      if (_permissions['sales'] == true) const SalesDashboard(),
      if (_permissions['production'] == true) ProductionDashboard(),
      if (_permissions['purchase'] == true) PurchaseOrderScreen(),
      if (_permissions['quality'] == true) QualityCheckScreen(),
      if (_permissions['mom'] == true) MinutesOfMeetingScreen(),
      if (_permissions['master'] == true) MasterDashboardScreen(),
    ];
  }

  // ================= SESSION CHECK =================
  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt('loginTime');

    if (loginTime == null) {
      _logout();
      return;
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final elapsedMinutes = (currentTime - loginTime) / (1000 * 60);

    if (elapsedMinutes >= sessionDurationMinutes) {
      _logout(sessionExpired: true);
    }
  }

  // ================= LOGOUT =================
  Future<void> _logout({bool sessionExpired = false}) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
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

  // ================= DISPOSE =================
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController?.dispose();
    _sessionTimer?.cancel();
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ================= TOP BAR (TAB + LOGOUT) =================
          Container(
            color: const Color(0xFFafcb1f),
            child: Row(
              children: [
                // ---------- TAB BAR ----------
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

                // ---------- LOGOUT BUTTON (LAST RIGHT) ----------
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                ),
              ],
            ),
          ),

          // ================= TAB BODY =================
          Expanded(
            child: TabBarView(controller: _tabController, children: screens),
          ),
        ],
      ),
    );
  }
}
