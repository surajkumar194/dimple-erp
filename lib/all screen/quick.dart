// import 'dart:typed_data';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// // ═══════════════════════════════════════════════════════════
// //  MODEL
// // ═══════════════════════════════════════════════════════════

// class _QProduct {
//   final int id;
//   final nameCtrl = TextEditingController();
//   final qtyCtrl  = TextEditingController();
//   final rateCtrl = TextEditingController();
//   final pktCtrl  = TextEditingController();

//   _QProduct(this.id);

//   bool get valid =>
//       nameCtrl.text.trim().isNotEmpty &&
//       (int.tryParse(qtyCtrl.text) ?? 0) > 0;

//   Map<String, dynamic> toMap() => {
//     'productName':      nameCtrl.text.trim(),
//     'quantity':         int.tryParse(qtyCtrl.text)    ?? 0,
//     'rate':             double.tryParse(rateCtrl.text) ?? 0.0,
//     'packets':          int.tryParse(pktCtrl.text)    ?? 0,
//     'isManuallyAdded':  true,
//     'isOverDispatched': false,
//   };

//   void dispose() {
//     nameCtrl.dispose(); qtyCtrl.dispose();
//     rateCtrl.dispose(); pktCtrl.dispose();
//   }
// }

// // ═══════════════════════════════════════════════════════════
// //  PDF GENERATOR
// // ═══════════════════════════════════════════════════════════

// Future<void> generateQuickAddPDF(
//   Map<String, dynamic> data, {
//   bool showRate = true,
// }) async {
//   final pdf = pw.Document();

//   Uint8List logoBytes;
//   try {
//     final raw = await rootBundle.load('assets/1.jpg');
//     logoBytes = raw.buffer.asUint8List();
//   } catch (_) {
//     logoBytes = Uint8List(0);
//   }
//   final logoImg = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

//   final dateStr    = DateFormat('dd/MM/yyyy').format(DateTime.now());
//   final challNo    = data['challNo']    ?? 'N/A';
//   final driverName = data['driverName'] ?? '';
//   final signature  = data['signature']  ?? '';
//   final List items = data['items']      ?? [];
//   final int totalQty = data['totalQty']     ?? 0;
//   final int totalPkt = data['totalPackets'] ?? 0;

//   pdf.addPage(
//     pw.Page(
//       pageFormat: PdfPageFormat.a4,
//       margin: const pw.EdgeInsets.only(left: 18, right: 18, top: 10),
//       build: (pw.Context ctx) {
//         pw.Widget cell(
//           String text, {
//           bool bold = false,
//           bool center = false,
//           double fontSize = 11,
//           PdfColor? color,
//           PdfColor? bg,
//         }) =>
//             pw.Container(
//               color: bg,
//               padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//               alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
//               child: pw.Text(
//                 text,
//                 textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
//                 style: pw.TextStyle(
//                   fontSize: fontSize,
//                   fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//                   color: color ?? PdfColors.black,
//                 ),
//               ),
//             );

//         return pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             // ── Header ──
//             pw.Container(
//               height: 110,
//               child: pw.Stack(children: [
//                 if (logoImg != null)
//                   pw.Positioned(
//                     left: 20, top: 20,
//                     child: pw.Image(logoImg,
//                         width: 120, height: 110, fit: pw.BoxFit.contain),
//                   ),
//                 pw.Positioned(
//                   right: 10, top: 10,
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.end,
//                     children: [
//                       pw.Text('CHALLAN /',
//                           style: pw.TextStyle(
//                               fontSize: 24, fontWeight: pw.FontWeight.bold)),
//                       pw.Text('EXTRA ADD',
//                           style: pw.TextStyle(
//                               fontSize: 34,
//                               fontWeight: pw.FontWeight.bold,
//                               color: PdfColor.fromInt(0xFF005B4F))),
//                       pw.Container(
//                           width: 190, height: 2,
//                           color: PdfColor.fromInt(0xFF7CB342)),
//                     ],
//                   ),
//                 ),
//               ]),
//             ),

