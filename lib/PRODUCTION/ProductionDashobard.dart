import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class UltraFlowProductionDashboard extends StatelessWidget {
  const UltraFlowProductionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
              Color(0xFF1e1e3f),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('machine_production')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.cyan),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No Data Yet",
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      color: Colors.white70,
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              int planned = 0, actual = 0, good = 0, reject = 0;
              double totalEff = 0;

              for (var doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                planned += (d['plannedQty'] ?? 0) as int;
                actual += (d['actualQty'] ?? 0) as int;
                good += (d['goodQty'] ?? 0) as int;
                reject += (d['rejection'] ?? 0) as int;
                totalEff += (d['efficiency'] ?? 0).toDouble();
              }
              final avgEff = docs.isNotEmpty ? totalEff / docs.length : 0.0;

              return CustomScrollView(
                slivers: [
                  // === Glowing AppBar ===
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    expandedHeight: 120,
                    floating: true,
 leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white, // ✅ white icon
          size: 22,
        ),
        onPressed: () {
          Navigator.pop(context); // ✅ navigation pop
        },
      ),

                    flexibleSpace: FlexibleSpaceBar(
                      title: AnimatedTextKit(
                        animatedTexts: [
                          FlickerAnimatedText(
                            'PRODUCTION FLOW',
                            textStyle: GoogleFonts.orbitron(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  color: Colors.cyan,
                                  blurRadius: 20,
                                )
                              ],
                            ),
                          ),
                        ],
                        repeatForever: true,
                      ),
                      centerTitle: true,
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Date
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                            style: GoogleFonts.exo2(
                              color: Colors.cyanAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Animated Counter Cards
                          Row(
                            children: [
                              Expanded(child: GlowCard(title: "Planned", value: planned, color: Colors.blue)),
                              const SizedBox(width: 12),
                              Expanded(child: GlowCard(title: "Actual", value: actual, color: Colors.purple)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: GlowCard(title: "Good", value: good, color: Colors.green)),
                              const SizedBox(width: 12),
                              Expanded(child: GlowCard(title: "Reject", value: reject, color: Colors.red)),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Hero Efficiency Card
                          HeroEfficiencyCard(efficiency: avgEff),

                          const SizedBox(height: 30),

                          // Flowing Charts
                         GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Production Flow", style: GoogleFonts.exo2(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 300,
                                  child: AnimatedBarChart(
                                    planned: planned,
                                    actual: actual,
                                    good: good,
                                    reject: reject,
                                  ),
                                ),
                              ],
                            ),
                          ),

                      
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ================= PREMIUM GLOW CARD =================
class GlowCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const GlowCard({required this.title, required this.value, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOutCubic,
      builder: (context, double animatedValue, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.6), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.exo2(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                animatedValue.toInt().toString(),
                style: GoogleFonts.orbitron(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: color, blurRadius: 15)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================= HERO EFFICIENCY CARD =================
class HeroEfficiencyCard extends StatelessWidget {
  final double efficiency;
  const HeroEfficiencyCard({required this.efficiency, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF00dbde), Color(0xFFfc00ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.cyan.withOpacity(0.7), blurRadius: 30, spreadRadius: 5),
          BoxShadow(color: Colors.purple.withOpacity(0.7), blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Text("Overall Efficiency", style: GoogleFonts.exo2(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 12),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: efficiency),
            duration: const Duration(seconds: 2),
            builder: (context, value, _) {
              return Text(
                "${value.toStringAsFixed(1)}%",
                style: GoogleFonts.orbitron(fontSize: 70, fontWeight: FontWeight.bold, color: Colors.white),
              );
            },
          ),
          Text(
            efficiency > 90 ? "Outstanding!" : efficiency > 75 ? "Great Job!" : "Push Harder!",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ================= GLASS CONTAINER =================
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}

// ================= ANIMATED BAR CHART =================
// REPLACE your old AnimatedBarChart with this FIXED version
class AnimatedBarChart extends StatefulWidget {
  final int planned, actual, good, reject;

  const AnimatedBarChart({
    required this.planned,
    required this.actual,
    required this.good,
    required this.reject,
    super.key,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planned != widget.planned ||
        oldWidget.actual != widget.actual ||
        oldWidget.good != widget.good ||
        oldWidget.reject != widget.reject) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = [
      widget.planned,
      widget.actual,
      widget.good,
      widget.reject
    ];
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = (maxValue > 0 ? maxValue * 1.3 : 100).toDouble();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            maxY: maxY,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),

            // ✅ TITLES
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),

              // 👇 BOTTOM NAMES
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    switch (value.toInt()) {
                      case 0:
                        return _bottomText("Planned");
                      case 1:
                        return _bottomText("Actual");
                      case 2:
                        return _bottomText("Good");
                      case 3:
                        return _bottomText("Reject");
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),

            barGroups: [
              _makeBar(0, widget.planned, const Color(0xFF3b82f6)),
              _makeBar(1, widget.actual, const Color(0xFF8b5cf6)),
              _makeBar(2, widget.good, const Color(0xFF10b981)),
              _makeBar(3, widget.reject, const Color(0xFFef4444)),
            ],
          ),
        );
      },
    );
  }

  BarChartGroupData _makeBar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: _animation.value * value,
          color: color,
          width: 34,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ],
    );
  }

  // 👇 Bottom label widget
  Widget _bottomText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}