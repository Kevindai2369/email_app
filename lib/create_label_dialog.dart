import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateLabelDialog extends StatefulWidget {
  final String userId;

  const CreateLabelDialog({required this.userId, Key? key}) : super(key: key);

  @override
  State<CreateLabelDialog> createState() => _CreateLabelDialogState();
}

class _CreateLabelDialogState extends State<CreateLabelDialog> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  Future<void> _createLabel() async {
    final labelName = _nameController.text.trim();
    final labelNote = _noteController.text.trim();

    if (labelName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên nhãn không được để trống.')),
      );
      return;
    }

    try {
      await _database.child('labels/${widget.userId}').push().set({
        'name': labelName,
        'note': labelNote,
      });
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create label: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo Nhãn'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên nhãn'),
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Ghi chú'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _createLabel,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
