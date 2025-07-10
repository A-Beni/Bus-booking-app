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
  bool? _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final emailUser = FirebaseAuth.instance.currentUser?.email;

    setState(() {
      email = emailUser ?? '';
    });

    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final firstName = data['firstName'] ?? 'Passenger';
        final lastName = data['lastName'] ?? '';
        setState(() {
          fullName = '$firstName $lastName'.trim();
          role = 'Passenger';
          imageUrl = data['imageUrl'];
        });
      } else {
        final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
        if (driverDoc.exists) {
          final data = driverDoc.data()!;
          setState(() {
            fullName = data['name'] ?? 'Driver';
            role = 'Driver';
            busPlate = data['busPlate'] ?? '';
            imageUrl = data['imageUrl'];
          });
        } else {
          setState(() {
            role = 'Unknown';
          });
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (loadingImage) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

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

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile image updated successfully")),
          );
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
    const phone = '250739933117';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: kBlue,
        elevation: 4,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, color: kWhite),
            tooltip: "Change Password",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
            },
          ),
        ],
      ),
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                        child: imageUrl == null
                            ? Icon(Icons.person_outline, size: 70, color: Colors.grey[600])
                            : null,
                      ),
                      GestureDetector(
                        onTap: loadingImage ? null : _pickAndUploadImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kBlue,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 5,
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: loadingImage
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_rounded, size: 24, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    fullName.isEmpty ? "Loading..." : fullName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user, size: 22, color: kBlue),
                      const SizedBox(width: 8),
                      Text(
                        "Role: $role",
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (role == 'Driver') ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_bus, size: 22, color: kBlue),
                        const SizedBox(width: 8),
                        Text(
                          "Bus Plate: $busPlate",
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  Divider(color: Colors.grey.shade300, thickness: 1.2),
                  const SizedBox(height: 24),

                  /// Theme toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.brightness_6, color: kBlue),
                      const SizedBox(width: 12),
                      const Text(
                        "Dark Mode",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _darkMode ?? false,
                        activeColor: kBlue,
                        onChanged: (value) {
                          setState(() {
                            _darkMode = value;
                          });
                          widget.onThemeChanged(value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
                    label: const Text("Contact Us via WhatsApp", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    onPressed: _contactViaWhatsApp,
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.confirmation_num, color: Colors.white, size: 20),
                    label: const Text("My Tickets", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 144, 181, 63),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TicketsHistoryPage()),
                      );
                    },
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
