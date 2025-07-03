import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_place/google_place.dart';
import 'package:uuid/uuid.dart';

import 'profile.dart';
import 'map.dart';
import 'booking_page.dart';
import 'login.dart';
import 'notifications_page.dart';

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

  @override
  void initState() {
    super.initState();
    loadUserData();
    tripDate = DateTime.now();
    tripTime = TimeOfDay.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showThankYouMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for booking your seats!')),
        );
      }
    });
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
                          } catch (e) {
                            print('Google Places API Error: $e');
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
                              shrinkWrap: true,
                              itemCount: predictions.length,
                              itemBuilder: (context, index) {
                                final prediction = predictions[index];
                                return ListTile(
                                  leading: const Icon(Icons.location_on, size: 20, color: Colors.grey),
                                  title: Text(
                                    prediction.description ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: prediction.structuredFormatting?.secondaryText != null
                                      ? Text(
                                          prediction.structuredFormatting!.secondaryText!,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        )
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
                        : Container(
                            height: 100,
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                searchController.text.isEmpty
                                    ? "Start typing to search locations in Rwanda"
                                    : "No suggestions found. Try different keywords.",
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
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
      bottomNavigationBar: SizedBox(
        height: 60,
        child: BottomNavigationBar(
          iconSize: 20,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Booking'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
            BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
          ],
          onTap: (index) async {
            switch (index) {
              case 0:
                if (fromController.text.isEmpty || toController.text.isEmpty || tripDate == null || tripTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please complete the trip details")),
                  );
                  return;
                }
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
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select destination first")),
                  );
                }
                break;
              case 2:
                Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsPage()));
                break;
              case 3:
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                );
                break;
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hey, $firstName", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfilePage(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("What is your next trip?", style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6))),
              const SizedBox(height: 14),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '📸 Kigali Image Slider Goes Here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              tripForm(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select destination first")),
                    );
                  }
                },
                icon: const Icon(Icons.map, size: 20),
                label: const Text("Track Your Bus", style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
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
        const Text("From", style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => openSearchModal(fromController),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fromController.text.isEmpty ? "Choose starting location" : fromController.text,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text("To", style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => openSearchModal(toController),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.grey, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    toController.text.isEmpty ? "Choose destination" : toController.text,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text("Choose your trip date", style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: tripDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => tripDate = picked);
            }
          },
          child: Text(
            tripDate == null
                ? "Pick a date"
                : "${tripDate!.day}/${tripDate!.month}/${tripDate!.year}",
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),
        const Text("Choose your trip time", style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: tripTime ?? TimeOfDay.now(),
            );
            if (picked != null) {
              setState(() => tripTime = picked);
            }
          },
          child: Text(
            tripTime == null
                ? "Pick time"
                : "${tripTime!.hour}:${tripTime!.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),
        const Text("How many seats you want?", style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            int seat = index + 1;
            return GestureDetector(
              onTap: () => setState(() => seatCount = seat),
              child: Container(
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: seatCount == seat ? Colors.red : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$seat seat',
                    style: const TextStyle(fontSize: 11, color: Colors.black)),
              ),
            );
          }),
        ),
      ],
    );
  }
}
