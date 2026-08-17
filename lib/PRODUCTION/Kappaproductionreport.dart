import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
class _RC {
  static const primary = Color(0xFF169a8d);
  static const darkText = Color(0xFF2C3E50);
  static const lightBg = Color(0xFFF8F9FA);
  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFE74C3C);
  static const accent = Color(0xFFFFA500);
}

const List<String> _stageIds = [
  'raw_material',
  'kappa_cutting',
  'die',
  'box_ready',
  'quality_checking',
];

const Map<String, String> _stageTitles = {
  'raw_material': 'Raw Material',
  'kappa_cutting': 'Kappa Cutting',
  'die': 'Die & Paper',
  'box_ready': 'Box Ready',
  'quality_checking': 'Quality Checking',
};

/// Ek stage-completion event
class _StageEvent {
  final String customer;
  final String company;
  final String productName;
  final String stageTitle;
  final bool done;
  final DateTime? date;

  _StageEvent({
    required this.customer,
    required this.company,
    required this.productName,
    required this.stageTitle,
    required this.done,
    required this.date,
  });
}

class KappaProductionReportScreen extends StatefulWidget {
  const KappaProductionReportScreen({super.key});

  @override
  State<KappaProductionReportScreen> createState() =>
      _KappaProductionReportScreenState();
}

