import 'package:flutter/material.dart';
import 'pages/land.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/profile.dart';
import 'pages/email_verification_handler.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TEBOOKA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LandPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/verify-check': (context) => const EmailVerificationHandlerPage(),
      },
    );
  }
}
