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
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 6), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignInPage(
            isDarkMode: widget.isDarkMode,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TEBOOKA',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: kWhite,
              ),
            ),
            const SizedBox(height: 7),
            Lottie.network(
              'https://lottie.host/9d606b14-a944-455e-8fc1-e2bdc29a08ec/VaJRPPJQnB.json',
              width: 200,
              height: 120,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
