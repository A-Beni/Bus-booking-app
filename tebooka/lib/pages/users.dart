import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class UsersPage extends StatefulWidget {
  final String from;
  final String to;

  const UsersPage({super.key, required this.from, required this.to});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  LatLng? driverPosition;
  List<Map<String, dynamic>> nearbyPassengers = [];

  @override
  void initState() {
    super.initState();
    _loadDriverLocation();
  }

  Future<void> _loadDriverLocation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat != null && lng != null) {
        driverPosition = LatLng(lat, lng);
        _fetchNearbyPassengers();
      }
    }
  }

  Future<void> _fetchNearbyPassengers() async {
    if (driverPosition == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('passenger_locations')
        .where('from', isEqualTo: widget.from)
        .where('to', isEqualTo: widget.to)
        .get();

    List<Map<String, dynamic>> passengers = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lat = data['latitude'];
      final lng = data['longitude'];
      final seats = data['seats'] ?? 1;
      final to = data['to'];

      if (lat != null && lng != null) {
        final distance = _calculateDistance(driverPosition!.latitude, driverPosition!.longitude, lat, lng);

        // Only include passengers within 100 meters and not yet passed
        if (distance > 0 && distance <= 100) {
          passengers.add({
            'distance': distance,
            'latitude': lat,
            'longitude': lng,
            'to': to,
            'seats': seats,
          });
        }
      }
    }

    passengers.sort((a, b) => a['distance'].compareTo(b['distance']));

    setState(() {
      nearbyPassengers = passengers;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Passengers'),
        backgroundColor: Colors.teal,
      ),
      body: nearbyPassengers.isEmpty
          ? const Center(child: Text('No nearby passengers found.'))
          : ListView.builder(
              itemCount: nearbyPassengers.length,
              itemBuilder: (context, index) {
                final passenger = nearbyPassengers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.person_pin_circle, color: Colors.green),
                    title: Text('Destination: ${passenger['to']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seats: ${passenger['seats']}'),
                        Text('Distance: ${passenger['distance'].toStringAsFixed(1)} meters'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
