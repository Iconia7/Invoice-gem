import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'package:local_auth/local_auth.dart';

void main() async {
  // Ensure Flutter binding is initialized before calling async code
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if onboarding is already done
  final prefs = await SharedPreferences.getInstance();
  final bool showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);

  runApp(InvoiceApp(showOnboarding: showOnboarding));
}

class InvoiceApp extends StatefulWidget {
  final bool showOnboarding;
  const InvoiceApp({super.key, required this.showOnboarding});

  @override
  State<InvoiceApp> createState() => _InvoiceAppState();
}

class _InvoiceAppState extends State<InvoiceApp> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheck = await auth.canCheckBiometrics;
    if (canCheck) {
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'Scan to access your Invoices',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );
        setState(() {
          _isAuthenticated = authenticated;
        });
      } catch (e) {
        print("Auth Error: $e");
      }
    } else {
      // No biometrics hardware? Just let them in.
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- 1. Glassmorphism Lock Icon ---
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 80, color: Colors.white),
                ),
                
                const SizedBox(height: 40),

                // --- 2. Welcome Text ---
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your invoices are secured.",
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                ),

                const SizedBox(height: 60),

                // --- 3. Unlock Button ---
                SizedBox(
                  width: 200,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _checkBiometrics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade900,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint),
                        SizedBox(width: 10),
                        Text(
                          "Unlock App",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Optional: Fallback text button
                TextButton(
                  onPressed: () {
                     // In a real app, you might offer a PIN fallback here
                     // For now, it just retries biometrics
                     _checkBiometrics();
                  },
                  child: Text(
                    "Use PIN or Pattern", 
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    // --- Main App ---
    return MaterialApp(
      title: 'Invoice Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
        fontFamily: 'Roboto', // Optional: Ensure you have a nice font or remove if not set up
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: widget.showOnboarding ? const OnboardingScreen() : const DashboardScreen(),
    );
  }
}