import 'package:flutter/material.dart';
import 'package:waste_tagging_app/services/auth_service.dart';
import 'package:waste_tagging_app/widgets/google_sign_in_button.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() => _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // Light pastel green
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top - 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Top row with logos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // UCSC Logo (top left)
                    Image.asset(
                      'assets/images/ucsc_logo.png',
                      height: 150,
                      width: 150,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if the image isn't available
                        return const Icon(
                          Icons.school,
                          size: 60,
                          color: Color(0xFF003C71), // UCSC Blue
                        );
                      },
                    ),
                    // Sustainability Office Logo (top right)
                    Image.asset(
                      'assets/images/sustainability_office.png',
                      height: 150,
                      width: 150,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if the image isn't available
                        return const Icon(
                          Icons.eco,
                          size: 60,
                          color: Color(0xFF2E7D32), // Forest Green
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // App Title
                const Text(
                  'UCSC Waste Auditing',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003C71), // UCSC Blue
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Caption
                const Text(
                  'A crowdsourced initiative to get a better understanding of progress towards campus waste objectives',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF2E7D32), // Forest Green (was yellow)
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                // Login Form
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
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Color(0xFF003C71)) // UCSC Blue (was yellow)
                        : const Text('Log In'),
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
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(
                      color: Color(0xFF003C71), // UCSC Blue
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
