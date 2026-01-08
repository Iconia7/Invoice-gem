import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoice_generator/custom_dialog.dart';
import 'invoice_model.dart';
import 'pdf_preview_screen.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  // Client Details
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  final TextEditingController _taxController = TextEditingController(text: '0');
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _paymentLinkController = TextEditingController();
  
  // Invoice Details
  DateTime _selectedDate = DateTime.now();
  final List<InvoiceItem> _items = [];
  String _selectedCurrency = '\$'; // Default Currency
  
  // Currencies List
  final List<Map<String, String>> _currencies = [
    {'symbol': '\$', 'name': 'USD (\$)'},
    {'symbol': '€', 'name': 'EUR (€)'},
    {'symbol': '£', 'name': 'GBP (£)'},
    {'symbol': 'KSh', 'name': 'KES (KSh)'},
    {'symbol': '₦', 'name': 'NGN (₦)'},
    {'symbol': '₹', 'name': 'INR (₹)'},
  ];

  // Totals
  double _grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _calculateTotal();
  }

  // Add this method to _CreateInvoiceScreenState
Future<void> _showClientPicker() async {
  final clients = await ClientManager.getClients();
  
  if (!mounted) return;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          children: [
            const Text("Select Saved Client", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            Expanded(
              child: clients.isEmpty 
              ? const Center(child: Text("No saved clients yet.")) 
              : ListView.builder(
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(client.name[0])),
                      title: Text(client.name),
                      subtitle: Text(client.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        setState(() {
                          _clientNameController.text = client.name;
                          _clientAddressController.text = client.address;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showProductPicker(int index) async {
  final products = await ProductManager.getProducts();
  
  if (!mounted) return;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          children: [
            const Text("Select Saved Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            Expanded(
              child: products.isEmpty 
              ? const Center(child: Text("No saved items yet.")) 
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final product = products[i];
                    return ListTile(
                      leading: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                      title: Text(product.name),
                      trailing: Text(_selectedCurrency + product.price.toStringAsFixed(2)),
                      onTap: () {
                        setState(() {
                          _items[index].description = product.name;
                          _items[index].unitPrice = product.price;
                          _calculateTotal();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
            ),
          ],
        ),
      );
    },
  );
}

  void _calculateTotal() {
    double total = 0;
    for (var item in _items) {
      total += item.total;
    }
    setState(() {
      _grandTotal = total;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _generateInvoice() async {
    if (_clientNameController.text.isEmpty) {
      CustomDialog.show(
    context,
    title: "Missing Details",
    message: "Please select a client or enter a client name to proceed.",
    isSuccess: false // Shows Red Icon
  );
      return;
    }

    if (_clientNameController.text.isNotEmpty) {
    await ClientManager.saveClient(Client(
      name: _clientNameController.text, 
      address: _clientAddressController.text
    ));
  }

  for (var item in _items) {
    if (item.description.isNotEmpty && item.unitPrice > 0) {
      await ProductManager.saveProduct(Product(
        name: item.description, 
        price: item.unitPrice
      ));
    }
  }

    final double tax = (double.tryParse(_taxController.text) ?? 0) / 100;
    final double discount = double.tryParse(_discountController.text) ?? 0;

    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientName: _clientNameController.text,
      clientAddress: _clientAddressController.text,
      items: _items,
      date: _selectedDate,
      taxRate: tax,
      discountAmount: discount,
      paymentLink: _paymentLinkController.text,
      currencySymbol: _selectedCurrency, // Pass the currency
    );

    await InvoiceManager.saveInvoice(invoice);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(invoice: invoice),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Modern Light Grey
      appBar: AppBar(
        title: const Text("New Invoice", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- Section 1: Settings (Date & Currency) ---
            _buildSectionCard(
              title: "Invoice Settings",
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Date", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 5),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Currency", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              isExpanded: true,
                              items: _currencies.map((curr) {
                                return DropdownMenuItem(
                                  value: curr['symbol'],
                                  child: Text(curr['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCurrency = val!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --- Section 2: Client Info ---
           Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. Header Row (Title + Button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Bill To", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: _showClientPicker, 
                        icon: const Icon(Icons.contacts, size: 18), 
                        label: const Text("Select Saved"),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 25),
                  
                  // 2. The Inputs (These were missing!)
                  _buildModernTextField(
                    controller: _clientNameController, 
                    label: "Client Name", 
                    icon: Icons.person_outline
                  ),
                  const SizedBox(height: 10),
                  _buildModernTextField(
                    controller: _clientAddressController, 
                    label: "Address / Contact Info", 
                    icon: Icons.location_on_outlined, 
                    maxLines: 2
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --- Section 3: Items ---
            _buildSectionCard(
              title: "Items",
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 30),
                    itemBuilder: (context, index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Inside the Item Builder loop:
Row(
  children: [
    Expanded(
      flex: 4,
      child: _buildModernTextField(
        label: "Description", 
        icon: Icons.description_outlined,
        onChanged: (val) => _items[index].description = val
        // Note: You need to pass controller to _buildModernTextField if you want the text to update visually when selecting from picker.
        // For simplicity, let's just use the picker to set the value in state, which rebuilds the widget.
      ),
    ),
    // --- NEW: Picker Button ---
    IconButton(
      icon: const Icon(Icons.list_alt, color: Colors.blue),
      tooltip: "Select Saved Item",
      onPressed: () => _showProductPicker(index),
    ),
    // --- Existing Delete Button ---
    IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
      onPressed: () => _removeItem(index),
    ),
  ],
),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernTextField(
                                  label: "Qty", 
                                  isNumber: true,
                                  onChanged: (val) {
                                    _items[index].quantity = int.tryParse(val) ?? 1;
                                    _calculateTotal();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildModernTextField(
                                  label: "Price", 
                                  isNumber: true,
                                  prefix: _selectedCurrency, // Use selected currency
                                  onChanged: (val) {
                                    _items[index].unitPrice = double.tryParse(val) ?? 0.0;
                                    _calculateTotal();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Live Total Preview for Item
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$_selectedCurrency${(_items[index].total).toStringAsFixed(2)}",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                                ),
                              )
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text("Add New Line Item"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.blue.shade900),
                        foregroundColor: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --- Section 4: Taxes & Discounts ---
            _buildSectionCard(
              title: "Adjustments & Payment",
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: _taxController, 
                          label: "Tax %", 
                          isNumber: true,
                          suffix: "%",
                          onChanged: (_) => setState((){}),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildModernTextField(
                          controller: _discountController, 
                          label: "Discount", 
                          isNumber: true,
                          prefix: _selectedCurrency,
                          onChanged: (_) => setState((){}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildModernTextField(
                    controller: _paymentLinkController,
                    label: "Payment Link / M-Pesa",
                    icon: Icons.qr_code,
                    hint: "https://paypal.me/..."
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- Footer: Total & Action ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Grand Total", style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text(
                  NumberFormat.currency(symbol: _selectedCurrency).format(_grandTotal),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _generateInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                shadowColor: Colors.blue.withOpacity(0.4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.print),
                  SizedBox(width: 10),
                  Text("Generate & Print PDF", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    TextEditingController? controller,
    required String label,
    IconData? icon,
    bool isNumber = false,
    int maxLines = 1,
    String? prefix,
    String? suffix,
    String? hint,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade900, width: 1.5),
        ),
      ),
    );
  }
}