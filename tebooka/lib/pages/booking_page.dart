
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_place/google_place.dart';
import 'package:uuid/uuid.dart';

import 'ticket.dart';
import 'seat_selection.dart';

class BookingPage extends StatefulWidget {
  final String from;
  final String to;
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
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fromController;
  late TextEditingController _toController;
  late DateTime _tripDate;
  late TimeOfDay _tripTime;
  int _seats = 1;
  List<int> selectedSeats = [];
  String? driverName, driverPhone;

  final String googleApiKey = "AIzaSyD4K4zUAbA8AxCRj3068Y3wRIJLWmxG6Rw";

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.from);
    _toController = TextEditingController(text: widget.to);
    _tripDate = widget.tripDate;
    _tripTime = widget.tripTime;
    _seats = widget.seats;
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tripDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _tripDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _tripTime,
    );
    if (picked != null) {
      setState(() {
        _tripTime = picked;
      });
    }
  }

  Future<void> _goToSeatSelection() async {
    List<int> reserved = [];

    final booked = await FirebaseFirestore.instance
        .collection('tickets')
        .where('from', isEqualTo: _fromController.text.trim())
        .where('to', isEqualTo: _toController.text.trim())
        .where('tripDate', isEqualTo: Timestamp.fromDate(_tripDate))
        .get();

    for (var doc in booked.docs) {
      reserved.add(doc['seatNumber']);
    }

    final result = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionPage(
          seatCount: _seats,
          reservedSeats: reserved,
        ),
      ),
    );

    if (result != null && result.length == _seats) {
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
          'from': _fromController.text.trim(),
          'to': _toController.text.trim(),
          'seats': _seats,
          'tripDate': Timestamp.fromDate(_tripDate),
          'tripTime': _tripTime.format(context),
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
            from: _fromController.text.trim(),
            to: _toController.text.trim(),
            tripDate: _tripDate,
            tripTime: _tripTime,
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

  Future<void> _selectPlace(TextEditingController controller) async {
    final googlePlace = GooglePlace(googleApiKey);
    final sessionToken = const Uuid().v4();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController search = TextEditingController();
        List<AutocompletePrediction> predictions = [];

        return StatefulBuilder(builder: (context, setState) {
          Future<void> onChanged(String val) async {
            if (val.isNotEmpty) {
              final res = await googlePlace.autocomplete.get(val, sessionToken: sessionToken);
              if (res != null && res.predictions != null) {
                setState(() {
                  predictions = res.predictions!;
                });
              }
            }
          }

          return AlertDialog(
            title: const Text("Search location"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  controller: search,
                  onChanged: onChanged,
                  decoration: const InputDecoration(hintText: "Enter place"),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: predictions.length,
                    itemBuilder: (context, index) {
                      final p = predictions[index];
                      return ListTile(
                        title: Text(p.description ?? ''),
                        onTap: () {
                          Navigator.pop(context, p.description);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );

    if (result != null) {
      setState(() {
        controller.text = result;
      });
    }
  }

  Widget _infoRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Align(alignment: Alignment.centerRight, child: child)),
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
          child: Form(
            key: _formKey,
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

                    _infoRow(
                      "From",
                      TextButton(
                        onPressed: () => _selectPlace(_fromController),
                        child: Text(_fromController.text.isEmpty ? "Select From" : _fromController.text),
                      ),
                    ),
                    _infoRow(
                      "To",
                      TextButton(
                        onPressed: () => _selectPlace(_toController),
                        child: Text(_toController.text.isEmpty ? "Select To" : _toController.text),
                      ),
                    ),

                    _infoRow(
                      "Date",
                      TextButton(
                        onPressed: _pickDate,
                        child: Text("${_tripDate.day}/${_tripDate.month}/${_tripDate.year}"),
                      ),
                    ),
                    _infoRow(
                      "Time",
                      TextButton(
                        onPressed: _pickTime,
                        child: Text("${_tripTime.hour}:${_tripTime.minute.toString().padLeft(2, '0')}"),
                      ),
                    ),
                    _infoRow(
                      "Seats",
                      DropdownButton<int>(
                        value: _seats,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _seats = value;
                              selectedSeats.clear();
                            });
                          }
                        },
                        items: List.generate(10, (i) => i + 1)
                            .map((e) => DropdownMenuItem(value: e, child: Text("$e")))
                            .toList(),
                      ),
                    ),

                    if (widget.distanceKm != null)
                      _infoRow("Distance", Text("${widget.distanceKm!.toStringAsFixed(2)} km")),
                    if (widget.etaMinutes != null)
                      _infoRow("ETA", Text("${widget.etaMinutes} min")),
                    if (driverName != null)
                      _infoRow("Driver", Text("$driverName (${driverPhone ?? 'N/A'})")),
                    if (selectedSeats.isNotEmpty)
                      _infoRow("Your Seats", Text(selectedSeats.map((e) => 'A$e').join(', '))),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _goToSeatSelection,
                      child: const Text('Select Seat(s)'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: selectedSeats.length == _seats ? () => notifyDriver(context) : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text('Notify Driver & Confirm'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
