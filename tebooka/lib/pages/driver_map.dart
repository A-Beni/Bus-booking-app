import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;

class DriverMapPage extends StatefulWidget {
  final String from;
  final String to;

  const DriverMapPage({super.key, required this.from, required this.to});

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  final loc.Location location = loc.Location();
  GoogleMapController? _controller;
  LatLng _currentPosition = const LatLng(-1.9706, 30.1044);
  bool _isLocationEnabled = false;
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _passengerIcon;
  int nearbyPassengerCount = 0;
  Set<Marker> passengerMarkers = {};
  int totalPassengersOnRoute = 0;

  final Map<String, LatLng> busStops = {
    'Kimironko Bus Stop': const LatLng(-1.935, 30.091),
    'Downtown Bus Stop': const LatLng(-1.949, 30.058),
    'Kicukiro Bus Stop': const LatLng(-1.967, 30.09),
  };

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _enableLocation();
    _setupRoute();
    _getAllPassengerMarkers(); // load once at start
  }

  Future<void> _loadIcons() async {
    _busIcon = await _createIcon(Icons.directions_bus, Colors.blue);
    _passengerIcon = await _createIcon(Icons.person_pin_circle, Colors.green);
  }

  Future<BitmapDescriptor> _createIcon(IconData icon, Color color) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Size size = Size(100, 100);
    const double iconSize = 80.0;

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - iconSize) / 2, (size.height - iconSize) / 2));

    final ui.Image img = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _enableLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    var permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    setState(() => _isLocationEnabled = true);
    _listenToLocationChanges();
  }

  void _setupRoute() {
    final fromPos = busStops[widget.from];
    final toPos = busStops[widget.to];

    if (fromPos != null && toPos != null) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: [fromPos, toPos],
          )
        };
      });
    }
  }

  void _listenToLocationChanges() {
    location.changeSettings(interval: 3000);
    location.onLocationChanged.listen((loc.LocationData locData) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      _currentPosition = LatLng(locData.latitude!, locData.longitude!);

      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'latitude': locData.latitude,
        'longitude': locData.longitude,
        'from': widget.from,
        'to': widget.to,
        'isLive': true,
        'name': 'Driver',
      });

      _controller?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      _checkNearbyPassengers();
      _getAllPassengerMarkers();
    });
  }

  void _checkNearbyPassengers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('passenger_locations')
        .where('to', isEqualTo: widget.to)
        .get();

    int count = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      double? lat = data['latitude'];
      double? lng = data['longitude'];
      if (lat != null && lng != null) {
        double distance = _calculateDistance(
            _currentPosition.latitude, _currentPosition.longitude, lat, lng);
        if (distance <= 100) {
          count++;
        }
      }
    }

    setState(() {
      nearbyPassengerCount = count;
    });
  }

  Future<void> _getAllPassengerMarkers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('passenger_locations')
        .where('to', isEqualTo: widget.to)
        .get();

    Set<Marker> tempMarkers = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        LatLng passengerPos = LatLng(data['latitude'], data['longitude']);
        tempMarkers.add(
          Marker(
            markerId: MarkerId('passenger_${doc.id}'),
            position: passengerPos,
            icon: _passengerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Pickup'),
          ),
        );
      }
    }

    setState(() {
      passengerMarkers = tempMarkers;
      totalPassengersOnRoute = snapshot.docs.length;
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
      appBar: AppBar(title: const Text('Driver - You are Live')),
      body: _isLocationEnabled
          ? Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('driver'),
                      position: _currentPosition,
                      icon: _busIcon ?? BitmapDescriptor.defaultMarker,
                      infoWindow: const InfoWindow(title: 'Bus Location'),
                    ),
                    ...passengerMarkers,
                  },
                  polylines: _polylines,
                  onMapCreated: (controller) => _controller = controller,
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text('Nearby (≤100m): $nearbyPassengerCount'),
                          Text('On Route: $totalPassengersOnRoute'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
