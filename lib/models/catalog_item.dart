class CatalogItem {
  final String title;
  final String currency;
  final String amount;
  final int quantity;
  final String usageInfo;
  final bool isNew;

  CatalogItem({
    required this.title,
    required this.amount,
    required this.quantity,
    this.currency = 'USD',
    this.usageInfo = 'USED IN 0 INVOICES',
    this.isNew = true,
  });

  // Create a copy of this item with modified properties
  CatalogItem copyWith({
    String? title,
    String? currency,
    String? amount,
    int? quantity,
    String? usageInfo,
    bool? isNew,
  }) {
    return CatalogItem(
      title: title ?? this.title,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      usageInfo: usageInfo ?? this.usageInfo,
      isNew: isNew ?? this.isNew,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'currency': currency,
      'amount': amount,
      'quantity': quantity,
      'usageInfo': usageInfo,
      'isNew': isNew,
    };
  }

  // Create from map
  factory CatalogItem.fromMap(Map<String, dynamic> map) {
    return CatalogItem(
      title: map['title'],
      currency: map['currency'],
      amount: map['amount'],
      quantity: map['quantity'] ?? 1,
      usageInfo: map['usageInfo'],
      isNew: map['isNew'] ?? false,
    );
  }
}
