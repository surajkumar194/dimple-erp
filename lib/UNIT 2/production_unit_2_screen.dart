import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _AppColors {
  static const darkGreen = Color(0xFF0A3D1F);
  static const midGreen = Color(0xFF1B6B3A);
  static const accentGreen = Color(0xFF2E9E55);
  static const lightGreen = Color(0xFF4CAF50);
  static const bgGreen = Color(0xFFF0F7F2);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF0D2B1A);
  static const textMid = Color(0xFF3D6B52);
  static const textLight = Color(0xFF8BA899);
  static const blue = Color(0xFF1565C0);
  static const orange = Color(0xFFE65100);
  static const red = Color(0xFFC62828);
  static const purple = Color(0xFF6A1B9A);
}

class _BoxSizeData {
  final int topL, topW, topH;
  final int botL, botW, botH;
  const _BoxSizeData({
    required this.topL,
    required this.topW,
    required this.topH,
    required this.botL,
    required this.botW,
    required this.botH,
  });
}

const Map<String, _BoxSizeData> _boxSizeTable = {
  '250G MM': _BoxSizeData(
    topL: 137,
    topW: 110,
    topH: 23,
    botL: 133,
    botW: 106,
    botH: 37,
  ),
  '500G MM': _BoxSizeData(
    topL: 178,
    topW: 143,
    topH: 28,
    botL: 174,
    botW: 139,
    botH: 40,
  ),
  '1KG MM': _BoxSizeData(
    topL: 254,
    topW: 176,
    topH: 25,
    botL: 249,
    botW: 173,
    botH: 46,
  ),
  '1KG AAM SZIE': _BoxSizeData(
    topL: 249,
    topW: 174,
    topH: 25,
    botL: 244,
    botW: 170,
    botH: 40,
  ),
  '1KG AAM SIZE': _BoxSizeData(
    topL: 249,
    topW: 174,
    topH: 25,
    botL: 244,
    botW: 170,
    botH: 40,
  ),
  'HR SIZE': _BoxSizeData(
    topL: 312,
    topW: 183,
    topH: 35,
    botL: 307,
    botW: 178,
    botH: 35,
  ),
  'NEW HR SIZE': _BoxSizeData(
    topL: 350,
    topW: 220,
    topH: 36,
    botL: 345,
    botW: 215,
    botH: 40,
  ),
  'LSPT': _BoxSizeData(
    topL: 265,
    topW: 192,
    topH: 25,
    botL: 261,
    botW: 188,
    botH: 38,
  ),
  '500G KAJU KATLI': _BoxSizeData(
    topL: 239,
    topW: 162,
    topH: 24,
    botL: 234,
    botW: 157,
    botH: 27,
  ),
  '1KG KAJU KATLI': _BoxSizeData(
    topL: 305,
    topW: 204,
    topH: 32,
    botL: 300,
    botW: 199,
    botH: 34,
  ),
  '1KG JUMBO KAJU': _BoxSizeData(
    topL: 339,
    topW: 244,
    topH: 22,
    botL: 335,
    botW: 240,
    botH: 31,
  ),
  '500G BENGLUR SIZE': _BoxSizeData(
    topL: 217,
    topW: 156,
    topH: 25,
    botL: 212,
    botW: 152,
    botH: 39,
  ),
  '6X6': _BoxSizeData(
    topL: 160,
    topW: 160,
    topH: 25,
    botL: 154,
    botW: 154,
    botH: 35,
  ),
  '8X8 BAJAJ': _BoxSizeData(
    topL: 207,
    topW: 207,
    topH: 28,
    botL: 202,
    botW: 202,
    botH: 42,
  ),
  '9X9': _BoxSizeData(
    topL: 233,
    topW: 233,
    topH: 25,
    botL: 229,
    botW: 229,
    botH: 36,
  ),
  '11X11': _BoxSizeData(
    topL: 272,
    topW: 272,
    topH: 25,
    botL: 268,
    botW: 268,
    botH: 50,
  ),
  '12X12': _BoxSizeData(
    topL: 304,
    topW: 304,
    topH: 27,
    botL: 300,
    botW: 300,
    botH: 51,
  ),
  'HARIBHOG': _BoxSizeData(
    topL: 348,
    topW: 272,
    topH: 25,
    botL: 343,
    botW: 267,
    botH: 52,
  ),
  '14X14': _BoxSizeData(
    topL: 356,
    topW: 357,
    topH: 25,
    botL: 351,
    botW: 351,
    botH: 50,
  ),
  '20 LADDO': _BoxSizeData(
    topL: 276,
    topW: 207,
    topH: 40,
    botL: 272,
    botW: 203,
    botH: 45,
  ),
  '24 LADDO': _BoxSizeData(
    topL: 311,
    topW: 200,
    topH: 42,
    botL: 305,
    botW: 195,
    botH: 45,
  ),
  '20 LADDO JUMBO': _BoxSizeData(
    topL: 319,
    topW: 251,
    topH: 40,
    botL: 315,
    botW: 246,
    botH: 53,
  ),
  '500G CANADA': _BoxSizeData(
    topL: 205,
    topW: 135,
    topH: 38,
    botL: 200,
    botW: 131,
    botH: 42,
  ),
  '1KG CANADA': _BoxSizeData(
    topL: 243,
    topW: 166,
    topH: 39,
    botL: 240,
    botW: 163,
    botH: 46,
  ),
  '500G GANGAOUR': _BoxSizeData(
    topL: 178,
    topW: 131,
    topH: 25,
    botL: 174,
    botW: 127,
    botH: 32,
  ),
  'AMRITSHARI': _BoxSizeData(
    topL: 288,
    topW: 176,
    topH: 30,
    botL: 284,
    botW: 171,
    botH: 39,
  ),
  '10 CAVITY TIP TOP': _BoxSizeData(
    topL: 260,
    topW: 121,
    topH: 29,
    botL: 255,
    botW: 161,
    botH: 55,
  ),
  '250G KAJU KATLI TIP TOP': _BoxSizeData(
    topL: 225,
    topW: 127,
    topH: 22,
    botL: 220,
    botW: 122,
    botH: 25,
  ),
  '1KG MARBLE': _BoxSizeData(
    topL: 277,
    topW: 172,
    topH: 36,
    botL: 272,
    botW: 167,
    botH: 38,
  ),
  '12 LADDO': _BoxSizeData(
    topL: 198,
    topW: 155,
    topH: 37,
    botL: 195,
    botW: 151,
    botH: 40,
  ),
  'MEBSTO DABBI': _BoxSizeData(
    topL: 62,
    topW: 62,
    topH: 49,
    botL: 59,
    botW: 59,
    botH: 62,
  ),
  'MEBSTO OUTER': _BoxSizeData(
    topL: 329,
    topW: 137,
    topH: 57,
    botL: 325,
    botW: 134,
    botH: 70,
  ),
  '1 LADDO': _BoxSizeData(
    topL: 106,
    topW: 106,
    topH: 16,
    botL: 101,
    botW: 101,
    botH: 67,
  ),
  '2 LADDO': _BoxSizeData(
    topL: 189,
    topW: 106,
    topH: 19,
    botL: 185,
    botW: 101,
    botH: 67,
  ),
  '4 LADDO': _BoxSizeData(
    topL: 199,
    topW: 199,
    topH: 21,
    botL: 194,
    botW: 194,
    botH: 67,
  ),
  '6 LADDO': _BoxSizeData(
    topL: 163,
    topW: 133,
    topH: 32,
    botL: 158,
    botW: 128,
    botH: 40,
  ),
  '250G ITC': _BoxSizeData(
    topL: 40,
    topW: 132,
    topH: 30,
    botL: 161,
    botW: 128,
    botH: 40,
  ),
  '500G ITC': _BoxSizeData(
    topL: 222,
    topW: 159,
    topH: 31,
    botL: 218,
    botW: 155,
    botH: 35,
  ),
  '16 BITE': _BoxSizeData(
    topL: 190,
    topW: 190,
    topH: 35,
    botL: 186,
    botW: 186,
    botH: 70,
  ),
  '49 BITE': _BoxSizeData(
    topL: 329,
    topW: 329,
    topH: 30,
    botL: 324,
    botW: 324,
    botH: 35,
  ),
  '500G GUJIYA': _BoxSizeData(
    topL: 202,
    topW: 192,
    topH: 25,
    botL: 197,
    botW: 187,
    botH: 50,
  ),
  '1KG GUJIYA': _BoxSizeData(
    topL: 317,
    topW: 194,
    topH: 25,
    botL: 313,
    botW: 191,
    botH: 47,
  ),
  '1KG MAKHAN BARA': _BoxSizeData(
    topL: 231,
    topW: 198,
    topH: 38,
    botL: 226,
    botW: 194,
    botH: 58,
  ),
  '500G MAKHAN BARA': _BoxSizeData(
    topL: 182,
    topW: 151,
    topH: 38,
    botL: 178,
    botW: 147,
    botH: 60,
  ),
  '250G AHUJA SPL': _BoxSizeData(
    topL: 185,
    topW: 124,
    topH: 26,
    botL: 183,
    botW: 119,
    botH: 64,
  ),
  '500G GUJRAT SIZE': _BoxSizeData(
    topL: 240,
    topW: 141,
    topH: 36,
    botL: 235,
    botW: 137,
    botH: 41,
  ),
  '500G PAKPATTNIAN': _BoxSizeData(
    topL: 235,
    topW: 157,
    topH: 35,
    botL: 230,
    botW: 152,
    botH: 45,
  ),
  '20 CAVITY TIP TOP': _BoxSizeData(
    topL: 260,
    topW: 215,
    topH: 29,
    botL: 255,
    botW: 210,
    botH: 55,
  ),
  'SARTAJ MARBLE': _BoxSizeData(
    topL: 276,
    topW: 173,
    topH: 35,
    botL: 271,
    botW: 168,
    botH: 35,
  ),
  '500G BOMBAY SIZE': _BoxSizeData(
    topL: 208,
    topW: 176,
    topH: 20,
    botL: 203,
    botW: 171,
    botH: 38,
  ),
  '6X6 PRASHANT': _BoxSizeData(
    topL: 160,
    topW: 160,
    topH: 22,
    botL: 155,
    botW: 155,
    botH: 36,
  ),
  '9X9 SARTAJ': _BoxSizeData(
    topL: 234,
    topW: 234,
    topH: 49,
    botL: 230,
    botW: 230,
    botH: 70,
  ),
  '20 CAVITY UTTAM': _BoxSizeData(
    topL: 261,
    topW: 215,
    topH: 54,
    botL: 256,
    botW: 210,
    botH: 64,
  ),
  '10 CAVITY UTTAM': _BoxSizeData(
    topL: 262,
    topW: 123,
    topH: 54,
    botL: 257,
    botW: 119,
    botH: 64,
  ),
  '6.5X6.5 CLASSIC': _BoxSizeData(
    topL: 172,
    topW: 172,
    topH: 32,
    botL: 168,
    botW: 168,
    botH: 40,
  ),
  'LOVELEY SIZE': _BoxSizeData(
    topL: 295,
    topW: 225,
    topH: 29,
    botL: 290,
    botW: 220,
    botH: 39,
  ),
  '7X7 GOPAL': _BoxSizeData(
    topL: 186,
    topW: 186,
    topH: 24,
    botL: 181,
    botW: 181,
    botH: 30,
  ),
  '9X9X3 (25 CAVITY)': _BoxSizeData(
    topL: 246,
    topW: 246,
    topH: 35,
    botL: 241,
    botW: 241,
    botH: 70,
  ),
  '9X9 (4KHANA)': _BoxSizeData(
    topL: 233,
    topW: 233,
    topH: 32,
    botL: 228,
    botW: 228,
    botH: 50,
  ),
  '7X10': _BoxSizeData(
    topL: 260,
    topW: 187,
    topH: 45,
    botL: 255,
    botW: 182,
    botH: 65,
  ),
  '9X9 LOVELEY': _BoxSizeData(
    topL: 236,
    topW: 236,
    topH: 36,
    botL: 232,
    botW: 232,
    botH: 55,
  ),
  '500G SHAGUN KAJU': _BoxSizeData(
    topL: 270,
    topW: 150,
    topH: 25,
    botL: 265,
    botW: 145,
    botH: 35,
  ),
  '35 CAVITY NEW (DT)': _BoxSizeData(
    topL: 334,
    topW: 243,
    topH: 20,
    botL: 328,
    botW: 238,
    botH: 45,
  ),
  '12 CAVITY KHOLI (PARDEEP)': _BoxSizeData(
    topL: 195,
    topW: 151,
    topH: 36,
    botL: 190,
    botW: 147,
    botH: 70,
  ),
  '8X8 RAJDHANI': _BoxSizeData(
    topL: 207,
    topW: 207,
    topH: 25,
    botL: 203,
    botW: 203,
    botH: 39,
  ),
  '7X7 RAJDHANI': _BoxSizeData(
    topL: 175,
    topW: 175,
    topH: 25,
    botL: 171,
    botW: 171,
    botH: 39,
  ),
  '250GM MUMBAI SIZE': _BoxSizeData(
    topL: 141,
    topW: 141,
    topH: 20,
    botL: 137,
    botW: 137,
    botH: 38,
  ),
  'LSPT JHODPUR': _BoxSizeData(
    topL: 0,
    topW: 0,
    topH: 0,
    botL: 264,
    botW: 185,
    botH: 43,
  ),
  '500G SPL SIZE': _BoxSizeData(
    topL: 0,
    topW: 0,
    topH: 0,
    botL: 210,
    botW: 150,
    botH: 39,
  ),
};

