import 'package:flutter/material.dart';

class SeatSelectionPage extends StatefulWidget {
  final List<int> reservedSeats;
  final int seatCount;

  const SeatSelectionPage({
    super.key,
    required this.reservedSeats,
    required this.seatCount,
  });

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  List<int> selectedSeats = [];

  Widget buildSeat(int seatNumber) {
    bool isReserved = widget.reservedSeats.contains(seatNumber);
    bool isSelected = selectedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: isReserved
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  selectedSeats.remove(seatNumber);
                } else {
                  if (selectedSeats.length < widget.seatCount) {
                    selectedSeats.add(seatNumber);
                  }
                }
              });
            },
      child: Column(
        children: [
          Icon(
            Icons.event_seat,
            color: isReserved
                ? Colors.grey
                : isSelected
                    ? Colors.red
                    : Colors.green,
            size: 18,
          ),
          Text('A$seatNumber', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Row> frontSeats = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [for (int i = 1; i <= 4; i++) Padding(padding: const EdgeInsets.all(2), child: buildSeat(i))],
          ),
          const SizedBox(width: 20),
          Column(
            children: [for (int i = 5; i <= 8; i++) Padding(padding: const EdgeInsets.all(2), child: buildSeat(i))],
          ),
        ],
      ),
    ];

    List<Row> mainSeatRows = [];
    int seatNumber = 9;
    for (int row = 0; row < 11; row++) {
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
      appBar: AppBar(title: const Text('Select Seats'), backgroundColor: Colors.red),
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
            const Text("Tap to select your seats", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),

            ...frontSeats,
            const SizedBox(height: 10),
            const Divider(),

            Expanded(
              child: ListView.separated(
                itemCount: mainSeatRows.length,
                itemBuilder: (_, index) => mainSeatRows[index],
                separatorBuilder: (_, __) => const SizedBox(height: 4),
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: selectedSeats.length == widget.seatCount
                  ? () {
                      Navigator.pop(context, selectedSeats);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text("Confirm Selection"),
            ),
          ],
        ),
      ),
    );
  }
}
