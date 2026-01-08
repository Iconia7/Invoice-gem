import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.grey);
    
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black87),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      pages: [
        // --- Page 1: Create ---
        PageViewModel(
          title: "Professional Invoices",
          body: "Create sleek, branded invoices in seconds. Add your logo and signature to look like a pro.",
          image: _buildImage(Icons.receipt_long_rounded, Colors.blue),
          decoration: pageDecoration,
        ),
        
        // --- Page 2: Pay ---
        PageViewModel(
          title: "Smart Payments",
          body: "Get paid faster. Add your PayPal or M-Pesa details and we generate a scannable QR code automatically.",
          image: _buildImage(Icons.qr_code_2_rounded, Colors.orange),
          decoration: pageDecoration,
        ),
        
        // --- Page 3: Track ---
        PageViewModel(
          title: "Business Insights",
          body: "Track your history, calculate taxes, and export PDFs. Keep your business organized in one place.",
          image: _buildImage(Icons.insights_rounded, Colors.green),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _completeOnboarding(context),
      onSkip: () => _completeOnboarding(context),
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      
      // --- Custom Button Styling ---
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
      next: const Icon(Icons.arrow_forward, color: Colors.blueAccent),
      done: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueAccent)),
      
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Colors.grey.shade300,
        activeSize: const Size(22.0, 10.0),
        activeColor: Colors.blue[900], // Brand Color
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }

  // Helper to build consistent, stylish images
  Widget _buildImage(IconData icon, Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Soft background
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 100.0,
        color: color,
      ),
    );
  }
}