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

  final Map<String, LatLng> busStops = {
    'Kimironko Bus Stop': const LatLng(-1.935, 30.091),
    'Downtown Bus Stop': const LatLng(-1.949, 30.058),
    'Kicukiro Bus Stop': const LatLng(-1.967, 30.09),
  };

  @override
  void initState() {
    super.initState();
    _loadBusIcon();
    _enableLocation();
    _setupRoute();
  }

  Future<void> _loadBusIcon() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Size size = Size(100, 100);
    final IconData iconData = Icons.directions_bus;
    const double iconSize = 80.0;

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.blue,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - iconSize) / 2, (size.height - iconSize) / 2));

    final ui.Image img = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List iconBytes = data!.buffer.asUint8List();

    setState(() {
      _busIcon = BitmapDescriptor.fromBytes(iconBytes);
    });
  }

  Future<void> _enableLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    var permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
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

      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'latitude': locData.latitude,
        'longitude': locData.longitude,
        'from': widget.from,
        'to': widget.to,
        'isLive': true,
        'name': 'Driver',
      });

      setState(() {
        _currentPosition = LatLng(locData.latitude!, locData.longitude!);
      });

      _controller?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver - You are Live')),
      body: _isLocationEnabled
          ? GoogleMap(
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
              },
              polylines: _polylines,
              onMapCreated: (controller) {
                _controller = controller;
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
