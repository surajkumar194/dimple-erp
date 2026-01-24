import 'package:dimple_erp/AdminDashboard/MigrateOrdersScreen.dart';
import 'package:flutter/material.dart';

class AdminCollectionsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> collections = [
    {
      'name': 'jobCards',
      'icon': Icons.work_outline,
      'description': 'Job cards and work records',
      'color': Colors.blue.shade600,
    },
    {
      'name': 'orders',
      'icon': Icons.shopping_cart_outlined,
      'description': 'Customer orders data',
      'color': Colors.green.shade600,
    },
    {
      'name': 'users',
      'icon': Icons.people_outline,
      'description': 'User accounts and profiles',
      'color': Colors.purple.shade600,
    },
    {
      'name': 'meta',
      'icon': Icons.settings_outlined,
      'description': 'Metadata and configuration',
      'color': Colors.orange.shade600,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Firestore Collections",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Future: Add search functionality
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            return Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminDocumentsScreen(
                        collection: collection['name'],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: collection['color'].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          collection['icon'],
                          size: 30,
                          color: collection['color'],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              collection['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              collection['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}