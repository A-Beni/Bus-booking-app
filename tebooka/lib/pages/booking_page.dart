import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ticket.dart';
import 'home.dart';
import 'seat_selection.dart';

class BookingPage extends StatefulWidget {
  final String from, to;
  final DateTime tripDate;
  final TimeOfDay tripTime;
  final int seats;
  final double? distanceKm;
  final int? etaMinutes;
  final String? driverId;

  const BookingPage({
    super.key,
    required this.from,
    required this.to,
    required this.tripDate,
    required this.tripTime,
    required this.seats,
    this.distanceKm,
    this.etaMinutes,
    this.driverId,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  List<int> selectedSeats = [];
  String? driverName, driverPhone;

  @override
  void initState() {
    super.initState();
    if (widget.driverId != null) _loadDriverDetails(widget.driverId!);
  }

  Future<void> _loadDriverDetails(String id) async {
    final doc = await FirebaseFirestore.instance.collection('drivers').doc(id).get();
    if (doc.exists) {
      setState(() {
        driverName = doc['name'];
        driverPhone = doc['phone'];
      });
    }
  }

  bool canModifyBooking() {
    final dt = DateTime(
      widget.tripDate.year,
      widget.tripDate.month,
      widget.tripDate.day,
      widget.tripTime.hour,
      widget.tripTime.minute,
    );
    return DateTime.now().isBefore(dt.subtract(const Duration(minutes: 10)));
  }

  Future<void> _cancelBooking() async {
    if (!canModifyBooking()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Cannot cancel booking less than 10 mins to departure'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Really cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final q = await FirebaseFirestore.instance
          .collection('tickets')
          .where('passengerId', isEqualTo: uid)
          .where('tripDate', isEqualTo: Timestamp.fromDate(widget.tripDate))
          .get();

      for (var d in q.docs) {
        await d.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking canceled')),
      );

      Navigator.pop(context);
    }
  }

  Future<void> _goToSeatSelection() async {
    List<int> reserved = [];

    final booked = await FirebaseFirestore.instance
        .collection('tickets')
        .where('from', isEqualTo: widget.from)
        .where('to', isEqualTo: widget.to)
        .where('tripDate', isEqualTo: Timestamp.fromDate(widget.tripDate))
        .get();

    for (var doc in booked.docs) {
      reserved.add(doc['seatNumber']);
    }

    final result = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionPage(
          seatCount: widget.seats,
          reservedSeats: reserved,
        ),
      ),
    );

    if (result != null && result.length == widget.seats) {
      setState(() {
        selectedSeats = result;
      });
    }
  }

  Future<void> notifyDriver(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    double fare = (widget.distanceKm ?? 0) * 100;

    if (uid != null && selectedSeats.isNotEmpty) {
      for (var seat in selectedSeats) {
        final ticket = <String, dynamic>{
          'passengerId': uid,
          'from': widget.from,
          'to': widget.to,
          'seats': widget.seats,
          'tripDate': Timestamp.fromDate(widget.tripDate),
          'tripTime': TimeOfDay(
            hour: widget.tripTime.hour,
            minute: widget.tripTime.minute,
          ).format(context),
          'seatNumber': seat,
          'timestamp': Timestamp.now(),
          'fare': fare,
        };

        if (widget.driverId != null) ticket['driverId'] = widget.driverId!;
        if (widget.distanceKm != null) ticket['distanceKm'] = widget.distanceKm!;
        if (widget.etaMinutes != null) ticket['etaMinutes'] = widget.etaMinutes!;

        await FirebaseFirestore.instance.collection('tickets').add(ticket);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Booking confirmed! Driver has been notified.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TicketPage(
            from: widget.from,
            to: widget.to,
            tripDate: widget.tripDate,
            tripTime: widget.tripTime,
            selectedSeats: selectedSeats,
            fare: fare,
            driverId: widget.driverId ?? '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select all seats before confirming.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Ticket'), backgroundColor: Colors.red),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("🚌 Booking Summary", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _infoRow("From", widget.from),
                  _infoRow("To", widget.to),
                  _infoRow("Date", "${widget.tripDate.day}/${widget.tripDate.month}/${widget.tripDate.year}"),
                  _infoRow("Time", "${widget.tripTime.hour}:${widget.tripTime.minute.toString().padLeft(2, '0')}"),
                  _infoRow("Seats", "${widget.seats}"),
                  if (widget.distanceKm != null)
                    _infoRow("Distance", "${widget.distanceKm!.toStringAsFixed(2)} km"),
                  if (widget.etaMinutes != null)
                    _infoRow("ETA", "${widget.etaMinutes} min"),
                  if (driverName != null)
                    _infoRow("Driver", "$driverName (${driverPhone ?? 'N/A'})"),
                  if (selectedSeats.isNotEmpty)
                    _infoRow("Your Seats", selectedSeats.map((e) => 'A$e').join(', ')),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _goToSeatSelection,
                    child: const Text('Select Seat(s)'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: selectedSeats.length == widget.seats ? () => notifyDriver(context) : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    child: const Text('Notify Driver & Confirm'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: canModifyBooking() ? _cancelBooking : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                    child: const Text('Cancel Booking'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: canModifyBooking()
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Editing coming soon!')),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Edit Booking'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