//             // ── Info row ──
//             pw.Row(
//               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//               children: [
//                 pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Row(children: [
//                       pw.Text('No.',
//                           style: pw.TextStyle(
//                               fontSize: 16, fontWeight: pw.FontWeight.bold)),
//                       pw.SizedBox(width: 14),
//                       pw.Text(challNo,
//                           style: pw.TextStyle(
//                               fontSize: 18,
//                               fontWeight: pw.FontWeight.bold,
//                               color: PdfColor.fromInt(0xFF005B4F))),
//                     ]),
//                     pw.SizedBox(height: 4),
//                     pw.Text('Extra Added Products',
//                         style: pw.TextStyle(
//                             fontSize: 20, fontWeight: pw.FontWeight.bold)),
//                   ],
//                 ),
//                 pw.Container(
//                   padding: const pw.EdgeInsets.all(12),
//                   decoration: pw.BoxDecoration(
//                       border: pw.Border.all(
//                           color: PdfColor.fromInt(0xFF7CB342), width: 1)),
//                   child: pw.Column(children: [
//                     pw.Text('Date', style: pw.TextStyle(fontSize: 13)),
//                     pw.SizedBox(height: 2),
//                     pw.Text(dateStr,
//                         style: pw.TextStyle(
//                             fontSize: 18, fontWeight: pw.FontWeight.bold)),
//                   ]),
//                 ),
//               ],
//             ),

//             pw.SizedBox(height: 10),

//             // ── Items Table ──
//             pw.Table(
//               border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.7),
//               columnWidths: {
//                 0: const pw.FixedColumnWidth(65),
//                 1: const pw.FlexColumnWidth(4),
//                 2: const pw.FixedColumnWidth(90),
//                 3: const pw.FixedColumnWidth(75),
//                 4: const pw.FixedColumnWidth(85),
//               },
//               children: [
//                 pw.TableRow(
//                   decoration: pw.BoxDecoration(
//                       color: PdfColor.fromInt(0xFF005B4F)),
//                   children: [
//                     cell('QNTY.', bold: true, center: true,
//                         color: PdfColors.white),
//                     cell('PARTICULARS', bold: true, color: PdfColors.white),
//                     cell('RATE', bold: true, center: true,
//                         color: PdfColors.white),
//                     cell('PACKET', bold: true, center: true,
//                         color: PdfColors.white),
//                     cell('NOTE', bold: true, center: true,
//                         color: PdfColors.white),
//                   ],
//                 ),
//                 ...items.asMap().entries.map<pw.TableRow>((entry) {
//                   final item = entry.value;
//                   return pw.TableRow(
//                     decoration: entry.key.isOdd
//                         ? const pw.BoxDecoration(color: PdfColors.grey100)
//                         : null,
//                     children: [
//                       cell('${item['quantity']}',
//                           bold: true, center: true, fontSize: 16),
//                       cell(item['productName'] ?? '',
//                           bold: true, fontSize: 14),
//                       cell(showRate ? 'Rs ${item['rate']}/-' : '',
//                           bold: true, center: true),
//                       cell('${item['packets']}',
//                           bold: true, center: true),
//                       cell('EXTRA',
//                           bold: true,
//                           center: true,
//                           color: PdfColor.fromInt(0xFFE65C00)),
//                     ],
//                   );
//                 }),
//                 pw.TableRow(children: [
//                   pw.SizedBox(height: 60),
//                   pw.SizedBox(), pw.SizedBox(),
//                   pw.SizedBox(), pw.SizedBox(),
//                 ]),
//                 pw.TableRow(children: [
//                   cell('Qty : $totalQty',
//                       bold: true,
//                       color: PdfColors.white,
//                       bg: PdfColor.fromInt(0xFF005B4F)),
//                   pw.SizedBox(), pw.SizedBox(),
//                   cell('Pct : $totalPkt', bold: true, center: true),
//                   pw.SizedBox(),
//                 ]),
//               ],
//             ),

//             pw.SizedBox(height: 10),

//             // ── Signature Table ──
//             pw.Table(
//               border: pw.TableBorder.all(
//                   color: PdfColor.fromInt(0xFF005B4F), width: 0.7),
//               columnWidths: {
//                 0: const pw.FlexColumnWidth(2),
//                 1: const pw.FlexColumnWidth(2),
//                 2: const pw.FlexColumnWidth(2),
//               },
//               children: [
//                 pw.TableRow(
//                   decoration: const pw.BoxDecoration(color: PdfColors.grey100),
//                   children: [
//                     cell("Receiver's Signature", bold: true, center: true),
//                     cell("Driver Name", bold: true, center: true),
//                     cell("Signature", bold: true, center: true),
//                   ],
//                 ),
//                 pw.TableRow(children: [
//                   pw.SizedBox(height: 80),
//                   pw.Container(
//                     height: 80, alignment: pw.Alignment.center,
//                     child: pw.Text(driverName.toUpperCase(),
//                         style: pw.TextStyle(
//                             fontSize: 18, fontWeight: pw.FontWeight.bold)),
//                   ),
//                   pw.Container(
//                     height: 80, alignment: pw.Alignment.center,
//                     child: pw.Text(signature,
//                         style: pw.TextStyle(
//                             fontSize: 18, fontWeight: pw.FontWeight.bold)),
//                   ),
//                 ]),
//                 pw.TableRow(children: [
//                   cell('DATE................................'),
//                   cell('Outgoing time...............'),
//                   pw.SizedBox(),
//                 ]),
//               ],
//             ),
//           ],
//         );
//       },
//     ),
//   );

