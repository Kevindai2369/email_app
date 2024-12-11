import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TrashScreen extends StatefulWidget {
  final String userId;

  const TrashScreen({required this.userId, super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<dynamic, dynamic>> _deletedEmails = [];

  @override
  void initState() {
    super.initState();
    _fetchDeletedEmails();
  }

  void _fetchDeletedEmails() {
    _database.child('deleted_emails/${widget.userId}').onValue.listen((event) {
      final deletedData = event.snapshot.value as Map<dynamic, dynamic>?;
      final deletedEmails = deletedData?.values
              .map((e) => Map<dynamic, dynamic>.from(e))
              .toList() ??
          [];

      setState(() {
        _deletedEmails = deletedEmails;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
      ),
      body: _deletedEmails.isEmpty
          ? const Center(child: Text('No deleted emails.'))
          : ListView.builder(
              itemCount: _deletedEmails.length,
              itemBuilder: (context, index) {
                final email = _deletedEmails[index];
                return Card(
                  child: ListTile(
                    title: Text(email['subject'] ?? 'No Subject'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email['body'] ?? 'No Content'),
                        const SizedBox(height: 4),
                        Text(
                          'From: ${email['sender'] ?? 'Unknown Sender'}',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                        Text(
                          'To: ${email['recipient'] ?? 'Unknown Recipient'}',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Text(
                      email['timestamp'] != null
                          ? DateTime.tryParse(email['timestamp'])
                                  ?.toLocal()
                                  .toString() ??
                              'Invalid Date'
                          : 'No Timestamp',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
