import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barcode_widget/barcode_widget.dart';

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
      setState(() {
        passengerName = doc.data()?['firstName'] ?? 'Passenger';
      });
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

  @override
  Widget build(BuildContext context) {
    final tripTimeStr =
        "${widget.tripTime.hour.toString().padLeft(2, '0')}:${widget.tripTime.minute.toString().padLeft(2, '0')}";
    final tripDateStr =
        "${widget.tripDate.day}/${widget.tripDate.month}/${widget.tripDate.year}";

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From', style: TextStyle(color: Colors.grey[600])),
                        Text(widget.from, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(tripTimeStr),
                        Text(tripDateStr),
                      ],
                    ),
                    const Icon(Icons.directions_bus, size: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('To', style: TextStyle(color: Colors.grey[600])),
                        Text(widget.to, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(tripTimeStr),
                        Text(tripDateStr),
                      ],
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
    );
  }
}
