import 'package:flutter/material.dart';

class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Master Control Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: [
            _masterTile(
              context,
              title: 'Departments',
              icon: Icons.apartment,
              color: Colors.blue,
              onTap: () {
                // Department Master Screen
              },
            ),
            _masterTile(
              context,
              title: 'Sub Departments',
              icon: Icons.account_tree,
              color: Colors.teal,
              onTap: () {
                // Sub-department master
              },
            ),
            _masterTile(
              context,
              title: 'Quality Check',
              icon: Icons.verified,
              color: Colors.orange,
              onTap: () {
                // Quality check master
              },
            ),
            _masterTile(
              context,
              title: 'MOM',
              icon: Icons.meeting_room,
              color: Colors.indigo,
              onTap: () {
                // MOM master
              },
            ),
            _masterTile(
              context,
              title: 'Dispatch',
              icon: Icons.local_shipping,
              color: Colors.green,
              onTap: () {
                // Dispatch master
              },
            ),
            _masterTile(
              context,
              title: 'Users / Roles',
              icon: Icons.people,
              color: Colors.red,
              onTap: () {
                // User roles master
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _masterTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 46, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