//   await Printing.layoutPdf(
//       onLayout: (PdfPageFormat fmt) async => pdf.save());
// }

// // ═══════════════════════════════════════════════════════════
// //  RATE DIALOG
// // ═══════════════════════════════════════════════════════════

// Future<bool?> showRateTypeDialog(BuildContext context) {
//   return showModalBottomSheet<bool>(
//     context: context,
//     backgroundColor: Colors.white,
//     shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//     builder: (ctx) => Padding(
//       padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//               width: 40, height: 4,
//               decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2))),
//           const SizedBox(height: 20),
//           const Text('PDF Type',
//               style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1A237E))),
//           const SizedBox(height: 6),
//           Text('Rate column ke saath ya bina?',
//               style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
//           const SizedBox(height: 24),
//           Row(children: [
//             Expanded(
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(ctx, true),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(vertical: 18),
//                   decoration: BoxDecoration(
//                       color: const Color(0xFF1A237E),
//                       borderRadius: BorderRadius.circular(16)),
//                   child: const Column(
//                     children: [
//                       Icon(Icons.attach_money_rounded,
//                           color: Colors.white, size: 28),
//                       SizedBox(height: 8),
//                       Text('With Rate',
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 15)),
//                       SizedBox(height: 4),
//                       Text('Rate column included',
//                           style:
//                               TextStyle(color: Colors.white70, fontSize: 11)),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(ctx, false),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(vertical: 18),
//                   decoration: BoxDecoration(
//                       color: const Color(0xFF00695C),
//                       borderRadius: BorderRadius.circular(16)),
//                   child: const Column(
//                     children: [
//                       Icon(Icons.money_off_rounded,
//                           color: Colors.white, size: 28),
//                       SizedBox(height: 8),
//                       Text('Without Rate',
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 15)),
//                       SizedBox(height: 4),
//                       Text('Rate column hidden',
//                           style:
//                               TextStyle(color: Colors.white70, fontSize: 11)),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ]),
//         ],
//       ),
//     ),
//   );
// }

// // ═══════════════════════════════════════════════════════════
// //  QUICK ADD BOTTOM SHEET
// // ═══════════════════════════════════════════════════════════

// class QuickAddSheet extends StatefulWidget {
//   const QuickAddSheet({super.key});

//   @override
//   State<QuickAddSheet> createState() => _QuickAddSheetState();
// }

// class _QuickAddSheetState extends State<QuickAddSheet>
//     with SingleTickerProviderStateMixin {
//   final List<_QProduct> _rows = [];
//   final _driverCtrl   = TextEditingController();
//   final _signCtrl     = TextEditingController();
//   late TabController _tabCtrl;

//   String _challNo     = '';
//   int    _challNum    = 1;
//   bool   _isSaving    = false;
//   bool   _challLoaded = false;

//   @override
//   void initState() {
//     super.initState();
//     _tabCtrl = TabController(length: 2, vsync: this);
//     _addRow();
//     _addRow();
//     _fetchChallNo();
//   }

//   // ── Challan number: extraChallan collection se fetch ──
//   Future<void> _fetchChallNo() async {
//     try {
//       final snap = await FirebaseFirestore.instance
//           .collection('extraChallan')
//           .orderBy('challNumericId', descending: true)
//           .limit(1)
//           .get();
//       final next = snap.docs.isEmpty
//           ? 1
//           : ((snap.docs.first.data()['challNumericId'] as int?) ?? 0) + 1;
//       if (mounted) {
//         setState(() {
//           _challNum    = next;
//           _challNo     = 'EC$next';   // EC = Extra Challan
//           _challLoaded = true;
//         });
//       }
//     } catch (_) {
//       if (mounted) {
//         setState(() {
//           _challNum    = 1;
//           _challNo     = 'EC1';
//           _challLoaded = true;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     for (final r in _rows) r.dispose();
//     _driverCtrl.dispose();
//     _signCtrl.dispose();
//     _tabCtrl.dispose();
//     super.dispose();
//   }

