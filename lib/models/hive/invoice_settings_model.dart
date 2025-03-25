import 'package:hive/hive.dart';

part 'invoice_settings_model.g.dart';

/// Invoice Settings model for Hive
@HiveType(typeId: 4)
class InvoiceSettings extends HiveObject {
  @HiveField(0)
  String idFormat;

  @HiveField(1)
  String? customNotes;

  @HiveField(2)
  bool isAutoGenerate;

  @HiveField(3)
  String idPrefix;

  @HiveField(4)
  int lastInvoiceNumber;

  @HiveField(5)
  int dueDateDays;

  InvoiceSettings({
    required this.idFormat,
    this.customNotes,
    this.isAutoGenerate = true,
    this.idPrefix = 'INV',
    this.lastInvoiceNumber = 0,
    this.dueDateDays = 30,
  });

  /// Convert from JSON
  factory InvoiceSettings.fromJson(Map<String, dynamic> json) {
    return InvoiceSettings(
      idFormat: json['idFormat'] ?? 'inv-000',
      customNotes: json['customNotes'],
      isAutoGenerate: json['isAutoGenerate'] ?? true,
      idPrefix: json['idPrefix'] ?? 'INV',
      lastInvoiceNumber: json['lastInvoiceNumber'] ?? 0,
      dueDateDays: json['dueDateDays'] ?? 30,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'idFormat': idFormat,
      'customNotes': customNotes,
      'isAutoGenerate': isAutoGenerate,
      'idPrefix': idPrefix,
      'lastInvoiceNumber': lastInvoiceNumber,
      'dueDateDays': dueDateDays,
    };
  }

  /// Create default settings
  factory InvoiceSettings.defaultSettings() {
    return InvoiceSettings(
      idFormat: 'inv-000',
      isAutoGenerate: true,
      idPrefix: 'INV',
      lastInvoiceNumber: 0,
      dueDateDays: 30,
    );
  }
}
