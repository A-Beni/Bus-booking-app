import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;

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
  String from = '';
  String to = '';
  bool isLive = false;

  final List<String> stops = [
    'Kimironko Bus Stop',
    'Downtown Bus Stop',
    'Kicukiro Bus Stop'
  ];

  int _selectedIndex = 1;

  Future<void> updateLocationAndGoLive() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'from': from,
      'to': to,
      'isLive': true,
      'name': 'Driver',
    });
  }

  void _onNavTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UsersPage(from: from, to: to), 
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverMapPage(from: from, to: to),
          ),
        );
        break;
      case 2:
        final navigator = Navigator.of(context);
        await FirebaseAuth.instance.signOut();
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginPage(
              isDarkMode: false,
              onThemeChanged: (_) {},
            ),
          ),
        );
        break;
    }
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select From:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: from.isEmpty ? null : from,
              hint: const Text('Choose starting point'),
              items: stops
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => from = val!),
            ),
            const SizedBox(height: 20),
            const Text("Select To:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: to.isEmpty ? null : to,
              hint: const Text('Choose destination'),
              items: stops
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => to = val!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                if (from.isEmpty || to.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select both locations')),
                  );
                  return;
                }

                final location = loc.Location();
                bool serviceEnabled = await location.serviceEnabled();
                if (!serviceEnabled) {
                  serviceEnabled = await location.requestService();
                }

                var permissionGranted = await location.hasPermission();
                if (permissionGranted == loc.PermissionStatus.denied) {
                  permissionGranted = await location.requestPermission();
                  if (permissionGranted != loc.PermissionStatus.granted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Location permission is required to go live')),
                    );
                    return;
                  }
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
                              builder: (_) =>
                                  DriverMapPage(from: from, to: to),
                            ),
                          );
                        },
                        child: const Text('OK'),
                      )
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
                setState(() => isLive = false);
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}
