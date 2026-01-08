import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoice_generator/invoice_model.dart';
import 'package:invoice_generator/pdf_preview_screen.dart';
import 'package:invoice_generator/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_screen.dart';
import 'create_invoice_screen.dart';
import 'view_all_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _businessName = "Loading...";
  List<Invoice> _recentInvoices = [];
  
  // Stats
  double _collectedRevenue = 0.0;
  double _pendingRevenue = 0.0;
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await _loadBusinessInfo();
    await _loadHistory();
  }

  Future<void> _loadBusinessInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('business_name');
    if (mounted) {
      setState(() {
        _businessName = (name == null || name.isEmpty) ? "Business Owner" : name;
      });
    }
  }

  Future<void> _loadHistory() async {
    final list = await InvoiceManager.getInvoices();
    
    double collected = 0;
    double pending = 0;
    String lastSymbol = '\$';

    for (var inv in list) {
      if (inv.isPaid) {
        collected += inv.grandTotal;
      } else {
        pending += inv.grandTotal;
      }
      if (list.isNotEmpty) lastSymbol = list.last.currencySymbol;
    }
    
    if (mounted) {
      setState(() {
        _recentInvoices = list.reversed.toList();
        _collectedRevenue = collected;
        _pendingRevenue = pending;
        _currencySymbol = lastSymbol;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. Custom Header ---
            _buildHeader(),

            // --- 2. Floating Action Grid ---
            // MOVED UP: Adjusted offset to be tighter
            Transform.translate(
              offset: const Offset(0, -30), 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.add_circle_outline,
                        title: "New Invoice",
                        color: Colors.blueAccent,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
                          );
                          _refreshData();
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.storefront,
                        title: "My Business",
                        color: Colors.orangeAccent,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SetupScreen()),
                          );
                          _refreshData();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- 3. Recent Activity Section ---
            // Added a negative transform here to pull the list up into the empty space
            Transform.translate(
              offset: const Offset(0, -15), 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent Invoices",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ViewAllScreen()),
                            );
                            _refreshData();
                          }, 
                          child: const Text("View All"),
                        )
                      ],
                    ),
                    const SizedBox(height: 5), // Reduced from 10
                    
                    _recentInvoices.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentInvoices.length > 5 ? 5 : _recentInvoices.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10), // Reduced from 12
                            itemBuilder: (context, index) {
                              final inv = _recentInvoices[index];
                              return _InvoiceTile(invoice: inv);
                            },
                          ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      // TIGHTER PADDING: Reduced top/bottom padding significantly
      padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back,",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _businessName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22, // Slightly smaller font for better fit
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
      ),
    )
            ],
          ),
          const SizedBox(height: 20), // Reduced from 25
          
          Row(
            children: [
              // Collected
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 5),
                          const Text("Collected", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        NumberFormat.compactSimpleCurrency(name: _currencySymbol).format(_collectedRevenue),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // Pending
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hourglass_empty, color: Colors.orangeAccent, size: 16),
                          const SizedBox(width: 5),
                          const Text("Pending", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        NumberFormat.compactSimpleCurrency(name: _currencySymbol).format(_pendingRevenue),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 5),
          Text(
            "No invoices yet",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100, // Reduced height from 110 to 100
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10), // Reduced padding
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24), // Smaller Icon
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(invoice: invoice)
        ));
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
            Container(
              height: 45, // Smaller avatar
              width: 45,
              decoration: BoxDecoration(
                color: invoice.isPaid ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  invoice.isPaid ? Icons.check : Icons.hourglass_bottom,
                  color: invoice.isPaid ? Colors.green : Colors.orange,
                  size: 20,
                )
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.clientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd').format(invoice.date),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.compactSimpleCurrency(name: invoice.currencySymbol).format(invoice.grandTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.isPaid ? "Paid" : "Pending",
                  style: TextStyle(
                    color: invoice.isPaid ? Colors.green : Colors.orange, 
                    fontWeight: FontWeight.bold,
                    fontSize: 10
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