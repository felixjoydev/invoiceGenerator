import 'package:invoicegenerator/models/client.dart' as old_model;
import 'package:invoicegenerator/models/hive/client_model.dart' as hive_model;

/// Helper class to convert between old Client model and Hive Client model
class ClientAdapter {
  /// Convert from Hive Client model to old Client model
  static old_model.Client fromHiveClient(hive_model.Client hiveClient) {
    return old_model.Client(
      name: hiveClient.name,
      clientId: hiveClient.clientId,
      country: hiveClient.country,
      addressLine1: hiveClient.addressLine1,
      addressLine2: hiveClient.addressLine2,
      city: hiveClient.city,
      zip: hiveClient.zipCode,
      phone: hiveClient.phone,
      email: hiveClient.email,
      type: hiveClient.type,
      invoiceCount: hiveClient.invoiceCount,
      currency: hiveClient.currencyOrDefault,
      amount: hiveClient.amount,
      outstandingAmount: hiveClient.outstandingAmount,
      hasOutstanding: hiveClient.hasOutstanding,
      dueAmount: hiveClient.dueAmount,
      hasDue: hiveClient.hasDue,
    );
  }

  /// Convert from old Client model to Hive Client model
  static hive_model.Client toHiveClient(old_model.Client oldClient) {
    return hive_model.Client(
      clientId: oldClient.clientId,
      name: oldClient.name,
      type: oldClient.type,
      email: oldClient.email,
      phone: oldClient.phone,
      addressLine1: oldClient.addressLine1,
      addressLine2: oldClient.addressLine2,
      city: oldClient.city,
      state: null, // Old model doesn't have state
      zipCode: oldClient.zip,
      country: oldClient.country,
      invoiceCount: oldClient.invoiceCount,
      amount: oldClient.amount,
      outstandingAmount: oldClient.outstandingAmount,
      dueAmount: oldClient.dueAmount,
      currency: oldClient.currency,
    );
  }
}
