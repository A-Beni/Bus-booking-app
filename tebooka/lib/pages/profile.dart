import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'change_password_page.dart'; // ✅ Corrected import
import '../utils/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '';
  String email = '';
  String role = '';
  String? imageUrl;
  String busPlate = '';

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final emailUser = FirebaseAuth.instance.currentUser?.email;
    setState(() {
      email = emailUser ?? '';
    });

    if (uid != null) {
      final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (driverDoc.exists) {
        final data = driverDoc.data()!;
        setState(() {
          name = data['name'] ?? 'Driver';
          role = 'Driver';
          busPlate = data['busPlate'] ?? '';
          imageUrl = data['imageUrl'];
        });
      } else if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          name = data['firstName'] ?? 'Passenger';
          role = 'Passenger';
        });
      } else {
        setState(() {
          role = 'Unknown';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlue,
      appBar: AppBar(
        backgroundColor: kBlue,
        title: const Text('Profile', style: TextStyle(color: kWhite)),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: kWhite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imageUrl != null && role == 'Driver')
              CircleAvatar(radius: 50, backgroundImage: NetworkImage(imageUrl!))
            else
              const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(color: kWhite, fontSize: 24)),
            const SizedBox(height: 8),
            Text(email, style: const TextStyle(color: kWhite, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Role: $role', style: const TextStyle(color: kWhite, fontSize: 16)),
            if (role == 'Driver')
              Text('Bus Plate: $busPlate', style: const TextStyle(color: kWhite, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
