import 'package:uuid/uuid.dart';

// User Model
class User {
  final String id;
  final String email;
  String companyName;
  String currency;
  double? taxRate;
  Address address;
  ContactInfo contactInfo;
  final DateTime createdAt;
  DateTime updatedAt;

  User({
    String? id,
    required this.email,
    required this.companyName,
    required this.currency,
    this.taxRate,
    required this.address,
    required this.contactInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'companyName': companyName,
      'currency': currency,
      'taxRate': taxRate,
      'address': address.toJson(),
      'contactInfo': contactInfo.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      companyName: json['companyName'],
      currency: json['currency'],
      taxRate: json['taxRate'],
      address: Address.fromJson(json['address']),
      contactInfo: ContactInfo.fromJson(json['contactInfo']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// Organization Model
class Organization {
  final String id;
  final String userId;
  String name;
  String currency;
  double? taxRate;
  Address address;
  ContactInfo contactInfo;
  final DateTime createdAt;
  DateTime updatedAt;

  Organization({
    String? id,
    required this.userId,
    required this.name,
    required this.currency,
    this.taxRate,
    required this.address,
    required this.contactInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'currency': currency,
      'taxRate': taxRate,
      'address': address.toJson(),
      'contactInfo': contactInfo.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      currency: json['currency'],
      taxRate: json['taxRate'],
      address: Address.fromJson(json['address']),
      contactInfo: ContactInfo.fromJson(json['contactInfo']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// Client Model
class Client {
  final String id;
  final String userId;
  final String organizationId;
  bool isOrganization;
  String name;
  String? taxId;
  Address address;
  ContactInfo contactInfo;
  String? notes;
  final DateTime createdAt;
  DateTime updatedAt;

  Client({
    String? id,
    required this.userId,
    required this.organizationId,
    required this.isOrganization,
    required this.name,
    this.taxId,
    required this.address,
    required this.contactInfo,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'organizationId': organizationId,
      'isOrganization': isOrganization,
      'name': name,
      'taxId': taxId,
      'address': address.toJson(),
      'contactInfo': contactInfo.toJson(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      userId: json['userId'],
      organizationId: json['organizationId'],
      isOrganization: json['isOrganization'],
      name: json['name'],
      taxId: json['taxId'],
      address: Address.fromJson(json['address']),
      contactInfo: ContactInfo.fromJson(json['contactInfo']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// Invoice Model
class Invoice {
  final String id;
  final String userId;
  final String organizationId;
  final String clientId;
  String invoiceNumber;
  DateTime issueDate;
  DateTime dueDate;
  List<InvoiceItem> items;
  double subtotal;
  double taxRate;
  double taxAmount;
  double? discountAmount;
  double total;
  String? notes;
  String templateId;
  InvoiceStatus status;
  final DateTime createdAt;
  DateTime updatedAt;

  Invoice({
    String? id,
    required this.userId,
    required this.organizationId,
    required this.clientId,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    this.discountAmount,
    required this.total,
    this.notes,
    required this.templateId,
    required this.status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'organizationId': organizationId,
      'clientId': clientId,
      'invoiceNumber': invoiceNumber,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'total': total,
      'notes': notes,
      'templateId': templateId,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      userId: json['userId'],
      organizationId: json['organizationId'],
      clientId: json['clientId'],
      invoiceNumber: json['invoiceNumber'],
      issueDate: DateTime.parse(json['issueDate']),
      dueDate: DateTime.parse(json['dueDate']),
      items:
          (json['items'] as List)
              .map((item) => InvoiceItem.fromJson(item))
              .toList(),
      subtotal: json['subtotal'],
      taxRate: json['taxRate'],
      taxAmount: json['taxAmount'],
      discountAmount: json['discountAmount'],
      total: json['total'],
      notes: json['notes'],
      templateId: json['templateId'],
      status: _parseInvoiceStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  static InvoiceStatus _parseInvoiceStatus(String status) {
    switch (status) {
      case 'InvoiceStatus.paid':
        return InvoiceStatus.paid;
      case 'InvoiceStatus.outstanding':
        return InvoiceStatus.outstanding;
      case 'InvoiceStatus.overdue':
        return InvoiceStatus.overdue;
      default:
        return InvoiceStatus.outstanding;
    }
  }
}

// InvoiceItem Model
class InvoiceItem {
  final String id;
  final String invoiceId;
  String? catalogItemId;
  String description;
  double quantity;
  double unitPrice;
  double amount;
  final DateTime createdAt;
  DateTime updatedAt;

  InvoiceItem({
    String? id,
    required this.invoiceId,
    this.catalogItemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'catalogItemId': catalogItemId,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'],
      invoiceId: json['invoiceId'],
      catalogItemId: json['catalogItemId'],
      description: json['description'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'],
      amount: json['amount'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// CatalogItem Model
class CatalogItem {
  final String id;
  final String userId;
  final String organizationId;
  String name;
  String? description;
  double defaultQuantity;
  double price;
  final DateTime createdAt;
  DateTime updatedAt;

  CatalogItem({
    String? id,
    required this.userId,
    required this.organizationId,
    required this.name,
    this.description,
    required this.defaultQuantity,
    required this.price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'organizationId': organizationId,
      'name': name,
      'description': description,
      'defaultQuantity': defaultQuantity,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'],
      userId: json['userId'],
      organizationId: json['organizationId'],
      name: json['name'],
      description: json['description'],
      defaultQuantity: json['defaultQuantity'],
      price: json['price'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// Address Model
class Address {
  String street;
  String city;
  String? state;
  String zipCode;
  String country;

  Address({
    required this.street,
    required this.city,
    this.state,
    required this.zipCode,
    required this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
    );
  }
}

// ContactInfo Model
class ContactInfo {
  String email;
  String? phone;
  String? website;

  ContactInfo({required this.email, this.phone, this.website});

  Map<String, dynamic> toJson() {
    return {'email': email, 'phone': phone, 'website': website};
  }

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
    );
  }
}

// InvoiceStatus Enum
enum InvoiceStatus { paid, outstanding, overdue }
