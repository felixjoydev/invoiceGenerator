import 'package:flutter/material.dart';
import 'package:invoicegenerator/screens/splash/splash_screen.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client - replace with your own URLs and keys
  await Supabase.initialize(url: 'SUPABASE_URL', anonKey: 'SUPABASE_ANON_KEY');

  runApp(const ProviderScope(child: InvoiceGeneratorApp()));
}

class InvoiceGeneratorApp extends StatelessWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(AppTheme.defaultPrimaryColor),
      // We'll implement the SplashScreen first
      home: const SplashScreen(),
    );
  }
}
