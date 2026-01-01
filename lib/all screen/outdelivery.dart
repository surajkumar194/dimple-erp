import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class OutForDeliveryScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OutForDeliveryScreen({
    required this.orderId,
    required this.orderData,
    super.key,
  });

  @override
  State<OutForDeliveryScreen> createState() => _OutForDeliveryScreenState();
}

class _OutForDeliveryScreenState extends State<OutForDeliveryScreen> {
  late List<Map<String, dynamic>> productsWithControllers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeProducts();
  }

  void _initializeProducts() {
    final products = widget.orderData['data']?['products'] as List<dynamic>? ?? [];
    productsWithControllers = products.map((p) {
      return {
        'name': p['name'] ?? 'N/A',
        'originalQty': int.tryParse(p['quantity']?.toString() ?? '0') ?? 0,
        'deliveryQty': TextEditingController(
          text: (int.tryParse(p['quantity']?.toString() ?? '0') ?? 0).toString(),
        ),
        'images': p['images'] as List<dynamic>? ?? [],
      };
    }).toList();
  }

  @override
  void dispose() {
    for (var product in productsWithControllers) {
      (product['deliveryQty'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobData = widget.orderData['data'] ?? {};
    final jobNo = jobData['jobNo'] ?? 'N/A';
    final customer = jobData['customer'] ?? 'N/A';
    final salesPerson = jobData['salesPerson'] ?? 'N/A';
    final size = jobData['size'] ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 8,
        backgroundColor: const Color(0xFF00ACC1),
        title: const Text('🚚 Out for Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.blue.shade400]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Job Card: $jobNo', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(customer, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _infoChip(Icons.person, 'Sales: $salesPerson', Colors.white)),
                        const SizedBox(width: 8),
                        Expanded(child: _infoChip(Icons.crop, 'Size: $size', Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text('Delivery Quantities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),

              const SizedBox(height: 12),

              ...productsWithControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                final controller = product['deliveryQty'] as TextEditingController;

                return _buildProductDeliveryTile(
                  index: index + 1,
                  productName: product['name'],
                  originalQty: product['originalQty'],
                  controller: controller,
                  images: product['images'],
                );
              }).toList(),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.amber.shade50]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade300, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.summarize, color: Colors.orange.shade600, size: 24),
                        const SizedBox(width: 8),
                        Text('Delivery Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _summaryRow('Total Products', productsWithControllers.length.toString(), Colors.blue),
                    _summaryRow(
                      'Total Qty (Original)',
                      productsWithControllers.fold<int>(0, (sum, p) => sum + (p['originalQty'] as int)).toString(),
                      Colors.green,
                    ),
                    _summaryRow(
                      'Total Qty (Delivery)',
                      productsWithControllers.fold<int>(0, (sum, p) {
                        final val = int.tryParse((p['deliveryQty'] as TextEditingController).text) ?? 0;
                        return sum + val;
                      }).toString(),
                      Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.red.shade600, Colors.pink.shade600]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.purple.shade600, Colors.deepPurple.shade600]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _generatePDF(),
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Text('Generate PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.green.shade600, Colors.teal.shade600]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _submitDelivery(),
                    icon: const Icon(Icons.check_circle, size: 24, color: Colors.white),
                    label: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProductDeliveryTile({
    required int index,
    required String productName,
    required int originalQty,
    required TextEditingController controller,
    required List<dynamic> images,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.shade500, Colors.teal.shade500]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(index.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF212121))),
                    Text('Original: $originalQty pcs', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter Delivery Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade700)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter quantity',
                    prefixIcon: Icon(Icons.inventory, color: Colors.blue.shade600),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.blue.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),

          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text('Images (${images.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(images[i], width: 60, height: 60, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF() async {
    setState(() => _isLoading = true);

    try {
      final pdf = pw.Document();
      final jobData = widget.orderData['data'] ?? {};

      Uint8List logoBytes;
      try {
        final data = await rootBundle.load('assets/logo.png');
        logoBytes = data.buffer.asUint8List();
      } catch (e) {
        logoBytes = Uint8List(0);
      }

      final logoImage = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

      final jobNo = jobData['jobNo'] ?? 'N/A';
      final customer = jobData['customer'] ?? 'N/A';
      final salesPerson = jobData['salesPerson'] ?? 'N/A';
      final size = jobData['size'] ?? 'N/A';

      int totalOriginalQty = 0;
      int totalDeliveryQty = 0;

      for (var product in productsWithControllers) {
        totalOriginalQty += product['originalQty'] as int;
        final deliveryQty = int.tryParse((product['deliveryQty'] as TextEditingController).text) ?? 0;
        totalDeliveryQty += deliveryQty;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (_) => [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 80,
                  height: 80,
                  child: logoImage != null ? pw.Image(logoImage, fit: pw.BoxFit.contain) : null,
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DIMPLE PACKAGING PVT. LTD.', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Ludhiana, Punjab - 141008', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text('Contact: 9872518000 | GST: 03AADCD5371K1ZP', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 12),

            pw.Center(
              child: pw.Text('DELIVERY CHALLAN', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
            ),

            pw.SizedBox(height: 16),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.teal), borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Column(
                children: [
                  _pdfDetailRow('Job No', jobNo),
                  _pdfDetailRow('Customer', customer),
                  _pdfDetailRow('Sales Person', salesPerson),
                  _pdfDetailRow('Size', size),
                  _pdfDetailRow('Delivery Date', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            pw.Text('DELIVERY DETAILS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal200),
                  children: [
                    _pdfTableCell('No', header: true),
                    _pdfTableCell('Product', header: true),
                    _pdfTableCell('Orig.', header: true),
                    _pdfTableCell('Delivery', header: true),
                  ],
                ),
                ...productsWithControllers.asMap().entries.map((e) {
                  final idx = e.key + 1;
                  final product = e.value;
                  final deliveryQty = int.tryParse((product['deliveryQty'] as TextEditingController).text) ?? 0;

                  return pw.TableRow(
                    children: [
                      _pdfTableCell(idx.toString()),
                      _pdfTableCell(product['name']),
                      _pdfTableCell(product['originalQty'].toString()),
                      _pdfTableCell(deliveryQty.toString()),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfTableCell('', header: true),
                    _pdfTableCell('TOTAL', header: true),
                    _pdfTableCell(totalOriginalQty.toString(), header: true),
                    _pdfTableCell(totalDeliveryQty.toString(), header: true),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Prepared By', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                    pw.Text('_________________'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Authorized By', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                    pw.Text('_________________'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Received By', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                    pw.Text('_________________'),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'DeliveryChallan_$jobNo.pdf');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('✅ Delivery Challan PDF Generated Successfully'), backgroundColor: Colors.green.shade600, duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitDelivery() async {
    setState(() => _isLoading = true);

    try {
      final deliveredProducts = productsWithControllers.map((p) {
        return {
          'name': p['name'],
          'originalQty': p['originalQty'],
          'deliveredQty': int.tryParse((p['deliveryQty'] as TextEditingController).text) ?? 0,
        };
      }).toList();

      await FirebaseFirestore.instance.collection('dispatchedOrders').doc(widget.orderId).update({
        'deliveryStatus': 'Delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'deliveredProducts': deliveredProducts,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('✅ Delivery Confirmed Successfully'), backgroundColor: Colors.green.shade600, duration: const Duration(seconds: 2)),
        );

        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  pw.Widget _pdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  pw.Widget _pdfTableCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: header ? 11 : 10, fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }
}