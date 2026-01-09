import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'dart:io'; 
import 'dart:typed_data'; 
import 'invoice_model.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Invoice invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    // 1. Dynamic App Bar Logic
    final isPaid = invoice.isPaid;
    final primaryColor = isPaid ? Colors.green : Colors.blue.shade900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPaid ? "Receipt #${invoice.id}" : "Invoice #${invoice.id}", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        backgroundColor: primaryColor, // Green if paid, Blue if pending
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () async => Printing.sharePdf(
                bytes: await _generatePdfBytes(PdfPageFormat.a4), 
                filename: '${isPaid ? 'receipt' : 'invoice'}_${invoice.id}.pdf'
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdfBytes(format),
        canChangeOrientation: false,
        canDebug: false,
        scrollViewDecoration: BoxDecoration(
          color: Colors.grey[100], 
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdfBytes(PdfPageFormat format) async {
    final pdf = pw.Document();
    final prefs = await SharedPreferences.getInstance();

    // Load User Data
    final businessName = prefs.getString('business_name') ?? "Business Name";
    final businessEmail = prefs.getString('business_email') ?? "";
    final logoPath = prefs.getString('logo_path');
    final sigPath = prefs.getString('signature_path');
    int colorInt = prefs.getInt('brand_color') ?? 0xFF1A237E;
    
    // 2. Dynamic PDF Colors & Titles
    final isPaid = invoice.isPaid;
    // If paid, force Green. If not, use Brand Color.
    final PdfColor brandColor = isPaid ? PdfColors.green : PdfColor.fromInt(colorInt);
    final String docTitle = isPaid ? "RECEIPT" : "INVOICE";

    pw.MemoryImage? logoImage;
    if (logoPath != null && File(logoPath).existsSync()) {
      logoImage = pw.MemoryImage(File(logoPath).readAsBytesSync());
    }

    pw.MemoryImage? signatureImage;
    if (sigPath != null && File(sigPath).existsSync()) {
      signatureImage = pw.MemoryImage(File(sigPath).readAsBytesSync());
    }

    String formatCurrency(double amount) {
      return "${invoice.currencySymbol}${amount.toStringAsFixed(2)}";
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Stack(
            children: [
              // --- MAIN CONTENT ---
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // --- Header Section ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo or Spacer
                      if (logoImage != null)
                          pw.Container(height: 60, width: 60, child: pw.Image(logoImage))
                      else
                          pw.SizedBox(height: 60),
                      
                      // Title & ID
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(docTitle, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: brandColor)),
                          pw.Text("#${invoice.id}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                          
                          // Status Stamp (Small Box)
                          pw.Container(
                            margin: const pw.EdgeInsets.only(top: 5),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: brandColor, width: 2),
                              borderRadius: pw.BorderRadius.circular(5),
                            ),
                            child: pw.Text(
                              isPaid ? "PAID" : "DUE", 
                              style: pw.TextStyle(color: brandColor, fontWeight: pw.FontWeight.bold)
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 20),

                  // --- From / To Section ---
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("FROM", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(businessName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(businessEmail, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),

                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("BILL TO", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(invoice.clientName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(invoice.clientAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 10),
                          // 3. Dynamic Date Label
                          pw.Text(
                            "${isPaid ? 'Date Paid' : 'Due Date'}: ${invoice.date.toString().split(' ')[0]}", 
                            style: const pw.TextStyle(fontSize: 10)
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 30),

                  // --- Items Table ---
                  pw.Table.fromTextArray(
                    headers: ['Description', 'Qty', 'Unit Price', 'Total'],
                    data: invoice.items.map((item) => [
                      item.description,
                      item.quantity.toString(),
                      formatCurrency(item.unitPrice),
                      formatCurrency(item.total),
                    ]).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                    headerDecoration: pw.BoxDecoration(color: brandColor),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    cellHeight: 30,
                    border: null,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft, 
                      1: pw.Alignment.center, 
                      2: pw.Alignment.centerRight, 
                      3: pw.Alignment.centerRight
                    },
                    rowDecoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // --- Totals Section ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 200,
                        child: pw.Column(
                          children: [
                            _buildTotalRow("Subtotal", formatCurrency(invoice.subtotal)),
                            if (invoice.discountAmount > 0)
                              _buildTotalRow("Discount", "-${formatCurrency(invoice.discountAmount)}", color: PdfColors.red),
                            if (invoice.taxRate > 0)
                              _buildTotalRow("Tax (${(invoice.taxRate * 100).toInt()}%)", formatCurrency(invoice.taxAmount)),
                            
                            pw.Divider(color: PdfColors.grey300),
                            
                            _buildTotalRow(
                              "Total", 
                              formatCurrency(invoice.grandTotal), 
                              isBold: true, 
                              color: brandColor,
                              fontSize: 14 // Make total larger
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // --- Footer: QR & Signature ---
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        if (invoice.paymentLink.isNotEmpty)
                          pw.Row(
                            children: [
                               pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: invoice.paymentLink,
                                width: 50,
                                height: 50,
                              ),
                              pw.SizedBox(width: 10),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text("Scan to Pay", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                  pw.Text("Use supported app", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                                ],
                              ),
                            ],
                          )
                        else 
                          pw.Container(),

                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            if (signatureImage != null)
                              pw.Image(signatureImage, width: 80, height: 40)
                            else
                              pw.SizedBox(height: 40),
                            
                            pw.Container(width: 100, height: 1, color: PdfColors.grey400),
                            pw.SizedBox(height: 2),
                            pw.Text("Authorized Signature", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 20),
                  pw.Center(child: pw.Text("Thank you for your business!", style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10))),
                ],
              ),

              // --- 4. WATERMARK (Appears only if Paid) ---
              if (isPaid)
                pw.Positioned(
                  bottom: 250,
                  left: 100,
                  child: pw.Transform.rotate(
                    angle: -0.5,
                    child: pw.Opacity(
                      opacity: 0.2, // Subtle transparency
                      child: pw.Text(
                        "PAID",
                        style: pw.TextStyle(
                          color: PdfColors.green,
                          fontSize: 100,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTotalRow(String label, String value, {bool isBold = false, PdfColor? color, double? fontSize}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black, fontSize: fontSize ?? 10)),
        ],
      ),
    );
  }
}