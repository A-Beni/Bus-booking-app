import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import 'map.dart';
import 'booking_page.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  final bool showThankYouMessage;

  const HomePage({super.key, this.showThankYouMessage = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String firstName = '';
  String fromCity = 'Kimironko Bus Stop';
  String toCity = 'Downtown Bus Stop';
  DateTime tripDate = DateTime.now();
  TimeOfDay tripTime = TimeOfDay.now();
  int seatCount = 1;

  @override
  void initState() {
    super.initState();
    loadUserData();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SizedBox(
        height: 60,
        child: BottomNavigationBar(
          iconSize: 20,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Booking'),
          ],
          onTap: (index) async {
            if (index == 0) {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingPage(
                    from: fromCity,
                    to: toCity,
                    tripDate: tripDate,
                    tripTime: tripTime,
                    seats: seatCount,
                    distanceKm: null,
                    etaMinutes: null,
                    driverId: null,
                  ),
                ),
              );
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hey, $firstName",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
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
              const Text(
                "What is your next trip?",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 14),

              // Image Slider Placeholder
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '📸 Kigali Image Slider Goes Here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // Booking Form
              tripForm(),
              const SizedBox(height: 16),

              // Track Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapPage(
                        passengerDestination: toCity,
                        seats: seatCount,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map, size: 20),
                label: const Text("Track Your Bus", style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('From', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  DropdownButton<String>(
                    value: fromCity,
                    iconSize: 18,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    underline: const SizedBox(),
                    items: [
                      'Kimironko Bus Stop',
                      'Downtown Bus Stop',
                      'Kicukiro Bus Stop'
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => fromCity = val!),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('To', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  DropdownButton<String>(
                    value: toCity,
                    iconSize: 18,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    underline: const SizedBox(),
                    items: [
                      'Kimironko Bus Stop',
                      'Downtown Bus Stop',
                      'Kicukiro Bus Stop'
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => toCity = val!),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text("Choose your trip date", style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: tripDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => tripDate = picked);
          },
          child: Text(
            "${tripDate.day}/${tripDate.month}/${tripDate.year}",
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),
        const Text("Choose your trip time", style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: tripTime,
            );
            if (picked != null) setState(() => tripTime = picked);
          },
          child: Text(
            "${tripTime.hour}:${tripTime.minute.toString().padLeft(2, '0')}",
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
