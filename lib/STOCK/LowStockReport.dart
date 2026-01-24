import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LowStockReport extends StatefulWidget {
  const LowStockReport({super.key});

  @override
  _LowStockReportState createState() => _LowStockReportState();
}

class _LowStockReportState extends State<LowStockReport> {
  String selectedFilter = 'All';
  final List<String> filterOptions = [
    'All',
    'Critical (≤2)',
    'Low (≤5)',
    'Medium (≤10)',
  ];
  int lowStockThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isDesktop, isTablet),
                const SizedBox(height: 24),
                _buildFilterSection(context, isDesktop),
                const SizedBox(height: 24),
                _buildLowStockList(context, isDesktop, isTablet, isMobile),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      title: const Text(
        'Inventory Management',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () {
            _showThresholdDialog(context);
          },
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Export Report',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B35), Color(0xFFE55A4E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Low Stock Alert System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor inventory levels and prevent stockouts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isDesktop || isTablet) ...[
            const SizedBox(height: 24),
            FutureBuilder<Map<String, dynamic>>(
              future: _getStockStatistics(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final stats = snapshot.data!;
                return Row(
                  children: [
                    _buildStatCard(
                      'Critical Items',
                      '${stats['critical']}',
                      Icons.error_outline,
                      true,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Low Stock',
                      '${stats['low']}',
                      Icons.warning_amber_outlined,
                      false,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Total Items',
                      '${stats['total']}',
                      Icons.inventory_2_outlined,
                      false,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    bool isCritical,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCritical
              ? Colors.red.withOpacity(0.15)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCritical
                ? Colors.red.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isCritical ? Colors.red.shade100 : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: isCritical ? Colors.red.shade100 : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              const Text(
                'Filter by Stock Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                'Threshold: ≤$lowStockThreshold',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: filterOptions.map((filter) {
              final isSelected = selectedFilter == filter;
              return FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: const Color(0xFFFF6B35),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockList(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_outlined, color: Color(0xFF64748B)),
                const SizedBox(width: 12),
                const Text(
                  'Stock Level Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<StockItem>>(
            future: _getFilteredLowStockItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 300,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B35),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Analyzing stock levels...',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(
                  height: 300,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'All items are well stocked!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No items require immediate attention',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final lowStockItems = snapshot.data!;
              return Column(
                children: [
                  if (lowStockItems.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFEF3C7), Color(0xFFFDE047)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEAB308).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAB308),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.warning_amber,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${lowStockItems.length} items require attention',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF92400E),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Consider restocking soon to avoid stockouts',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF92400E,
                                    ).withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lowStockItems.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final item = lowStockItems[index];
                      return _buildStockItemTile(
                        item,
                        isDesktop,
                        isTablet,
                        isMobile,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStockItemTile(
    StockItem item,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    final isCritical = item.quantity <= 2;
    final isLow = item.quantity <= 5;

    Color statusColor = isCritical
        ? const Color(0xFFDC2626)
        : isLow
        ? const Color(0xFFEAB308)
        : const Color(0xFFFF6B35);

    String statusText = isCritical
        ? 'CRITICAL'
        : isLow
        ? 'LOW'
        : 'MEDIUM';

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCritical
                    ? [const Color(0xFFDC2626), const Color(0xFFB91C1C)]
                    : [statusColor, statusColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isCritical ? Icons.error_outline : Icons.warning_amber_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Current Stock: ${item.quantity} units',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 2),
                  LinearProgressIndicator(
                    value: (item.quantity / 20).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.1),
                      statusColor.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        _showRestockDialog(context);
      },
      backgroundColor: const Color(0xFF10B981),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_shopping_cart),
      label: const Text('Restock Items'),
    );
  }

  void _showThresholdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Low Stock Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Items with stock equal to or below this threshold will be flagged as low stock.',
            ),
            const SizedBox(height: 16),
            Slider(
              value: lowStockThreshold.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: '$lowStockThreshold',
              onChanged: (value) {
                setState(() {
                  lowStockThreshold = value.round();
                });
              },
            ),
            Text('Threshold: $lowStockThreshold units'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restock Items'),
        content: const Text(
          'This feature will allow you to quickly restock low inventory items. Implementation coming soon!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getStockStatistics() async {
    final lowStockItems = await _getLowStockItems();
    final critical = lowStockItems.where((item) => item.value <= 2).length;
    final low = lowStockItems
        .where((item) => item.value <= 5 && item.value > 2)
        .length;

    return {'critical': critical, 'low': low, 'total': lowStockItems.length};
  }

  Future<List<StockItem>> _getFilteredLowStockItems() async {
    final lowStockItems = await _getLowStockItems();

    List<MapEntry<String, int>> filteredItems;

    switch (selectedFilter) {
      case 'Critical (≤2)':
        filteredItems = lowStockItems.where((item) => item.value <= 2).toList();
        break;
      case 'Low (≤5)':
        filteredItems = lowStockItems
            .where((item) => item.value <= 5 && item.value > 2)
            .toList();
        break;
      case 'Medium (≤10)':
        filteredItems = lowStockItems
            .where((item) => item.value <= 10 && item.value > 5)
            .toList();
        break;
      default:
        filteredItems = lowStockItems
            .where((item) => item.value <= lowStockThreshold)
            .toList();
    }

    return filteredItems
        .map(
          (entry) => StockItem(productName: entry.key, quantity: entry.value),
        )
        .toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
  }

  Future<List<MapEntry<String, int>>> _getLowStockItems() async {
    final stockSnapshot = await FirebaseFirestore.instance
        .collection('stock')
        .get();
    final Map<String, int> currentStock = {};

    for (final doc in stockSnapshot.docs) {
      final data = doc.data();
      final product = data['product'] as String;
      final qty = data['qty'] as int;
      final type = data['type'] as String;

      currentStock[product] =
          (currentStock[product] ?? 0) + (type == 'IN' ? qty : -qty);
    }

    return currentStock.entries.where((entry) => entry.value <= 20).toList();
  }
}

class StockItem {
  final String productName;
  final int quantity;

  StockItem({required this.productName, required this.quantity});
}
