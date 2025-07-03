import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'change_password_page.dart';
import 'tickets_history.dart';
import '../utils/colors.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String fullName = '';
  String email = '';
  String role = '';
  String? imageUrl;
  String busPlate = '';
  bool loadingImage = false;
  bool? _darkMode; // Changed from late to nullable to avoid LateInitializationError

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode; // Initialize safely
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
          fullName = data['name'] ?? 'Driver';
          role = 'Driver';
          busPlate = data['busPlate'] ?? '';
          imageUrl = data['imageUrl'];
        });
      } else if (userDoc.exists) {
        final data = userDoc.data()!;
        final firstName = data['firstName'] ?? 'Passenger';
        final lastName = data['lastName'] ?? '';
        setState(() {
          fullName = '$firstName $lastName';
          role = 'Passenger';
          imageUrl = data['imageUrl'];
        });
      } else {
        setState(() {
          role = 'Unknown';
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() => loadingImage = true);

        final uid = FirebaseAuth.instance.currentUser?.uid;
        final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
        await ref.putData(await pickedFile.readAsBytes());
        final downloadUrl = await ref.getDownloadURL();

        if (uid != null) {
          final collection = role == 'Driver' ? 'drivers' : 'users';
          await FirebaseFirestore.instance.collection(collection).doc(uid).update({
            'imageUrl': downloadUrl,
          });

          setState(() {
            imageUrl = downloadUrl;
            loadingImage = false;
          });
        }
      }
    } catch (e) {
      setState(() => loadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    }
  }

  Future<void> _contactViaWhatsApp() async {
    final phone = '250739933117';
    final message = Uri.encodeComponent("Hello, I need assistance with TEBOOKA.");
    final uri = Uri.parse("https://wa.me/$phone?text=$message");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlue,
      appBar: AppBar(
        backgroundColor: kBlue,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: kWhite)),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: kWhite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                          backgroundColor: Colors.grey[200],
                          child: imageUrl == null
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                      ),
                      if (loadingImage)
                        const Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(fullName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user, size: 20),
                      const SizedBox(width: 6),
                      Text("Role: $role", style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  if (role == 'Driver') ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_bus, size: 20),
                        const SizedBox(width: 6),
                        Text("Bus Plate: $busPlate", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  /// 🌙 Theme toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.brightness_6),
                      const SizedBox(width: 10),
                      const Text("Dark Mode"),
                      Switch(
                        value: _darkMode ?? false,
                        onChanged: (value) {
                          setState(() {
                            _darkMode = value;
                          });
                          widget.onThemeChanged(value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _contactViaWhatsApp,
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
                    label: const Text("Contact Us via WhatsApp"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TicketsHistoryPage()),
                      );
                    },
                    icon: const Icon(Icons.confirmation_num, color: Colors.white),
                    label: const Text("My Tickets"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 144, 181, 63),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
