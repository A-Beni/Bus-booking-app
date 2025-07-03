import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ticket.dart';

class TicketsHistoryPage extends StatelessWidget {
  const TicketsHistoryPage({super.key});

  Future<List<Map<String, dynamic>>> fetchLast10Tickets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('tickets')
        .where('passengerId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    final seenIds = <String>{}; // avoid accidental duplicate docs
    final tickets = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      if (!seenIds.contains(doc.id)) {
        final data = doc.data();
        data['id'] = doc.id;
        tickets.add(data);
        seenIds.add(doc.id);
      }
    }

    return tickets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ticket History'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchLast10Tickets(),
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text("Ticket ID: $id"),
                  subtitle: Text("Route: $from → $to"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    final timeParts = timeStr.split(':');
                    final hour = int.tryParse(timeParts[0]) ?? 0;
                    final minute = int.tryParse(timeParts[1]) ?? 0;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketPage(
                          from: from,
                          to: to,
                          tripDate: tripDate,
                          tripTime: TimeOfDay(hour: hour, minute: minute),
                          selectedSeats: [seatNumber],
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
    );
  }
}
