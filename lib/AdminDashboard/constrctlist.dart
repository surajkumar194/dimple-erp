import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConstructionProductionListScreen extends StatefulWidget {
  const ConstructionProductionListScreen({super.key});
  @override
  State<ConstructionProductionListScreen> createState() =>
      _ConstructionProductionListScreenState();
}

class _ConstructionProductionListScreenState
    extends State<ConstructionProductionListScreen> {
  String _search = '';
  String? _expandedOrderId;
  // ✅ FIX: "Done" filter added to list
  String _filterType = "All";
  DateTimeRange? _customRange;

  // ─── Colors ──────────────────────────────────────────────────
  static const _primary = Color(0xFF169a8d);
  static const _darkText = Color(0xFF2C3E50);
  static const _lightBg = Color(0xFFF8F9FA);
  static const _success = Color(0xFF2ECC71);
  static const _warning = Color(0xFFE74C3C);
  static const _accent = Color(0xFFFFA500);
  static const _primaryGrad = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final List<String> _boxContractors = [
    'MDF Box (HR, Bhaji Box, Wedding Box Plain)',
    'Trays',
    'Double Door Box',
    'Flap Down',
    'ARC Box',
    'One Slant',
    'Mandir Box / TV Box',
    'Plater (without handle)',
    'Doom Box',
    'File Box',
    'Two Side Tapper Box',
    'Chocunki Box',
    'Farme Box',
    'Window Box',
    'Other',
  ];

  final List<String> _cuttingContractors = [
    'Mehfos',
    'Sadiq',
    'Shoaib',
    'Other',
  ];

  final List<String> _pastingContractors = [
    'Shahnawaz',
    'Ankush',
    'Danish',
    'Karan',
    'Pappu',
    'Tohid',
    'Nandu',
    'Sadiq / Shahnawaz',
    'Azam',
    'Anil',
    'Other',
  ];

  // ─── Per-product state — key = "$orderId__$productIndex" ─────
  final Map<String, _ProductFormState> _formStates = {};

  _ProductFormState _stateFor(String key) {
    return _formStates.putIfAbsent(key, () => _ProductFormState());
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Color _pColor(String p) {
    if (p == 'High') return _warning;
    if (p == 'Medium') return _accent;
    return _success;
  }

  int _mdfCount(List products) => products.where((p) {
    final cat = (p['productCategory'] ?? '').toString().toLowerCase();
    return cat == 'mdf' || cat == 'construction';
  }).length;

  List _mdfProducts(List products) => products.where((p) {
    final cat = (p['productCategory'] ?? '').toString().toLowerCase();
    return cat == 'mdf' || cat == 'construction';
  }).toList();

  // ─── Select Box Contractors (per product) ─────────────────────
  Future<void> _selectBoxContractors(String key) async {
    final state = _stateFor(key);
    final List<String> tempSelected = List.from(state.selectedBoxContractors);
    String? tempCustom = state.customBoxContractor;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Box Contractor'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: [
                    ..._boxContractors.map((contractor) {
                      final isSelected = tempSelected.contains(contractor);

                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(contractor),
                        onChanged: (val) {
                          setStateDialog(() {
                            if (val == true) {
                              tempSelected.add(contractor);
                            } else {
                              tempSelected.remove(contractor);
                            }
                          });
                        },
                      );
                    }),

                    /// 🔥 OTHER INPUT FIELD
                    if (tempSelected.contains("Other"))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Enter Other Contractor",
                          ),
                          onChanged: (val) {
                            tempCustom = val;
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  state.selectedBoxContractors = tempSelected;

                  if (tempSelected.contains("Other") && tempCustom != null) {
                    // 👇 Replace "Other" with actual value
                    state.selectedBoxContractors.remove("Other");
                    state.selectedBoxContractors.add(tempCustom!);
                  }

                  state.customBoxContractor = tempCustom;
                });
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ─── Build Widgets ─────────────────────────────────────────────
  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.currency_rupee),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _qtyBanner(int qty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 18, color: _primary),
          const SizedBox(width: 8),
          Text(
            'Product Quantity: ',
            style: TextStyle(
              fontSize: 13,
              color: _primary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$qty',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  // ─── Per-product production form ──────────────────────────────
  Widget _buildProductionForm({
    required String formKey,
    required String orderId,
    required int productQty,
    required int productIndex,
  }) {
    final state = _stateFor(formKey);
    final type = state.productionType;

    if (type == null) return const SizedBox.shrink();

    // ── Employee only ──────────────────────────────────────────
    if (type == "employee") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _qtyBanner(productQty),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: productQty.toString(),
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Employee Quantity (Auto-fetched)',
              prefixIcon: const Icon(Icons.numbers),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: const Icon(
                Icons.lock_outline,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Employee Remark',
              prefixIcon: const Icon(Icons.note_alt_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            maxLines: 2,
            onChanged: (v) => state.employeeRemark = v,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.save),
            label: const Text("Save"),
            onPressed: () async {
              // ✅ FIX: Loading state show karo, try-catch lagao
              try {
                await _saveProductProduction(
                  orderId: orderId,
                  productIndex: productIndex,
                  data: {
                    "productionType": "employee",
                    "totalQuantity": productQty,
                    "employeeQuantity": productQty,
                    "employeeRemark": state.employeeRemark,
                  },
                );
                if (mounted) {
                  setState(() => state.isSaved = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Employee Production Saved ✅"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error saving: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      );
    }

    // ── Contractor only ────────────────────────────────────────
    if (type == "contractor") {
      return _contractorForm(
        formKey: formKey,
        orderId: orderId,
        productQty: productQty,
        productIndex: productIndex,
        state: state,
      );
    }

    // ── Both ──────────────────────────────────────────────────
    if (type == "both") {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          final empVal = int.tryParse(state.empQtyController.text) ?? 0;
          final conVal = int.tryParse(state.conQtyController.text) ?? 0;
          final used = empVal + conVal;
          final remaining = productQty - used;
          final isOver = remaining < 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: _primaryGrad,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _bannerCol('Total', '$productQty'),
                    Container(height: 40, width: 1, color: Colors.white24),
                    _bannerCol('Used', '$used'),
                    Container(height: 40, width: 1, color: Colors.white24),
                    _bannerColColored(
                      'Remaining',
                      isOver ? '-${remaining.abs()}' : '$remaining',
                      isOver ? Colors.red.shade200 : Colors.white,
                    ),
                  ],
                ),
              ),

              if (isOver)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Limit exceeded by ${remaining.abs()}! Reduce quantity.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Employee Section ───────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Employee",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: state.empQtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Employee Quantity',
                        prefixIcon: const Icon(Icons.numbers),
                        helperText:
                            'Total: $productQty  |  Used: $used  |  Left: ${isOver ? 0 : remaining}',
                        helperStyle: TextStyle(
                          color: isOver ? Colors.red : Colors.grey.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onChanged: (v) {
                        final empN = int.tryParse(v) ?? 0;
                        final rem = productQty - empN;
                        if (rem >= 0) {
                          state.conQtyController.text = rem.toString();
                        }
                        setLocalState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Employee Remark',
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      maxLines: 2,
                      onChanged: (v) => state.employeeRemark = v,
                    ),
                  ],
                ),
              ),

              // ── Contractor Section ─────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.engineering,
                          color: Colors.orange.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Contractor",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: state.conQtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Contractor Quantity',
                        prefixIcon: const Icon(Icons.numbers),
                        helperText:
                            'Total: $productQty  |  Used: $used  |  Left: ${isOver ? 0 : remaining}',
                        helperStyle: TextStyle(
                          color: isOver ? Colors.red : Colors.grey.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onChanged: (v) {
                        final conN = int.tryParse(v) ?? 0;
                        final rem = productQty - conN;
                        if (rem >= 0) {
                          state.empQtyController.text = rem.toString();
                        }
                        setLocalState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    _contractorFields(formKey, state, setLocalState),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Contractor Remark',
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      maxLines: 2,
                      onChanged: (v) => state.contractorRemark = v,
                    ),
                  ],
                ),
              ),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Both"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOver ? Colors.grey.shade400 : _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isOver
                    ? null
                    : () async {
                        // ✅ FIX: try-catch + mounted check
                        try {
                          await _saveProductProduction(
                            orderId: orderId,
                            productIndex: productIndex,
                            data: {
                              "productionType": "both",
                              "totalQuantity": productQty,
                              "employeeQuantity":
                                  int.tryParse(state.empQtyController.text) ??
                                  0,
                              "employeeRemark": state.employeeRemark,
                              "contractorQuantity":
                                  int.tryParse(state.conQtyController.text) ??
                                  0,
                              "boxContractor": state.selectedBoxContractors,
                              "cuttingContractor":
                                  state.selectedCuttingContractor == "Other"
                                  ? state.customCuttingContractor
                                  : state.selectedCuttingContractor,
                              "cuttingPrice": state.cuttingPriceController.text,
                              "pastingContractor":
                                  state.selectedPastingContractor == "Other"
                                  ? state.customPastingContractor
                                  : state.selectedPastingContractor,
                              "pastingPrice": state.pastingPriceController.text,
                              "contractorRemark": state.contractorRemark,
                            },
                          );
                          if (mounted) {
                            setState(() => state.isSaved = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Both Production Saved ✅"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error saving: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
              ),
            ],
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  // ── Contractor-only form ───────────────────────────────────────
  Widget _contractorForm({
    required String formKey,
    required String orderId,
    required int productQty,
    required int productIndex,
    required _ProductFormState state,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _qtyBanner(productQty),
            const SizedBox(height: 12),
            _contractorFields(formKey, state, setLocalState),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Save Production"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // ✅ FIX: try-catch + mounted check + no FieldValue inside nested map
                try {
                  await _saveProductProduction(
                    orderId: orderId,
                    productIndex: productIndex,
                    data: {
                      "productionType": "contractor",
                      "totalQuantity": productQty,
                      "boxContractor": state.selectedBoxContractors,
                      "cuttingContractor":
                          state.selectedCuttingContractor == "Other"
                          ? state.customCuttingContractor
                          : state.selectedCuttingContractor,
                      "cuttingPrice": state.cuttingPriceController.text,
                      "pastingContractor":
                          state.selectedPastingContractor == "Other"
                          ? state.customPastingContractor
                          : state.selectedPastingContractor,
                      "pastingPrice": state.pastingPriceController.text,
                      "contractorRemark": state.contractorRemark,
                    },
                  );
                  if (mounted) {
                    setState(() => state.isSaved = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Production Saved ✅"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ── Shared contractor fields widget ───────────────────────────
  Widget _contractorFields(
    String formKey,
    _ProductFormState state,
    StateSetter setLocal,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _selectBoxContractors(formKey),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.selectedBoxContractors.isEmpty
                        ? 'Select Box Contractor'
                        : state.selectedBoxContractors.join(', '),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        state.selectedCuttingContractor == "Other"
            ? TextFormField(
                decoration: InputDecoration(
                  labelText: "Enter Cutting Contractor",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (val) {
                  setLocal(() => state.customCuttingContractor = val);
                },
              )
            : _buildDropdown(
                label: 'Cutting Contractor',
                icon: Icons.person,
                value: state.selectedCuttingContractor,
                items: _cuttingContractors,
                onChanged: (v) {
                  setLocal(() {
                    state.selectedCuttingContractor = v;
                    state.customCuttingContractor = null; // reset
                  });
                },
              ),
        const SizedBox(height: 10),
        _buildPriceField(
          controller: state.cuttingPriceController,
          label: 'Cutting Price',
        ),
        const SizedBox(height: 10),
        state.selectedPastingContractor == "Other"
            ? TextFormField(
                decoration: InputDecoration(
                  labelText: "Enter Pasting Contractor",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
                onChanged: (val) {
                  setLocal(() => state.customPastingContractor = val);
                },
              )
            : _buildDropdown(
                label: 'Pasting Contractor',
                icon: Icons.person,
                value: state.selectedPastingContractor,
                items: _pastingContractors,
                onChanged: (val) {
                  setLocal(() {
                    state.selectedPastingContractor = val;
                    state.customPastingContractor = null; // reset
                  });
                },
              ),
        const SizedBox(height: 10),
        _buildPriceField(
          controller: state.pastingPriceController,
          label: 'Pasting Price',
        ),
      ],
    );
  }

  // ─── ✅ FIXED: Save to Firestore ───────────────────────────────
  // Problem tha: FieldValue.serverTimestamp() nested array ke andar nahi
  // chalti Firestore mein — ab hum savedAt top-level pe rakh rahe hain
  Future<void> _saveProductProduction({
    required String orderId,
    required int productIndex,
    required Map<String, dynamic> data,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('constructionProduction')
        .doc(orderId);

    // Read existing doc first
    final existing = await docRef.get();
    List<dynamic> arr = [];
    if (existing.exists) {
      final d = existing.data() as Map<String, dynamic>;
      arr = List.from(d['productsProduction'] ?? []);
    }

    // Grow array if needed
    while (arr.length <= productIndex) {
      arr.add({});
    }

    // ✅ FIX: FieldValue.serverTimestamp() array ke andar nahi chalti
    // Isliye savedAt ko String (ISO) ke roop mein save karo
    arr[productIndex] = {
      ...data,
      "productIndex": productIndex,
      "savedAt": DateTime.now().toIso8601String(), // ✅ Fixed
    };

    // ✅ FIX: updatedAt sirf top-level pe — yahan FieldValue.serverTimestamp() sahi kaam karta hai
    await docRef.set({
      "orderId": orderId,
      "productsProduction": arr,
      "updatedAt": FieldValue.serverTimestamp(), // ✅ top-level mein sahi hai
    }, SetOptions(merge: true));
  }

  // ─── Banner helpers ────────────────────────────────────────────
  Widget _bannerCol(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _bannerColColored(String label, String value, Color valueColor) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  // ─── Single product tile ───────────────────────────────────────
  Widget _productTile({
    required String orderId,
    required int productIndex,
    required Map<String, dynamic> product,
    required Map<String, dynamic>? savedData,
  }) {
    final formKey = '${orderId}__$productIndex';
    final state = _stateFor(formKey);

    if (savedData != null && !state.loadedFromFirestore) {
      state.loadedFromFirestore = true;
      state.isSaved = true;
      state.productionType = savedData['productionType'];
    }

    final name = (product['productName'] ?? 'Product ${productIndex + 1}')
        .toString();
    final images = product['images'] as List?;
    final image = (images != null && images.isNotEmpty)
        ? images[0].toString()
        : '';
    final qty = _parseQty(product['quantity']);
    final isExpanded = state.isExpanded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: state.isSaved ? Colors.green.shade300 : Colors.grey.shade200,
          width: state.isSaved ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => state.isExpanded = !state.isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (image.isEmpty) return;
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.black,
                          insetPadding: EdgeInsets.zero,
                          child: Stack(
                            children: [
                              InteractiveViewer(
                                child: Image.network(
                                  image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 30,
                                right: 20,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: image.isNotEmpty
                          ? Image.network(
                              image,
                              height: 56,
                              width: 56,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 56,
                              width: 56,
                              color: Colors.grey.shade100,
                              child: Icon(
                                Icons.image,
                                size: 30,
                                color: Colors.grey.shade400,
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
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Qty: $qty',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (state.isSaved) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Saved',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Production Type",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: state.productionType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.settings),
                    ),
                    hint: const Text("Select Production Type"),
                    items: const [
                      DropdownMenuItem(
                        value: "employee",
                        child: Text("Only Employee"),
                      ),
                      DropdownMenuItem(
                        value: "contractor",
                        child: Text("Only Contractor"),
                      ),
                      DropdownMenuItem(
                        value: "both",
                        child: Text("Employee + Contractor"),
                      ),
                    ],
                    onChanged: state.isSaved
                        ? null
                        : (val) {
                            setState(() => state.productionType = val);
                          },
                  ),
                  const SizedBox(height: 14),
                  if (!state.isSaved && state.productionType != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: _buildProductionForm(
                        formKey: formKey,
                        orderId: orderId,
                        productQty: qty,
                        productIndex: productIndex,
                      ),
                    ),
                  if (state.isSaved) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Production Saved",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (state.productionType != null)
                                Text(
                                  "Type: ${state.productionType!.toUpperCase()}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                state.isSaved = false;
                                state.loadedFromFirestore = false;
                              });
                            },
                            child: const Text(
                              "Edit",
                              style: TextStyle(color: _primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _parseQty(dynamic qty) {
    if (qty is int) return qty;
    if (qty is double) return qty.toInt();
    if (qty is String) return int.tryParse(qty) ?? 0;
    return 0;
  }

  // ─── Order Card ───────────────────────────────────────────────
  Widget _orderCard(String orderId, Map<String, dynamic> data) {
    final customer = data['customerName'] ?? '-';
    final company = data['companyName'] ?? '';
    final priority = data['priority'] ?? 'Medium';
    final sp = data['salesPerson'] ?? '-';
    final unit = data['unit'] ?? '-';
    final products = data['products'] is List ? data['products'] as List : [];
    final mdfProds = _mdfProducts(products);
    final mdfCount = mdfProds.length;

    final delivery = (data['deliveryDate'] as Timestamp?)?.toDate();
    final delivStr = delivery != null
        ? '${delivery.day}/${delivery.month}/${delivery.year}'
        : '-';

    final isExpanded = _expandedOrderId == orderId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('constructionProduction')
          .doc(orderId)
          .get(),
      builder: (context, snap) {
        List<dynamic> savedArr = [];
        if (snap.hasData && snap.data!.exists) {
          final cData = snap.data!.data() as Map<String, dynamic>;
          savedArr = List.from(cData['productsProduction'] ?? []);
        }

        final savedCount = savedArr
            .where((e) => e != null && (e as Map).isNotEmpty)
            .length;
        final allSaved = mdfCount > 0 && savedCount >= mdfCount;

        return GestureDetector(
          onTap: () {
            setState(() {
              _expandedOrderId = isExpanded ? null : orderId;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF169a8d).withOpacity(0.08),
                        const Color(0xFF0d7c70).withOpacity(0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _primaryGrad,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.construction,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _darkText,
                              ),
                            ),
                            if (company.isNotEmpty)
                              Text(
                                company,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sp,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _pColor(priority).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _pColor(priority)),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                color: _pColor(priority),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: _primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _infoChip(Icons.factory_outlined, unit),
                      const SizedBox(width: 10),
                      _infoChip(Icons.calendar_today, delivStr),
                      const SizedBox(width: 10),
                      _infoChip(Icons.precision_manufacturing, '$mdfCount MDF'),
                      if (allSaved) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 13,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "All Done",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (savedCount > 0) ...[
                        const SizedBox(width: 10),
                        _infoChip(
                          Icons.pending_actions,
                          '$savedCount/$mdfCount',
                        ),
                      ],
                    ],
                  ),
                ),

                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "MDF Products",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(mdfProds.length, (i) {
                          final prod = mdfProds[i] as Map<String, dynamic>;
                          Map<String, dynamic>? saved;
                          if (i < savedArr.length &&
                              savedArr[i] != null &&
                              (savedArr[i] as Map).isNotEmpty) {
                            saved = Map<String, dynamic>.from(
                              savedArr[i] as Map,
                            );
                          }
                          return _productTile(
                            orderId: orderId,
                            productIndex: i,
                            product: prod,
                            savedData: saved,
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Main Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: _primary),
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
                  'Contractor Production',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Manage Contractor production stages',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by customer or company...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _primary.withOpacity(0.7),
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _filterChips(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                final allDocs = snap.data!.docs;

                // ✅ FIX: "Done" filter ke liye constructionProduction collection
                // se data laana padega — isliye yahan FutureBuilder use karenge
                // Lekin StreamBuilder mein nested async nahi chalti,
                // isliye hum "Done" filter ke liye alag stream use karte hain

                return _filterType == "Done"
                    ? _doneFilteredList(allDocs)
                    : _buildOrderList(allDocs);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Done filter — sirf woh orders jinke sab products saved hain
  Widget _doneFilteredList(List<QueryDocumentSnapshot> allDocs) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('constructionProduction')
          .snapshots(),
      builder: (ctx, prodSnap) {
        if (!prodSnap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        // constructionProduction mein jo saved hain unka map banao
        final Map<String, Map<String, dynamic>> savedMap = {};
        for (final doc in prodSnap.data!.docs) {
          savedMap[doc.id] = doc.data() as Map<String, dynamic>;
        }

        // Sirf woh orders filter karo jisme sab MDF products saved hain
        final doneOrders = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final products = data['products'] is List
              ? data['products'] as List
              : [];
          final mdfCount = _mdfCount(products);
          if (mdfCount == 0) return false;

          final saved = savedMap[doc.id];
          if (saved == null) return false;

          final arr = List.from(saved['productsProduction'] ?? []);
          final savedCount = arr
              .where((e) => e != null && (e as Map).isNotEmpty)
              .length;

          // Search filter bhi apply karo
          if (_search.isNotEmpty) {
            final customer = (data['customerName'] ?? '')
                .toString()
                .toLowerCase();
            final company = (data['companyName'] ?? '')
                .toString()
                .toLowerCase();
            if (!customer.contains(_search) && !company.contains(_search)) {
              return false;
            }
          }

          return savedCount >= mdfCount;
        }).toList();

        if (doneOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Koi Done Order Nahi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Abhi tak koi order poora nahi hua.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: doneOrders.length,
          itemBuilder: (ctx, i) {
            final doc = doneOrders[i];
            final data = doc.data() as Map<String, dynamic>;
            return _orderCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildOrderList(List<QueryDocumentSnapshot> allDocs) {
    final filtered = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final products = data['products'] is List ? data['products'] as List : [];
      if (_mdfCount(products) == 0) return false;

      final timestamp = data['updatedAt'] ?? data['orderDate'];
      if (timestamp == null) return false;
      final date = (timestamp as Timestamp).toDate();

      if (_filterType == "All") {
        // no restriction
      } else if (_filterType == "Custom" && _customRange != null) {
        if (date.isBefore(_customRange!.start) ||
            date.isAfter(_customRange!.end))
          return false;
      } else {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        DateTime startDate;
        if (_filterType == "Today") {
          startDate = today;
        } else if (_filterType == "2 Days") {
          startDate = today.subtract(const Duration(days: 2));
        } else if (_filterType == "1 Week") {
          startDate = today.subtract(const Duration(days: 7));
        } else if (_filterType == "1 Month") {
          startDate = today.subtract(const Duration(days: 30));
        } else {
          startDate = today;
        }
        if (date.isBefore(startDate)) return false;
      }

      if (_search.isEmpty) return true;
      final customer = (data['customerName'] ?? '').toString().toLowerCase();
      final company = (data['companyName'] ?? '').toString().toLowerCase();
      return customer.contains(_search) || company.contains(_search);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.construction,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No MDF Orders Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _search.isEmpty
                  ? 'No orders have MDF products yet.'
                  : 'No matching orders found.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final doc = filtered[i];
        final data = doc.data() as Map<String, dynamic>;
        return _orderCard(doc.id, data);
      },
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip("All"),
          _chip("Today"),
          _chip("2 Days"),
          _chip("1 Week"),
          _chip("1 Month"),
          // ✅ NEW: Done filter chip — green color ke saath
          _chipColored("Done", Colors.green),
          _chip("Custom"),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final isSelected = _filterType == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: _primary.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? _primary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) async {
          setState(() => _filterType = label);
          if (label == "Custom") {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _customRange = picked);
          }
        },
      ),
    );
  }

  // ✅ NEW: Colored chip (Done ke liye green)
  Widget _chipColored(String label, Color color) {
    final isSelected = _filterType == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) Icon(Icons.check_circle, size: 14, color: color),
            if (isSelected) const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        selectedColor: color.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: isSelected
            ? BorderSide(color: color.withOpacity(0.5))
            : BorderSide(color: Colors.grey.shade300),
        onSelected: (_) {
          setState(() => _filterType = label);
        },
      ),
    );
  }
}

// ─── Per-product form state ─────────────────────────────────────
class _ProductFormState {
  String? productionType;
  bool isExpanded = false;
  bool isSaved = false;
  bool loadedFromFirestore = false;

  String employeeRemark = '';

  final TextEditingController empQtyController = TextEditingController();
  final TextEditingController conQtyController = TextEditingController();

  List<String> selectedBoxContractors = [];
  String? customBoxContractor; // 👈 NEW
  String? selectedCuttingContractor;
  String? customCuttingContractor; // 👈 add this
  String? selectedPastingContractor;
  String? customPastingContractor; // 👈 NEW
  final TextEditingController cuttingPriceController = TextEditingController();
  final TextEditingController pastingPriceController = TextEditingController();
  String contractorRemark = '';

  void dispose() {
    empQtyController.dispose();
    conQtyController.dispose();
    cuttingPriceController.dispose();
    pastingPriceController.dispose();
  }
}
