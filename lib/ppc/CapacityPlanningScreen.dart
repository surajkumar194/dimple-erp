import 'package:flutter/material.dart';

class CapacityPlanningScreen extends StatelessWidget {
  const CapacityPlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capacity Planning'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Production Capacity Overview', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildCapacityRow('Machine 1', 85),
                    const SizedBox(height: 12),
                    _buildCapacityRow('Machine 2', 70),
                    const SizedBox(height: 12),
                    _buildCapacityRow('Machine 3', 95),
                    const SizedBox(height: 12),
                    _buildCapacityRow('Machine 4', 60),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resource Utilization', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildStatRow('Total Machines', '4'),
                    _buildStatRow('Active Machines', '3'),
                    _buildStatRow('Average Utilization', '77.5%'),
                    _buildStatRow('Available Capacity', '22.5%'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityRow(String machine, int utilization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(machine, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('$utilization%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: utilization / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            utilization > 90 ? Colors.red : 
            utilization > 75 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}