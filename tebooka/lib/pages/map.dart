import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'booking_page.dart';

class MapPage extends StatefulWidget {
  final String passengerDestination;

  const MapPage({super.key, required this.passengerDestination});

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Location permission is required to find nearby buses.')),
      );
    }
  }

  void _getNearbyDrivers() async {
    FirebaseFirestore.instance
        .collection('drivers')
        .snapshots()
        .listen((snapshot) async {
      Set<Marker> tempMarkers = {};
      Position userPos = await Geolocator.getCurrentPosition();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isLive'] == true && data['to'] == widget.passengerDestination) {
          final LatLng driverPos =
              LatLng(data['latitude'], data['longitude']);
          double distanceMeters = Geolocator.distanceBetween(
            userPos.latitude,
            userPos.longitude,
            driverPos.latitude,
            driverPos.longitude,
          );

          setState(() {
            distanceInKm = distanceMeters / 1000;
            estimatedTimeInMin = (distanceInKm / 0.5 * 60).toInt();
          });

          tempMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: driverPos,
              infoWindow: InfoWindow(
                title: data['name'],
                snippet: 'From ${data['from']} to ${data['to']}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          );
        }
      }

      setState(() {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(
                      from: "Unknown", // since 'from' is not passed here
                      to: widget.passengerDestination,
                      tripDate: DateTime.now(), // you can pass real date if available
                      tripTime: TimeOfDay.now(), // you can pass real time if available
                      seats: 1, // default seat as 1
                      distanceKm: distanceInKm,
                      etaMinutes: estimatedTimeInMin,
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
                  markers: busMarkers,
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
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
