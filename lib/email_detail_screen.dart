import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EmailDetailScreen extends StatelessWidget {
  final String userId;
  final Map<dynamic, dynamic> email;

  const EmailDetailScreen({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  void _replyToEmail(BuildContext context, DatabaseReference database) {
    TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reply to Email'),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(labelText: 'Your Reply'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repliesRef = database.child('replies/$userId');
                await repliesRef.push().set({
                  'originalEmail': email,
                  'reply': replyController.text,
                  'timestamp': DateTime.now().toIso8601String(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply sent successfully!')),
                );
              },
              child: const Text('Send Reply'),
            ),
          ],
        );
      },
    );
  }

  void _forwardEmail(BuildContext context, DatabaseReference database) {
    TextEditingController recipientController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Forward Email'),
          content: TextField(
            controller: recipientController,
            decoration: const InputDecoration(labelText: 'Recipient Email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final forwardsRef = database.child('forwards/$userId');
                await forwardsRef.push().set({
                  'originalEmail': email,
                  'recipient': recipientController.text,
                  'timestamp': DateTime.now().toIso8601String(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Email forwarded successfully!')),
                );
              },
              child: const Text('Forward'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference database = FirebaseDatabase.instance.ref();

    return Scaffold(
      appBar: AppBar(
        title: Text(email['subject'] ?? 'No Subject'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email['subject'] ?? 'No Subject',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              email['body'] ?? 'No Content',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _replyToEmail(context, database),
                  child: const Text('Reply'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _forwardEmail(context, database),
                  child: const Text('Forward'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
