import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'change_password_page.dart';
import 'seat_selection.dart';
import '../utils/colors.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final TextEditingController busPlateController = TextEditingController();
  bool isLoading = false;
  bool loadingImage = false;

  String name = '';
  String email = '';
  String plate = '';
  String? imageUrl;
  bool isDarkMode = false;
  bool isEditingPlate = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final emailUser = FirebaseAuth.instance.currentUser?.email;
    setState(() {
      email = emailUser ?? '';
    });

    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? 'Driver';
          plate = data['busPlate'] ?? '';
          imageUrl = data['imageUrl'];
          busPlateController.text = plate;
        });
      }
    }
  }

  Future<void> uploadDetails() async {
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final plateText = busPlateController.text.trim();
    if (uid != null && plateText.isNotEmpty) {
      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
        'uid': uid,
        'busPlate': plateText,
      }, SetOptions(merge: true));
      setState(() {
        plate = plateText;
        isEditingPlate = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus plate saved successfully.')),
      );
    }
    setState(() => isLoading = false);
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
          await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
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

  void navigateToSeatSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SeatSelectionPage(
          reservedSeats: [],
          seatCount: 60,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlue,
      appBar: AppBar(
        backgroundColor: kBlue,
        elevation: 0,
        title: const Text("Driver Profile", style: TextStyle(color: kWhite)),
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
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user, size: 20),
                      const SizedBox(width: 6),
                      const Text("Role: Driver", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// Bus Plate with edit icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_bus, size: 20),
                      const SizedBox(width: 6),
                      Text("Bus Plate: $plate", style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          setState(() => isEditingPlate = true);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (isEditingPlate) ...[
                    TextField(
                      controller: busPlateController,
                      decoration: const InputDecoration(labelText: 'Edit Bus Plate'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: uploadDetails,
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Bus Plate'),
                    ),
                    const SizedBox(height: 20),
                  ],

                  ElevatedButton.icon(
                    onPressed: navigateToSeatSelection,
                    icon: const Icon(Icons.event_seat),
                    label: const Text("Manage Bus Seats"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.brightness_6),
                      const SizedBox(width: 10),
                      const Text("Dark Mode"),
                      Switch(
                        value: isDarkMode,
                        onChanged: (value) {
                          setState(() => isDarkMode = value);
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
