import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'users.dart';

class SeatSelectionPage extends StatefulWidget {
  final int seatCount;
  final List<int>? reservedSeats;
  final String? from;
  final String? to;
  final DateTime? tripDate;
  final TimeOfDay? tripTime;
  final double? fare;
  final String? driverId;
  final bool isDarkMode;
  final Function(bool)? onThemeChanged;

  const SeatSelectionPage({
    super.key,
    required this.seatCount,
    this.reservedSeats,
    this.from,
    this.to,
    this.tripDate,
    this.tripTime,
    this.fare,
    this.driverId,
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  List<int> reservedSeats = [];
  List<int> selectedSeats = [];
  bool isDriver = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRoleAndLoadSeats();
  }

  Future<void> _checkUserRoleAndLoadSeats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = userDoc.data()?['role'];
    setState(() {
      isDriver = role == 'driver';
    });

    if (isDriver) {
      final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
      final data = driverDoc.data();
      if (data != null && data['reservedSeats'] is List) {
        reservedSeats = List<int>.from((data['reservedSeats'] as List).map((e) => e as int));
      }
    } else {
      if (widget.reservedSeats != null) {
        reservedSeats = widget.reservedSeats!;
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> _confirmSeatSelection() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (isDriver) {
      final docRef = FirebaseFirestore.instance.collection('drivers').doc(uid);
      List<int> updatedReservedSeats = List<int>.from(reservedSeats);

      for (int seat in selectedSeats) {
        if (updatedReservedSeats.contains(seat)) {
          updatedReservedSeats.remove(seat);
        } else {
          updatedReservedSeats.add(seat);
        }
      }

      await docRef.set({
        'reservedSeats': updatedReservedSeats,
      }, SetOptions(merge: true));

      setState(() {
        reservedSeats = updatedReservedSeats;
        selectedSeats.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seats updated successfully.")),
      );

      if (widget.from != null && widget.to != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UsersPage(
              from: widget.from!,
              to: widget.to!,
              isDarkMode: widget.isDarkMode,
              onThemeChanged: widget.onThemeChanged ?? (_) {},
            ),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context, selectedSeats);
    }
  }

  Widget buildSeat(int seatNumber) {
    final isReserved = reservedSeats.contains(seatNumber);
    final isSelected = selectedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isDriver) {
            if (selectedSeats.contains(seatNumber)) {
              selectedSeats.remove(seatNumber);
            } else {
              selectedSeats.add(seatNumber);
            }
          } else {
            if (!isReserved) {
              if (isSelected) {
                selectedSeats.remove(seatNumber);
              } else {
                if (selectedSeats.length < widget.seatCount) {
                  selectedSeats.add(seatNumber);
                }
              }
            }
          }
        });
      },
      child: Column(
        children: [
          Icon(
            Icons.event_seat,
            color: isReserved
                ? (isDriver && selectedSeats.contains(seatNumber)
                    ? Colors.green
                    : Colors.grey)
                : (isSelected ? Colors.red : Colors.green),
            size: 20,
          ),
          Text('A$seatNumber', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<Row> frontSeats = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [for (int i = 1; i <= 4; i++) buildSeat(i)],
          ),
          const SizedBox(width: 20),
          Column(
            children: [for (int i = 5; i <= 8; i++) buildSeat(i)],
          ),
        ],
      ),
    ];

    List<Row> mainSeatRows = [];
    int seatNumber = 9;
    for (int row = 0; row < 13; row++) {
      mainSeatRows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildSeat(seatNumber++),
            buildSeat(seatNumber++),
            const SizedBox(width: 20),
            buildSeat(seatNumber++),
            buildSeat(seatNumber++),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isDriver ? 'Driver Seat Management' : 'Select Seats'),
        backgroundColor: isDriver ? Colors.teal : Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Icon(Icons.sports_motorsports, size: 30, color: Colors.black87),
              ),
            ),
            Text(
              isDriver ? "Tap seats to mark/unmark booked" : "Tap to select your seats",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            ...frontSeats,
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: mainSeatRows.length,
                itemBuilder: (_, index) => mainSeatRows[index],
                separatorBuilder: (_, __) => const SizedBox(height: 5),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: selectedSeats.isNotEmpty || isDriver ? _confirmSeatSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDriver ? Colors.teal : Colors.blue,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: Text(isDriver ? "Update Seats" : "Confirm Selection"),
            ),
          ],
        ),
      ),
    );
  }
}
