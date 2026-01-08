import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Invoice {
  final String id;
  final String clientName;
  final String clientAddress;
  final List<InvoiceItem> items;
  final String currencySymbol;
  bool isPaid;
  final DateTime date;
  final double taxRate; // e.g., 0.16 for 16%
  final double discountAmount;
  final String paymentLink; // URL or Payment Info for QR

  Invoice({
    required this.id,
    required this.clientName,
    required this.clientAddress,
    required this.items,
    required this.date,
    this.isPaid = false,
    this.currencySymbol = '\$',
    this.taxRate = 0.0,
    this.discountAmount = 0.0,
    this.paymentLink = '',
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxAmount => (subtotal - discountAmount) * taxRate;
  double get grandTotal => (subtotal - discountAmount) + taxAmount;

  // Save to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'clientName': clientName,
    'clientAddress': clientAddress,
    'items': items.map((i) => i.toJson()).toList(),
    'date': date.toIso8601String(),
    'isPaid': isPaid,
    'currencySymbol': currencySymbol,
    'taxRate': taxRate,
    'discountAmount': discountAmount,
    'paymentLink': paymentLink,
  };

  // Load from JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      clientName: json['clientName'],
      clientAddress: json['clientAddress'],
      items: (json['items'] as List).map((i) => InvoiceItem.fromJson(i)).toList(),
      date: DateTime.parse(json['date']),
      isPaid: json['isPaid'] ?? false,
      currencySymbol: json['currencySymbol'] ?? '\$',
      taxRate: json['taxRate'] ?? 0.0,
      discountAmount: json['discountAmount'] ?? 0.0,
      paymentLink: json['paymentLink'] ?? '',
    );
  }
}



class InvoiceItem {
  String description;
  int quantity;
  double unitPrice;

  InvoiceItem({this.description = '', this.quantity = 1, this.unitPrice = 0.0});

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'],
    );
  }
}

class InvoiceManager {
  static Future<void> saveInvoice(Invoice invoice) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> invoices = prefs.getStringList('saved_invoices') ?? [];
    
    // Convert invoice to JSON string and add to list
    invoices.add(jsonEncode(invoice.toJson()));
    
    await prefs.setStringList('saved_invoices', invoices);
  }

  static Future<void> toggleStatus(String id, bool newStatus) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> savedStrings = prefs.getStringList('saved_invoices') ?? [];
  
  List<Invoice> invoices = savedStrings.map((item) => Invoice.fromJson(jsonDecode(item))).toList();
  
  // Find and update
  final index = invoices.indexWhere((inv) => inv.id == id);
  if (index != -1) {
    invoices[index].isPaid = newStatus;
    
    // Save back
    List<String> newStrings = invoices.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('saved_invoices', newStrings);
  }
}

  static Future<void> deleteInvoice(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedStrings = prefs.getStringList('saved_invoices') ?? [];
    
    // Decode, Remove the one with matching ID, then Encode back
    List<Invoice> invoices = savedStrings.map((item) => Invoice.fromJson(jsonDecode(item))).toList();
    invoices.removeWhere((invoice) => invoice.id == id);
    
    // Save the updated list
    List<String> newStrings = invoices.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('saved_invoices', newStrings);
  }

  static Future<List<Invoice>> getInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> invoices = prefs.getStringList('saved_invoices') ?? [];
    
    return invoices.map((item) => Invoice.fromJson(jsonDecode(item))).toList();
  }
}

class Client {
  final String name;
  final String address;

  Client({required this.name, required this.address});

  Map<String, dynamic> toJson() => {'name': name, 'address': address};

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(name: json['name'], address: json['address']);
  }
}

class ClientManager {
  static Future<void> saveClient(Client client) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> clients = prefs.getStringList('saved_clients') ?? [];
    
    // Avoid duplicates
    bool exists = clients.any((c) => Client.fromJson(jsonDecode(c)).name == client.name);
    if (!exists) {
      clients.add(jsonEncode(client.toJson()));
      await prefs.setStringList('saved_clients', clients);
    }
  }

  static Future<List<Client>> getClients() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> clients = prefs.getStringList('saved_clients') ?? [];
    return clients.map((c) => Client.fromJson(jsonDecode(c))).toList();
  }
}

class Product {
  final String name;
  final double price;

  Product({required this.name, required this.price});

  Map<String, dynamic> toJson() => {'name': name, 'price': price};

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(name: json['name'], price: json['price']);
  }
}

class ProductManager {
  static Future<void> saveProduct(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> products = prefs.getStringList('saved_products') ?? [];
    
    // Avoid duplicates
    bool exists = products.any((p) => Product.fromJson(jsonDecode(p)).name == product.name);
    if (!exists) {
      products.add(jsonEncode(product.toJson()));
      await prefs.setStringList('saved_products', products);
    }
  }

  static Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> products = prefs.getStringList('saved_products') ?? [];
    return products.map((p) => Product.fromJson(jsonDecode(p))).toList();
  }
}