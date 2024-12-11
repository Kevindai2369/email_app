import 'dart:async';

import 'package:email_app/auth_screen.dart';
import 'package:email_app/email_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:email_app/app_drawer.dart';
import 'package:email_app/compose_email.dart';
import 'package:email_app/create_label_dialog.dart';

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
  List<Map<dynamic, dynamic>> _labels = [];
  String? _selectedLabel;
  late final StreamSubscription _emailSubscription;

  @override
  void initState() {
    super.initState();
    _emailSubscription = _database
        .child('emails/${widget.userId}')
        .onValue
        .listen((event) => _fetchEmails());
    _fetchEmails();
    _searchController.addListener(_onSearchChanged);
    _fetchLabels();
  }

  void _fetchLabels() {
    _database.child('labels/${widget.userId}').onValue.listen((event) {
      final data = event.snapshot.value;

      if (data is Map<dynamic, dynamic>) {
        final loadedLabels = data.entries
            .map((entry) {
          final value = entry.value;

          if (value is Map<dynamic, dynamic>) {
            return {
              ...Map<dynamic, dynamic>.from(value),
              'key': entry.key,
            };
          } else {
            return null;
          }
        })
            .where((label) => label != null)
            .cast<Map<dynamic, dynamic>>()
            .toList();

        if (mounted) {
          setState(() {
            _labels = loadedLabels;
          });
        }
      }
    });
  }

  void _openCreateLabelDialog() async {
    await showDialog(
      context: context,
      builder: (context) => CreateLabelDialog(userId: widget.userId),
    );
    _fetchLabels();
  }

  void _filterEmailsByLabel(String labelName) {
    setState(() {
      if (_selectedLabel == labelName) {
        _selectedLabel = null;
        _filteredEmails = _emails;
      } else if (labelName == "Spam") {
        _filteredEmails = _emails.where((email) {
          return email['label'] == "Spam";
        }).toList();
      } else {
        _selectedLabel = labelName;
        _filteredEmails = _emails.where((email) {
          return email['label'] == labelName;
        }).toList();
      }
    });
  }

  void _fetchEmails() {
    final allEmails = <Map<dynamic, dynamic>>[];

    _database.child('emails/${widget.userId}').onValue.listen((event) {
      final userEmails = event.snapshot.value;

      if (userEmails is Map<dynamic, dynamic>) {
        final emailsList = userEmails.entries
            .map((entry) {
          final value = entry.value;

          if (value is Map<dynamic, dynamic>) {
            return {
              'key': entry.key,
              ...Map<dynamic, dynamic>.from(value),
            };
          } else {
            return null;
          }
        })
            .where((email) => email != null)
            .cast<Map<dynamic, dynamic>>()
            .toList();

        allEmails.addAll(emailsList);
        _updateEmailList(allEmails);
      }
    });

    _database.child('sent_emails/${widget.userId}').onValue.listen((event) {
      final sentEmails = event.snapshot.value;

      if (sentEmails is Map<dynamic, dynamic>) {
        final sentEmailsList = sentEmails.entries
            .map((entry) {
          final value = entry.value;

          if (value is Map<dynamic, dynamic>) {
            return {
              'key': entry.key,
              ...Map<dynamic, dynamic>.from(value),
            };
          } else {
            return null;
          }
        })
            .where((email) => email != null)
            .cast<Map<dynamic, dynamic>>()
            .toList();

        allEmails.addAll(sentEmailsList);
        _updateEmailList(allEmails);
      }
    });
  }

  void _updateEmailList(List<Map<dynamic, dynamic>> emails) {
    emails.sort((a, b) {
      final timeA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(0);
      final timeB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(0);
      return timeB.compareTo(timeA);
    });

    if (mounted) {
      setState(() {
        _emails = emails;
        _filteredEmails = _emails;
      });
    }
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();

    if (mounted) {
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
  }

  Future<void> _updateEmailStatus({
    required String emailKey,
    required bool isSent,
    String? newLabel,
    bool? isRead,
    bool moveToSpam = false,
  }) async {
    try {
      final sourcePath = isSent
          ? 'sent_emails/${widget.userId}/$emailKey'
          : 'emails/${widget.userId}/$emailKey';

      final emailSnapshot = await _database.child(sourcePath).once();
      final emailData = emailSnapshot.snapshot.value;

      if (emailData != null) {
        if (moveToSpam) {
          final spamPath = 'emails/${widget.userId}/spam';
          await _database.child('$spamPath/$emailKey').set(emailData);
          await _database.child(sourcePath).remove();
          _showSnackbar('Email moved to Spam.');
        } else {
          // Chỉ cập nhật trạng thái
          final updates = <String, dynamic>{};
          if (newLabel != null) updates['label'] = newLabel;
          if (isRead != null) updates['isRead'] = isRead;
          await _database.child(sourcePath).update(updates);
          _showSnackbar('Email updated successfully.');
        }

        _fetchEmails();
      }
    } catch (e) {
      _showSnackbar('Failed to update email: $e');
    }
  }

  Future<void> _markAsRead(String emailKey, bool isSent) async {
    _updateEmailStatus(
      emailKey: emailKey,
      isSent: isSent,
      isRead: true,
    );
  }

  void _markAsSpam(String emailKey, bool isSent) {
    _updateEmailStatus(
      emailKey: emailKey,
      isSent: isSent,
      moveToSpam: true,
    );
  }

  void _showLabelSelectionDialog(String emailKey, bool isSent) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select a Label'),
          children: _labels.map((label) {
            return SimpleDialogOption(
              onPressed: () async {
                try {
                  await _database
                      .child('emails/${widget.userId}/$emailKey')
                      .update({'label': label['name']});

                  await _database
                      .child('sent_emails/${widget.userId}/$emailKey')
                      .update({'label': label['name']});

                  if (mounted) {
                    setState(() {
                      final emailIndex = _emails
                          .indexWhere((email) => email['key'] == emailKey);
                      if (emailIndex != -1) {
                        _emails[emailIndex]['label'] = label['name'];
                      }
                    });
                  }
                  Navigator.pop(context);
                  _showSnackbar('Label "${label['name']}" applied to email.');
                } catch (e) {
                  _showSnackbar('Failed to apply label: ${e.toString()}');
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.label, size: 20),
                  const SizedBox(width: 8),
                  Text(label['name']),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _onEmailLongPress(String emailKey, bool isSent) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Mark as Read'),
              onTap: () {
                Navigator.pop(context);
                _markAsRead(emailKey, isSent);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Mark Label'),
              onTap: () {
                Navigator.pop(context);
                _showLabelSelectionDialog(emailKey, isSent);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Remove Label'),
              onTap: () {
                Navigator.pop(context);
                _removeLabel(emailKey, isSent);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Mark as Spam'),
              onTap: () {
                Navigator.pop(context);
                _markAsSpam(emailKey, isSent);
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  Future<void> _removeLabel(String emailKey, bool isSent) async {
    try {
      final path = isSent
          ? 'sent_emails/${widget.userId}/$emailKey'
          : 'emails/${widget.userId}/$emailKey';

      await _database.child(path).update({'label': null});

      if (mounted) {
        setState(() {
          final emailIndex =
          _emails.indexWhere((email) => email['key'] == emailKey);
          if (emailIndex != -1) {
            _emails[emailIndex]['label'] = null;
          }
        });
      }

      _showSnackbar('Label removed successfully.');
    } catch (e) {
      _showSnackbar('Failed to remove label: $e');
    }
  }

  @override
  void dispose() {
    _emailSubscription.cancel();
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
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _openCreateLabelDialog,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  "Add Label",
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _labels.map((label) {
                      return ChoiceChip(
                        label: Text(label['name']),
                        selected: _selectedLabel == label['name'],
                        onSelected: (_) => _filterEmailsByLabel(label['name']),
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(
                          color: _selectedLabel == label['name']
                              ? Colors.white
                              : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredEmails.isEmpty
                ? const Center(child: Text('No emails found.'))
                : ListView.builder(
              itemCount: _filteredEmails.length,
              itemBuilder: (context, index) {
                final email = _filteredEmails[index];
                final emailKey = email['key'] ?? '';
                final isSent = email['isSent'] == true;

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
                    onLongPress: () =>
                        _onEmailLongPress(emailKey, isSent),
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
