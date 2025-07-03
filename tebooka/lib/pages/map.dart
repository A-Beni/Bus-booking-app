import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'booking_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapPage extends StatefulWidget {
  final String passengerDestination;
  final int seats;

  const MapPage({
    super.key,
    required this.passengerDestination,
    required this.seats,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final LatLng _kigaliCenter = const LatLng(-1.9706, 30.1044);
  Set<Marker> busMarkers = {};
  double distanceInKm = 0.0;
  int estimatedTimeInMin = 0;
  bool _locationPermissionGranted = false;

  LatLng? _selectedPickup;
  String nearestDriverFrom = "Unknown";
  String nearestDriverId = ''; // ✅ NEW: to store the correct driverId

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() => _locationPermissionGranted = true);
      _getNearbyDrivers();
      _setPassengerLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required to find nearby buses.'),
        ),
      );
    }
  }

  Future<void> _setPassengerLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('passengers').doc(user.uid).set({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'destination': widget.passengerDestination,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _updateManualPickup(LatLng position) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('passengers').doc(user.uid).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    }
    setState(() {
      _selectedPickup = position;
    });
  }

  void _getNearbyDrivers() async {
    FirebaseFirestore.instance
        .collection('drivers')
        .snapshots()
        .listen((snapshot) async {
      Set<Marker> tempMarkers = {};
      Position userPos = await Geolocator.getCurrentPosition();
      double minDistance = double.infinity;
      String closestDriverId = '';
      String closestFrom = 'Unknown';

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isLive'] == true && data['to'] == widget.passengerDestination) {
          final LatLng driverPos = LatLng(data['latitude'], data['longitude']);
          double distanceMeters = Geolocator.distanceBetween(
            userPos.latitude,
            userPos.longitude,
            driverPos.latitude,
            driverPos.longitude,
          );

          if (distanceMeters < minDistance) {
            minDistance = distanceMeters;
            closestFrom = data['from'] ?? "Unknown";
            closestDriverId = doc.id;
          }

          tempMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: driverPos,
              infoWindow: InfoWindow(
                title: data['name'],
                snippet: 'From ${data['from']} to ${data['to']}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        from: data['from'],
                        to: data['to'],
                        tripDate: DateTime.now(),
                        tripTime: TimeOfDay.now(),
                        seats: widget.seats,
                        distanceKm: distanceMeters / 1000,
                        etaMinutes: (distanceMeters / 500 * 60).toInt(),
                        driverId: doc.id,
                      ),
                    ),
                  );
                },
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          );
        }
      }

      setState(() {
        distanceInKm = minDistance / 1000;
        estimatedTimeInMin = (distanceInKm / 0.5 * 60).toInt();
        nearestDriverFrom = closestFrom;
        nearestDriverId = closestDriverId; // ✅ Save it for icon tap
        busMarkers = tempMarkers;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Buses'),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IconButton(
              key: const ValueKey('book_now_button'),
              icon: const Icon(Icons.confirmation_num),
              tooltip: 'Book Now',
              onPressed: () {
                if (nearestDriverId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❗ No available drivers found"),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(
                      from: nearestDriverFrom,
                      to: widget.passengerDestination,
                      tripDate: DateTime.now(),
                      tripTime: TimeOfDay.now(),
                      seats: widget.seats,
                      distanceKm: distanceInKm,
                      etaMinutes: estimatedTimeInMin,
                      driverId: nearestDriverId, // ✅ Correct driver ID now
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _locationPermissionGranted
          ? Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _kigaliCenter,
                    zoom: 12,
                  ),
                  markers: {
                    ...busMarkers,
                    if (_selectedPickup != null)
                      Marker(
                        markerId: const MarkerId('pickup'),
                        position: _selectedPickup!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen),
                        infoWindow: const InfoWindow(title: 'Your Pickup'),
                      )
                  },
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  onTap: (LatLng pos) {
                    _updateManualPickup(pos);
                  },
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _driverInfoWidget(),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _driverInfoWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.directions_bus, color: Colors.blue, size: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Driver Distance: ${distanceInKm.toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 16)),
                Text('ETA: $estimatedTimeInMin min',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
