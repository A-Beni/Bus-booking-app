import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusDetailsPage extends StatelessWidget {
  final String driverId;

  const BusDetailsPage({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bus Details"), backgroundColor: Colors.blue),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('drivers').doc(driverId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No bus details found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Driver Info",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Name: ${data['name'] ?? 'N/A'}", style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text("Bus Plate: ${data['busPlate'] ?? 'N/A'}", style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text("From: ${data['from'] ?? 'N/A'} ➝ ${data['to'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text("Location: (${data['latitude']}, ${data['longitude']})",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  const Text("Live bus location and info displayed above.",
                      style: TextStyle(color: Colors.grey)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