//   void _addRow() {
//     setState(() => _rows.add(_QProduct(DateTime.now().millisecondsSinceEpoch)));
//   }

//   void _removeRow(int i) {
//     _rows[i].dispose();
//     setState(() => _rows.removeAt(i));
//   }

//   List<_QProduct> get _valid => _rows.where((r) => r.valid).toList();
//   int get _totalQty =>
//       _valid.fold(0, (s, r) => s + (int.tryParse(r.qtyCtrl.text) ?? 0));
//   int get _totalPkt =>
//       _valid.fold(0, (s, r) => s + (int.tryParse(r.pktCtrl.text) ?? 0));

//   // ── SAVE → extraChallan collection ──
//   Future<void> _save() async {
//     if (_valid.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Kam se kam ek product (name + qty) daalo!'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }
//     if (!_challLoaded) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Challan number load ho raha hai...')),
//       );
//       return;
//     }

//     setState(() => _isSaving = true);
//     try {
//       final items = _valid.map((r) => r.toMap()).toList();
//       final now   = Timestamp.now();

//       final data = <String, dynamic>{
//         'challNo':        _challNo,
//         'challNumericId': _challNum,
//         'driverName':     _driverCtrl.text.trim(),
//         'signature':      _signCtrl.text.trim(),
//         'items':          items,
//         'totalQty':       _totalQty,
//         'totalPackets':   _totalPkt,
//         'createdAt':      now,
//         'date':           now,
//         'type':           'extra_challan',
//         'status':         'Saved',
//       };

//       // ✅ Firebase mein 'extraChallan' collection mein save
//       await FirebaseFirestore.instance
//           .collection('extraChallan')
//           .add(data);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ Saved! Challan: $_challNo'),
//           backgroundColor: Colors.green.shade700,
//         ),
//       );

//       final bool? withRate = await showRateTypeDialog(context);
//       if (withRate != null) {
//         await generateQuickAddPDF(data, showRate: withRate);
//       }

//       if (mounted) Navigator.pop(context, _valid.length);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.93,
//       minChildSize: 0.5,
//       maxChildSize: 0.97,
//       expand: false,
//       builder: (_, sc) => Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         child: Column(
//           children: [
//             _buildHandle(),
//             _buildHeader(),
//             _buildMetaRow(),
//             _buildTabBar(),
//             Expanded(
//               child: TabBarView(
//                 controller: _tabCtrl,
//                 children: [
//                   _buildAddTab(sc),
//                   _buildHistoryTab(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHandle() => Container(
//         margin: const EdgeInsets.only(top: 10, bottom: 4),
//         width: 40,
//         height: 4,
//         decoration: BoxDecoration(
//             color: Colors.grey.shade300,
//             borderRadius: BorderRadius.circular(2)),
//       );

//   Widget _buildHeader() => Padding(
//         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.add_box_rounded,
//                   color: Colors.white, size: 24),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('Extra Challan',
//                       style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1A237E))),
//                   Text('Bina order ke extra products dispatch karo',
//                       style:
//                           TextStyle(fontSize: 11, color: Colors.grey.shade500)),
//                 ],
//               ),
//             ),
//             // Challan badge
//             Container(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFE8EAF6),
//                 border: Border.all(color: const Color(0xFF9FA8DA)),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: _challLoaded
//                   ? Text(_challNo,
//                       style: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1A237E)))
//                   : const SizedBox(
//                       width: 14,
//                       height: 14,
//                       child: CircularProgressIndicator(
//                           strokeWidth: 2, color: Color(0xFF1A237E))),
//             ),
//           ],
//         ),
//       );

//   Widget _buildMetaRow() => Padding(
//         padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
//         child: Row(
//           children: [
//             Expanded(
//                 child: _metaField(
//                     _driverCtrl, 'Driver Name', Icons.drive_eta_rounded)),
//             const SizedBox(width: 10),
//             Expanded(
//                 child:
//                     _metaField(_signCtrl, 'Signature', Icons.draw_rounded)),
//           ],
//         ),
//       );

