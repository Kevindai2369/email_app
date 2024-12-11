import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CustomizeProfileScreen extends StatefulWidget {
  final String userId;

  const CustomizeProfileScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<CustomizeProfileScreen> createState() => _CustomizeProfileScreenState();
}

class _CustomizeProfileScreenState extends State<CustomizeProfileScreen> {
  final _nameController = TextEditingController();
  final _profilePicController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Save updated profile to Firebase
  void _saveProfile() async {
    try {
      await _database.child('users/${widget.userId}').update({
        'name': _nameController.text,
        'profilePic': _profilePicController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  // Load current profile data
  void _loadProfile() async {
    final snapshot = await _database.child('users/${widget.userId}').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _nameController.text = data['name'] ?? '';
        _profilePicController.text = data['profilePic'] ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profilePicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _profilePicController,
              decoration:
                  const InputDecoration(labelText: 'Profile Picture URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
