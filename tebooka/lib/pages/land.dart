import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/colors.dart';
import 'sign_in.dart';

class LandPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const LandPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<LandPage> createState() => _LandPageState();
}

class _LandPageState extends State<LandPage> {
  void navigateToSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignInPage(
          isDarkMode: widget.isDarkMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F1F8), // light sky blue
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // 🚌 Lottie Bus Animation (No white circle)
            SizedBox(
              height: 240,
              width: double.infinity,
              child: Center(
                child: Lottie.network(
                  'https://lottie.host/9d606b14-a944-455e-8fc1-e2bdc29a08ec/VaJRPPJQnB.json',
                  repeat: true,
                  fit: BoxFit.contain,
                  height: 200,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🧭 Main Title
            const Text(
              "Find your trip",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // 📍 Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "No need to worry if you want to go anywhere. Find lots of tickets to various destinations you want in just an app!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 🟦 TEBOOKA Logo Text
            const Text(
              'TEBOOKA',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: kBlue, // Assuming this is defined in utils/colors.dart
              ),
            ),

            const Spacer(),

            // 🟩 Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: ElevatedButton(
                onPressed: navigateToSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Get Started",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
