import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDocumentDetailScreen extends StatelessWidget {
  final String collection;
  final String docId;
  final Map<String, dynamic> data;

  const AdminDocumentDetailScreen({
    required this.collection,
    required this.docId,
    required this.data,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeys = data.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          docId,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1A1A2E),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              onPressed: () => _confirmDelete(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
              ),
            ),
          ),
        ],
      ),
      body: data.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Empty Document",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This document has no fields",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final key = sortedKeys[index];
                final value = data[key];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _editField(context, key, value),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    key,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                _typeBadge(value),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    color: Color(0xFF10B981),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _formatValue(value),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1A1A2E),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return "null";
    if (value is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(value.toDate());
    }
    if (value is bool) return value ? "True" : "False";
    if (value is num) return value.toString();
    if (value is List) return "List (${value.length} items)";
    if (value is Map) return "Map (${value.keys.length} fields)";
    return value.toString();
  }

  Widget _typeBadge(dynamic value) {
    Color bgColor;
    Color textColor;
    String label;

    if (value == null) {
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF64748B);
      label = "null";
    } else if (value is String) {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF10B981);
      label = "text";
    } else if (value is num) {
      bgColor = const Color(0xFFDEF7EC);
      textColor = const Color(0xFF047857);
      label = "number";
    } else if (value is bool) {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      label = "boolean";
    } else if (value is Timestamp) {
      bgColor = const Color(0xFFEDE9FE);
      textColor = const Color(0xFF7C3AED);
      label = "timestamp";
    } else if (value is List || value is Map) {
      bgColor = const Color(0xFFCCFBF1);
      textColor = const Color(0xFF0D9488);
      label = value is List ? "array" : "map";
    } else {
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF64748B);
      label = "other";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  void _editField(BuildContext context, String key, dynamic currentValue) {
    final controller = TextEditingController(text: _textFromValue(currentValue));
    bool isBool = currentValue is bool;
    bool? boolValue = currentValue is bool ? currentValue : null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Edit $key",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: isBool
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButton<bool>(
                    value: boolValue,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: true, child: Text("True")),
                      DropdownMenuItem(value: false, child: Text("False")),
                    ],
                    onChanged: (val) => setState(() => boolValue = val),
                  ),
                )
              : TextField(
                  controller: controller,
                  keyboardType: _keyboardType(currentValue),
                  maxLines: currentValue is String && currentValue.toString().length > 50 ? 5 : 1,
                  decoration: InputDecoration(
                    hintText: "Enter new value",
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                dynamic newValue;
                if (isBool) {
                  newValue = boolValue;
                } else {
                  String text = controller.text.trim();
                  newValue = _parseValue(text, currentValue);
                }

                await FirebaseFirestore.instance
                    .collection(collection)
                    .doc(docId)
                    .update({key: newValue});

                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  String _textFromValue(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm').format(value.toDate());
    }
    return value?.toString() ?? '';
  }

  TextInputType _keyboardType(dynamic value) {
    if (value is num) return TextInputType.number;
    if (value is Timestamp) return TextInputType.datetime;
    return TextInputType.text;
  }

  dynamic _parseValue(String text, dynamic original) {
    if (text.isEmpty) return null;
    if (original is num) {
      return num.tryParse(text) ?? text;
    }
    if (original is Timestamp) {
      return Timestamp.fromDate(DateTime.tryParse(text) ?? DateTime.now());
    }
    return text;
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            size: 40,
          ),
        ),
        title: const Text(
          "Delete Document?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Permanently delete document\n'$docId'\nfrom '$collection'?\n\nThis action cannot be undone.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(docId)
                  .delete();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}