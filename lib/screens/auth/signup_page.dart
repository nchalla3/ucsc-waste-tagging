import 'package:flutter/material.dart';
import 'package:waste_tagging_app/services/auth_service.dart';
import 'package:waste_tagging_app/widgets/google_sign_in_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  String? _error;

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Firebase automatically signs in the user after sign-up
      // Navigate back to let AuthWrapper handle the authenticated state
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // Light pastel green
      appBar: AppBar(
        title: const Text('Sign Up', style: TextStyle(color: Color(0xFF003C71))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF003C71)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFD32F2F)), // Alert Red
                  textAlign: TextAlign.center,
                ),
              ),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Color(0xFF212121)), // Charcoal
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Color(0xFF424242)), // Dark Gray
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)), // Forest Green
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1B5E20), width: 2), // Deep Forest Green
                ),
                filled: true,
                fillColor: Colors.white, // Surface
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Color(0xFF212121)), // Charcoal
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Color(0xFF424242)), // Dark Gray
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)), // Forest Green
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1B5E20), width: 2), // Deep Forest Green
                ),
                filled: true,
                fillColor: Colors.white, // Surface
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003C71), // UCSC Blue (was yellow)
                  foregroundColor: Colors.white, // onPrimary
                  elevation: 2,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: _loading ? null : _signUp,
                child: _loading
                    ? const CircularProgressIndicator(color: Color(0xFF003C71)) // UCSC Blue (was yellow)
                    : const Text('Sign Up'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'OR',
              style: TextStyle(
                color: Color(0xFF003C71), // UCSC Blue
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const GoogleSignInButton(),
          ],
        ),
      ),
    );
  }
}
