import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_page.dart';

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

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  LatLng? _selectedPickup;

  double distanceInKm = 0.0;
  int estimatedTimeInMin = 0;
  String nearestDriverFrom = "Unknown";
  String nearestDriverId = "";

  bool _locationPermissionGranted = false;

  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _pickupIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons().then((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _loadIcons() async {
    _busIcon = await _createIcon(Icons.directions_bus, Colors.blue, size: 100, iconSize: 80);
    _pickupIcon = await _createIcon(Icons.location_pin, Colors.green, size: 100, iconSize: 80);
  }

  Future<BitmapDescriptor> _createIcon(IconData icon, Color color,
      {double size = 100, double iconSize = 80}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    painter.layout();
    painter.paint(canvas, Offset((size - iconSize) / 2, (size - iconSize) / 2));
    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() => _locationPermissionGranted = true);
      _setPassengerLocation();
      _listenToNearbyDrivers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required.')),
      );
    }
  }

  Future<void> _setPassengerLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('passengers').doc(user.uid).set({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'destination': widget.passengerDestination,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _selectedPickup = LatLng(pos.latitude, pos.longitude);
      });
    }
  }

  void _updateManualPickup(LatLng position) async {
    final user = FirebaseAuth.instance.currentUser;
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

  void _listenToNearbyDrivers() {
    FirebaseFirestore.instance
        .collection('drivers')
        .where('isLive', isEqualTo: true)
        .where('to', isEqualTo: widget.passengerDestination)
        .snapshots()
        .listen((snapshot) async {
      Set<Marker> tempMarkers = {};
      Set<Polyline> tempPolylines = {};

      final userPos = await Geolocator.getCurrentPosition();
      double minDistance = double.infinity;
      String closestDriverId = '';
      String closestFrom = 'Unknown';

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final driverId = doc.id;

        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          final LatLng driverPos = LatLng(data['latitude'], data['longitude']);

          final distance = Geolocator.distanceBetween(
            userPos.latitude,
            userPos.longitude,
            driverPos.latitude,
            driverPos.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            closestFrom = data['from'] ?? "Unknown";
            closestDriverId = driverId;
          }

          tempMarkers.add(
            Marker(
              markerId: MarkerId('driver_$driverId'),
              position: driverPos,
              icon: _busIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(
                title: data['busPlate'] ?? 'Bus',
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
                        distanceKm: distance / 1000,
                        etaMinutes: (distance / 500 * 60).toInt(),
                        driverId: driverId,
                      ),
                    ),
                  );
                },
              ),
            ),
          );

          if (data['polyline'] != null) {
            List<LatLng> routePoints = _decodePolyline(data['polyline']);
            tempPolylines.add(
              Polyline(
                polylineId: PolylineId('route_$driverId'),
                color: Colors.blue,
                width: 4,
                points: routePoints,
              ),
            );
          }
        }
      }

      // Add pickup marker only once after loading icons
      if (_selectedPickup != null && _pickupIcon != null) {
        tempMarkers.add(
          Marker(
            markerId: const MarkerId('passenger_pickup'),
            position: _selectedPickup!,
            icon: _pickupIcon!,
            infoWindow: const InfoWindow(title: 'Your Pickup'),
          ),
        );
      }

      setState(() {
        distanceInKm = minDistance / 1000;
        estimatedTimeInMin = (distanceInKm / 0.5 * 60).toInt();
        nearestDriverFrom = closestFrom;
        nearestDriverId = closestDriverId;
        markers = tempMarkers;
        polylines = tempPolylines;
      });
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Buses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_num),
            tooltip: 'Book Now',
            onPressed: () {
              if (nearestDriverId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❗ No available drivers found")),
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
                    driverId: nearestDriverId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _locationPermissionGranted && _busIcon != null && _pickupIcon != null
          ? Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _kigaliCenter, zoom: 12),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) => mapController = controller,
                  onTap: _updateManualPickup,
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
                Text('Driver Distance: ${distanceInKm.toStringAsFixed(2)} km', style: const TextStyle(fontSize: 16)),
                Text('ETA: $estimatedTimeInMin min', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
