import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockLedger extends StatefulWidget {
  const StockLedger({super.key});

  @override
  _StockLedgerState createState() => _StockLedgerState();
}

class _StockLedgerState extends State<StockLedger> with TickerProviderStateMixin {
  String? selectedProductFilter;
  String selectedTypeFilter = 'ALL';
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  // Professional Color Scheme for Ledger
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color inColor = Color(0xFF10B981);
  static const Color outColor = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width > 600 && size.width <= 1024;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: _buildLedgerContent(isDesktop),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFilterFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_long, size: 20),
          ),
          SizedBox(width: 12),
          Text('Stock Ledger', 
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        ],
      ),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 70,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16, top: 12, bottom: 12),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.filter_list, size: 20),
            ),
            onPressed: _showFilterDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    if (selectedProductFilter == null && selectedTypeFilter == 'ALL') {
      return SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Icon(Icons.filter_list, color: primaryColor, size: 20),
              SizedBox(width: 12),
              Text('Active Filters:', 
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  fontSize: 14,
                )),
              SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (selectedProductFilter != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedProductFilter!,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => selectedProductFilter = null),
                              child: Icon(Icons.close, size: 16, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    if (selectedTypeFilter != 'ALL')
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: secondaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedTypeFilter,
                              style: TextStyle(
                                color: secondaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => selectedTypeFilter = 'ALL'),
                              child: Icon(Icons.close, size: 16, color: secondaryColor),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedProductFilter = null;
                    selectedTypeFilter = 'ALL';
                  });
                },
                child: Text('Clear All', 
                  style: TextStyle(color: primaryColor, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerContent(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLedgerHeader(),
          Expanded(child: _buildLedgerList()),
        ],
      ),
    );
  }

  Widget _buildLedgerHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assessment, color: primaryColor, size: 24),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock Movement History', 
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                )),
              Text('Complete transaction records', 
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                )),
            ],
          ),
          Spacer(),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('stock').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        int totalIn = 0, totalOut = 0;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final qty = data['qty'] as int? ?? 0;
          if (data['type'] == 'IN') {
            totalIn += qty;
          } else if (data['type'] == 'OUT') totalOut += qty;
        }

        return Row(
          children: [
            _buildStatCard('Total IN', totalIn, inColor, Icons.add_circle),
            SizedBox(width: 12),
            _buildStatCard('Total OUT', totalOut, outColor, Icons.remove_circle),
            SizedBox(width: 12),
            _buildStatCard('Net Stock', totalIn - totalOut, 
              totalIn - totalOut >= 0 ? inColor : outColor, Icons.inventory),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                SizedBox(height: 16),
                Text('Loading ledger data...', 
                  style: TextStyle(color: textSecondary)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(Icons.receipt_long, 
                    size: 64, color: Colors.grey.shade400),
                ),
                SizedBox(height: 24),
                Text(
                  'No Stock Movements Found',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  selectedProductFilter != null || selectedTypeFilter != 'ALL'
                      ? 'Try adjusting your filters'
                      : 'Stock transactions will appear here',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                if (selectedProductFilter != null || selectedTypeFilter != 'ALL')
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedProductFilter = null;
                          selectedTypeFilter = 'ALL';
                        });
                      },
                      icon: Icon(Icons.clear_all, size: 18),
                      label: Text('Clear Filters'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        final stocks = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: stocks.length,
          itemBuilder: (context, index) {
            final stock = stocks[index].data() as Map<String, dynamic>;
            final isStockIn = stock['type'] == 'IN';

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Transaction Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isStockIn ? inColor : outColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isStockIn ? inColor : outColor).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isStockIn ? Icons.add_circle : Icons.remove_circle,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 20),
                    
                    // Transaction Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock['product'] ?? 'Unknown Product',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          // Type and Quantity
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isStockIn 
                                ? inColor.withOpacity(0.1) 
                                : outColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${stock['type']} • Quantity: ${stock['qty']}',
                              style: TextStyle(
                                color: isStockIn ? inColor : outColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          // Date and Time
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 16, color: textSecondary),
                              SizedBox(width: 6),
                              Text(
                                _formatDateTime(stock['date']),
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          // User Info
                          if (stock['user'] != null)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: textSecondary),
                                  SizedBox(width: 6),
                                  Text(
                                    stock['user'],
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Remarks
                          if (stock['remarks'] != null && stock['remarks'].isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.note, size: 16, color: textSecondary),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        stock['remarks'],
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: textSecondary,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Quantity Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isStockIn 
                          ? inColor.withOpacity(0.1) 
                          : outColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isStockIn 
                            ? inColor.withOpacity(0.3) 
                            : outColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isStockIn ? '+' : '-'}${stock['qty']}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isStockIn ? inColor : outColor,
                            ),
                          ),
                          Text(
                            stock['type'],
                            style: TextStyle(
                              fontSize: 10,
                              color: isStockIn ? inColor : outColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterFAB() {
    return FloatingActionButton.extended(
      onPressed: _showFilterDialog,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      icon: Icon(Icons.tune),
      label: Text('Filter'),
      elevation: 4,
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    Query query = FirebaseFirestore.instance.collection('stock');

    if (selectedProductFilter != null) {
      query = query.where('product', isEqualTo: selectedProductFilter);
    }

    if (selectedTypeFilter != 'ALL') {
      query = query.where('type', isEqualTo: selectedTypeFilter);
    }

    return query.orderBy('date', descending: true).snapshots();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.filter_list, color: primaryColor, size: 24),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Filter Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Product Filter
              Text('Filter by Product', 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                )),
              SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  final products = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: selectedProductFilter,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.inventory_2, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Products', 
                          style: TextStyle(color: textSecondary)),
                      ),
                      ...products.map((doc) {
                        final product = doc.data() as Map<String, dynamic>;
                        final name = product['name']?.toString() ?? 'Unknown';
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }),
                    ],
                    onChanged: (value) => setState(() => selectedProductFilter = value),
                    isExpanded: true,
                  );
                },
              ),
              SizedBox(height: 20),
              
              // Type Filter
              Text('Filter by Transaction Type', 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                )),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedTypeFilter,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.swap_horiz, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'ALL', 
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive, size: 18, color: primaryColor),
                        SizedBox(width: 8),
                        Text('All Types'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'IN', 
                    child: Row(
                      children: [
                        Icon(Icons.add_circle, size: 18, color: inColor),
                        SizedBox(width: 8),
                        Text('Stock IN'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'OUT', 
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, size: 18, color: outColor),
                        SizedBox(width: 8),
                        Text('Stock OUT'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => selectedTypeFilter = value!),
                isExpanded: true,
              ),
              SizedBox(height: 32),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedProductFilter = null;
                        selectedTypeFilter = 'ALL';
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Clear All', style: TextStyle(color: textSecondary)),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Apply Filters', 
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }
}