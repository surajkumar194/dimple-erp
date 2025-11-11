import 'package:dimple_erp/AdminDashboard/UserManagementScreen.dart';
import 'package:flutter/material.dart';
// import 'user_management_screen.dart';
// import 'system_settings_screen.dart';
// import 'backup_restore_screen.dart';
// import 'activity_logs_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildSubcategoryItem(
            context,
            'User Management',
            Icons.people,
            const Color(0xFF607D8B),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManagementScreen()),
              );
            },
          ),
          _buildSubcategoryItem(
            context,
            'System Settings',
            Icons.settings,
            const Color(0xFF607D8B),
            () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const SystemSettingsScreen()),
              // );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Backup & Restore',
            Icons.backup,
            const Color(0xFF607D8B),
            () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
              // );
            },
          ),
          _buildSubcategoryItem(
            context,
            'Activity Logs',
            Icons.history,
            const Color(0xFF607D8B),
            () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const ActivityLogsScreen()),
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