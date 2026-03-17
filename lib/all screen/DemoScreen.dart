import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DemoDashboard extends StatefulWidget {
  const DemoDashboard({super.key});

  @override
  State<DemoDashboard> createState() => _DemoDashboardState();
}

class _DemoDashboardState extends State<DemoDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Theme Colors ──────────────────────────────────────────
  static const Color bgLight       = Color(0xFFF0F4FF);
  static const Color bgWhite       = Color(0xFFFFFFFF);
  static const Color bgSurface     = Color(0xFFF7F9FF);
  static const Color accent        = Color(0xFF6C63FF); // purple
  static const Color accentGreen   = Color(0xFF00C48C); // green
  static const Color accentOrange  = Color(0xFFFF7A3D); // orange
  static const Color accentBlue    = Color(0xFF2196F3); // blue
  static const Color accentPink    = Color(0xFFFF4D8D); // pink
  static const Color textPrimary   = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color borderColor   = Color(0xFFE4E9F5);

  List<Map<String, dynamic>> rawMaterials = [
    {"name": "Kraft Paper",   "qty": 1200, "unit": "kg", "level": 0.72},
    {"name": "Duplex Board",  "qty": 850,  "unit": "kg", "level": 0.45},
  ];

  List<Map<String, dynamic>> machines = [
    {"name": "Printing Machine", "status": "Running", "uptime": "14h 32m"},
    {"name": "Die Cutting",      "status": "Idle",    "uptime": "2h 10m"},
  ];

  List<Map<String, dynamic>> production = [
    {"product": "Pizza Box", "qty": 5000, "unit": "pcs"},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showDialog({
    required String title,
    required List<_FieldConfig> fields,
    required VoidCallback onAdd,
    required List<TextEditingController> controllers,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Dialog(
        backgroundColor: bgWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add_rounded, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        color: textPrimary, fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 22),
              ...List.generate(fields.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildTextField(
                    controller: controllers[i],
                    label: fields[i].label,
                    color: color,
                    keyboardType: fields[i].isNumeric
                        ? TextInputType.number
                        : TextInputType.text),
              )),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: borderColor)),
                    ),
                    child: const Text("Cancel",
                        style: TextStyle(color: textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { onAdd(); Navigator.pop(ctx); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Add",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void addRawMaterial() {
    final name = TextEditingController();
    final qty  = TextEditingController();
    _showDialog(
      title: "Add Raw Material",
      color: accentBlue,
      fields: [_FieldConfig("Material Name", false), _FieldConfig("Quantity (kg)", true)],
      controllers: [name, qty],
      onAdd: () => setState(() {
        rawMaterials.add({"name": name.text,
          "qty": int.tryParse(qty.text) ?? 0, "unit": "kg", "level": 0.5});
      }),
    );
  }

  void addMachine() {
    final name = TextEditingController();
    _showDialog(
      title: "Add Machine",
      color: accentOrange,
      fields: [_FieldConfig("Machine Name", false)],
      controllers: [name],
      onAdd: () => setState(() {
        machines.add({"name": name.text, "status": "Running", "uptime": "0h 0m"});
      }),
    );
  }

  void addProduction() {
    final product = TextEditingController();
    final qty     = TextEditingController();
    _showDialog(
      title: "Add Production",
      color: accentGreen,
      fields: [_FieldConfig("Product Name", false), _FieldConfig("Quantity (pcs)", true)],
      controllers: [product, qty],
      onAdd: () => setState(() {
        production.add({"product": product.text,
          "qty": int.tryParse(qty.text) ?? 0, "unit": "pcs"});
      }),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSummaryRow(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8),
                  children: [
                    _buildSection(
                      title: "Raw Materials",
                      icon: Icons.inventory_2_rounded,
                      iconColor: accentBlue,
                      gradientColors: [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
                      onAdd: addRawMaterial,
                      child: Column(children: rawMaterials
                          .map((item) => _rawMaterialCard(item)).toList()),
                    ),
                    SizedBox(height: 2.h),
                    _buildSection(
                      title: "Machines",
                      icon: Icons.precision_manufacturing_rounded,
                      iconColor: accentOrange,
                      gradientColors: [const Color(0xFFFF7A3D), const Color(0xFFFFAB76)],
                      onAdd: addMachine,
                      child: Column(children: machines
                          .map((m) => _machineCard(m)).toList()),
                    ),
                    SizedBox(height: 2.h),
                    _buildSection(
                      title: "Production",
                      icon: Icons.factory_rounded,
                      iconColor: accentGreen,
                      gradientColors: [const Color(0xFF00C48C), const Color(0xFF4DD9B0)],
                      onAdd: addProduction,
                      child: Column(children: production
                          .map((p) => _productionCard(p)).toList()),
                    ),
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 16),
      decoration: const BoxDecoration(
        color: bgWhite,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9C96FF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
              color: accent.withOpacity(0.3),
              blurRadius: 10, offset: const Offset(0, 4),
            )],
          ),
          child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("ERP Dashboard",
              style: TextStyle(color: textPrimary, fontSize: 17,
                  fontWeight: FontWeight.w800)),
          Text("Manufacturing Overview",
              style: TextStyle(color: textSecondary, fontSize: 11.5.sp)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C48C), Color(0xFF4DD9B0)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: accentGreen.withOpacity(0.35),
              blurRadius: 8, offset: const Offset(0, 3),
            )],
          ),
          child: Row(children: [
            Container(width: 7, height: 7,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text("Live", style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  // ── Summary Row ────────────────────────────────────────────

  Widget _buildSummaryRow() {
    int running = machines.where((m) => m["status"] == "Running").length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 14),
      child: Row(children: [
        _summaryChip(
            "${rawMaterials.fold(0, (s, e) => s + (e["qty"] as int))} kg",
            "Total Stock", accentBlue,
            [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
            Icons.inventory_2_rounded),
        const SizedBox(width: 10),
        _summaryChip("$running/${machines.length}", "Running",
            accentOrange,
            [const Color(0xFFFF7A3D), const Color(0xFFFFAB76)],
            Icons.precision_manufacturing_rounded),
        const SizedBox(width: 10),
        _summaryChip(
            "${production.fold(0, (s, e) => s + (e["qty"] as int))} pcs",
            "Output", accentGreen,
            [const Color(0xFF00C48C), const Color(0xFF4DD9B0)],
            Icons.factory_rounded),
      ]),
    );
  }

  Widget _summaryChip(String value, String label, Color color,
      List<Color> gradient, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 5),
          )],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(
              color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── Section Wrapper ────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required VoidCallback onAdd,
    required Widget child,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
              color: iconColor.withOpacity(0.3),
              blurRadius: 8, offset: const Offset(0, 3),
            )],
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(
            color: textPrimary, fontSize: 15,
            fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors,
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: iconColor.withOpacity(0.3),
                blurRadius: 8, offset: const Offset(0, 3),
              )],
            ),
            child: Row(children: [
              const Icon(Icons.add, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              const Text("Add", style: TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      child,
    ]);
  }

  // ── Raw Material Card ──────────────────────────────────────

  Widget _rawMaterialCard(Map<String, dynamic> item) {
    double level = (item["level"] as double?) ?? 0.5;
    Color levelColor = level > 0.6
        ? accentGreen : level > 0.3 ? accentOrange : accentPink;
    List<Color> levelGradient = level > 0.6
        ? [const Color(0xFF00C48C), const Color(0xFF4DD9B0)]
        : level > 0.3
            ? [const Color(0xFFFF7A3D), const Color(0xFFFFAB76)]
            : [const Color(0xFFFF4D8D), const Color(0xFFFF85B3)];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: accentBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(item["name"],
              style: const TextStyle(color: textPrimary,
                  fontSize: 14, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text("${item["qty"]} ${item["unit"]}",
                style: const TextStyle(color: accentBlue,
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Stack(children: [
              Container(height: 6,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(3),
                  )),
              FractionallySizedBox(
                widthFactor: level,
                child: Container(height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: levelGradient),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [BoxShadow(
                      color: levelColor.withOpacity(0.4),
                      blurRadius: 6, offset: const Offset(0, 2),
                    )],
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Text("${(level * 100).round()}%",
              style: TextStyle(color: levelColor,
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  // ── Machine Card ───────────────────────────────────────────

  Widget _machineCard(Map<String, dynamic> machine) {
    bool isRunning = machine["status"] == "Running";
    Color statusColor = isRunning ? accentGreen : accentOrange;
    List<Color> statusGradient = isRunning
        ? [const Color(0xFF00C48C), const Color(0xFF4DD9B0)]
        : [const Color(0xFFFF7A3D), const Color(0xFFFFAB76)];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: statusGradient,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(
              color: statusColor.withOpacity(0.3),
              blurRadius: 8, offset: const Offset(0, 3),
            )],
          ),
          child: Icon(
            isRunning ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: Colors.white, size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(machine["name"], style: const TextStyle(
                color: textPrimary, fontSize: 14,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.access_time_rounded,
                  color: textSecondary, size: 12),
              const SizedBox(width: 4),
              Text("Uptime: ${machine["uptime"]}",
                  style: const TextStyle(
                      color: textSecondary, fontSize: 12)),
            ]),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: statusGradient,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: statusColor.withOpacity(0.3),
              blurRadius: 6, offset: const Offset(0, 2),
            )],
          ),
          child: Text(machine["status"],
              style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  // ── Production Card ────────────────────────────────────────

  Widget _productionCard(Map<String, dynamic> prod) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00C48C).withOpacity(0.08),
            const Color(0xFF4DD9B0).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentGreen.withOpacity(0.2)),
        boxShadow: [BoxShadow(
          color: accentGreen.withOpacity(0.08),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C48C), Color(0xFF4DD9B0)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(
              color: accentGreen.withOpacity(0.35),
              blurRadius: 8, offset: const Offset(0, 3),
            )],
          ),
          child: const Icon(Icons.widgets_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prod["product"], style: const TextStyle(
                color: textPrimary, fontSize: 14,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            const Text("Today's Output",
                style: TextStyle(color: textSecondary, fontSize: 12)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("${prod["qty"]}", style: const TextStyle(
              color: accentGreen, fontSize: 22,
              fontWeight: FontWeight.w800, height: 1.1)),
          Text(prod["unit"], style: const TextStyle(
              color: textSecondary, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _FieldConfig {
  final String label;
  final bool isNumeric;
  _FieldConfig(this.label, this.isNumeric);
}