class _KappaProductionReportScreenState
    extends State<KappaProductionReportScreen> {
  bool _loading = true;
  String? _error;
  List<_StageEvent> _events = [];

  /// null = "All". Otherwise 'yyyy-mm-dd'
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      final prodSnap = await FirebaseFirestore.instance
          .collection('kappaProduction')
          .get();

      final ordersById = {for (final d in ordersSnap.docs) d.id: d.data()};

      final List<_StageEvent> events = [];

      for (final doc in prodSnap.docs) {
        final data = doc.data();
        final products = data['products'] is List
            ? data['products'] as List
            : [];
        final orderData = ordersById[doc.id];
        final customer = (orderData?['customerName'] ?? 'Unknown').toString();
        final company = (orderData?['companyName'] ?? '').toString();

        for (final p in products) {
          final productName = (p['productName'] ?? 'Product').toString();
          final prod = (p['kappaProduction'] as Map?) ?? {};
          for (final sId in _stageIds) {
            final sd = prod[sId];
            final done = sd?['done'] == true;
            DateTime? dt;
            if (sd?['savedAt'] != null) {
              try {
                dt = DateTime.parse(sd['savedAt'].toString());
              } catch (_) {}
            }
            events.add(
              _StageEvent(
                customer: customer,
                company: company,
                productName: productName,
                stageTitle: _stageTitles[sId] ?? sId,
                done: done,
                date: done ? dt : null,
              ),
            );
          }
        }
      }

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  // ─── Aggregations ──────────────────────────────────────────────
  int get _totalStages => _events.length;
  int get _totalDone => _events.where((e) => e.done).length;
  int get _totalPending => _totalStages - _totalDone;

  /// Map<'yyyy-mm-dd', events done on that date>
  Map<String, List<_StageEvent>> get _byDate {
    final Map<String, List<_StageEvent>> m = {};
    for (final e in _events) {
      if (!e.done || e.date == null) continue;
      final key = _dateKey(e.date!);
      m.putIfAbsent(key, () => []).add(e);
    }
    // sabse naya event pehle
    for (final list in m.values) {
      list.sort((a, b) => b.date!.compareTo(a.date!));
    }
    return m;
  }

  String _prettyDate(String key) {
    final p = key.split('-');
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
backgroundColor: const Color.fromARGB(255, 219, 215, 215),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Colors.blue),
        ),
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset('assets/dpl.png', height: 28),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kappa Production Report',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  'Daily activity & progress',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _fetch,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _RC.primary))
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: _RC.warning)),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final byDate = _byDate;
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));
    final earlierKeys =
        byDate.keys.where((k) => k != todayKey && k != yesterdayKey).toList()
          ..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _overallStrip(),
        const SizedBox(height: 14),
        _dailyActivityCard(byDate, todayKey, yesterdayKey, earlierKeys),
        const SizedBox(height: 16),
        _resultsHeader(),
        const SizedBox(height: 10),
        _resultsList(byDate, todayKey, yesterdayKey),
      ],
    );
  }

  // ─── Overall status strip (date se independent) ───────────────
  Widget _overallStrip() {
    return Row(
      children: [
        Expanded(child: _miniStat('Total', '$_totalStages', _RC.darkText)),
        const SizedBox(width: 8),
        Expanded(child: _miniStat('Done', '$_totalDone', _RC.success)),
        const SizedBox(width: 8),
        Expanded(child: _miniStat('Pending', '$_totalPending', _RC.warning)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
      ],
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    ),
  );

  // ─── Clickable Daily Activity card ─────────────────────────────
  Widget _dailyActivityCard(
    Map<String, List<_StageEvent>> byDate,
    String todayKey,
    String yesterdayKey,
    List<String> earlierKeys,
  ) {
    final todayCount = byDate[todayKey]?.length ?? 0;
    final yesterdayCount = byDate[yesterdayKey]?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _RC.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      size: 16,
                      color: _RC.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Daily Activity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _RC.darkText,
                    ),
                  ),
                ],
              ),
              _allChip(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dayBox(
                  label: 'Today',
                  count: todayCount,
                  color: _RC.primary,
                  icon: Icons.today_rounded,
                  keyVal: todayKey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dayBox(
                  label: 'Yesterday',
                  count: yesterdayCount,
                  color: _RC.accent,
                  icon: Icons.history_rounded,
                  keyVal: yesterdayKey,
                ),
              ),
            ],
          ),
          if (earlierKeys.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Earlier',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: earlierKeys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final k = earlierKeys[i];
                  final c = byDate[k]?.length ?? 0;
                  final selected = _selectedKey == k;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedKey = k),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _RC.primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _RC.primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _prettyDate(k).substring(0, 5), // dd/mm
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : _RC.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$c',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: selected ? _RC.primary : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _allChip() {
    final selected = _selectedKey == null;
    return GestureDetector(
      onTap: () => setState(() => _selectedKey = null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? _RC.success.withOpacity(0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _RC.success : Colors.grey.shade300,
          ),
        ),
        child: Text(
          'All',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected ? _RC.success : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _dayBox({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required String keyVal,
  }) {
    final selected = _selectedKey == keyVal;
    return GestureDetector(
      onTap: () => setState(() => _selectedKey = keyVal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selected
                ? [color, color.withOpacity(0.8)]
                : [color.withOpacity(0.12), color.withOpacity(0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(selected ? 1 : 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$count stages',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Results header ─────────────────────────────────────────────
  Widget _resultsHeader() {
    String label;
    if (_selectedKey == null) {
      label = 'All Completed Stages';
    } else {
      final now = DateTime.now();
      if (_selectedKey == _dateKey(now)) {
        label = 'Today (${_prettyDate(_selectedKey!)})';
      } else if (_selectedKey ==
          _dateKey(now.subtract(const Duration(days: 1)))) {
        label = 'Yesterday (${_prettyDate(_selectedKey!)})';
      } else {
        label = _prettyDate(_selectedKey!);
      }
    }
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: _RC.darkText,
      ),
    );
  }

  // ─── Results list ────────────────────────────────────────────────
  Widget _resultsList(
    Map<String, List<_StageEvent>> byDate,
    String todayKey,
    String yesterdayKey,
  ) {
    if (_selectedKey != null) {
      final events = byDate[_selectedKey] ?? [];
      if (events.isEmpty) return _emptyResult();
      return Column(children: events.map(_eventTile).toList());
    }

    // "All" selected → date descending, har date ka apna header
    final keys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    if (keys.isEmpty) return _emptyResult();

    return Column(
      children: keys.map((k) {
        final events = byDate[k]!;
        String header = _prettyDate(k);
        if (k == todayKey) header = 'Today — $header';
        if (k == yesterdayKey) header = 'Yesterday — $header';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _RC.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$header  •  ${events.length} stages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _RC.primary,
                  ),
                ),
              ),
              ...events.map(_eventTile),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyResult() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Center(
      child: Text(
        'No stage was completed on this date',
        style: TextStyle(color: Colors.grey.shade500),
      ),
    ),
  );

  Widget _eventTile(_StageEvent e) {
    final time = e.date != null
        ? '${e.date!.hour.toString().padLeft(2, '0')}:${e.date!.minute.toString().padLeft(2, '0')}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _RC.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: _RC.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.customer,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _RC.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.productName} • ${e.stageTitle}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
