import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;

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
  bool _iconsReady = false;

  Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  Set<Marker> passengerMarkers = {};

  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _passengerIcon;
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _endIcon;

  int nearbyPassengerCount = 0;
  int totalPassengersOnRoute = 0;

  double totalRouteDistance = 0;
  double remainingDistance = 0;
  String eta = '...';
  String driverPlate = 'Driver';

  final String googleApiKey = "AIzaSyD4K4zUAbA8AxCRj3068Y3wRIJLWmxG6Rw";

  @override
  void initState() {
    super.initState();
    _initializeDriverMap();
  }

  Future<void> _initializeDriverMap() async {
    await _loadIcons();
    setState(() => _iconsReady = true);
    await _fetchDriverPlate();
    await _checkLiveStatus();
  }

  @override
  void dispose() {
    _setDriverOffline();
    super.dispose();
  }

  Future<void> _fetchDriverPlate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
    setState(() {
      driverPlate = doc.data()?['busPlate'] ?? 'Driver';
    });
  }

  Future<void> _checkLiveStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
      'isLive': true,
      'from': widget.from,
      'to': widget.to,
      'busPlate': driverPlate,
    });

    await _enableLocation();
    await _drawRouteAndDistance();
    await _getAllPassengerMarkers();
  }

  Future<void> _setDriverOffline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'isLive': false,
      });
    }
  }

  Future<void> _loadIcons() async {
    _busIcon = await _createIcon(Icons.directions_bus, Colors.blue);
    _passengerIcon = await _createIcon(Icons.person_pin_circle, Colors.green);
    _startIcon = await _createIcon(Icons.my_location, Colors.green);
    _endIcon = await _createIcon(Icons.flag, Colors.red);
  }

  Future<BitmapDescriptor> _createIcon(IconData icon, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(100, 100);
    const iconSize = 80.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontSize: iconSize, fontFamily: icon.fontFamily, color: color),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - iconSize) / 2, (size.height - iconSize) / 2));
    final img = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _enableLocation() async {
    if (!await location.serviceEnabled()) await location.requestService();
    if (await location.hasPermission() == loc.PermissionStatus.denied) {
      await location.requestPermission();
    }
    setState(() => _isLocationEnabled = true);
    _listenToLocationChanges();
  }

  void _listenToLocationChanges() {
    location.changeSettings(interval: 3000);
    location.onLocationChanged.listen((loc.LocationData locData) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      if (locData.latitude == null || locData.longitude == null) return;

      _currentPosition = LatLng(locData.latitude!, locData.longitude!);

      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'latitude': locData.latitude,
        'longitude': locData.longitude,
        'from': widget.from,
        'to': widget.to,
        'isLive': true,
        'busPlate': driverPlate,
      });

      _controller?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      await _getAllPassengerMarkers();
      await _checkNearbyPassengers();
      await _updateRemainingDistance();

      setState(() {});
    });
  }

  Future<void> _drawRouteAndDistance() async {
    final origin = await _getLatLngFromPlace(widget.from);
    final destination = await _getLatLngFromPlace(widget.to);
    if (origin == null || destination == null) return;

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKey&traffic_model=best_guess&departure_time=now');
    final response = await http.get(url);
    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    final route = data['routes'][0];
    final polylinePoints = route['overview_polyline']['points'];
    final leg = route['legs'][0];

    totalRouteDistance = leg['distance']['value'] / 1000;
    remainingDistance = totalRouteDistance;
    eta = leg['duration_in_traffic']?['text'] ?? leg['duration']['text'];

    final points = _decodePolyline(polylinePoints);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'polyline': polylinePoints,
      });
    }

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: points,
        ),
      };

      _markers.addAll({
        Marker(
          markerId: const MarkerId('start'),
          position: origin,
          icon: _startIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: destination,
          icon: _endIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      });
    });
  }

  Future<LatLng?> _getLatLngFromPlace(String place) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(place)}&key=$googleApiKey');
    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    final loc = data['results'][0]['geometry']['location'];
    return LatLng(loc['lat'].toDouble(), loc['lng'].toDouble());
  }

  Future<void> _updateRemainingDistance() async {
    final dest = await _getLatLngFromPlace(widget.to);
    if (dest == null) return;

    remainingDistance = _calculateDistance(
      _currentPosition.latitude,
      _currentPosition.longitude,
      dest.latitude,
      dest.longitude,
    ) / 1000;
  }

  Future<void> _getAllPassengerMarkers() async {
    if (_passengerIcon == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('passenger_locations')
        .where('to', isEqualTo: widget.to)
        .get();

    Set<Marker> tempMarkers = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        LatLng pos = LatLng(data['latitude'].toDouble(), data['longitude'].toDouble());
        tempMarkers.add(
          Marker(
            markerId: MarkerId('passenger_${doc.id}'),
            position: pos,
            icon: _passengerIcon!,
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

  Future<void> _checkNearbyPassengers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('passenger_locations')
        .where('to', isEqualTo: widget.to)
        .get();

    int count = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      double? lat = data['latitude']?.toDouble();
      double? lng = data['longitude']?.toDouble();

      if (lng != null) {
        double distance = _calculateDistance(
          _currentPosition.latitude,
          _currentPosition.longitude,
          lat!,
          lng,
        );
        if (distance <= 100) count++;
      }
    }

    setState(() {
      nearbyPassengerCount = count;
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
        title: const Text('Driver - You are Live'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _setDriverOffline();
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pop(context);
            },
          )
        ],
      ),
      body: (_isLocationEnabled && _iconsReady)
          ? Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 15),
                  markers: {
                    Marker(
                      markerId: const MarkerId('driver'),
                      position: _currentPosition,
                      icon: _busIcon ?? BitmapDescriptor.defaultMarker,
                      infoWindow: InfoWindow(title: driverPlate),
                    ),
                    ..._markers,
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
                          Text('Remaining: ${remainingDistance.toStringAsFixed(2)} km'),
                          Text('ETA: $eta'),
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