//   Widget _metaField(
//           TextEditingController ctrl, String label, IconData icon) =>
//       TextField(
//         controller: ctrl,
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle:
//               TextStyle(fontSize: 12, color: Colors.grey.shade600),
//           prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
//           filled: true,
//           fillColor: const Color(0xFFF4F6FF),
//           border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide.none),
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           isDense: true,
//         ),
//       );

//   Widget _buildTabBar() => Container(
//         margin: const EdgeInsets.only(top: 12),
//         decoration: BoxDecoration(
//             border: Border(
//                 bottom: BorderSide(
//                     color: Colors.grey.shade200, width: 1))),
//         child: TabBar(
//           controller: _tabCtrl,
//           labelColor: const Color(0xFF1A237E),
//           unselectedLabelColor: Colors.grey.shade500,
//           labelStyle: const TextStyle(
//               fontWeight: FontWeight.bold, fontSize: 13),
//           indicatorColor: const Color(0xFF1A237E),
//           indicatorWeight: 2.5,
//           tabs: [
//             Tab(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.add_rounded, size: 16),
//                   const SizedBox(width: 6),
//                   const Text('Add Products'),
//                   if (_valid.isNotEmpty) ...[
//                     const SizedBox(width: 6),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                           color: Colors.green.shade100,
//                           borderRadius: BorderRadius.circular(10)),
//                       child: Text('${_valid.length}',
//                           style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green.shade700)),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             const Tab(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.history_rounded, size: 16),
//                   SizedBox(width: 6),
//                   Text('History'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );

//   Widget _buildAddTab(ScrollController sc) {
//     return ListView(
//       controller: sc,
//       padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
//       children: [
//         // Column header
//         Padding(
//           padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
//           child: Row(
//             children: [
//               const Expanded(
//                   flex: 5,
//                   child: Text('PRODUCT NAME',
//                       style: TextStyle(
//                           fontSize: 9,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey,
//                           letterSpacing: 0.5))),
//               for (final l in ['QTY', 'RATE ₹', 'PKT'])
//                 SizedBox(
//                   width: 58,
//                   child: Text(l,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                           fontSize: 9,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey,
//                           letterSpacing: 0.5)),
//                 ),
//               const SizedBox(width: 28),
//             ],
//           ),
//         ),

//         // Product rows
//         ..._rows.asMap().entries.map((e) => _buildRow(e.key, e.value)),

//         // Add row button
//         GestureDetector(
//           onTap: _addRow,
//           child: Container(
//             margin: const EdgeInsets.only(top: 4, bottom: 14),
//             padding: const EdgeInsets.symmetric(vertical: 13),
//             decoration: BoxDecoration(
//               color: Colors.amber.shade50,
//               borderRadius: BorderRadius.circular(14),
//               border:
//                   Border.all(color: Colors.amber.shade300, width: 1.5),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                       color: Colors.amber.shade600,
//                       borderRadius: BorderRadius.circular(6)),
//                   child: const Icon(Icons.add_rounded,
//                       color: Colors.white, size: 16),
//                 ),
//                 const SizedBox(width: 8),
//                 Text('Add another product',
//                     style: TextStyle(
//                         color: Colors.amber.shade800,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13)),
//               ],
//             ),
//           ),
//         ),

//         // Summary strip
//         Container(
//           padding: const EdgeInsets.all(18),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: _valid.isEmpty
//                   ? [Colors.grey.shade400, Colors.grey.shade500]
//                   : [const Color(0xFF1A237E), const Color(0xFF1565C0)],
//             ),
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: _valid.isEmpty
//                 ? []
//                 : [
//                     BoxShadow(
//                       color:
//                           const Color(0xFF1A237E).withOpacity(0.3),
//                       blurRadius: 12,
//                       offset: const Offset(0, 6),
//                     )
//                   ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _sumChip('Products', '${_valid.length}'),
//               Container(
//                   width: 1,
//                   height: 36,
//                   color: const Color.fromARGB(255, 239, 9, 9).withOpacity(0.25)),
//               _sumChip('Total Qty', '$_totalQty'),
//               Container(
//                   width: 1,
//                   height: 36,
//                   color: const Color.fromARGB(255, 238, 5, 5).withOpacity(0.25)),
//               _sumChip('Packets', '$_totalPkt'),
//             ],
//           ),
//         ),

//         const SizedBox(height: 14),

