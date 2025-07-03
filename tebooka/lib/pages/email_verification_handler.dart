import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home.dart';
import 'login.dart';
import 'driver_home.dart';

class EmailVerificationHandlerPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const EmailVerificationHandlerPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<EmailVerificationHandlerPage> createState() =>
      _EmailVerificationHandlerPageState();
}

class _EmailVerificationHandlerPageState
    extends State<EmailVerificationHandlerPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    handleVerificationCheck();
  }

  Future<void> handleVerificationCheck() async {
    User? user = _auth.currentUser;

    if (user != null) {
      await user.reload(); // Refresh email verification status
      user = _auth.currentUser;

      if (user!.emailVerified) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = doc.data()?['role'] ?? 'passenger';

        if (role == 'driver') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverHomePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                isDarkMode: widget.isDarkMode,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        }
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          isDarkMode: widget.isDarkMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
