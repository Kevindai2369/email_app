import 'package:email_app/auth_screen.dart';
import 'package:email_app/email_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:email_app/app_drawer.dart';
import 'package:email_app/compose_email.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen(this.userId, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  List<Map<dynamic, dynamic>> _emails = [];
  List<Map<dynamic, dynamic>> _filteredEmails = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmails();
    _searchController.addListener(_onSearchChanged);
  }

  void _fetchEmails() {
    _database.child('emails/${widget.userId}').onValue.listen((event) {
      final receivedData = event.snapshot.value as Map<dynamic, dynamic>?;
      final receivedEmails = receivedData?.values
              .map((e) => Map<dynamic, dynamic>.from(e))
              .toList() ??
          [];

      setState(() {
        _emails = receivedEmails +
            _emails.where((email) => email['isSent'] == true).toList();
        _filteredEmails = _emails;
      });
    });

    _database.child('sent_emails/${widget.userId}').onValue.listen((event) {
      final sentData = event.snapshot.value as Map<dynamic, dynamic>?;
      final sentEmails =
          sentData?.values.map((e) => Map<dynamic, dynamic>.from(e)).toList() ??
              [];

      setState(() {
        _emails.addAll(sentEmails.map((email) => {
              ...email,
              'isSent': true,
            }));
        _filteredEmails = _emails;
      });
    });
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isNotEmpty) {
        _filteredEmails = _emails.where((email) {
          String subject = email['subject']?.toLowerCase() ?? '';
          String body = email['body']?.toLowerCase() ?? '';
          return subject.contains(query) || body.contains(query);
        }).toList();
      } else {
        _filteredEmails = _emails;
      }
    });
  }

  Future<void> _deleteEmail(String emailKey, bool isSent) async {
    try {
      final path = isSent
          ? 'sent_emails/${widget.userId}/$emailKey'
          : 'emails/${widget.userId}/$emailKey';
      final emailData = (await _database.child(path).once()).snapshot.value;

      if (emailData != null) {
        await _database
            .child('deleted_emails/${widget.userId}')
            .push()
            .set(emailData);
        await _database.child(path).remove();
        _showSnackbar('Email moved to trash.');
      }
    } catch (e) {
      _showSnackbar('Failed to delete email: ${e.toString()}');
    }
  }

  void _composeEmail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeEmailScreen(userId: widget.userId),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp.toString().isEmpty) {
      return 'Unknown date';
    }
    try {
      final parsedDate = DateTime.parse(timestamp.toString());
      return '${parsedDate.toLocal()}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_currentUser?.email ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create),
            onPressed: _composeEmail,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: AppDrawer(
        userId: widget.userId,
        email: _currentUser?.email ?? '',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search emails...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Received Emails:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: _filteredEmails.isEmpty
                ? const Center(child: Text('No emails found.'))
                : ListView.builder(
                    itemCount: _filteredEmails.length,
                    itemBuilder: (context, index) {
                      final email = _filteredEmails[index];
                      final emailKey = email['key'] ?? '';
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTimestamp(email['timestamp']),
                                style: const TextStyle(fontSize: 12),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteEmail(
                                  emailKey,
                                  email['isSent'] == true,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmailDetailScreen(
                                userId: widget.userId,
                                email: email,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
