import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:uuid/uuid.dart';

import 'driver_map.dart';
import 'driver_profile.dart';
import 'users.dart';
import 'login.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  int _selectedIndex = 1;
  final String googleApiKey = "AIzaSyD4K4zUAbA8AxCRj3068Y3wRIJLWmxG6Rw";

  Future<void> updateLocationAndGoLive() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'from': fromController.text,
      'to': toController.text,
      'isLive': true,
      'name': 'Driver',
    });
  }

  void _onNavTapped(int index) async {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                UsersPage(from: fromController.text, to: toController.text),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DriverMapPage(from: fromController.text, to: toController.text),
          ),
        );
        break;
      case 2:
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(isDarkMode: false, onThemeChanged: (_) {}),
          ),
        );
        break;
    }
  }

  Future<void> openSearchModal(TextEditingController controller) async {
    final googlePlace = GooglePlace(googleApiKey);
    final sessionToken = const Uuid().v4();
    TextEditingController searchController =
        TextEditingController(text: controller.text);
    List<AutocompletePrediction> predictions = [];

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, localSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Search location...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (input) async {
                          if (input.isEmpty) {
                            localSetState(() => predictions = []);
                            return;
                          }

                          final result = await googlePlace.autocomplete.get(
                            input,
                            sessionToken: sessionToken,
                            components: [Component("country", "rw")],
                            location: LatLon(-1.9441, 30.0619),
                            radius: 20000,
                          );

                          if (result != null && result.predictions != null) {
                            localSetState(() => predictions = result.predictions!);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    predictions.isNotEmpty
                        ? SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: predictions.length,
                              itemBuilder: (context, index) {
                                final prediction = predictions[index];
                                return ListTile(
                                  title: Text(prediction.description ?? ''),
                                  onTap: () {
                                    controller.text = prediction.description ?? '';
                                    Navigator.pop(context);
                                    setState(() {}); // refresh UI to update text
                                  },
                                );
                              },
                            ),
                          )
                        : const SizedBox(
                            height: 100,
                            child: Center(child: Text("No suggestions found."))),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildLocationField(TextEditingController controller, String placeholder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      child: Text(
        controller.text.isEmpty ? placeholder : controller.text,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select From:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  if (fromController.text.isNotEmpty) {
                    setState(() {
                      fromController.clear();
                    });
                  } else {
                    openSearchModal(fromController);
                  }
                },
                child: buildLocationField(fromController, "Choose starting location"),
              ),
              const SizedBox(height: 20),
              const Text("Select To:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  if (toController.text.isNotEmpty) {
                    setState(() {
                      toController.clear();
                    });
                  } else {
                    openSearchModal(toController);
                  }
                },
                child: buildLocationField(toController, "Choose destination"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (fromController.text.isEmpty || toController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select both locations')),
                    );
                    return;
                  }
                  await updateLocationAndGoLive();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('You Are Live!'),
                      content: const Text('Passengers can now see your location.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DriverMapPage(
                                  from: fromController.text,
                                  to: toController.text,
                                ),
                              ),
                            );
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Go Live (Share Location)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  String uid = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance
                      .collection('drivers')
                      .doc(uid)
                      .update({'isLive': false});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are offline now')),
                  );
                },
                child: const Text('Stop Sharing Location'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}
