import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ticket.dart';

class TicketsHistoryPage extends StatefulWidget {
  const TicketsHistoryPage({super.key});

  @override
  State<TicketsHistoryPage> createState() => _TicketsHistoryPageState();
}

class _TicketsHistoryPageState extends State<TicketsHistoryPage> {
  late Future<List<Map<String, dynamic>>> _ticketFuture;

  @override
  void initState() {
    super.initState();
    _ticketFuture = fetchLast10Tickets();
  }

  Future<List<Map<String, dynamic>>> fetchLast10Tickets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('tickets')
        .where('passengerId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();

    final seenTripKeys = <String>{};
    final allTickets = snapshot.docs;

    List<Map<String, dynamic>> uniqueTickets = [];

    for (final doc in allTickets) {
      final data = doc.data();
      final from = data['from'] ?? '';
      final to = data['to'] ?? '';
      final tripDate = (data['tripDate'] as Timestamp).toDate();
      final tripTime = data['tripTime'] ?? '';
      final uniqueKey = '$from-$to-${tripDate.toIso8601String()}-$tripTime';

      if (!seenTripKeys.contains(uniqueKey)) {
        data['id'] = doc.id;
        uniqueTickets.add(data);
        seenTripKeys.add(uniqueKey);
      }

      if (uniqueTickets.length >= 10) break;
    }

    // FIFO logic: Delete tickets beyond the 10 most recent (optional)
    if (uniqueTickets.length == 10 && allTickets.length > 10) {
      for (int i = 10; i < allTickets.length; i++) {
        await allTickets[i].reference.delete();
      }
    }

    return uniqueTickets;
  }

  Future<void> clearTicketHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('tickets')
        .where('passengerId', isEqualTo: uid)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Refresh UI
    setState(() {
      _ticketFuture = fetchLast10Tickets();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ticket history cleared.")),
    );
  }

  void confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Are you sure you want to clear your ticket history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await clearTicketHistory();
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ticket History'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ticketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading tickets."));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No tickets found."));
          }

          final tickets = snapshot.data!;

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final from = ticket['from'] ?? '';
              final to = ticket['to'] ?? '';
              final tripDate = (ticket['tripDate'] as Timestamp).toDate();
              final timeStr = ticket['tripTime'] ?? '00:00';
              final seats = ticket['seats'] ?? 1;
              final fare = (ticket['fare'] ?? 0).toDouble();
              final driverId = ticket['driverId'] ?? '';
              final seatNumber = ticket['seatNumber'];
              final id = ticket['id'] ?? '';

              final timeParts = timeStr.split(':');
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;

              List<int> selectedSeats = [];
              if (seatNumber is int) {
                selectedSeats = [seatNumber];
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text("Ticket ID: $id"),
                  subtitle: Text("Route: $from → $to"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketPage(
                          from: from,
                          to: to,
                          tripDate: tripDate,
                          tripTime: TimeOfDay(hour: hour, minute: minute),
                          selectedSeats: selectedSeats,
                          fare: fare,
                          driverId: driverId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: confirmClearHistory,
        backgroundColor: const Color.fromARGB(255, 111, 255, 82),
        child: const Icon(Icons.delete_forever),
        tooltip: 'Clear Ticket History',
      ),
    );
  }
}