/// Returns matched size data or null.  Matching is case-insensitive + trims spaces.
_BoxSizeData? _lookupSize(String name) {
  final key = name.trim().toUpperCase();
  if (_boxSizeTable.containsKey(key)) return _boxSizeTable[key];
  // fuzzy: try contains match
  for (final entry in _boxSizeTable.entries) {
    if (entry.key.contains(key) || key.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}

class ProductionUnit2Screen extends StatefulWidget {
  const ProductionUnit2Screen({super.key});
  @override
  State<ProductionUnit2Screen> createState() => _ProductionUnit2ScreenState();
}

class _ProductionUnit2ScreenState extends State<ProductionUnit2Screen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade600,
                  Colors.blue.shade600,
                  Colors.teal.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset('assets/dpl.png', height: 36),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Unit 2 — Job Cards',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage Job Cards for Unit 2',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _searchQuery = v.toLowerCase().trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('unit2JobCards')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingState();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildBody([]);
                }
                final validDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _filterRigidBoxProducts(data['products']).isNotEmpty;
                }).toList();

                final filteredDocs = validDocs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final products = _filterRigidBoxProducts(data['products']);
                  return products.any((p) {
                    final name = (p['productName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final customer = (data['customerName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final length = (p['length'] ?? '').toString().toLowerCase();
                    final height = (p['height'] ?? '').toString().toLowerCase();
                    final width = (p['width'] ?? '').toString().toLowerCase();
                    final size = '$length $height $width';
                    return name.contains(_searchQuery) ||
                        customer.contains(_searchQuery) ||
                        size.contains(_searchQuery);
                  });
                }).toList();

                return _buildBody(filteredDocs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<QueryDocumentSnapshot> allDocs) {
    final sorted = List<QueryDocumentSnapshot>.from(allDocs);
    sorted.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['createdAt'] as Timestamp?;
      final bTime = bData['createdAt'] as Timestamp?;
      return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
        aTime?.millisecondsSinceEpoch ?? 0,
      );
    });

    return sorted.isEmpty
        ? const _EmptyState()
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final doc = sorted[index];
              return _OrderCard(
                serialNumber: sorted.length - index,
                docId: doc.id,
                data: doc.data() as Map<String, dynamic>,
              );
            },
          );
  }
}

