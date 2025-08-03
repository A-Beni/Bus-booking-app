import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:google_place/google_place.dart';
import 'package:uuid/uuid.dart';

import 'driver_map.dart';
import 'driver_profile.dart';
import 'login.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> with SingleTickerProviderStateMixin {
  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  int _selectedIndex = 0;

  final String googleApiKey = "AIzaSyD4K4zUAbA8AxCRj3068Y3wRIJLWmxG6Rw";
  bool _darkMode = false;

  bool _isLive = false;

  String _currentAddress = "Fetching location...";
  Position? _currentPosition;

  late final AnimationController _animationController;
  late final ScrollController _scrollController;
  double _textWidth = 0;
  double _containerWidth = 0;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
    _listenToLiveStatus();

    // Initialize animation controller for marquee effect
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _scrollController = ScrollController();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reverse scroll
        _scrollController.jumpTo(0);
        _animationController.forward(from: 0);
      }
    });

    // Start location updates if live
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverInfo() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isLive'] == true) {
        fromController.text = data['from'] ?? '';
        toController.text = data['to'] ?? '';
        _isLive = true;
        _startLocationUpdates(); // start streaming if live
      } else {
        _isLive = false;
      }
    }
    setState(() {});
  }

  void _listenToLiveStatus() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('drivers')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isLive = data['isLive'] == true;
          fromController.text = data['from'] ?? fromController.text;
          toController.text = data['to'] ?? toController.text;
          if (_isLive) {
            _startLocationUpdates();
          }
        });
      }
    });
  }

  void _onThemeChanged(bool value) {
    setState(() {
      _darkMode = value;
    });
  }

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
    }, SetOptions(merge: true));

    _currentPosition = pos;
    _getAddressFromLatLng(pos);
  }

  // START LISTENING TO LOCATION CHANGES
  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      _currentPosition = position;
      _updateLocationInFirestore(position);
      _getAddressFromLatLng(position);
    });
  }

  Future<void> _updateLocationInFirestore(Position position) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
    }, SetOptions(merge: true));
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String newAddress = "${place.name}, ${place.locality}, ${place.country}";

        if (mounted && newAddress != _currentAddress) {
          setState(() {
            _currentAddress = newAddress;
          });

          // Restart marquee animation on address change
          _startMarquee();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Could not get address";
        });
      }
    }
  }

  // MARQUEE LOGIC: Animate horizontal scroll from right to left and loop
  void _startMarquee() {
    // Only start if container and text widths are measured
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _containerWidth > 0 && _textWidth > 0) {
        _scrollController.jumpTo(0);
        _animationController.repeat();
      }
    });
  }

  void _onNavTapped(int index) async {
    setState(() => _selectedIndex = index);

    switch (index) {
  case 0:
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverMapPage(
          from: fromController.text,
          to: toController.text,
        ),
      ),
    );
    break;
  case 1:
    _handleLogout();
    break;
}

  }

  Future<void> _handleLogout() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
    bool isLive = doc.exists && doc['isLive'] == true;

    if (isLive) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('You Are Still Live'),
          content: const Text(
              'You are still sharing your location. Do you want to continue sharing it after logout or stop sharing now?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      isDarkMode: _darkMode,
                      onThemeChanged: _onThemeChanged,
                    ),
                  ),
                );
              },
              child: const Text('Continue Sharing'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('drivers')
                    .doc(uid)
                    .update({'isLive': false});
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      isDarkMode: _darkMode,
                      onThemeChanged: _onThemeChanged,
                    ),
                  ),
                );
              },
              child: const Text('Stop Sharing & Logout'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            isDarkMode: _darkMode,
            onThemeChanged: _onThemeChanged,
          ),
        ),
      );
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
                                    setState(() {});
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
        color: _darkMode ? Colors.grey[900] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      child: Text(
        controller.text.isEmpty ? placeholder : controller.text,
        style: TextStyle(
          fontSize: 14,
          color: _darkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildLiveStatusCard() {
    return Card(
      color: _isLive ? Colors.green[600] : Colors.red[600],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isLive ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _isLive ? "You Are LIVE" : "You Are OFFLINE",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Marquee widget for scrolling text horizontally
  Widget _buildMarqueeText() {
    return LayoutBuilder(builder: (context, constraints) {
      _containerWidth = constraints.maxWidth;

      // Measure text width using a TextPainter
      final textPainter = TextPainter(
        text: TextSpan(
          text: _currentAddress,
          style: TextStyle(
            color: _darkMode ? Colors.white70 : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      _textWidth = textPainter.width;

      // If text width <= container width, no need to scroll
      if (_textWidth <= _containerWidth) {
        return Text(
          _currentAddress,
          style: TextStyle(
            color: _darkMode ? Colors.white70 : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        );
      }

      // Animate scrolling from right to left using ScrollController & AnimationController
      return SizedBox(
        height: 20,
        child: ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 30),
              child: Text(
                _currentAddress,
                style: TextStyle(
                  color: _darkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Duplicate text to create seamless scrolling effect
            Padding(
              padding: const EdgeInsets.only(right: 30),
              child: Text(
                _currentAddress,
                style: TextStyle(
                  color: _darkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _darkMode ? Colors.black : Colors.white;
    final textColor = _darkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: _darkMode ? Colors.grey[850] : Colors.teal,
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverProfilePage(
                    isDarkMode: _darkMode,
                    onThemeChanged: _onThemeChanged,
                  ),
                ),
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
              Center(child: _buildLiveStatusCard()),
              const SizedBox(height: 30),
              Text("Select From:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor)),
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
              Text("Select To:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor)),
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
              const SizedBox(height: 10),

              //  NEW DYNAMIC LOCATION NAME SUBTITLE
              if (_isLive)
                Container(
                  height: 20,
                  width: double.infinity,
                  color: Colors.transparent,
                  child: _buildMarqueeText(),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        selectedItemColor: Colors.green,
        backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
        selectedLabelStyle: TextStyle(color: textColor),
        unselectedItemColor: _darkMode ? Colors.grey[500] : Colors.grey[700],
        items: const [
          
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}
