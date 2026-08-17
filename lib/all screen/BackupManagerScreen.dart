import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

// ─── Color constants (same as rest of app) ───────────────────────────────────
class _AppColors {
  static const Color primary = Color(0xFF169a8d);
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF169a8d), Color(0xFF0d7c70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class BackupOrdersTab extends StatefulWidget {
  const BackupOrdersTab({super.key});
  @override
  State<BackupOrdersTab> createState() => _BackupOrdersTabState();
}

class _BackupOrdersTabState extends State<BackupOrdersTab> {
  String searchQuery = '';
  bool _isLoading = false;
  DateTimeRange? _selectedDateRange;
  String _selectedDateFilter = 'All';
  String _selectedUnit = 'All';


  List safeList(dynamic data) {
    if (data is List) return data;
    if (data is Map) return data.values.toList();
    return [];
  }

  void downloadFileWeb(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<pw.ImageProvider?> _loadNetworkImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('Image load error: $e');
    }
    return null;
  }

  Future<String?> _getJobNoFromBackupOrder(String orderId) async {
    // Check jobCards collection linked to this backup order
    final snap = await FirebaseFirestore.instance
        .collection('jobCards')
        .where('linkedOrderId', isEqualTo: orderId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return snap.docs.first.id;
    return null;
  }

  Future<bool> _checkIfJobCardExistsForBackup(String orderId) async {
    final snap = await FirebaseFirestore.instance
        .collection('jobCards')
        .where('linkedOrderId', isEqualTo: orderId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ─── PDF Row builder ─────────────────────────────────────────────────────

  pw.TableRow _buildPdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.grey200,
          child: pw.Text(label,
              style:
                  pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  // ─── Generate PDF (same logic as SelectSalesOrderTab) ────────────────────

  Future<void> _generateAllProductsPDF(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    final pdf = pw.Document();
    final jobNo = await _getJobNoFromBackupOrder(orderId) ?? orderId;
    final notes = orderData['notes'] ?? '';
    final products = safeList(orderData['products']);
    final orderDate =
        (orderData['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final deliveryDate =
        (orderData['deliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final customerName = orderData['customerName'] ?? '';
    final companyName = orderData['companyName'] ?? '';
    final salesPerson = orderData['salesPerson'] ?? '';

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final dplNo = product['dplNo'] ?? '$jobNo-${i + 1}';
      final rawSections = product['sections'];
      final Map<String, dynamic> sections =
          rawSections is Map<String, dynamic> ? rawSections : {};

      String getDetail(dynamic value) {
        if (value == null) return '';
        if (value is String) return value;
        if (value is Map) {
          return value['detail']?.toString() ??
              value['details']?.toString() ??
              value['value']?.toString() ??
              '';
        }
        return value.toString();
      }

      final trayDetail =
          getDetail(sections['trayDetail']) + getDetail(sections['tray']);
      final salophinDetail =
          getDetail(sections['salophinDetail']) + getDetail(sections['salophin']);
      final boxCoverDetail =
          getDetail(sections['boxCoverDetail']) + getDetail(sections['boxCover']);
      final innerDetail =
          getDetail(sections['innerDetail']) + getDetail(sections['inner']);
      final bottomDetail =
          getDetail(sections['bottomDetail']) + getDetail(sections['bottom']);
      final dieDetail =
          getDetail(sections['dieDetail']) + getDetail(sections['die']);
      final otherDetail =
          getDetail(sections['otherDetail']) + getDetail(sections['other']);
      final extraSections =
          product['customExtraSections'] is List
              ? product['customExtraSections']
              : [];
      final images =
          product['images'] is List ? product['images'] : [];

      List<pw.ImageProvider> loadedImages = [];
      for (final url in images) {
        if (url is String && url.isNotEmpty) {
          final img = await _loadNetworkImage(url);
          if (img != null) loadedImages.add(img);
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(
             marginTop: 1,
            marginBottom: 5,
            marginLeft: 1,
            marginRight: 1,
          ),
          build: (context) {
            return pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: <pw.Widget>[
                  pw.Text(
                    'All Rights Reserved © Dimple Packaging Pvt. Ltd.',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.yellow700,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Job No: $jobNo',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('DPL: $dplNo',
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              "Order Location: ${orderData['unit'] ?? 'N/A'}",
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                          // pw.Text(
                          //     "[BACKUP ORDER]",
                          //     style: pw.TextStyle(
                          //         fontSize: 10,
                          //         fontWeight: pw.FontWeight.bold,
                          //         color: PdfColors.red700)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                              'DATE - ${DateFormat('dd-MM-yyyy').format(orderDate)}',
                              style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey300,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text('DATE OF SUPPLY',
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(
                                    DateFormat('dd-MM-yyyy')
                                        .format(deliveryDate),
                                    style: const pw.TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        companyName.toString().trim().isNotEmpty
                            ? '$customerName ($companyName)'
                            : customerName,
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey600),
                    children: [
                      _buildPdfRow('Product', product['productName'] ?? ''),
                      _buildPdfRow(
                          'Category', product['productCategory'] ?? ''),
                      _buildPdfRow(
                          'Dimensions (L×H×W)',
                          '${product['length'] ?? ''} × ${product['height'] ?? ''} × ${product['width'] ?? ''}'),
                      _buildPdfRow(
                          'Quantity', '${product['quantity'] ?? ''}'),
                      // _buildPdfRow(
                      //     'HSN Code', product['hsnCode']?.toString() ?? ''),
                      // _buildPdfRow(
                      //     'GST %',
                      //     '${product['gstPercent'] ?? ''}%'),
                      if ((product['remarks'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty)
                        _buildPdfRow('Remark', product['remarks']),
                      _buildPdfRow('Assign Person', ''),
                     if (trayDetail.toString().trim().isNotEmpty)
                        _buildPdfRow('Tray', trayDetail),
                      if (salophinDetail.toString().trim().isNotEmpty)
                        _buildPdfRow('Salophin', salophinDetail),
                      if (boxCoverDetail.toString().trim().isNotEmpty)
                        _buildPdfRow('Box Cover', boxCoverDetail),
                      if (innerDetail.toString().trim().isNotEmpty)
                        _buildPdfRow('Inner', innerDetail),
                      if (bottomDetail.toString().trim().isNotEmpty)
                        _buildPdfRow('Bottom', bottomDetail),
                      if (dieDetail.toString().trim().isNotEmpty)
                        _buildPdfRow('Die', dieDetail),
                      if (otherDetail.toString().trim().isNotEmpty)
                        _buildPdfRow('Other', otherDetail.toString()),
                      if (extraSections.isNotEmpty)
                        ...extraSections.map<pw.TableRow?>((sec) {
                          final detail = sec['detail'] ?? sec['details'] ?? '';
                          if (detail.toString().trim().isEmpty) return null;
                          return _buildPdfRow(sec['title'] ?? 'Extra', detail);
                        }).whereType<pw.TableRow>(),
                      _buildPdfRow('Conerned Person', salesPerson),
                    ],
                  ),
                  if (notes.toString().trim().isNotEmpty) ...[
                    pw.SizedBox(height: 1),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Additional Notes:',
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 0.1),
                          pw.Text(notes,
                              style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                pw.SizedBox(height: 3),
                    if (loadedImages.isNotEmpty)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Product Images:',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 4),
                            pw.Expanded(
                              child: pw.GridView(
                                crossAxisCount:
                                    loadedImages.length <= 3
                                        ? loadedImages.length
                                        : 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.2,
                                children: loadedImages
                                    .map((img) =>
                                        pw.Image(img, fit: pw.BoxFit.contain))
                                    .toList(),
                              ),
                            ),
                                                      pw.SizedBox(height: 4),

                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      }
       final pdfBytes = await pdf.save();
      final images = await Printing.raster(pdfBytes, dpi: 150).toList();

      if (kIsWeb) {
        final archive = Archive();
        int page = 1;
        for (final img in images) {
          final pngBytes = await img.toPng();
          archive.addFile(ArchiveFile(
            'JobCard_${orderId}_Page$page.png',
            pngBytes.length,
            pngBytes,
          ));
          page++;
        }
        final zipData = ZipEncoder().encode(archive)!;
        downloadFileWeb(
            Uint8List.fromList(zipData), 'JobCard_$orderId.zip');
      } else {
        int page = 1;
        for (final img in images) {
          final pngBytes = await img.toPng();
          await Printing.sharePdf(
            bytes: pngBytes,
            filename: 'JobCard_${orderId}_Page$page.png',
          );
          page++;
        }
      }
    } 
  // ─── Generate JPG ─────────────────────────────────────────────────────────

  Future<void> _generateAllProductsJPG(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    _showLoadingDialog();
    try {
      final pdf = pw.Document();
      final jobNo = await _getJobNoFromBackupOrder(orderId) ?? orderId;
      final notes = orderData['notes'] ?? '';
      final products = safeList(orderData['products']);
      final orderDate =
          (orderData['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final deliveryDate =
          (orderData['deliveryDate'] as Timestamp?)?.toDate() ??
              DateTime.now();
      final customerName = orderData['customerName'] ?? '';
      final companyName = orderData['companyName'] ?? '';
      final salesPerson = orderData['salesPerson'] ?? '';

      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        final dplNo = product['dplNo'] ?? '$jobNo-${i + 1}';
        final rawSections = product['sections'];
        final Map<String, dynamic> sections =
            rawSections is Map<String, dynamic> ? rawSections : {};

        String getDetail(dynamic value) {
          if (value == null) return '';
          if (value is String) return value;
          if (value is Map) {
            return value['detail']?.toString() ??
                value['details']?.toString() ??
                value['value']?.toString() ??
                '';
          }
          return value.toString();
        }

        final trayDetail =
            getDetail(sections['trayDetail']) + getDetail(sections['tray']);
        final salophinDetail =
            getDetail(sections['salophinDetail']) +
                getDetail(sections['salophin']);
        final boxCoverDetail =
            getDetail(sections['boxCoverDetail']) +
                getDetail(sections['boxCover']);
        final innerDetail =
            getDetail(sections['innerDetail']) + getDetail(sections['inner']);
        final bottomDetail =
            getDetail(sections['bottomDetail']) +
                getDetail(sections['bottom']);
        final dieDetail =
            getDetail(sections['dieDetail']) + getDetail(sections['die']);
        final otherDetail =
            getDetail(sections['otherDetail']) +
                getDetail(sections['other']);
        final extraSections =
            product['customExtraSections'] is List
                ? product['customExtraSections']
                : [];
        final images =
            product['images'] is List ? product['images'] : [];

        List<pw.ImageProvider> loadedImages = [];
        for (final url in images) {
          if (url is String && url.isNotEmpty) {
            final img = await _loadNetworkImage(url);
            if (img != null) loadedImages.add(img);
          }
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.copyWith(
              marginLeft: 8,
              marginRight: 8,
              marginTop: 8,
              marginBottom: 8,
            ),
            build: (context) {
              return pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'All Rights Reserved © Dimple Packaging Pvt. Ltd.',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.yellow700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Job No: $jobNo',
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('DPL: $dplNo',
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                                "Order Location: ${orderData['unit'] ?? 'N/A'}",
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold)),
                            // pw.Text('[BACKUP ORDER]',
                            //     style: pw.TextStyle(
                            //         fontSize: 10,
                            //         fontWeight: pw.FontWeight.bold,
                            //         color: PdfColors.red700)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                                'DATE - ${DateFormat('dd-MM-yyyy').format(orderDate)}',
                                style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey300,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Column(
                                children: [
                                  pw.Text('DATE OF SUPPLY',
                                      style: pw.TextStyle(
                                          fontSize: 8,
                                          fontWeight: pw.FontWeight.bold)),
                                  pw.Text(
                                      DateFormat('dd-MM-yyyy')
                                          .format(deliveryDate),
                                      style:
                                          const pw.TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          companyName.toString().trim().isNotEmpty
                              ? '$customerName ($companyName)'
                              : customerName,
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Table(
                      border:
                          pw.TableBorder.all(color: PdfColors.grey600),
                      children: [
                        _buildPdfRow(
                            'Product', product['productName'] ?? ''),
                        _buildPdfRow(
                            'Category',
                            product['productCategory'] ?? ''),
                        _buildPdfRow(
                            'Dimensions (L×H×W)',
                            '${product['length'] ?? ''} × ${product['height'] ?? ''} × ${product['width'] ?? ''}'),
                        _buildPdfRow(
                            'Quantity',
                            '${product['quantity'] ?? ''}'),
                        // _buildPdfRow(
                        //     'HSN Code',
                        //     product['hsnCode']?.toString() ?? ''),
                        // _buildPdfRow(
                        //     'GST %',
                        //     '${product['gstPercent'] ?? ''}%'),
                        if ((product['remarks'] ?? '')
                            .toString()
                            .trim()
                            .isNotEmpty)
                          _buildPdfRow('Remark', product['remarks']),
                        _buildPdfRow('Assign Person', ''),
                        if (trayDetail.toString().trim().isNotEmpty)
                          _buildPdfRow('Tray', trayDetail),
                        if (salophinDetail.toString().trim().isNotEmpty)
                          _buildPdfRow('Salophin', salophinDetail),
                        if (boxCoverDetail.toString().trim().isNotEmpty)
                          _buildPdfRow('Box Cover', boxCoverDetail),
                        if (innerDetail.toString().trim().isNotEmpty)
                          _buildPdfRow('Inner', innerDetail),
                        if (bottomDetail.toString().trim().isNotEmpty)
                          _buildPdfRow('Bottom', bottomDetail),
                        if (dieDetail.toString().trim().isNotEmpty)
                          _buildPdfRow('Die', dieDetail),
                        if (otherDetail.toString().trim().isNotEmpty)
                          _buildPdfRow('Other', otherDetail.toString()),
                        if (extraSections.isNotEmpty)
                          ...extraSections.map<pw.TableRow?>((sec) {
                            final detail =
                                sec['detail'] ?? sec['details'] ?? '';
                            if (detail.toString().trim().isEmpty) return null;
                            return _buildPdfRow(
                                sec['title'] ?? 'Extra', detail);
                          }).whereType<pw.TableRow>(),
                        _buildPdfRow('Conerned Person', salesPerson),
                      ],
                    ),
                    if (notes.toString().trim().isNotEmpty) ...[
                      pw.SizedBox(height: 1),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border:
                              pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Additional Notes:',
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(notes,
                                style:
                                    const pw.TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 3),
                    if (loadedImages.isNotEmpty)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Product Images:',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 6),
                            pw.Expanded(
                              child: pw.GridView(
                                crossAxisCount:
                                    loadedImages.length <= 3
                                        ? loadedImages.length
                                        : 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.2,
                                children: loadedImages
                                    .map((img) => pw.Image(img,
                                        fit: pw.BoxFit.contain))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      }

      final pdfBytes = await pdf.save();
      final images =
          await Printing.raster(pdfBytes, dpi: 150).toList();

      if (kIsWeb) {
        final archive = Archive();
        int page = 1;
        for (final img in images) {
          final pngBytes = await img.toPng();
          archive.addFile(ArchiveFile(
            'BackupJobCard_${orderId}_Page$page.png',
            pngBytes.length,
            pngBytes,
          ));
          page++;
        }
        final zipData = ZipEncoder().encode(archive)!;
        downloadFileWeb(
            Uint8List.fromList(zipData),
            'BackupJobCard_$orderId.zip');
      } else {
        int page = 1;
        for (final img in images) {
          final pngBytes = await img.toPng();
          await Printing.sharePdf(
            bytes: pngBytes,
            filename: 'BackupJobCard_${orderId}_Page$page.png',
          );
          page++;
        }
      }
    } catch (e) {
      debugPrint('JPG generation error: $e');
    } finally {
      _hideLoadingDialog();
    }
  }

  // ─── Create Job Card from Backup Order ────────────────────────────────────

  Future<void> _generateJobCardFromBackupOrder(
    Map<String, dynamic> order,
    String orderId,
  ) async {
    final alreadyExists =
        await _checkIfJobCardExistsForBackup(orderId);
    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Job Card already created for this Backup Order!',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ]),
          backgroundColor: const Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ));
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final counterRef = FirebaseFirestore.instance
          .collection('meta')
          .doc('jobCardCounter');
      String jobNo = '';
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        final last = (snap.data()?['last'] as int?) ?? 0;
        final next = last + 1;
        tx.set(counterRef, {'last': next}, SetOptions(merge: true));
        jobNo = 'DPL$next';
      });

      List products = safeList(order['products']);
      List<Map<String, dynamic>> jobCardProducts = [];
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        jobCardProducts.add({
          'dplIndex': i + 1,
          'dplNo': '$jobNo-${i + 1}',
          'productName': product['productName'] ?? '',
          'productCategory': product['productCategory'] ?? '',
          'hsnCode': product['hsnCode'] ?? '',
          'gstPercent': product['gstPercent'] ?? 0,
          'length': product['length'] ?? '',
          'height': product['height'] ?? '',
          'width': product['width'] ?? '',
          'quantity': product['quantity'] ?? 0,
          'price': product['price'] ?? 0,
          'remarks': product['remarks'] ?? '',
          'images': List<String>.from(product['images'] ?? []),
          'sections': product['sections'] ?? {},
          'customExtraSections': product['customExtraSections'] ?? [],
        });
      }

      List<Map<String, dynamic>> partialDispatchesData = [];
      final partialDispatches =
          order['partialDispatches'] as List? ?? [];
      for (var dispatch in partialDispatches) {
        partialDispatchesData.add({
          'name': dispatch['name'] ?? '',
          'quantity': dispatch['quantity'] ?? '',
          'date': dispatch['date'] ?? '',
          'timestamp': dispatch['timestamp'],
        });
      }

      await FirebaseFirestore.instance
          .collection('jobCards')
          .doc(jobNo)
          .set({
        'jobNo': jobNo,
        'date': order['orderDate'] ?? DateTime.now(),
        'priority': order['priority'] ?? 'Medium',
        'customerName': order['customerName'] ?? '',
        'companyName': order['companyName'] ?? '',
        'salesPerson': order['salesPerson'] ?? '',
        'products': jobCardProducts,
        'partialDispatches': partialDispatchesData,
        'extraInstruction': order['notes'] ?? '',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'backup_order',
        'deliveryDate': order['deliveryDate'],
        'unit': order['unit'],
        'linkedOrderId': orderId,
        'isFromBackup': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Job Card created from Backup!',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ]),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Error: $e',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ]),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateJobCardDialog(
      String orderId, Map<String, dynamic> orderData) async {
    final jobCardExists =
        await _checkIfJobCardExistsForBackup(orderId);
    if (!jobCardExists && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.deepOrange.shade400,
                  Colors.deepOrange.shade600
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Create Job Card from Backup?',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ]),
          content: const Text(
            'Would you like to create a Job Card from this Backup Order?',
            style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(
                      fontSize: 15, color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _generateJobCardFromBackupOrder(
                    orderData, orderId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create Job Card',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.info_outline, color: Colors.white),
          SizedBox(width: 12),
          Text('Job Card already exists for this order.'),
        ]),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ─── Loading Dialog ───────────────────────────────────────────────────────

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  "Generating images… Please wait",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  // ─── Color helpers ────────────────────────────────────────────────────────

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return const Color(0xFFFFEBEE);
      case 'medium':
        return const Color(0xFFFFF3E0);
      case 'low':
        return const Color(0xFFF1F8E9);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getPriorityBorderColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF5350);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.of(context).size.width < 600;

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
                  Colors.deepOrange.shade700,
                  Colors.orange.shade600,
                  Colors.amber.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
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
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
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
                        'Backup Orders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'View & Manage Backed-up Orders',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFFFFF)],
          ),
        ),
        child: Column(
          children: [
            // ── Search Bar ─────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                isPhone ? 12 : 16,
                isPhone ? 10 : 12,
                isPhone ? 12 : 16,
                isPhone ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade100.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                      colors: [Colors.white, Colors.orange.shade50]),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade100.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  style: TextStyle(fontSize: isPhone ? 14 : 15),
                  decoration: InputDecoration(
                    hintText: 'Search backup orders...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: isPhone ? 13 : 15,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(isPhone ? 10 : 12),
                      child: Icon(Icons.search_rounded,
                          color: Colors.deepOrange.shade600,
                          size: isPhone ? 22 : 26),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: Colors.grey.shade400,
                                size: isPhone ? 18 : 22),
                            onPressed: () =>
                                setState(() => searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 14 : 20,
                      vertical: isPhone ? 13 : 18,
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => searchQuery = v.toLowerCase()),
                ),
              ),
            ),

            // ── Filters ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                isPhone ? 12 : 20,
                isPhone ? 8 : 12,
                isPhone ? 12 : 20,
                isPhone ? 10 : 20,
              ),
              child: Row(
                children: [
                  // Date Filter
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.white,
                          Colors.deepOrange.shade50
                        ]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade100
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedDateFilter,
                        isExpanded: true,
                        isDense: isPhone,
                        decoration: InputDecoration(
                          labelText:
                              isPhone ? '📅 Date' : '📅 Date Filter',
                          labelStyle: TextStyle(
                            color: Colors.deepOrange.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: isPhone ? 12 : 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isPhone ? 10 : 16,
                            vertical: isPhone ? 8 : 12,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: isPhone ? 12 : 14,
                          color: Colors.black87,
                        ),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(
                              value: 'All', child: Text('All Time')),
                          DropdownMenuItem(
                              value: 'Day', child: Text('Today')),
                          DropdownMenuItem(
                              value: 'Week',
                              child: Text('This Week')),
                          DropdownMenuItem(
                              value: 'Month',
                              child: Text('This Month')),
                          DropdownMenuItem(
                              value: 'Custom',
                              child: Text('Custom Range')),
                        ],
                        onChanged: (val) async {
                          if (val == null) return;
                          if (val == 'Custom') {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary:
                                        Colors.deepOrange.shade600,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (range == null) return;
                            setState(() {
                              _selectedDateFilter = val;
                              _selectedDateRange = range;
                            });
                          } else {
                            setState(() {
                              _selectedDateFilter = val;
                              _selectedDateRange = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: isPhone ? 8 : 14),
                  // Unit Filter
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.white,
                          Colors.amber.shade50
                        ]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade100
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        isExpanded: true,
                        isDense: isPhone,
                        decoration: InputDecoration(
                          labelText:
                              isPhone ? '🏭 Unit' : '🏭 Unit Filter',
                          labelStyle: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: isPhone ? 12 : 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isPhone ? 10 : 16,
                            vertical: isPhone ? 8 : 12,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: isPhone ? 12 : 14,
                          color: Colors.black87,
                        ),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(
                              value: 'All', child: Text('All Units')),
                          DropdownMenuItem(
                              value: 'Unit 1', child: Text('Unit 1')),
                          DropdownMenuItem(
                              value: 'Unit 2', child: Text('Unit 2')),
                          DropdownMenuItem(
                              value: 'Meena Bazar',
                              child: Text('Meena Bazar')),
                          DropdownMenuItem(
                              value: 'College Road',
                              child: Text('College Road')),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedUnit = val ?? 'All'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Orders List ────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders_backup')
                    .orderBy('orderDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              color: Colors.deepOrange.shade600,
                              strokeWidth: 3),
                          const SizedBox(height: 20),
                          Text(
                            'Loading backup orders...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ── Filter logic ──────────────────────────────────
                  var orders =
                      snapshot.data!.docs.where((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final customer = (data['customerName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final searchMatch =
                        customer.contains(searchQuery) ||
                            (data['companyName'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(searchQuery);
                    final unit =
                        (data['unit'] ?? '').toString();
                    final unitMatch = _selectedUnit == 'All' ||
                        unit == _selectedUnit;

                    // orderDate may be Timestamp or missing
                    final ts = data['orderDate'];
                    DateTime? orderDate;
                    if (ts is Timestamp) {
                      orderDate = ts.toDate().toLocal();
                    }

                    bool dateMatch = true;
                    if (orderDate != null) {
                      final now = DateTime.now();
                      if (_selectedDateFilter == 'Day') {
                        final start = DateTime(
                            now.year, now.month, now.day);
                        final end = start
                            .add(const Duration(days: 1));
                        dateMatch = orderDate.isAfter(start.subtract(
                                const Duration(
                                    milliseconds: 1))) &&
                            orderDate.isBefore(end);
                      } else if (_selectedDateFilter == 'Week') {
                        final start = now.subtract(
                            Duration(days: now.weekday - 1));
                        final weekStart = DateTime(
                            start.year, start.month, start.day);
                        final weekEnd = weekStart
                            .add(const Duration(days: 7));
                        dateMatch = orderDate.isAfter(
                                weekStart.subtract(const Duration(
                                    milliseconds: 1))) &&
                            orderDate.isBefore(weekEnd);
                      } else if (_selectedDateFilter == 'Month') {
                        final monthStart =
                            DateTime(now.year, now.month, 1);
                        final monthEnd = DateTime(
                            now.year, now.month + 1, 1);
                        dateMatch = orderDate.isAfter(
                                monthStart.subtract(const Duration(
                                    milliseconds: 1))) &&
                            orderDate.isBefore(monthEnd);
                      } else if (_selectedDateFilter == 'Custom' &&
                          _selectedDateRange != null) {
                        dateMatch = orderDate.isAfter(
                                _selectedDateRange!.start.subtract(
                                    const Duration(
                                        milliseconds: 1))) &&
                            orderDate.isBefore(
                                _selectedDateRange!.end.add(
                                    const Duration(days: 1)));
                      }
                    }

                    return searchMatch && unitMatch && dateMatch;
                  }).toList();

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                                isPhone ? 18 : 24),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.backup_outlined,
                                size: isPhone ? 60 : 80,
                                color:
                                    Colors.deepOrange.shade300),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            searchQuery.isEmpty
                                ? 'No backup orders found'
                                : 'No matching backup orders',
                            style: TextStyle(
                              fontSize: isPhone ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchQuery.isEmpty
                                ? 'Backup orders will appear here'
                                : 'Try adjusting your filters',
                            style: TextStyle(
                                fontSize: isPhone ? 13 : 15,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      isPhone ? 12 : 20,
                      0,
                      isPhone ? 12 : 20,
                      isPhone ? 12 : 20,
                    ),
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final doc = orders[i];
                      final data =
                          doc.data() as Map<String, dynamic>;
                      final products = safeList(data['products']);
                      final priority =
                          data['priority'] ?? 'Medium';
                      final orderDate =
                          (data['orderDate'] as Timestamp?)
                              ?.toDate();
                      final deliveryDate =
                          (data['deliveryDate'] as Timestamp?)
                              ?.toDate();

                      return FutureBuilder<bool>(
                        future:
                            _checkIfJobCardExistsForBackup(doc.id),
                        builder: (context, snapshot) {
                          final jobCardExists =
                              snapshot.data ?? false;

                          return Container(
                            margin: EdgeInsets.only(
                                bottom: isPhone ? 14 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.orange.shade50
                                      .withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                  isPhone ? 18 : 24),
                              border: Border.all(
                                color: Colors.deepOrange.shade100,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.shade100
                                      .withOpacity(0.6),
                                  blurRadius: isPhone ? 12 : 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.symmetric(
                                  horizontal: isPhone ? 14 : 20,
                                  vertical: isPhone ? 8 : 12,
                                ),
                                childrenPadding:
                                    EdgeInsets.all(isPhone ? 10 : 14),
                                leading: Container(
                                  padding: EdgeInsets.all(
                                      isPhone ? 8 : 10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Colors.deepOrange.shade400,
                                      Colors.deepOrange.shade700,
                                    ]),
                                    borderRadius: BorderRadius.circular(
                                        isPhone ? 12 : 16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors
                                            .deepOrange.shade300,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.backup_rounded,
                                    color: Colors.white,
                                    size: isPhone ? 18 : 22,
                                  ),
                                ),
                                title: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Backup badge
                                    Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 4),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.deepOrange
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.deepOrange
                                                .shade200),
                                      ),
                                      child: Text(
                                        '🗂️ BACKUP',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .deepOrange.shade700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      data['customerName'] ??
                                          'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isPhone ? 15 : 18,
                                        color:
                                            const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    if ((data['companyName'] ?? '')
                                        .toString()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        data['companyName'],
                                        style: TextStyle(
                                          fontSize: isPhone ? 12 : 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline,
                                            size: isPhone ? 12 : 14,
                                            color:
                                                Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            data['salesPerson'] ??
                                                'Unknown',
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.w500,
                                              fontSize:
                                                  isPhone ? 12 : 14,
                                              color:
                                                  Colors.grey.shade700,
                                            ),
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (jobCardExists) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.red.shade400,
                                                  Colors.red.shade700,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                            ),
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons
                                                          .picture_as_pdf_rounded,
                                                      color:
                                                          Colors.white),
                                                  iconSize: isPhone
                                                      ? 18
                                                      : 22,
                                                  onPressed: () =>
                                                      _generateAllProductsPDF(
                                                          doc.id, data),
                                                  tooltip:
                                                      'Generate PDF',
                                                  padding:
                                                      EdgeInsets.all(
                                                          isPhone
                                                              ? 6
                                                              : 10),
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.image_rounded,
                                                      color: Colors
                                                          .blueAccent),
                                                  iconSize: isPhone
                                                      ? 18
                                                      : 22,
                                                  tooltip:
                                                      'Download JPG',
                                                  onPressed: () =>
                                                      _generateAllProductsJPG(
                                                          doc.id, data),
                                                  padding:
                                                      EdgeInsets.all(
                                                          isPhone
                                                              ? 6
                                                              : 10),
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    isPhone ? 10 : 14,
                                                vertical:
                                                    isPhone ? 6 : 8,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green.shade400,
                                                    Colors.green.shade700,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .check_circle_rounded,
                                                      color: Colors.white,
                                                      size: 14),
                                                  const SizedBox(
                                                      width: 4),
                                                  Text(
                                                    'Job Card ✓',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: isPhone
                                                          ? 11
                                                          : 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Priority Badge
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isPhone ? 10 : 12,
                                              vertical: isPhone ? 4 : 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                  priority),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12),
                                              border: Border.all(
                                                color:
                                                    _getPriorityBorderColor(
                                                        priority),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Icon(Icons.flag_rounded,
                                                    size:
                                                        isPhone ? 12 : 14,
                                                    color:
                                                        _getPriorityBorderColor(
                                                            priority)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  priority,
                                                  style: TextStyle(
                                                    fontSize:
                                                        isPhone ? 11 : 12,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color:
                                                        _getPriorityBorderColor(
                                                            priority),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Unit badge
                                          if ((data['unit'] ?? '')
                                              .toString()
                                              .isNotEmpty)
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    isPhone ? 8 : 10,
                                                vertical:
                                                    isPhone ? 4 : 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors
                                                    .deepOrange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                border: Border.all(
                                                    color: Colors.deepOrange
                                                        .shade200),
                                              ),
                                              child: Text(
                                                data['unit'],
                                                style: TextStyle(
                                                  fontSize:
                                                      isPhone ? 11 : 12,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: Colors.deepOrange
                                                      .shade700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (orderDate != null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                size: 12,
                                                color:
                                                    Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Order: ${DateFormat('dd MMM yyyy').format(orderDate)}',
                                              style: TextStyle(
                                                  fontSize: isPhone
                                                      ? 11
                                                      : 12,
                                                  color:
                                                      Colors.grey.shade600),
                                            ),
                                            if (deliveryDate != null) ...[
                                              const SizedBox(width: 10),
                                              Icon(
                                                  Icons
                                                      .local_shipping_outlined,
                                                  size: 12,
                                                  color: Colors
                                                      .grey.shade500),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Delivery: ${DateFormat('dd MMM yyyy').format(deliveryDate)}',
                                                style: TextStyle(
                                                    fontSize: isPhone
                                                        ? 11
                                                        : 12,
                                                    color: Colors
                                                        .grey.shade600),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                children: [
                                  // ── Products List ─────────────────
                                  Container(
                                    padding: EdgeInsets.all(
                                        isPhone ? 14 : 18),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        Colors.grey.shade50,
                                        Colors.white,
                                      ]),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Container(
                                            padding: EdgeInsets.all(
                                                isPhone ? 6 : 8),
                                            decoration: BoxDecoration(
                                              color: Colors
                                                  .deepOrange.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                            ),
                                            child: Icon(
                                                Icons.inventory_2_rounded,
                                                size: isPhone ? 16 : 20,
                                                color: Colors.deepOrange
                                                    .shade700),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Products (${products.length})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  isPhone ? 14 : 16,
                                              color:
                                                  Colors.grey.shade800,
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(height: 12),
                                        ...products.map(
                                          (p) => Container(
                                            margin: EdgeInsets.only(
                                                bottom:
                                                    isPhone ? 8 : 10),
                                            padding: EdgeInsets.all(
                                                isPhone ? 10 : 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12),
                                              border: Border.all(
                                                  color: Colors
                                                      .orange.shade100),
                                            ),
                                            child: Row(children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        Colors.deepOrange
                                                            .shade400,
                                                        Colors.deepOrange
                                                            .shade600,
                                                      ]),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      '${p['productName'] ?? 'Product'}  ${p['productCategory'] ?? ''}',
                                                      style: TextStyle(
                                                        fontSize: isPhone
                                                            ? 13
                                                            : 15,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                        color: Colors
                                                            .grey.shade800,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              horizontal:
                                                                  8,
                                                              vertical:
                                                                  3),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .orange
                                                                .shade100,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Text(
                                                            'Qty: ${p['quantity'] ?? '-'}',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  isPhone
                                                                      ? 11
                                                                      : 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .orange
                                                                  .shade800,
                                                            ),
                                                          ),
                                                        ),
                                                        if ((p['price'] ??
                                                                0) !=
                                                            0) ...[
                                                          const SizedBox(
                                                              width: 6),
                                                          Container(
                                                            padding: const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    8,
                                                                vertical:
                                                                    3),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .green
                                                                  .shade50,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .green
                                                                      .shade200),
                                                            ),
                                                            child: Text(
                                                              '₹${p['price']}',
                                                              style: TextStyle(
                                                                fontSize:
                                                                    isPhone
                                                                        ? 11
                                                                        : 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .green
                                                                    .shade700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    // Dimensions
                                                    if ((p['length'] ??
                                                                '')
                                                            .toString()
                                                            .isNotEmpty ||
                                                        (p['height'] ??
                                                                '')
                                                            .toString()
                                                            .isNotEmpty) ...[
                                                      const SizedBox(
                                                          height: 2),
                                                      Text(
                                                        'L×H×W: ${p['length'] ?? '-'} × ${p['height'] ?? '-'} × ${p['width'] ?? '-'}',
                                                        style: TextStyle(
                                                          fontSize:
                                                              isPhone
                                                                  ? 11
                                                                  : 12,
                                                          color: Colors
                                                              .grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: isPhone ? 12 : 18),

                                  // ── Financial Summary ─────────────
                                  if ((data['grandTotal'] ?? 0) != 0) ...[
                                    Container(
                                      padding: EdgeInsets.all(
                                          isPhone ? 12 : 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Colors.green.shade50,
                                          Colors.teal.shade50,
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                Colors.green.shade200),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Sub Total',
                                                style: TextStyle(
                                                    fontSize: isPhone
                                                        ? 11
                                                        : 12,
                                                    color: Colors
                                                        .grey.shade600),
                                              ),
                                              Text(
                                                '₹${(data['subTotal'] ?? 0).toStringAsFixed(0)}',
                                                style: TextStyle(
                                                    fontSize: isPhone
                                                        ? 13
                                                        : 14,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors
                                                        .grey.shade800),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'GST',
                                                style: TextStyle(
                                                    fontSize: isPhone
                                                        ? 11
                                                        : 12,
                                                    color: Colors
                                                        .grey.shade600),
                                              ),
                                              Text(
                                                '₹${(data['totalGstAmount'] ?? 0).toStringAsFixed(0)}',
                                                style: TextStyle(
                                                    fontSize: isPhone
                                                        ? 13
                                                        : 14,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors
                                                        .orange.shade700),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Grand Total',
                                                style: TextStyle(
                                                    fontSize: isPhone
                                                        ? 11
                                                        : 12,
                                                    color: Colors
                                                        .grey.shade600),
                                              ),
                                              Text(
                                                '₹${(data['grandTotal'] ?? 0).toStringAsFixed(0)}',
                                                style: TextStyle(
                                                    fontSize: isPhone
                                                        ? 15
                                                        : 18,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors
                                                        .green.shade700),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: isPhone ? 12 : 18),
                                  ],

                                  // ── PDF / JPG buttons (no job card yet) ──
                                  if (!jobCardExists) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _generateAllProductsPDF(
                                                    doc.id, data),
                                            icon: const Icon(Icons
                                                .picture_as_pdf_rounded),
                                            label:
                                                const Text('PDF'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.red.shade700,
                                              side: BorderSide(
                                                  color:
                                                      Colors.red.shade300),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      isPhone ? 10 : 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _generateAllProductsJPG(
                                                    doc.id, data),
                                            icon: const Icon(
                                                Icons.image_rounded),
                                            label: const Text('JPG'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.blue.shade700,
                                              side: BorderSide(
                                                  color: Colors
                                                      .blue.shade300),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      isPhone ? 10 : 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  // ── Create Job Card Button ─────────
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () =>
                                              _showCreateJobCardDialog(
                                                  doc.id, data),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: jobCardExists
                                            ? Colors.green.shade600
                                            : Colors.deepOrange.shade600,
                                        foregroundColor: Colors.white,
                                        elevation: 6,
                                        shadowColor: jobCardExists
                                            ? Colors.green.shade300
                                            : Colors.deepOrange.shade300,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  isPhone ? 12 : 16),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isPhone ? 20 : 28,
                                          vertical: isPhone ? 12 : 16,
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  jobCardExists
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons
                                                          .assignment_turned_in_rounded,
                                                  size:
                                                      isPhone ? 18 : 22,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  jobCardExists
                                                      ? 'Job Card Created ✓'
                                                      : 'Create Job Card from Backup',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isPhone ? 14 : 16,
                                                    fontWeight:
                                                        FontWeight.bold,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}