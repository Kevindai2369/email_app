import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ViewDraftsScreen extends StatelessWidget {
  final String userId;
  const ViewDraftsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final draftsRef = FirebaseDatabase.instance.ref('drafts/$userId');

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Draft Mails')),
      body: StreamBuilder(
        stream: draftsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final Map<dynamic, dynamic> drafts =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            return ListView.builder(
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final key = drafts.keys.toList()[index];
                final draft = drafts[key];
                return ListTile(
                  title: Text(draft['subject'] ?? 'No Subject'),
                  subtitle: Text(draft['body'] ?? 'No Body'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await draftsRef.child(key).remove();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Draft deleted')),
                      );
                    },
                  ),
                );
              },
            );
          }
          return const Center(child: Text('No drafts found.'));
        },
      ),
    );
  }
}
