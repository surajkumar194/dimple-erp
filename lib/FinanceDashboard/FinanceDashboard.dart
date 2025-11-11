import 'package:dimple_erp/FinanceDashboard/InvoicingScreen.dart';
import 'package:flutter/material.dart';

class FinanceDashboard extends StatelessWidget {
  const FinanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildSubcategoryItem(
            context,
            'Invoicing',
            Icons.receipt_long,
            const Color(0xFF009688),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InvoicingScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Payment Tracking',
            Icons.payments,
            const Color(0xFF009688),
            () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const PaymentTrackingScreen()),
              // );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Expense Management',
            Icons.account_balance_wallet,
            const Color(0xFF009688),
            () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const ExpenseManagementScreen()),
              // );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Financial Reports',
            Icons.bar_chart,
            const Color(0xFF009688),
            () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const FinancialReportsScreen()),
              // );
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
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(Icons.arrow_forward_ios, color: color, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: Icon(icon, color: color, size: 24),
        onTap: onTap,
      ),
    );
  }
}