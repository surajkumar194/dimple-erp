import 'package:dimple_erp/STOCK/ProductList.dart';
import 'package:dimple_erp/STOCK/ReportsPage.dart';
import 'package:dimple_erp/STOCK/SettingsPage.dart';
import 'package:dimple_erp/STOCK/StockInPage.dart';
import 'package:dimple_erp/STOCK/StockLedger.dart';
import 'package:dimple_erp/STOCK/StockOutPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _backgroundController;

  // Low-stock threshold (change if needed)
  static const int kLowStockThreshold = 10;

  final List<DashboardItem> items = [
    DashboardItem(
      'Product Master',
      Icons.inventory_2_outlined,
      const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
      'Manage your complete product catalog',
      () => ProductList(),
    ),
    DashboardItem(
      'Stock IN',
      Icons.add_box_outlined,
      const LinearGradient(colors: [Color(0xFF48bb78), Color(0xFF38a169)]),
      'Record incoming inventory & purchases',
      () => StockInPage(),
    ),
    DashboardItem(
      'Stock OUT',
      Icons.remove_circle_outline,
      const LinearGradient(colors: [Color(0xFFed8936), Color(0xFFdd6b20)]),
      'Track outgoing inventory & sales',
      () => StockOutPage(),
    ),
    DashboardItem(
      'Stock Ledger',
      Icons.list_alt_outlined,
      const LinearGradient(colors: [Color(0xFF805ad5), Color(0xFF6b46c1)]),
      'View detailed transaction history',
      () => StockLedger(),
    ),
    DashboardItem(
      'Reports',
      Icons.analytics_outlined,
      const LinearGradient(colors: [Color(0xFF319795), Color(0xFF2c7a7b)]),
      'Generate comprehensive analytics',
      () => ReportsPage(),
    ),
    DashboardItem(
      'Settings',
      Icons.settings_outlined,
      const LinearGradient(colors: [Color(0xFF718096), Color(0xFF4a5568)]),
      'Configure system preferences',
      () => SettingsPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _animationController.forward();
    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF667eea),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                    child: Column(
                      children: [
                        _buildWelcomeSection(context),
                        const SizedBox(height: 32),
                        _buildStatsSectionRealtime(context, isDesktop, isTablet),
                        const SizedBox(height: 32),
                        _buildDashboardGrid(context, isDesktop, isTablet),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Positioned.fill(
          child: Stack(
            children: [
              Positioned(
                top: 100 + 50 * _backgroundController.value,
                left: 50,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                top: 300 - 30 * _backgroundController.value,
                right: 80,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: 200 + 40 * _backgroundController.value,
                left: 100,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.95),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Center(
              child: Text(
                'D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ).createShader(bounds),
            child: const Text(
              'Dimple ERP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => _showNotifications(context),
            icon: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                color: Color(0xFF667eea),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<int>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 20,
            onSelected: (value) {
              if (value == 1) {
                _showProfile(context);
              } else if (value == 2) {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Row(
                  children: const [
                    Icon(Icons.person_outline, size: 20, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Profile', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFF667eea),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
      ),
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Dashboard',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your inventory and business operations efficiently',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Realtime STATS Section (4 live metrics) =====================
  Widget _buildStatsSectionRealtime(BuildContext context, bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 2);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        int totalProducts = 0;
        int totalQty = 0; // sum of currentStock
        int lowStock = 0; // currentStock < threshold
        int outOfStock = 0; // currentStock <= 0

        if (snapshot.hasData) {
          totalProducts = snapshot.data!.size;
          for (final doc in snapshot.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final int currentStock = (d['currentStock'] is num)
                ? (d['currentStock'] as num).toInt()
                : int.tryParse('${d['currentStock'] ?? 0}') ?? 0;

            totalQty += currentStock;
            if (currentStock <= 0) outOfStock++;
            if (currentStock < kLowStockThreshold) lowStock++;
          }
        }

        final cards = [
          _StatData(value: snapshot.connectionState == ConnectionState.waiting ? '—' : '$totalProducts', label: 'Total Products', icon: Icons.inventory_2, color: Colors.blue),
          _StatData(value: snapshot.connectionState == ConnectionState.waiting ? '—' : '$totalQty',      label: 'Total Qty (Available)', icon: Icons.warehouse, color: Colors.green),
          _StatData(value: snapshot.connectionState == ConnectionState.waiting ? '—' : '$lowStock',      label: 'Low Stock Items (<$kLowStockThreshold)', icon: Icons.warning_amber, color: Colors.orange),
          _StatData(value: snapshot.connectionState == ConnectionState.waiting ? '—' : '$outOfStock',    label: 'Out of Stock', icon: Icons.error_outline, color: Colors.purple),
        ];

        return AnimationLimiter(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final c = cards[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 600),
                columnCount: crossAxisCount,
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildStatCard(c),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(stat.icon, color: stat.color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, size: 16, color: stat.color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(BuildContext context, bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: isDesktop ? 1.1 : (isTablet ? 1.0 : 1.2),
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 800),
            columnCount: crossAxisCount,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _DashboardCard(item: items[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications'),
        content: const Text('No new notifications'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profile'),
        content: const Text('Profile settings coming soon!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ======================== Models / Card data ========================
class _StatData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  _StatData({required this.value, required this.label, required this.icon, required this.color});
}

class _DashboardCard extends StatefulWidget {
  final DashboardItem item;
  const _DashboardCard({required this.item});

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -8 * _hoverController.value),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => widget.item.page()),
              ),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1 + 0.1 * _hoverController.value),
                      blurRadius: 20 + 20 * _hoverController.value,
                      offset: Offset(0, 8 + 12 * _hoverController.value),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: widget.item.gradient,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: widget.item.gradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.item.gradient.colors.first.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.item.icon,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.item.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              widget.item.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: widget.item.gradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
}

class DashboardItem {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final String description;
  final Widget Function() page;

  DashboardItem(this.title, this.icon, this.gradient, this.description, this.page);
}

// Animation helper stubs (so code runs without external package)
class AnimationLimiter extends StatelessWidget {
  final Widget child;
  const AnimationLimiter({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class AnimationConfiguration {
  static Widget staggeredGrid({
    required int position,
    required Duration duration,
    required int columnCount,
    required Widget child,
  }) {
    return child;
  }
}

class SlideAnimation extends StatelessWidget {
  final double verticalOffset;
  final Widget child;
  const SlideAnimation({super.key, required this.verticalOffset, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class FadeInAnimation extends StatelessWidget {
  final Widget child;
  const FadeInAnimation({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