List<Map<String, dynamic>> _filterRigidBoxProducts(dynamic rawProducts) {
  List<Map<String, dynamic>> products = [];
  if (rawProducts is List) {
    products = rawProducts.map((e) => Map<String, dynamic>.from(e)).toList();
  } else if (rawProducts is Map) {
    products = [Map<String, dynamic>.from(rawProducts)];
  }
  return products.where((p) {
    final cat = (p['productCategory'] ?? '').toString().trim().toLowerCase();
    return cat.contains('rigid box');
  }).toList();
}

String _formatDate(dynamic ts) {
  if (ts is Timestamp) {
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
  return 'N/A';
}

// ══════════════════════════════════════════════════
//  LOADING / EMPTY STATES
// ══════════════════════════════════════════════════
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _AppColors.midGreen.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: _AppColors.midGreen,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Orders...',
            style: TextStyle(
              color: _AppColors.textMid,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _AppColors.midGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: _AppColors.midGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Orders Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending job cards.',
            style: TextStyle(fontSize: 14, color: _AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  ORDER CARD
// ══════════════════════════════════════════════════
class _OrderCard extends StatelessWidget {
  final int serialNumber;
  final String docId;
  final Map<String, dynamic> data;

  const _OrderCard({
    required this.serialNumber,
    required this.docId,
    required this.data,
  });

  List<Map<String, dynamic>> _extractProducts() =>
      _filterRigidBoxProducts(data['products']);

  @override
  Widget build(BuildContext context) {
    final status = data['productionStatus'] ?? 'Pending';
    final products = _extractProducts();
    if (products.isEmpty) return const SizedBox.shrink();

    // ════════════════════════════════════════════
    // 🔥 KEY CHANGE: We use StreamBuilder to get
    // ALL existing job cards for this order, then
    // filter out products that already have one.
    // ════════════════════════════════════════════
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('unit2ProductJobCards')
          .where('orderId', isEqualTo: docId)
          .snapshots(),
      builder: (context, jcSnap) {
        // Build a set of product indices that already have a job card
        final Set<int> createdIndices = {};
        if (jcSnap.hasData) {
          for (final doc in jcSnap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final idx = d['productIndex'];
            if (idx != null) createdIndices.add(idx as int);
          }
        }

        // Filter products: only show those WITHOUT a job card
        final pendingProducts = products.asMap().entries.where((entry) {
          return !createdIndices.contains(entry.key);
        }).toList();

        // If ALL products of this order have job cards → hide this card entirely
        if (pendingProducts.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: _AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _AppColors.midGreen.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(data, status, pendingProducts.length),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0xFFEEF2EE),
              ),
              _buildProductsSection(pendingProducts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data, String status, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _AppColors.darkGreen,
            _AppColors.midGreen,
            _AppColors.accentGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Center(
                  child: Text(
                    '#$serialNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.domain, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['companyName'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data['customerName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderChip(
                icon: Icons.inventory_2_outlined,
                text: '$count Pending',
              ),
              const SizedBox(width: 8),
              _PriorityChip(priority: data['priority']?.toString() ?? 'Normal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(
    List<MapEntry<int, Map<String, dynamic>>> pendingProducts,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _AppColors.midGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Rigid Box Products',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              _UnitBadge(),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.darkGreen, _AppColors.accentGreen],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pendingProducts.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pendingProducts.map(
            (entry) => _ProductTile(
              product: entry.value,
              index: entry.key, // original index in full products list
              displayIndex: pendingProducts.indexOf(
                entry,
              ), // for display numbering
              jobCardDocId: '${docId}_${entry.key}',
              orderDocId: docId,
              orderData: data,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  PRODUCT TILE
// ══════════════════════════════════════════════════
class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final int index; // real index in full products array
  final int displayIndex; // just for tile numbering UI
  final String jobCardDocId;
  final String orderDocId;
  final Map<String, dynamic> orderData;

  const _ProductTile({
    required this.product,
    required this.index,
    required this.displayIndex,
    required this.jobCardDocId,
    required this.orderDocId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final sections = product['sections'] as Map<String, dynamic>? ?? {};
    final extras = product['customExtraSections'] as List? ?? [];
    final productName = product['productName'] ?? 'Product ${displayIndex + 1}';
    final quantity = product['quantity'] ?? 0;
    final length = product['length']?.toString() ?? '';
    final height = product['height']?.toString() ?? '';
    final width = product['width']?.toString() ?? '';
    final hasDimensions =
        length.isNotEmpty || height.isNotEmpty || width.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.darkGreen, _AppColors.accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    '${displayIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _AppColors.textDark,
                      ),
                    ),
                    if (hasDimensions)
                      Row(
                        children: [
                          const Icon(
                            Icons.straighten_outlined,
                            size: 11,
                            color: _AppColors.textLight,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$length × $height × $width',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _AppColors.darkGreen.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _AppColors.midGreen.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  'Qty: $quantity',
                  style: const TextStyle(
                    color: _AppColors.darkGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),
            _ProductDetailsGrid(product: product),
            if (sections.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionBlock(
                title: 'Packaging Sections',
                color: _AppColors.blue,
                icon: Icons.layers_outlined,
                children: sections.entries
                    .map(
                      (e) => _InfoRow(label: e.key, value: e.value.toString()),
                    )
                    .toList(),
              ),
            ],
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 10),
              _SectionBlock(
                title: 'Extra Sections',
                color: _AppColors.orange,
                icon: Icons.add_box_outlined,
                children: extras
                    .map(
                      (e) => _InfoRow(
                        label: e['title'] ?? '',
                        value: 'Qty: ${e['qty']}  |  ₹${e['price']}',
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            _CreateJobCardButton(
              jobCardDocId: jobCardDocId,
              orderDocId: orderDocId,
              orderData: orderData,
              product: product,
              productIndex: index,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  PRODUCT DETAILS GRID
// ══════════════════════════════════════════════════
class _ProductDetailsGrid extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductDetailsGrid({required this.product});

  @override
  Widget build(BuildContext context) {
    final category = product['productCategory']?.toString() ?? '';
    final remarks = product['remarks']?.toString() ?? '';
    final length = product['length']?.toString() ?? '';
    final height = product['height']?.toString() ?? '';
    final width = product['width']?.toString() ?? '';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (category.isNotEmpty)
          _DetailPill(
            label: 'Category',
            value: category,
            icon: Icons.category_outlined,
          ),
        if (length.isNotEmpty)
          _DetailPill(
            label: 'L×H×W',
            value: '$length×$height×$width',
            icon: Icons.straighten_outlined,
          ),
        if (remarks.isNotEmpty)
          _DetailPill(
            label: 'Remarks',
            value: remarks,
            icon: Icons.notes_outlined,
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
//  CREATE JOB CARD BUTTON
// ══════════════════════════════════════════════════
class _CreateJobCardButton extends StatefulWidget {
  final String jobCardDocId;
  final String orderDocId;
  final Map<String, dynamic> orderData;
  final Map<String, dynamic> product;
  final int productIndex;

  const _CreateJobCardButton({
    required this.jobCardDocId,
    required this.orderDocId,
    required this.orderData,
    required this.product,
    required this.productIndex,
  });

  @override
  State<_CreateJobCardButton> createState() => _CreateJobCardButtonState();
}

class _CreateJobCardButtonState extends State<_CreateJobCardButton> {
  bool _isSubmitting = false;

  void _openJobCardForm(BuildContext context) {
    // ── Pre-fill size field with product name ──
    final sizeController = TextEditingController(
      text: widget.product['productName'] ?? '',
    );

    // ── Try auto-lookup on the product name ──
    final initialData = _lookupSize(widget.product['productName'] ?? '');

    String topText = initialData != null && initialData.topL > 0
        ? '${initialData.topL} × ${initialData.topW} × ${initialData.topH}'
        : '';
    String bottomText = initialData != null
        ? '${initialData.botL} × ${initialData.botW} × ${initialData.botH}'
        : '';

    final topSizeController = TextEditingController(text: topText);
    final bottomSizeController = TextEditingController(text: bottomText);
    bool autoFilled = initialData != null;

    String selectedTray = 'SBS';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            // ── Auto-fill when size name field changes ──
            void onSizeChanged(String val) {
              final found = _lookupSize(val);
              if (found != null) {
                setSheetState(() {
                  autoFilled = true;
                  topSizeController.text = found.topL > 0
                      ? '${found.topL} × ${found.topW} × ${found.topH}'
                      : 'TOP FOLDING';
                  bottomSizeController.text =
                      '${found.botL} × ${found.botW} × ${found.botH}';
                });
              } else {
                if (autoFilled) {
                  setSheetState(() {
                    autoFilled = false;
                  });
                }
              }
            }

            sizeController.addListener(
              () => onSizeChanged(sizeController.text),
            );

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                top: 30,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _AppColors.midGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_add,
                            color: _AppColors.midGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create Job Card',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Unit 2 — ${widget.product['productName'] ?? 'Rigid Box'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Size Name (triggers auto-fill + A-Z dropdown) ──
                    _SizeNameField(
                      controller: sizeController,
                      onChanged: onSizeChanged,
                      autoFilled: autoFilled,
                    ),
                    const SizedBox(height: 8),

                    // ── Auto-fill banner ──
                    if (autoFilled)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _AppColors.lightGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _AppColors.lightGreen.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: _AppColors.midGreen,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Size auto-filled from lookup table ✓',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _AppColors.midGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    _FormSection(
                      title: 'Top Part',
                      icon: Icons.vertical_align_top_rounded,
                      color: _AppColors.blue,
                      sizeController: topSizeController,
                    ),
                    const SizedBox(height: 8),
                    _FormSection(
                      title: 'Bottom Part',
                      icon: Icons.vertical_align_bottom_rounded,
                      color: _AppColors.orange,
                      sizeController: bottomSizeController,
                    ),
                    const SizedBox(height: 8),
                    _TrayDropdown(
                      selectedTray: selectedTray,
                      onChanged: (val) =>
                          setSheetState(() => selectedTray = val!),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (sizeController.text.trim().isEmpty ||
                                    topSizeController.text.trim().isEmpty ||
                                    bottomSizeController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    _snackBar(
                                      '⚠️ All fields are required!',
                                      Colors.red.shade700,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.of(
                                  sheetContext,
                                  rootNavigator: true,
                                ).pop();
                                await _createJobCard(
                                  context,
                                  size: sizeController.text.trim(),
                                  topSize: topSizeController.text.trim(),
                                  traySize: selectedTray,
                                  bottomSize: bottomSizeController.text.trim(),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubmitting
                              ? Colors.grey
                              : _AppColors.midGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_turned_in_outlined,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Generate Job Card',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
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

  Future<void> _createJobCard(
    BuildContext context, {
    required String size,
    required String topSize,
    required String traySize,
    required String bottomSize,
  }) async {
    if (_isSubmitting) return;
    if (mounted) setState(() => _isSubmitting = true);

    try {
      final jobCardRef = FirebaseFirestore.instance.collection(
        'unit2ProductJobCards',
      );

      final existingDoc = await jobCardRef.doc(widget.jobCardDocId).get();
      if (existingDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _snackBar(
              '⚠️ Job Card already exists for this product',
              Colors.orange,
            ),
          );
        }
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }

      // Auto-increment job card number
      final snapshot = await jobCardRef
          .orderBy('jobCardNumber', descending: true)
          .limit(1)
          .get();

      int lastNumber = 0;
      if (snapshot.docs.isNotEmpty) {
        final lastCode =
            snapshot.docs.first.data()['jobCardNumber'] ?? 'DPL-HSP-00';
        lastNumber = int.tryParse(lastCode.split('-').last) ?? 0;
      }
      lastNumber++;

      final jobCardNumber = 'DPL-HSP-${lastNumber.toString().padLeft(2, '0')}';

      await jobCardRef.doc(widget.jobCardDocId).set({
        'jobCardNumber': jobCardNumber,
        'orderId': widget.orderDocId,
        'productIndex': widget.productIndex,
        'customerName': widget.orderData['customerName'] ?? '',
        'companyName': widget.orderData['companyName'] ?? '',
        'salesPerson': widget.orderData['salesPerson'] ?? '',
        'dispatchDate': widget.orderData['deliveryDate'],
        'productionUnit': 'Unit 2',
        'createdDate': Timestamp.now(),
        'status': 'Pending',
        'product': widget.product,
        'parts': {
          'size': {'size': size},
          'topPart': {'size': topSize},
          'bottomPart': {'size': bottomSize},
          'tray': {'size': traySize},
        },
        'inventoryUsed': {},
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save product defaults
      await FirebaseFirestore.instance
          .collection('productDefaults')
          .doc(
            "${widget.product['productName']}_${widget.product['length']}_${widget.product['height']}_${widget.product['width']}",
          )
          .set({
            'productName': widget.product['productName'],
            'topPart': topSize,
            'bottomPart': bottomSize,
            'tray': traySize,
          }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('✅ Job Card Created: $jobCardNumber', _AppColors.midGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_snackBar('❌ Error: ${e.toString()}', Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  SnackBar _snackBar(String msg, Color color) => SnackBar(
    content: Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : () => _openJobCardForm(context),
        icon: const Icon(Icons.assignment_add, size: 20),
        label: const Text(
          'Create Job Card',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  SIZE NAME FIELD (with A-Z dropdown + autocomplete)
// ══════════════════════════════════════════════════
class _SizeNameField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final bool autoFilled;

  const _SizeNameField({
    required this.controller,
    required this.onChanged,
    required this.autoFilled,
  });

  @override
  State<_SizeNameField> createState() => _SizeNameFieldState();
}

class _SizeNameFieldState extends State<_SizeNameField> {
  List<String> _suggestions = [];

  // ── Sorted A-Z list of all size names ──
  List<String> get _allSizesSorted {
    final keys = _boxSizeTable.keys.toList();
    keys.sort((a, b) => a.compareTo(b));
    return keys;
  }

  void _updateSuggestions(String val) {
    final query = val.trim().toUpperCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final matches = _allSizesSorted
        .where((k) => k.contains(query))
        .take(6)
        .toList();
    setState(() => _suggestions = matches);
  }

  void _selectSize(String size) {
    widget.controller.text = size;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: size.length),
    );
    widget.onChanged(size);
    setState(() => _suggestions = []);
  }

  // ── Opens full A-Z dropdown list in a bottom sheet ──
  void _openAllSizesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        List<String> filtered = _allSizesSorted;
        final searchCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.list_alt_rounded,
                            color: _AppColors.midGreen,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'All Sizes (A-Z)',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${filtered.length} sizes',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search size name...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        onChanged: (v) {
                          final q = v.trim().toUpperCase();
                          setSheetState(() {
                            filtered = q.isEmpty
                                ? _allSizesSorted
                                : _allSizesSorted
                                      .where((k) => k.contains(q))
                                      .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final sizeName = filtered[index];
                            final data = _boxSizeTable[sizeName]!;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              leading: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _AppColors.midGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  sizeName.isNotEmpty ? sizeName[0] : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _AppColors.midGreen,
                                  ),
                                ),
                              ),
                              title: Text(
                                sizeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _AppColors.textDark,
                                ),
                              ),
                              subtitle: Text(
                                'Top: ${data.topL}×${data.topW}×${data.topH}   '
                                'Bottom: ${data.botL}×${data.botW}×${data.botH}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _AppColors.textLight,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: _AppColors.textLight,
                              ),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _selectSize(sizeName);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 233, 31, 13).withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color.fromARGB(255, 233, 31, 13).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        233,
                        31,
                        13,
                      ).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.swap_horizontal_circle_sharp,
                      size: 16,
                      color: Color.fromARGB(255, 233, 31, 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Size Name',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color.fromARGB(255, 233, 31, 13),
                    ),
                  ),
                  const Spacer(),
                  if (widget.autoFilled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _AppColors.lightGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: _AppColors.midGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Auto-filled',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _AppColors.midGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.textDark,
                      ),
                      onChanged: (v) {
                        widget.onChanged(v);
                        _updateSuggestions(v);
                      },
                      decoration: InputDecoration(
                        labelText: 'Enter size name (e.g. 1KG MM)',
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: const Color.fromARGB(
                            255,
                            233,
                            31,
                            13,
                          ).withOpacity(0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 16,
                          color: const Color.fromARGB(
                            255,
                            233,
                            31,
                            13,
                          ).withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: const Color.fromARGB(
                              255,
                              233,
                              31,
                              13,
                            ).withOpacity(0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 233, 31, 13),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ── Dropdown button: opens full A-Z list of all sizes ──
                  GestureDetector(
                    onTap: () => _openAllSizesSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _AppColors.midGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_drop_down_circle_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Suggestion chips (A-Z filtered, as-you-type) ──
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggestions:',
                  style: TextStyle(
                    fontSize: 11,
                    color: _AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _suggestions
                      .map(
                        (s) => GestureDetector(
                          onTap: () => _selectSize(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _AppColors.midGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _AppColors.midGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _AppColors.darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
//  TRAY DROPDOWN
// ══════════════════════════════════════════════════
class _TrayDropdown extends StatelessWidget {
  final String selectedTray;
  final Function(String?) onChanged;

  const _TrayDropdown({required this.selectedTray, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AppColors.purple.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _AppColors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_rows_outlined,
                  size: 16,
                  color: _AppColors.purple,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tray',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedTray,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'SBS', child: Text('SBS')),
              DropdownMenuItem(value: 'Golden', child: Text('Golden')),
              DropdownMenuItem(value: 'Plastic', child: Text('Plastic')),
              DropdownMenuItem(value: 'N/A', child: Text('N/A')),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  FORM SECTION
// ══════════════════════════════════════════════════
class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final TextEditingController sizeController;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.sizeController,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StyledTextField(
            controller: sizeController,
            label: 'Size (L × W × H)',
            icon: Icons.straighten_outlined,
            color: color,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  STYLED TEXT FIELD
// ══════════════════════════════════════════════════
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _AppColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
        prefixIcon: Icon(icon, size: 16, color: color.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  SMALL WIDGETS
// ══════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'Completed':
        return const Color(0xFF2E7D32);
      case 'In Progress':
        return _AppColors.orange;
      default:
        return _AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip({required this.priority});

  Color get _color {
    final p = priority.toLowerCase();
    if (p.contains('high') || p.contains('urgent')) return _AppColors.red;
    if (p.contains('medium')) return _AppColors.orange;
    return _AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeaderChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _AppColors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.blue.withOpacity(0.35)),
      ),
      child: const Text(
        'Unit 2',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _AppColors.blue,
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _AppColors.bgGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E8DA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _AppColors.midGreen),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: _AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: _AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<Widget> children;

  const _SectionBlock({
    required this.title,
    required this.color,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
