import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart'; // Adjust this path if needed.

class BookingPage extends StatelessWidget {
  final String from;
  final String to;
  final DateTime tripDate;
  final TimeOfDay tripTime;
  final int seats;
  final double? distanceKm;
  final int? etaMinutes;

  const BookingPage({
    super.key,
    required this.from,
    required this.to,
    required this.tripDate,
    required this.tripTime,
    required this.seats,
    this.distanceKm,
    this.etaMinutes,
  });

  Future<void> notifyDriver(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('passenger_notifications').doc(uid).set({
        'from': from,
        'to': to,
        'seats': seats,
        'notifiedAt': DateTime.now(),
        'notified': true,
      });

      // Show confirmation dialog
      showDialog(
        context: context,
        barrierDismissible: false, // user must press OK
        builder: (ctx) => AlertDialog(
          title: const Text('Notification Sent'),
          content: const Text('Thank you for booking your seats. Your bus will be here soon.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // close the dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const HomePage(showThankYouMessage: true),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Booking'),
        backgroundColor: Colors.red,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bus Ticket",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text("From: $from", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("To: $to", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("Date: ${tripDate.day}/${tripDate.month}/${tripDate.year}",
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("Time: ${tripTime.hour}:${tripTime.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("Seats: $seats", style: const TextStyle(fontSize: 18)),
                if (distanceKm != null) ...[
                  const SizedBox(height: 10),
                  Text("Distance: ${distanceKm!.toStringAsFixed(2)} km",
                      style: const TextStyle(fontSize: 18)),
                ],
                if (etaMinutes != null) ...[
                  const SizedBox(height: 10),
                  Text("ETA: $etaMinutes minutes",
                      style: const TextStyle(fontSize: 18)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => notifyDriver(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Notify Driver'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