//         // Save button
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton.icon(
//             onPressed: _isSaving ? null : _save,
//             icon: _isSaving
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                         color: Colors.white, strokeWidth: 2))
//                 : const Icon(Icons.picture_as_pdf_rounded, size: 20),
//             label: Text(
//                 _isSaving ? 'Saving...' : 'Save & Generate PDF',
//                 style: const TextStyle(
//                     fontSize: 15, fontWeight: FontWeight.bold)),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF1B5E20),
//               foregroundColor: Colors.white,
//               disabledBackgroundColor: Colors.grey.shade400,
//               disabledForegroundColor: Colors.white60,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14)),
//               elevation: 0,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRow(int i, _QProduct r) {
//     final bool active = r.valid;
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       margin: const EdgeInsets.only(bottom: 1),
//       decoration: BoxDecoration(
//         color: active ? const Color(0xFFF0F4FF) : Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: active
//               ? const Color(0xFF1A237E)
//               : Colors.grey.shade200,
//           width: active ? 1.5 : 1,
//         ),
//       ),
//       child: Column(
//         children: [
//           // Name row
//           Padding(
//             padding: const EdgeInsets.fromLTRB(10, 9, 8, 6),
//             child: Row(
//               children: [
//                 // Row number
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   width: 22,
//                   height: 35,
//                   decoration: BoxDecoration(
//                     color: active
//                         ? const Color(0xFF1A237E)
//                         : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Center(
//                     child: Text('${i + 1}',
//                         style: TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.bold,
//                             color: active
//                                 ? Colors.white
//                                 : Colors.grey.shade600)),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: TextField(
//                     controller: r.nameCtrl,
//                     textCapitalization: TextCapitalization.words,
//                     onChanged: (_) => setState(() {}),
//                     style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1E293B)),
//                     decoration: InputDecoration(
//                       hintText: 'Product name *',
//                       hintStyle: TextStyle(
//                           color: Colors.grey.shade400,
//                           fontSize: 12,
//                           fontWeight: FontWeight.normal),
//                       border: InputBorder.none,
//                       isDense: true,
//                       contentPadding: EdgeInsets.zero,
//                     ),
//                   ),
//                 ),
//                 // Check indicator
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   width: 20,
//                   height: 20,
//                   decoration: BoxDecoration(
//                     color: active
//                         ? Colors.green.shade500
//                         : Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(5),
//                   ),
//                   child:
//                       const Icon(Icons.check_rounded, color: Colors.white, size: 13),
//                 ),
//                 const SizedBox(width: 6),
//                 // Delete
//                 if (_rows.length > 1)
//                   GestureDetector(
//                     onTap: () => _removeRow(i),
//                     child: Container(
//                       padding: const EdgeInsets.all(5),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         borderRadius: BorderRadius.circular(7),
//                       ),
//                       child: Icon(Icons.delete_outline_rounded,
//                           color: Colors.red.shade400, size: 16),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           // Divider
//           Divider(height: 1, color: Colors.grey.shade100),
//           // Qty / Rate / Pkt
//           IntrinsicHeight(
//             child: Row(
//               children: [
//                 _numCell(r.qtyCtrl, 'Qty', false, first: true),
//                 VerticalDivider(width: 1, color: Colors.grey.shade100),
//                 _numCell(r.rateCtrl, 'Rate ₹', true),
//                 VerticalDivider(width: 1, color: Colors.grey.shade100),
//                 _numCell(r.pktCtrl, 'Pkt', false),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//  Widget _numCell(
//   TextEditingController ctrl,
//   String label,
//   bool decimal, {
//   bool first = false,
// }) =>
//     Expanded(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [

//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 9,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//                 letterSpacing: 0.4,
//               ),
//             ),

//             const SizedBox(height: 2),

//             SizedBox(
//               height: 30,
//               child: TextField(
//                 controller: ctrl,

//                 keyboardType:
//                     TextInputType.numberWithOptions(
//                   decimal: decimal,
//                 ),

//                 inputFormatters: [
//                   decimal
//                       ? FilteringTextInputFormatter.allow(
//                           RegExp(r'^\d*\.?\d*'),
//                         )
//                       : FilteringTextInputFormatter.digitsOnly
//                 ],

//                 onChanged: (_) => setState(() {}),

//                 textAlign: TextAlign.center,

//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1E293B),
//                 ),

//                 decoration: InputDecoration(
//                   hintText: '0',

//                   hintStyle: TextStyle(
//                     color: Colors.grey.shade300,
//                     fontSize: 12,
//                   ),

//                   border: InputBorder.none,

//                   isDense: true,

