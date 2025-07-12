import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/auth/login_page.dart';
import '../screens/home/home_page.dart';
import '../services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Log the current auth state for debugging
        print('🔵 AuthWrapper: Connection state: ${snapshot.connectionState}');
        print('🔵 AuthWrapper: Has data: ${snapshot.hasData}');
        print('🔵 AuthWrapper: User: ${snapshot.data?.email ?? 'null'}');
        
        // Debug authentication state
        authService.debugAuthState();
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While checking auth state, show loading
          print('🔵 AuthWrapper: Showing loading screen');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking authentication status...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('🔴 AuthWrapper: Stream error: ${snapshot.error}');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('Authentication error occurred'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in
          print('🟢 AuthWrapper: User is authenticated, showing HomePage');
          return const HomePage();
        } else {
          // User is not logged in
          print('🟡 AuthWrapper: No user authenticated, showing LoginPage');
          return const LoginPage();
        }
      },
    );
  }
}
