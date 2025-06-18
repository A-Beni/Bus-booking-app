import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlue,
      appBar: AppBar(
        backgroundColor: kBlue,
        title: const Text('Profile', style: TextStyle(color: kWhite)),
      ),
      body: const Center(
        child: Text(
          'Profile Update Page',
          style: TextStyle(color: kWhite, fontSize: 20),
        ),
      ),
    );
  }
}
