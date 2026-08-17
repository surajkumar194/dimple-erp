import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class IssueFullHistoryScreen extends StatefulWidget {
  const IssueFullHistoryScreen({super.key});

  @override
  State<IssueFullHistoryScreen> createState() => _IssueFullHistoryScreenState();
}

class _IssueFullHistoryScreenState extends State<IssueFullHistoryScreen>
    with SingleTickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────
  String _searchQuery = '';
  _DateFilter _selectedFilter = _DateFilter.all;
  late final TextEditingController _searchCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Date boundary helper ─────────────────────────────────────
  DateTime? get _fromDate {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case _DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case _DateFilter.twoDays:
        return now.subtract(const Duration(days: 2));
      case _DateFilter.oneWeek:
        return now.subtract(const Duration(days: 7));
      case _DateFilter.all:
        return null;
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchAndFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              // Back button
              _GlassButton(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              // Logo
              _GlassButton(
                padding: const EdgeInsets.all(6),
                child: Image.asset('assets/dpl.png', height: 32,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: 28)),
              ),
              const SizedBox(width: 12),
              // Title
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Issue History',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3)),
                    SizedBox(height: 2),
                    Text('Stock issue records & details',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              // Stats badge
              _GlassButton(
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search + Filter bar ──────────────────────────────────────
  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      child: Column(
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by item name…',
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.indigo.shade300),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Date filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _DateFilter.values
                  .map((f) => _FilterChip(
                        label: f.label,
                        icon: f.icon,
                        selected: _selectedFilter == f,
                        onTap: () =>
                            setState(() => _selectedFilter = f),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main list ────────────────────────────────────────────────
  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stock_transactions')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation(Color(0xFF6A11CB))));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyState(message: 'No transactions found');
        }

        // ── Filter by type == 'issue'
        List<Map<String, dynamic>> docs = snapshot.data!.docs
            .map((e) => {...e.data() as Map<String, dynamic>, '__id': e.id})
            .where((d) => d['type'] == 'issue')
            .toList();

        // ── Date filter
        final from = _fromDate;
        if (from != null) {
          docs = docs.where((d) {
            final ts = d['timestamp'] as Timestamp?;
            if (ts == null) return false;
            return ts.toDate().isAfter(from);
          }).toList();
        }

        // ── Search filter (item name)
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final name = (d['itemName'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery);
          }).toList();
        }

        // ── Sort newest first
        docs.sort((a, b) {
          final t1 = a['timestamp'] as Timestamp?;
          final t2 = b['timestamp'] as Timestamp?;
          if (t1 == null || t2 == null) return 0;
          return t2.compareTo(t1);
        });

        if (docs.isEmpty) {
          return _EmptyState(message: 'No results for current filters');
        }

        // ── Group by JobCard / Other
        // Same jobCardId  →  merged into ONE group
        final Map<String, List<Map<String, dynamic>>> grouped = {};

        for (final d in docs) {
          final String key;
          if (d['issueType'] == 'jobcard') {
            final jcId = (d['jobCardId'] ?? 'Unknown').toString();
            key = 'jobcard||$jcId';
          } else {
            final reason = (d['otherReason'] ?? 'No Reason').toString();
            key = 'other||$reason';
          }
          grouped.putIfAbsent(key, () => []).add(d);
        }

        return FadeTransition(
          opacity: _fadeAnim,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final entry = grouped.entries.elementAt(i);
              return _GroupCard(
                  groupKey: entry.key,
                  transactions: entry.value);
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  _GroupCard  —  One card per JobCard / OtherReason group
// ═══════════════════════════════════════════════════════════════
class _GroupCard extends StatefulWidget {
  final String groupKey;
  final List<Map<String, dynamic>> transactions;

  const _GroupCard(
      {required this.groupKey, required this.transactions});

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _expanded = false;

  String get _isJobCard =>
      widget.groupKey.startsWith('jobcard') ? 'jobcard' : 'other';

  String get _groupTitle {
    final parts = widget.groupKey.split('||');
    if (_isJobCard == 'jobcard') return 'Job Card: ${parts[1]}';
    return 'Other: ${parts[1]}';
  }

  Color get _accentColor =>
      _isJobCard == 'jobcard'
          ? const Color(0xFF6A11CB)
          : const Color(0xFF0A9396);

  // Total qty across all items in this group
  int get _totalQty => widget.transactions
      .fold(0, (sum, t) => sum + ((t['quantity'] ?? 0) as num).toInt());

  // Unique items
  Set<String> get _uniqueItems =>
      widget.transactions.map((t) => (t['itemName'] ?? 'Unknown').toString()).toSet();

  @override
  Widget build(BuildContext context) {
    // Group items inside this card
    final Map<String, List<Map<String, dynamic>>> itemMap = {};
    for (final t in widget.transactions) {
      final k = (t['itemName'] ?? 'Unknown').toString();
      itemMap.putIfAbsent(k, () => []).add(t);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _accentColor.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // ── Header tap row ───────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _accentColor.withOpacity(0.15),
                          _accentColor.withOpacity(0.05)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                        _isJobCard == 'jobcard'
                            ? Icons.assignment_rounded
                            : Icons.category_rounded,
                        color: _accentColor,
                        size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_groupTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MetaBadge(
                                icon: Icons.inventory_2_outlined,
                                label: '${_uniqueItems.length} items',
                                color: _accentColor),
                            const SizedBox(width: 6),
                            _MetaBadge(
                                icon: Icons.move_to_inbox_rounded,
                                label: 'Qty: $_totalQty',
                                color: Colors.orange.shade700),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand icon
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: _accentColor, size: 26),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable content ───────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  ...itemMap.entries.map((e) => _ItemSection(
                        itemName: e.key,
                        transactions: e.value,
                        accentColor: _accentColor,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  _ItemSection  —  Item name + image + all transactions
// ═══════════════════════════════════════════════════════════════
class _ItemSection extends StatelessWidget {
  final String itemName;
  final List<Map<String, dynamic>> transactions;
  final Color accentColor;

  const _ItemSection({
    required this.itemName,
    required this.transactions,
    required this.accentColor,
  });

  String? get _imageUrl {
    for (final t in transactions) {
      final url = t['imageUrl'] as String?;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Item header (image + name + total) ───────────────
          Row(
            children: [
              // Item image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _imageUrl != null
                    ? Image.network(
                        _imageUrl!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _PlaceholderImage(color: accentColor),
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : SizedBox(
                                    width: 54,
                                    height: 54,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: accentColor),
                                    ),
                                  ),
                      )
                    : _PlaceholderImage(color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemName,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: accentColor)),
                    const SizedBox(height: 4),
                    Text(
                      'Total issued: ${transactions.fold(0, (s, t) => s + ((t['quantity'] ?? 0) as num).toInt())} units',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${transactions.length} records',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Transaction rows ─────────────────────────────────
          ...transactions.map((t) {
            final ts = t['timestamp'] as Timestamp?;
            final date = ts != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
                : 'No Date';
            final qty = t['quantity'] ?? 0;
            final issuedBy = t['issuedBy'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.swap_horiz_rounded,
                        color: Colors.orange.shade700, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(date,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                        if (issuedBy != null && issuedBy.isNotEmpty)
                          Text('By: $issuedBy',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Qty: $qty',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Small reusable widgets
// ═══════════════════════════════════════════════════════════════

class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const _GlassButton(
      {required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(10)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: child,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: selected
                    ? const Color(0xFF6A11CB).withOpacity(0.3)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color)),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final Color color;
  const _PlaceholderImage({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.inventory_2_rounded, color: color, size: 24),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Date filter enum
// ═══════════════════════════════════════════════════════════════
enum _DateFilter {
  all,
  today,
  twoDays,
  oneWeek;

  String get label {
    switch (this) {
      case _DateFilter.all:
        return 'All';
      case _DateFilter.today:
        return 'Today';
      case _DateFilter.twoDays:
        return '2 Days';
      case _DateFilter.oneWeek:
        return '1 Week';
    }
  }

  IconData get icon {
    switch (this) {
      case _DateFilter.all:
        return Icons.all_inclusive_rounded;
      case _DateFilter.today:
        return Icons.today_rounded;
      case _DateFilter.twoDays:
        return Icons.date_range_rounded;
      case _DateFilter.oneWeek:
        return Icons.calendar_view_week_rounded;
    }
  }
}