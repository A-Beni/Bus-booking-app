import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/land.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/profile.dart';
import 'pages/email_verification_handler.dart';

class App extends StatefulWidget {
  final bool isDarkMode;

  const App({super.key, required this.isDarkMode});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void _toggleTheme(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TEBOOKA',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: LandPage(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
      routes: {
        '/home': (context) => HomePage(
              isDarkMode: _isDarkMode,
              onThemeChanged: _toggleTheme,
            ),
        '/login': (context) => LoginPage(
              isDarkMode: _isDarkMode,
              onThemeChanged: _toggleTheme,
            ),
        '/profile': (context) => ProfilePage(
              isDarkMode: _isDarkMode,
              onThemeChanged: _toggleTheme,
            ),
        '/verify-check': (context) => EmailVerificationHandlerPage(
              isDarkMode: _isDarkMode,
              onThemeChanged: _toggleTheme,
            ),
      },
    );
  }
}
