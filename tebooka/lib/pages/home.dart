import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'profile.dart'; // You will create this file for profile updates

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? origin;
  String? destination;

  final List<String> busStops = [
    'Kimironko Bus Stop',
    'Downtown Bus Stop',
    'Kicukiro Bus Stop'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlue,
      appBar: AppBar(
        backgroundColor: kBlue,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'TEBOOKA',
            style: const TextStyle(
              color: kWhite,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: kWhite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Book Your Ride',
              style: TextStyle(
                color: kWhite,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Origin Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                hint: const Text('Select Origin'),
                value: origin,
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                underline: Container(),
                onChanged: (String? newValue) {
                  setState(() {
                    origin = newValue!;
                  });
                },
                items: busStops.map<DropdownMenuItem<String>>((String stop) {
                  return DropdownMenuItem<String>(
                    value: stop,
                    child: Text(stop),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Destination Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                hint: const Text('Select Destination'),
                value: destination,
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                underline: Container(),
                onChanged: (String? newValue) {
                  setState(() {
                    destination = newValue!;
                  });
                },
                items: busStops.map<DropdownMenuItem<String>>((String stop) {
                  return DropdownMenuItem<String>(
                    value: stop,
                    child: Text(stop),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
