import 'package:flutter/material.dart';

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
