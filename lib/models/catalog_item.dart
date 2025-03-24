class CatalogItem {
  final String? id; // Supabase UUID
  final String? userId; // Auth user ID
  final String? itemId; // Unique item ID (used for migration)
  final String title;
  final String currency;
  final String amount;
  final int quantity;
  final String usageInfo;
  final bool isNew;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CatalogItem({
    this.id,
    this.userId,
    this.itemId,
    required this.title,
    required this.amount,
    required this.quantity,
    this.currency = 'USD',
    this.usageInfo = 'USED IN 0 INVOICES',
    this.isNew = true,
    this.createdAt,
    this.updatedAt,
  });

  // Create a copy of this item with modified properties
  CatalogItem copyWith({
    String? id,
    String? userId,
    String? itemId,
    String? title,
    String? currency,
    String? amount,
    int? quantity,
    String? usageInfo,
    bool? isNew,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      usageInfo: usageInfo ?? this.usageInfo,
      isNew: isNew ?? this.isNew,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'item_id': itemId,
      'title': title,
      'currency': currency,
      'amount': amount,
      'quantity': quantity,
      'usage_info': usageInfo,
      'is_new': isNew,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from map
  factory CatalogItem.fromMap(Map<String, dynamic> map) {
    return CatalogItem(
      id: map['id'],
      userId: map['user_id'],
      itemId: map['item_id'],
      title: map['title'],
      currency: map['currency'],
      amount: map['amount'],
      quantity: map['quantity'] ?? 1,
      usageInfo: map['usage_info'] ?? map['usageInfo'] ?? 'USED IN 0 INVOICES',
      isNew: map['is_new'] ?? map['isNew'] ?? false,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
