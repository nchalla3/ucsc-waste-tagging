import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'wrappers/auth_wrapper.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔵 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('🟢 Firebase initialized successfully');
  
  // Test Google Sign-In configuration on app start
  print('🔵 Testing Google Sign-In configuration...');
  try {
    await AuthService().testGoogleSignInConfiguration();
    print('🟢 Google Sign-In configuration test completed');
  } catch (e) {
    print('🔴 Google Sign-In configuration test failed: $e');
  }

  runApp(const WasteTrackingApp());
}

class WasteTrackingApp extends StatelessWidget {
  const WasteTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCSC Waste Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
