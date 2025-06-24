import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import 'map.dart';
import 'booking_page.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  final bool showThankYouMessage; // Added for Snackbar from BookingPage

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

    // Show SnackBar if redirected from BookingPage after Notify Driver
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
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        firstName = doc.data()?['firstName'] ?? 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'View Booking'),
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
                ),
              ),
            );
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Hey, $firstName",
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text("What is your next trip?",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (toCity.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a destination')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapPage(
                      passengerDestination: toCity,
                      seats: seatCount, // Pass the seat count properly here
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("FIND YOUR BUS"),
            ),
            const SizedBox(height: 20),
            tripForm(),
          ],
        ),
      ),
    );
  }

  Widget tripForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('From', style: TextStyle(color: Colors.grey[600])),
                  DropdownButton<String>(
                    value: fromCity,
                    items: [
                      'Kimironko Bus Stop',
                      'Downtown Bus Stop',
                      'Kicukiro Bus Stop'
                    ]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => fromCity = val!);
                    },
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('To', style: TextStyle(color: Colors.grey[600])),
                  DropdownButton<String>(
                    value: toCity,
                    items: [
                      'Kimironko Bus Stop',
                      'Downtown Bus Stop',
                      'Kicukiro Bus Stop'
                    ]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => toCity = val!);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text("Choose your trip date"),
        ElevatedButton(
          onPressed: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: tripDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                tripDate = picked;
              });
            }
          },
          child: Text("${tripDate.day}/${tripDate.month}/${tripDate.year}"),
        ),
        const SizedBox(height: 20),
        const Text("Choose your trip time"),
        ElevatedButton(
          onPressed: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: tripTime,
            );
            if (picked != null) {
              setState(() {
                tripTime = picked;
              });
            }
          },
          child: Text("${tripTime.hour}:${tripTime.minute.toString().padLeft(2, '0')}"),
        ),
        const SizedBox(height: 20),
        const Text("How many seats you want?"),
        Row(
          children: List.generate(5, (index) {
            int seat = index + 1;
            return GestureDetector(
              onTap: () => setState(() => seatCount = seat),
              child: Container(
                margin: const EdgeInsets.all(5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: seatCount == seat ? Colors.red : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$seat seat', style: const TextStyle(fontSize: 12)),
              ),
            );
          }),
        ),
      ],
    );
  }
}
