import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invoicegenerator/services/auth_service.dart';

class AuthProvider extends StatelessWidget {
  final Widget child;

  const AuthProvider({super.key, required this.child});

  static AuthService of(BuildContext context) {
    return Provider.of<AuthService>(context, listen: false);
  }

  static AuthService watchAuth(BuildContext context) {
    return Provider.of<AuthService>(context);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => AuthService(), child: child);
  }
}
