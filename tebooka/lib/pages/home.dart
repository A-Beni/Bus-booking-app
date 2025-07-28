import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_place/google_place.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

import 'profile.dart';
import 'map.dart';
import 'booking_page.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final bool showThankYouMessage;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.showThankYouMessage = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String firstName = '';
  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  DateTime? tripDate;
  TimeOfDay? tripTime;
  int seatCount = 1;

  final String googleApiKey = "AIzaSyD4K4zUAbA8AxCRj3068Y3wRIJLWmxG6Rw";
  int _currentImageIndex = 0;
  late Timer _carouselTimer;

  final List<String> carouselImages = [
    'assets/bpr.jpg',
    'assets/liberation.jpg',
    'assets/pinnacle.jpg',
    'assets/town.jpg',
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
    tripDate = DateTime.now();
    tripTime = TimeOfDay.now();

    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % carouselImages.length;
      });
    });
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        firstName = doc.data()?['firstName'] ?? 'User';
      });
    }
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      fromController.text = "Current Location (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})";
    });
  }

  Future<void> openSearchModal(TextEditingController controller) async {
    final googlePlace = GooglePlace(googleApiKey);
    final sessionToken = const Uuid().v4();
    TextEditingController searchController = TextEditingController(text: controller.text);
    List<AutocompletePrediction> predictions = [];

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, localSetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (input) async {
                          if (input.isEmpty) {
                            localSetState(() => predictions = []);
                            return;
                          }

                          try {
                            await Future.delayed(const Duration(milliseconds: 300));
                            final result = await googlePlace.autocomplete.get(
                              input,
                              sessionToken: sessionToken,
                              components: [Component("country", "rw")],
                              location: LatLon(-1.9441, 30.0619),
                              radius: 20000,
                            );

                            if (result != null && result.predictions != null && result.predictions!.isNotEmpty) {
                              localSetState(() => predictions = result.predictions!);
                            } else {
                              localSetState(() => predictions = []);
                            }
                          } catch (_) {
                            localSetState(() => predictions = []);
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
                                  leading: const Icon(Icons.location_on, color: Colors.grey),
                                  title: Text(prediction.description ?? '', style: const TextStyle(fontSize: 14)),
                                  subtitle: prediction.structuredFormatting?.secondaryText != null
                                      ? Text(prediction.structuredFormatting!.secondaryText!, style: const TextStyle(fontSize: 12, color: Colors.grey))
                                      : null,
                                  onTap: () {
                                    controller.text = prediction.description ?? '';
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                          )
                        : const SizedBox(height: 100),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: NavigationBar(
        elevation: 1,
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: "Booking"),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: "Map"),
          NavigationDestination(icon: Icon(Icons.logout_rounded), label: "Logout"),
        ],
        onDestinationSelected: (index) async {
          switch (index) {
            case 0:
              if (fromController.text.isEmpty || toController.text.isEmpty || tripDate == null || tripTime == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingPage(
                    from: fromController.text.trim(),
                    to: toController.text.trim(),
                    tripDate: tripDate!,
                    tripTime: tripTime!,
                    seats: seatCount,
                  ),
                ),
              );
              break;
            case 1:
              if (toController.text.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapPage(
                    passengerDestination: toController.text.trim(),
                    seats: seatCount,
                  ),
                ),
              );
              break;
            case 2:
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginPage(
                    isDarkMode: widget.isDarkMode,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
              break;
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hey, $firstName",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                          ),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "What is your next trip?",
                style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  key: ValueKey<String>(carouselImages[_currentImageIndex]),
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      carouselImages[_currentImageIndex],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 5,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: tripForm(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (toController.text.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapPage(
                            passengerDestination: toController.text.trim(),
                            seats: seatCount,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.map_rounded, size: 20),
                  label: const Text("Track Your Bus on Map", style: TextStyle(fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tripForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelWithIcon("From", Icons.location_on, fromController, () => openSearchModal(fromController)),
        const SizedBox(height: 10),
        labelWithIcon("To", Icons.flag, toController, () => openSearchModal(toController)),
        const SizedBox(height: 10),
        tripDateTimePicker(
          "Choose your trip date",
          tripDate == null ? "Pick a date" : "${tripDate!.day}/${tripDate!.month}/${tripDate!.year}",
          () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: tripDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => tripDate = picked);
          },
        ),
        const SizedBox(height: 10),
        tripDateTimePicker(
          "Choose your trip time",
          tripTime == null ? "Pick time" : "${tripTime!.hour}:${tripTime!.minute.toString().padLeft(2, '0')}",
          () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: tripTime ?? TimeOfDay.now(),
            );
            if (picked != null) setState(() => tripTime = picked);
          },
        ),
        const SizedBox(height: 10),
        const Text("Seats", style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: List.generate(5, (index) {
            int seat = index + 1;
            return ChoiceChip(
              label: Text('$seat seat'),
              selected: seatCount == seat,
              onSelected: (_) => setState(() => seatCount = seat),
              selectedColor: Colors.red.shade400,
            );
          }),
        ),
      ],
    );
  }

  Widget labelWithIcon(String label, IconData icon, TextEditingController controller, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade400,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Text(
                    controller.text.isEmpty ? "Tap to select" : controller.text,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              if (label == "From")
                IconButton(
                  icon: const Icon(Icons.my_location, size: 18, color: Colors.blue),
                  onPressed: getCurrentLocation,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget tripDateTimePicker(String label, String display, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(display, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
