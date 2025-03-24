import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ClearDataApp());
}

class ClearDataApp extends StatelessWidget {
  const ClearDataApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clear Data',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ClearDataScreen(),
    );
  }
}

class ClearDataScreen extends StatefulWidget {
  const ClearDataScreen({Key? key}) : super(key: key);

  @override
  State<ClearDataScreen> createState() => _ClearDataScreenState();
}

class _ClearDataScreenState extends State<ClearDataScreen> {
  String _status = 'Ready to clear data';

  Future<void> _clearAllData() async {
    setState(() {
      _status = 'Clearing data...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all client data
      await prefs.remove('clients');

      // Clear company data
      await prefs.remove('company_info');

      // Clear catalog items
      await prefs.remove('catalog_items');

      // Clear invoices
      await prefs.remove('invoices');

      // Clear any temporary onboarding data
      await prefs.remove('temp_business_name');
      await prefs.remove('temp_logo_path');
      await prefs.remove('temp_currency');
      await prefs.remove('temp_tax_rate');
      await prefs.remove('temp_enable_tax');
      await prefs.remove('temp_country');
      await prefs.remove('temp_address_line1');
      await prefs.remove('temp_address_line2');
      await prefs.remove('temp_city');
      await prefs.remove('temp_zip');

      // Clear any other keys you might have
      await prefs.clear(); // This will clear ALL shared preferences

      setState(() {
        _status = 'All data cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error clearing data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clear Data')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearAllData,
              child: const Text('Clear All Local Data'),
            ),
          ],
        ),
      ),
    );
  }
}
