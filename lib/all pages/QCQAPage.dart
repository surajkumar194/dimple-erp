import 'package:flutter/material.dart';

class QCQAPage extends StatelessWidget {
  const QCQAPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QC/QA')),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue]),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QC/QA Section',
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              mainButton(context, 'Masters', [
                'FG COA Parameters',
                'Finished Goods Defects',
                'ISO Document Master',
                'Process Defect Master',
                'Process Inspection Parameters',
                'Rm-Test Group Master',
                'Shade Card master',
                'RM-Test Master',
                'SOP',
              ]),
              const SizedBox(height: 10),
              mainButton(context, 'Transactions', [
                'Customer Complaint Report',
                'FG Certificate Of Analysis',
                'Final Inspection',
                'Minutes Of Meeting',
                'Preventive Action Report',
                'Process Inspection Data Entry',
                'Quality Test Certificate',
                'RM-Test Certificate',
                'Sorting Report',
                'Vendor Complain Report',
              ]),
              const SizedBox(height: 10),
              mainButton(context, 'Reports', [
                'Process Inspection of the Day',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget mainButton(BuildContext context, String title, List<String> subButtons) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubMenuPage(title: title, buttons: subButtons),
          ),
        );
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrangeAccent]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class SubMenuPage extends StatelessWidget {
  final String title;
  final List<String> buttons;

  const SubMenuPage({super.key, required this.title, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue]),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...buttons.map((btn) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: subButton(context, btn),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget subButton(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title Clicked')));
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrangeAccent]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