//                   contentPadding:
//                       const EdgeInsets.symmetric(
//                     vertical: 6,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   Widget _sumChip(String label, String value) => Column(
//         children: [
//           Text(value,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 17)),
//           const SizedBox(height: 1),
//           Text(label,
//               style:
//                   const TextStyle(color: Colors.white70, fontSize: 11)),
//         ],
//       );

//   Widget _buildHistoryTab() =>
//       const QuickAddHistoryList(embedded: true);
// }

// // ═══════════════════════════════════════════════════════════
// //  HISTORY LIST — extraChallan collection se real-time
// // ═══════════════════════════════════════════════════════════

// class QuickAddHistoryList extends StatelessWidget {
//   final bool embedded;
//   const QuickAddHistoryList({super.key, this.embedded = false});

//   String _fmt(dynamic ts) {
//     if (ts is! Timestamp) return 'N/A';
//     return DateFormat('dd/MM/yyyy  hh:mm a').format(ts.toDate());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('extraChallan')          // ✅ extraChallan collection
//           .orderBy('createdAt', descending: true)
//           .snapshots(),
//       builder: (ctx, snap) {
//         if (!snap.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         final docs = snap.data!.docs;
//         if (docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.history_rounded,
//                     size: 70, color: Colors.grey.shade300),
//                 const SizedBox(height: 14),
//                 Text('Koi history nahi mili',
//                     style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade400)),
//                 const SizedBox(height: 6),
//                 Text('Pehle kuch extra challan save karo',
//                     style: TextStyle(
//                         fontSize: 13, color: Colors.grey.shade400)),
//               ],
//             ),
//           );
//         }

//         return ListView.builder(
//           padding:
//               EdgeInsets.fromLTRB(12, 12, 12, embedded ? 20 : 80),
//           itemCount: docs.length,
//           itemBuilder: (ctx, i) {
//             final data = docs[i].data() as Map<String, dynamic>;
//             return _HistoryCard(data: data, fmt: _fmt);
//           },
//         );
//       },
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════
// //  HISTORY CARD — puri details
// // ═══════════════════════════════════════════════════════════

// class _HistoryCard extends StatelessWidget {
//   final Map<String, dynamic> data;
//   final String Function(dynamic) fmt;
//   const _HistoryCard({required this.data, required this.fmt});

//   @override
//   Widget build(BuildContext context) {
//     final challNo   = data['challNo']      ?? 'N/A';
//     final createdAt = fmt(data['createdAt']);
//     final totalQty  = data['totalQty']     ?? 0;
//     final totalPkt  = data['totalPackets'] ?? 0;
//     final driver    = data['driverName']   ?? '';
//     final signature = data['signature']    ?? '';
//     final List items = data['items']       ?? [];

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.indigo.shade100),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.indigo.withOpacity(0.08),
//               blurRadius: 16,
//               offset: const Offset(0, 6)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Card header ──
//           Container(
//             padding: const EdgeInsets.symmetric(
//                 horizontal: 16, vertical: 14),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
//               ),
//               borderRadius:
//                   BorderRadius.vertical(top: Radius.circular(19)),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.18),
//                       borderRadius: BorderRadius.circular(9)),
//                   child: const Icon(Icons.receipt_long_rounded,
//                       color: Colors.white, size: 20),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(challNo,
//                           style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18)),
//                       Text(createdAt,
//                           style: const TextStyle(
//                               color: Colors.white60, fontSize: 11)),
//                     ],
//                   ),
//                 ),
//                 // Items count badge
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10, vertical: 5),
//                   decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.18),
//                       borderRadius: BorderRadius.circular(8)),
//                   child: Text('${items.length} Items',
//                       style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 11,
//                           fontWeight: FontWeight.bold)),
//                 ),
//               ],
//             ),
//           ),

//           // ── Summary chips ──
//           Padding(
//             padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 6,
//               children: [
//                 _chip(Icons.format_list_numbered_rounded,
//                     'Total Qty: $totalQty', Colors.blue),
//                 _chip(Icons.inventory_2_rounded,
//                     'Packets: $totalPkt', Colors.orange),
//                 if (driver.isNotEmpty)
//                   _chip(Icons.drive_eta_rounded, 'Driver: $driver',
//                       Colors.teal),
//                 if (signature.isNotEmpty)
//                   _chip(Icons.draw_rounded, 'Sign: $signature',
//                       Colors.purple),
//               ],
//             ),
//           ),

//           // ── Divider ──
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 14),
//             child: Divider(color: Colors.grey.shade100, height: 16),
//           ),

