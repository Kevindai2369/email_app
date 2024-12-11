import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quill_html_editor/quill_html_editor.dart';

class ComposeEmailScreen extends StatefulWidget {
  final String userId;

  const ComposeEmailScreen({super.key, required this.userId});

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final QuillEditorController _quillController = QuillEditorController();

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  void _sendEmail() async {
    final recipient = _recipientController.text.trim();
    final subject = _subjectController.text.trim();
    final emailBody = await _quillController.getText();

    if (recipient.isEmpty) {
      _showSnackbar('Recipient cannot be empty!');
      return;
    }
    if (subject.isEmpty) {
      _showSnackbar('Subject cannot be empty!');
      return;
    }
    if (emailBody.trim().isEmpty) {
      _showSnackbar('Email body cannot be empty!');
      return;
    }

    await _database.child('sent_emails/${widget.userId}').push().set({
      'sender': _currentUser?.email ?? 'Unknown Sender',
      'recipient': recipient,
      'subject': subject,
      'body': emailBody,
      'cc': _ccController.text.isNotEmpty ? _ccController.text : null,
      'bcc': _bccController.text.isNotEmpty ? _bccController.text : null,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _showSnackbar('Email sent successfully!');
    Navigator.pop(context);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendEmail,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ccController,
                decoration: const InputDecoration(
                  labelText: 'CC',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bccController,
                decoration: const InputDecoration(
                  labelText: 'BCC',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Body:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                height: 300,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QuillHtmlEditor(
                  controller: _quillController,
                  hintText: 'Write your email here...',
                  minHeight: 300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    super.dispose();
  }
}
