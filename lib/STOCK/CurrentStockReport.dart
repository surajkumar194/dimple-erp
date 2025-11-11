import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CurrentStockReport extends StatefulWidget {
  const CurrentStockReport({super.key});

  @override
  _CurrentStockReportState createState() => _CurrentStockReportState();
}

class _CurrentStockReportState extends State<CurrentStockReport> {
  String _searchQuery = '';
  String _filterStatus = 'All';
  bool _sortDescending = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;
    final maxWidth = isWeb ? 1200.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Current Stock Report',
          style: TextStyle(
            fontSize: isWeb ? 24 : 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: !isWeb,
        toolbarHeight: isWeb ? 80 : 56,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded),
              onPressed: () => setState(() {}),
              tooltip: 'Refresh Data',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF1F5F9),
              const Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: FutureBuilder<Map<String, int>>(
              future: _calculateCurrentStock(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState(isWeb);
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString(), isWeb);
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(isWeb);
                }

                final stockData = snapshot.data!;
                final filteredData = _filterStockData(stockData);

                return Column(
                  children: [
                    // Header and Controls
                    _buildHeader(stockData, isWeb),
                    
                    // Search and Filter Bar
                    _buildSearchAndFilter(isWeb),
                    
                    // Stock Data List/Grid
                    Expanded(
                      child: _buildStockList(filteredData, isWeb),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, int> stockData, bool isWeb) {
    final inStock = stockData.values.where((qty) => qty > 0).length;
    final outOfStock = stockData.values.where((qty) => qty <= 0).length;
    final lowStock = stockData.values.where((qty) => qty > 0 && qty <= 10).length;
    final totalValue = stockData.values.fold(0, (sum, qty) => sum + qty);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 40 : 16,
        vertical: isWeb ? 32 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Container(
            margin: EdgeInsets.only(bottom: isWeb ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Overview',
                  style: TextStyle(
                    fontSize: isWeb ? 28 : 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Real-time stock levels and inventory status',
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Stats Cards
          LayoutBuilder(
            builder: (context, constraints) {
              if (isWeb && constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(child: _buildStatCard('In Stock', inStock.toString(), const Color(0xFF10B981), Icons.check_circle_outline, isWeb)),
                    SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Out of Stock', outOfStock.toString(), const Color(0xFFEF4444), Icons.cancel_outlined, isWeb)),
                    SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Low Stock', lowStock.toString(), const Color(0xFFF59E0B), Icons.warning_outlined, isWeb)),
                    SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Total Items', totalValue.toString(), const Color(0xFF3B82F6), Icons.inventory_2_outlined, isWeb)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('In Stock', inStock.toString(), const Color(0xFF10B981), Icons.check_circle_outline, isWeb)),
                        SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Out of Stock', outOfStock.toString(), const Color(0xFFEF4444), Icons.cancel_outlined, isWeb)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Low Stock', lowStock.toString(), const Color(0xFFF59E0B), Icons.warning_outlined, isWeb)),
                        SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Total Items', totalValue.toString(), const Color(0xFF3B82F6), Icons.inventory_2_outlined, isWeb)),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isWeb ? 20 : 18),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isWeb ? 24 : 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isWeb ? 14 : 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 40 : 16,
        vertical: 16,
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isWeb ? 16 : 12,
                ),
                hintStyle: TextStyle(color: const Color(0xFF94A3B8)),
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Filter and Sort Row
          Row(
            children: [
              // Filter Dropdown
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF64748B)),
                      items: ['All', 'In Stock', 'Out of Stock', 'Low Stock']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _filterStatus = value!),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // Sort Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  onPressed: () => setState(() => _sortDescending = !_sortDescending),
                  icon: Icon(
                    _sortDescending ? Icons.sort_rounded : Icons.sort_rounded,
                    color: const Color(0xFF64748B),
                  ),
                  tooltip: _sortDescending ? 'Sort Ascending' : 'Sort Descending',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(Map<String, int> stockData, bool isWeb) {
    final sortedEntries = stockData.entries.toList()
      ..sort((a, b) => _sortDescending 
          ? b.value.compareTo(a.value) 
          : a.value.compareTo(b.value));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 16),
      child: ListView.builder(
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final product = entry.key;
          final quantity = entry.value;

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isWeb ? 24 : 16,
                vertical: isWeb ? 12 : 8,
              ),
              leading: Container(
                width: isWeb ? 48 : 40,
                height: isWeb ? 48 : 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(quantity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(quantity).withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    product.isNotEmpty ? product[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _getStatusColor(quantity),
                      fontWeight: FontWeight.w700,
                      fontSize: isWeb ? 18 : 16,
                    ),
                  ),
                ),
              ),
              title: Text(
                product,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isWeb ? 16 : 15,
                  color: const Color(0xFF1E293B),
                ),
              ),
              subtitle: Container(
                margin: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(quantity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(quantity),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(quantity),
                        ),
                      ),
                    ),
                    if (quantity > 0 && quantity <= 10) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'LOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 16 : 12,
                  vertical: isWeb ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(quantity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(quantity).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  quantity.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isWeb ? 18 : 16,
                    color: _getStatusColor(quantity),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(bool isWeb) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isWeb ? 48 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: const Color(0xFF3B82F6),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading Stock Data',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Calculating current inventory levels...',
              style: TextStyle(
                fontSize: isWeb ? 14 : 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isWeb) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isWeb ? 48 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: isWeb ? 48 : 40,
                color: const Color(0xFFEF4444),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Failed to load stock information',
              style: TextStyle(
                fontSize: isWeb ? 14 : 13,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isWeb) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isWeb ? 48 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: isWeb ? 48 : 40,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Stock Data Available',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add products and stock transactions to see inventory levels',
              style: TextStyle(
                fontSize: isWeb ? 14 : 13,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.add_rounded),
              label: Text('Add Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _filterStockData(Map<String, int> stockData) {
    var filtered = stockData;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = Map.fromEntries(
        filtered.entries.where(
          (entry) => entry.key.toLowerCase().contains(_searchQuery.toLowerCase()),
        ),
      );
    }

    // Apply status filter
    switch (_filterStatus) {
      case 'In Stock':
        filtered = Map.fromEntries(
          filtered.entries.where((entry) => entry.value > 0),
        );
        break;
      case 'Out of Stock':
        filtered = Map.fromEntries(
          filtered.entries.where((entry) => entry.value <= 0),
        );
        break;
      case 'Low Stock':
        filtered = Map.fromEntries(
          filtered.entries.where((entry) => entry.value > 0 && entry.value <= 10),
        );
        break;
    }

    return filtered;
  }

  Color _getStatusColor(int quantity) {
    if (quantity <= 0) return const Color(0xFFEF4444); // Red for out of stock
    if (quantity <= 10) return const Color(0xFFF59E0B); // Orange for low stock
    return const Color(0xFF10B981); // Green for in stock
  }

  String _getStatusText(int quantity) {
    if (quantity <= 0) return 'Out of Stock';
    if (quantity <= 10) return 'Low Stock';
    return 'In Stock';
  }

  Future<Map<String, int>> _calculateCurrentStock() async {
    try {
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock')
          .get();
      
      final Map<String, int> currentStock = {};

      for (final doc in stockSnapshot.docs) {
        final data = doc.data();
        final product = data['product'] as String? ?? '';
        final qty = data['qty'] as int? ?? 0;
        final type = data['type'] as String? ?? '';

        if (product.isNotEmpty) {
          currentStock[product] = (currentStock[product] ?? 0) + 
              (type == 'IN' ? qty : -qty);
        }
      }

      return currentStock;
    } catch (e) {
      throw Exception('Failed to load stock data: $e');
    }
  }
}