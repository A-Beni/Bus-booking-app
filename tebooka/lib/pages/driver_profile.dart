import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final TextEditingController busPlateController = TextEditingController();
  bool isLoading = false;
  String name = '';
  String plate = '';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          plate = data['busPlate'] ?? '';
          name = data['name'] ?? '';
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
      setState(() => plate = plateText);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Details updated')));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(children: [
            const Icon(Icons.directions_bus, size: 80, color: Colors.grey),
            const SizedBox(height: 12),
            TextField(controller: busPlateController, decoration: const InputDecoration(labelText: 'Bus Plate')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: uploadDetails,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            ),
          ]),
        ),
      ),
    );
  }
}
