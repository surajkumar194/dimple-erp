import 'package:dimple_erp/all%20screen/CustomerAllOrderScreen.dart';
import 'package:dimple_erp/all%20screen/DeliverySchedulingScreen.dart';
import 'package:dimple_erp/all%20screen/OrderBookingScreen.dart';
import 'package:flutter/material.dart';
// import 'order_booking_screen.dart';
// import 'customer_all_order_screen.dart';
// import 'delivery_scheduling_screen.dart';

class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildSubcategoryItem(
            context,
            'Order Booking',
            Icons.book_online,
            const Color(0xFFE91E63),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderBookingScreen(),
                ),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Customer All order',
            Icons.list_alt,
            const Color(0xFFE91E63),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerAllOrderScreen(),
                ),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Delivery Scheduling',
            Icons.local_shipping,
            const Color(0xFFE91E63),
     //    isSelected: true,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  DeliverySchedulingScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color, [
    VoidCallback? onTap,
    bool isSelected = false,
  ]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.arrow_forward_ios,
          color: color,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : Colors.black87,
          ),
        ),
        trailing: Icon(
          icon,
          color: color,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }
}