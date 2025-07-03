import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barcode_widget/barcode_widget.dart';

import 'booking_page.dart';
import 'tickets_history.dart';

class TicketPage extends StatefulWidget {
  final String from;
  final String to;
  final DateTime tripDate;
  final TimeOfDay tripTime;
  final List<int> selectedSeats;
  final double fare;
  final String driverId;

  const TicketPage({
    super.key,
    required this.from,
    required this.to,
    required this.tripDate,
    required this.tripTime,
    required this.selectedSeats,
    required this.fare,
    required this.driverId,
  });

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  String passengerName = '';
  String driverName = '';
  String ticketId = '';

  @override
  void initState() {
    super.initState();
    _loadPassengerInfo();
    _loadDriverInfo();
    _generateTicketId();
  }

  Future<void> _loadPassengerInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        setState(() {
          passengerName = '$firstName $lastName'.trim();
        });
      }
    }
  }

  Future<void> _loadDriverInfo() async {
    final doc = await FirebaseFirestore.instance.collection('drivers').doc(widget.driverId).get();
    if (doc.exists) {
      setState(() {
        driverName = doc.data()?['name'] ?? 'Driver';
      });
    }
  }

  void _generateTicketId() {
    setState(() {
      ticketId = DateTime.now().millisecondsSinceEpoch.toString();
    });
  }

  Future<void> _deleteCurrentTicket() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final q = await FirebaseFirestore.instance
          .collection('tickets')
          .where('passengerId', isEqualTo: uid)
          .where('tripDate', isEqualTo: Timestamp.fromDate(widget.tripDate))
          .get();

      for (var doc in q.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Do you really want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCurrentTicket();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking canceled successfully')),
      );

      Navigator.pop(context);
    }
  }

  Future<void> _editBooking() async {
    await _deleteCurrentTicket();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(
          from: widget.from,
          to: widget.to,
          tripDate: widget.tripDate,
          tripTime: widget.tripTime,
          seats: widget.selectedSeats.length,
          distanceKm: null, // Optional: replace with actual value
          etaMinutes: null, // Optional: replace with actual value
          driverId: widget.driverId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripTimeStr = "${widget.tripTime.hour.toString().padLeft(2, '0')}:${widget.tripTime.minute.toString().padLeft(2, '0')}";
    final tripDateStr = "${widget.tripDate.day}/${widget.tripDate.month}/${widget.tripDate.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFE0ECF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('ID $ticketId', style: const TextStyle(color: Colors.blue)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _cancelBooking,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Booking'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                    ),
                    ElevatedButton.icon(
                      onPressed: _editBooking,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Booking'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Ticket content
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3E8DF5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Icon(Icons.directions_bus, color: Colors.white, size: 40),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From', style: TextStyle(color: Colors.grey[600])),
                            Text(widget.from, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(tripTimeStr),
                            Text(tripDateStr),
                          ],
                        ),
                      ),
                      const Icon(Icons.directions_bus, size: 30),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('To', style: TextStyle(color: Colors.grey[600])),
                            Text(widget.to, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(tripTimeStr),
                            Text(tripDateStr),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fullname'),
                          Text(passengerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Seat'),
                          Text(widget.selectedSeats.map((e) => 'A$e').join(', '), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Driver:'),
                      Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fare:'),
                      Text('RWF ${widget.fare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BarcodeWidget(
                  data: ticketId,
                  barcode: Barcode.code128(),
                  width: 200,
                  height: 80,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsHistoryPage()));
        },
        icon: const Icon(Icons.history),
        label: const Text('History'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
