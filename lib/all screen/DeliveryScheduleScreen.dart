import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore data shape expected:
/// deliverySchedule: [
///   {"title": "Packed", "date": <Timestamp>, "done": true},
///   {"title": "Shipped", "date": <Timestamp>, "done": true},
///   {"title": "Out for delivery", "date": <Timestamp>, "done": false},
///   {"title": "Delivered", "date": <Timestamp>, "done": false}
/// ]
class DeliveryScheduleScreen extends StatefulWidget {
  final String orderId;

  const DeliveryScheduleScreen({super.key, required this.orderId});

  @override
  State<DeliveryScheduleScreen> createState() => _DeliveryScheduleScreenState();
}

class _DeliveryScheduleScreenState extends State<DeliveryScheduleScreen> {
  bool _loading = true;
  bool _saving = false;
  List<_DeliveryStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      final data = doc.data() ?? {};
      _steps = _parseDeliverySchedule(data['deliverySchedule']);

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load schedule: $e')),
      );
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _saving = true);
    try {
      // Sort by date before save
      _steps.sort((a, b) {
        final ad = a.date?.millisecondsSinceEpoch ?? 0;
        final bd = b.date?.millisecondsSinceEpoch ?? 0;
        return ad.compareTo(bd);
      });

      final payload = _steps
          .map((s) => {
                'title': s.title,
                'date': s.date != null ? Timestamp.fromDate(s.date!) : null,
                'done': s.isDone,
              })
          .toList();

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'deliverySchedule': payload});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery schedule saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final completed = _steps.where((s) => s.isDone).length;
    final progress = _steps.isEmpty ? 0.0 : completed / _steps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Scheduling'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading || _saving ? null : _loadSchedule,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: (_loading || _saving) ? null : _saveSchedule,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF42A5F5),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _saving ? null : _addStep,
        icon: const Icon(Icons.add),
        label: const Text('Add Step'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _steps.isEmpty
              ? _emptyState()
              : Column(
                  children: [
                    // Progress summary
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$completed of ${_steps.length} steps completed',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Reorderable list
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: _steps.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _steps.removeAt(oldIndex);
                            _steps.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (ctx, i) {
                          final s = _steps[i];
                          return Card(
                            key: ValueKey('step_$i'),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // drag handle
                                  const Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Icon(Icons.drag_indicator),
                                  ),
                                  const SizedBox(width: 8),

                                  // switch + content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Switch(
                                              value: s.isDone,
                                              onChanged: (v) => setState(() =>
                                                  _steps[i] = s.copyWith(isDone: v)),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: s.title,
                                                decoration: const InputDecoration(
                                                  labelText: 'Step title',
                                                  border: InputBorder.none,
                                                ),
                                                onChanged: (val) => _steps[i] =
                                                    s.copyWith(
                                                        title: val.isEmpty ? 'Step' : val),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.event, size: 16, color: Colors.grey[700]),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _formatDateTime(s.date),
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[800],
                                                    fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(Icons.edit_calendar),
                                              label: const Text('Pick date'),
                                              onPressed: () async {
                                                final dt =
                                                    await _pickDateTime(context, s.date);
                                                if (dt != null) {
                                                  setState(() =>
                                                      _steps[i] = s.copyWith(date: dt));
                                                }
                                              },
                                            ),
                                            IconButton(
                                              tooltip: 'Delete',
                                              icon: const Icon(Icons.delete_outline),
                                              onPressed: () => _deleteStep(i),
                                            ),
                                          ],
                                        ),
                                      ],
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
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 84, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No delivery steps yet',
                style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            const SizedBox(height: 6),
            Text('Tap “Add Step” to create your first milestone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ===== list ops =====
  void _addStep() async {
    final dt = await _pickDateTime(context, DateTime.now());
    setState(() {
      _steps.add(_DeliveryStep(title: 'New Step', date: dt, isDone: false));
    });
  }

  void _deleteStep(int i) {
    setState(() => _steps.removeAt(i));
  }

  // ===== helpers =====
  List<_DeliveryStep> _parseDeliverySchedule(dynamic raw) {
    if (raw is! List) return [];
    final now = DateTime.now();
    final steps = <_DeliveryStep>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final title = (item['title'] ?? 'Step').toString();
        final date = _toDateTime(item['date']);
        final doneField = item['done'];
        final isDone =
            (doneField is bool) ? doneField : (date != null ? !date.isAfter(now) : false);
        steps.add(_DeliveryStep(title: title, date: date, isDone: isDone));
      }
    }
    steps.sort((a, b) {
      final ad = a.date?.millisecondsSinceEpoch ?? 0;
      final bd = b.date?.millisecondsSinceEpoch ?? 0;
      return ad.compareTo(bd);
    });
    return steps;
  }

  DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'No date set';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $hh:$mm';
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime? initial) async {
    final now = DateTime.now();
    final initDate = initial ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (pickedDate == null) return initial;

    final initialTime = TimeOfDay.fromDateTime(initDate);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null) {
      return DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
          initDate.hour, initDate.minute);
    }
    return DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute);
  }
}

// ===== model =====
class _DeliveryStep {
  final String title;
  final DateTime? date;
  final bool isDone;

  _DeliveryStep({required this.title, required this.date, required this.isDone});

  _DeliveryStep copyWith({String? title, DateTime? date, bool? isDone}) {
    return _DeliveryStep(
      title: title ?? this.title,
      date: date ?? this.date,
      isDone: isDone ?? this.isDone,
    );
  }
}
