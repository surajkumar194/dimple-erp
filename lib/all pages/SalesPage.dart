import 'package:flutter/material.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finished goods')),
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
              const Text('Finished goods', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              mainButton(context, 'Master Data', [
                // 'Customers Master',
                // 'General Master-1',
                // 'General Master-2',
                // 'Sales Person',
              ]),
              const SizedBox(height: 10),
              mainButton(context, 'Transaction', [
                'Inventory Received',
                'Stock Received from U1',
                'Stock received U2',
                'Stock received Shop',
             
              ]),
              const SizedBox(height: 10),
              mainButton(context, 'Inventory Issue', [
                'Sale to party',
                'Inter Unit Transfer',
                'U1',
                'U2',
                'Shop',
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => SubMenuPage(title: title, buttons: subButtons)));
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrangeAccent]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Smooth scrolling
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...buttons.map((btn) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: subButton(context, title, btn),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget subButton(BuildContext context, String mainTitle, String subTitle) {
    bool hasNext = (mainTitle == 'Masters' && (subTitle == 'General Master-1' || subTitle == 'General Master-2'));

    return InkWell(
      onTap: () {
        if (hasNext) {
          if (subTitle == 'General Master-1') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GeneralMaster1Page()));
          } else if (subTitle == 'General Master-2') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GeneralMaster2Page()));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$subTitle Clicked')));
        }
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrangeAccent]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(subTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            if (hasNext) const Icon(Icons.arrow_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class GeneralMaster1Page extends StatelessWidget {
  const GeneralMaster1Page({super.key});

  final List<String> buttons = const [
    'Additional Operation Master',
    'Cell Size (Honey Comb)',
    'Category Master',
    'Currency Master',
    'Film/Density Master',
    'Flute Type Master',
    'Industry Type Master',
    'Infrastructure (Machines) Master',
    'Ink Master',
    'Material Master',
    'Margin Master',
    'Material Category Master',
  ];

  @override
  Widget build(BuildContext context) {
    return buildSubMenu(context, 'General Master-1', buttons);
  }
}

class GeneralMaster2Page extends StatelessWidget {
  const GeneralMaster2Page({super.key});

  final List<String> buttons = const [
    'Material Group (Add. Operation only)',
    'Operation Group (Add. Operation only)',
    'Operation Master',
    'Product Style Master',
    'Printing Application Master',
    'Product Type For Folding Carton',
    'RMC Default Consumption',
    'Standard Sheet Size',
    'Wastage Master For Folding Carton',
    'UPs in Sheet Master',
    'Units Master',
    'Zone',
  ];

  @override
  Widget build(BuildContext context) {
    return buildSubMenu(context, 'General Master-2', buttons);
  }
}

Widget buildSubMenu(BuildContext context, String title, List<String> buttons) {
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...buttons.map((btn) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$btn Clicked'))),
                      child: Container(
                        width: 250,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrangeAccent]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(btn, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    ),
  );
}
