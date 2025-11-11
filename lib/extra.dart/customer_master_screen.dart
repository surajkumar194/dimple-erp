import 'package:flutter/material.dart';

class CustomerMasterScreen extends StatelessWidget {
  const CustomerMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Master')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Industry Type')),
            DataColumn(label: Text('Buyer Group Id')),
            DataColumn(label: Text('Buyer Name')),
            DataColumn(label: Text('Country')),
            DataColumn(label: Text('State')),
            DataColumn(label: Text('State Code')),
            DataColumn(label: Text('Report')),
            DataColumn(label: Text('Billing')),
            DataColumn(label: Text('Shipping')),
            DataColumn(label: Text('Action')),
          ],
          rows: [
            DataRow(cells: [
              DataCell(Text('HOSIERY')),
              DataCell(Text('JALANDHAR DISPOSAL KHAJUWALA')),
              DataCell(Text('JALANDHAR DISPOSAL KHAJUWALA')),
              DataCell(Text('India')),
              DataCell(Text('Punjab')),
              DataCell(Text('03')),
              DataCell(Text('Report')),
              DataCell(Text('Add New')),
              DataCell(Text('Add New')),
              DataCell(Icon(Icons.edit)),
            ]),
          ],
        ),
      ),
    );
  }
}
