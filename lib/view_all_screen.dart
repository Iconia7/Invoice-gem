import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart'; // Import CSV
import 'package:invoice_generator/custom_dialog.dart';
import 'package:path_provider/path_provider.dart'; // Import Path Provider
import 'package:share_plus/share_plus.dart'; // Import Share
import 'invoice_model.dart';
import 'pdf_preview_screen.dart';

class ViewAllScreen extends StatefulWidget {
  const ViewAllScreen({super.key});

  @override
  State<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final list = await InvoiceManager.getInvoices();
    setState(() {
      _allInvoices = list.reversed.toList();
      _filteredInvoices = _allInvoices;
    });
  }

  void _runFilter(String keyword) {
    List<Invoice> results = [];
    if (keyword.isEmpty) {
      results = _allInvoices;
    } else {
      results = _allInvoices
          .where((inv) =>
              inv.clientName.toLowerCase().contains(keyword.toLowerCase()) ||
              inv.id.contains(keyword))
          .toList();
    }
    setState(() {
      _filteredInvoices = results;
    });
  }

  Future<void> _deleteInvoice(int index) async {
    final invoiceToDelete = _filteredInvoices[index];
    await InvoiceManager.deleteInvoice(invoiceToDelete.id);
    setState(() {
      _allInvoices.removeWhere((i) => i.id == invoiceToDelete.id);
      _filteredInvoices.removeAt(index);
    });
  }

  Future<bool> _confirmDelete() async {
  return await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Delete Invoice?"),
      content: const Text("This action cannot be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  ) ?? false;
}

  // --- NEW: Export Function ---
  Future<void> _exportToCSV() async {
    if (_allInvoices.isEmpty) {
      CustomDialog.show(
    context,
    title: "No Invoices",
    message: "You don't have any invoices to export yet.",
    isSuccess: false
  );
      return;
    }

    // 1. Create the CSV Data List
    List<List<dynamic>> rows = [];
    
    // Add Headers
    rows.add([
      "Invoice ID",
      "Date",
      "Client Name",
      "Client Address",
      "Total Amount",
      "Currency",
      "Status",
      "Payment Link"
    ]);

    // Add Data Rows
    for (var inv in _allInvoices) {
      rows.add([
        inv.id,
        DateFormat('yyyy-MM-dd').format(inv.date),
        inv.clientName,
        inv.clientAddress,
        inv.grandTotal.toStringAsFixed(2),
        inv.currencySymbol,
        inv.isPaid ? "Paid" : "Pending",
        inv.paymentLink
      ]);
    }

    // 2. Convert to CSV String
    String csvData = const ListToCsvConverter().convert(rows);

    // 3. Write to File
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/invoice_report.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    // 4. Share the File
    await Share.shareXFiles([XFile(path)], text: 'Here is my Invoice Report');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("All Invoices", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // --- NEW: Export Button ---
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.blueAccent),
            tooltip: "Export to Excel/CSV",
            onPressed: _exportToCSV,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                labelText: 'Search Client or ID',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue.shade900, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Invoice List
            Expanded(
              child: _filteredInvoices.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: _filteredInvoices.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        
                        return Dismissible(
                          key: Key(invoice.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
    return await _confirmDelete();
  },
                          onDismissed: (direction) {
                            _deleteInvoice(index);
                          },
                          child: _buildInvoiceTile(invoice),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "No invoices found",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTile(Invoice invoice) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfPreviewScreen(invoice: invoice)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  invoice.clientName.isNotEmpty 
                      ? invoice.clientName.substring(0, 1).toUpperCase()
                      : "?",
                  style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 15),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.clientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(invoice.date),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            
            // Amount & Status Logic
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.compactSimpleCurrency(name: invoice.currencySymbol).format(invoice.grandTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                
                // Status Chip (Clickable)
                GestureDetector(
                  onTap: () async {
                    await InvoiceManager.toggleStatus(invoice.id, !invoice.isPaid);
                    _loadInvoices(); 
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: invoice.isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: invoice.isPaid ? Colors.green : Colors.orange,
                        width: 1
                      ),
                    ),
                    child: Text(
                      invoice.isPaid ? "PAID" : "MARK PAID", 
                      style: TextStyle(
                        color: invoice.isPaid ? Colors.green : Colors.orange, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}