//           // ── Product rows ──
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 14),
//             child: Text('Products',
//                 style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey.shade500,
//                     letterSpacing: 0.5)),
//           ),
//           const SizedBox(height: 6),

//           ...items.asMap().entries.map<Widget>((entry) {
//             final idx  = entry.key;
//             final item = entry.value;
//             final name = item['productName'] ?? '';
//             final qty  = item['quantity']    ?? 0;
//             final rate = item['rate']        ?? 0;
//             final pkt  = item['packets']     ?? 0;

//             return Container(
//               margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: idx.isEven
//                     ? const Color(0xFFF0F4FF)
//                     : Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.indigo.shade50),
//               ),
//               child: Row(
//                 children: [
//                   // Serial + Qty
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [
//                             Color(0xFF1A237E),
//                             Color(0xFF1565C0)
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(10)),
//                     child: Center(
//                       child: Text('$qty',
//                           style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14)),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(name,
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                                 color: Color(0xFF1A237E))),
//                         const SizedBox(height: 3),
//                         Row(
//                           children: [
//                             _microChip('Rate: ₹$rate',
//                                 Colors.green.shade100,
//                                 Colors.green.shade700),
//                             const SizedBox(width: 6),
//                             _microChip('Pkt: $pkt',
//                                 Colors.orange.shade100,
//                                 Colors.orange.shade700),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   // EXTRA badge
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                         color: Colors.amber.shade50,
//                         borderRadius: BorderRadius.circular(7),
//                         border: Border.all(
//                             color: Colors.amber.shade300)),
//                     child: Text('EXTRA',
//                         style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.amber.shade800)),
//                   ),
//                 ],
//               ),
//             );
//           }),

//           const SizedBox(height: 4),

//           // ── Reprint button ──
//           Padding(
//             padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
//             child: GestureDetector(
//               onTap: () async {
//                 final bool? wr = await showRateTypeDialog(context);
//                 if (wr != null) {
//                   await generateQuickAddPDF(data, showRate: wr);
//                 }
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 13),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [
//                       Color(0xFF1B5E20),
//                       Color(0xFF388E3C)
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.green.withOpacity(0.25),
//                       blurRadius: 8,
//                       offset: const Offset(0, 4),
//                     )
//                   ],
//                 ),
//                 child: const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.picture_as_pdf_rounded,
//                         color: Colors.white, size: 18),
//                     SizedBox(width: 8),
//                     Text('Re-Print / Download PDF',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _chip(IconData icon, String label, MaterialColor c) =>
//       Container(
//         padding:
//             const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
//         decoration: BoxDecoration(
//             color: c.shade50,
//             borderRadius: BorderRadius.circular(8)),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 12, color: c.shade700),
//             const SizedBox(width: 4),
//             Text(label,
//                 style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                     color: c.shade700)),
//           ],
//         ),
//       );

//   Widget _microChip(String label, Color bg, Color fg) => Container(
//         padding:
//             const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//         decoration: BoxDecoration(
//             color: bg, borderRadius: BorderRadius.circular(6)),
//         child: Text(label,
//             style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w600,
//                 color: fg)),
//       );
// }

// // ═══════════════════════════════════════════════════════════
// //  FULL HISTORY PAGE
// // ═══════════════════════════════════════════════════════════

// class QuickAddHistoryPage extends StatelessWidget {
//   const QuickAddHistoryPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF0F4FF),
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(60),
//         child: AppBar(
//           automaticallyImplyLeading: false,
//           elevation: 0,
//           flexibleSpace: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF4A148C),
//                   Color(0xFF7B1FA2),
//                   Color(0xFF0D47A1),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           title: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12)),
//                     child: const Icon(
//                         Icons.arrow_back_ios_new_rounded,
//                         color: Colors.white,
//                         size: 18),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Extra Challan History',
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18)),
//                       Text('Sab extra challan records',
//                           style: TextStyle(
//                               color: Colors.white70, fontSize: 12)),
//                     ],
//                   ),
//                 ),
//                 // Total count badge
//                 StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance
//                       .collection('extraChallan')
//                       .snapshots(),
//                   builder: (ctx, snap) {
//                     final count =
//                         snap.hasData ? snap.data!.docs.length : 0;
//                     return Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 5),
//                       decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(8)),
//                       child: Text('$count Total',
//                           style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 12)),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: const QuickAddHistoryList(),
//     );
//   }
// }