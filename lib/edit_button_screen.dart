import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditButtonScreen extends StatefulWidget {
  final String? buttonId;
  final Map<String, dynamic>? buttonData;

  const EditButtonScreen({super.key, this.buttonId, this.buttonData});

  @override
  State<EditButtonScreen> createState() => _EditButtonScreenState();
}

class _EditButtonScreenState extends State<EditButtonScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _subscribeController;
  late TextEditingController _publishController;
  late TextEditingController _onValueController;
  late TextEditingController _offValueController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.buttonData?['name'] ?? '');
    _subscribeController =
        TextEditingController(text: widget.buttonData?['subscribeTopic'] ?? '');
    _publishController =
        TextEditingController(text: widget.buttonData?['publishTopic'] ?? '');
    _onValueController =
        TextEditingController(text: widget.buttonData?['onValue'] ?? '');
    _offValueController =
        TextEditingController(text: widget.buttonData?['offValue'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.buttonId == null ? 'Add Button' : 'Edit Button')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: _subscribeController,
                decoration:
                    const InputDecoration(labelText: 'Subscribe Topic')),
            TextField(
                controller: _publishController,
                decoration: const InputDecoration(labelText: 'Publish Topic')),
            TextField(
                controller: _onValueController,
                decoration: const InputDecoration(labelText: 'ON Value')),
            TextField(
                controller: _offValueController,
                decoration: const InputDecoration(labelText: 'OFF Value')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveButton,
              child: Text(widget.buttonId == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveButton() async {
    final data = {
      'name': _nameController.text,
      'subscribeTopic': _subscribeController.text,
      'publishTopic': _publishController.text,
      'onValue': _onValueController.text,
      'offValue': _offValueController.text,
      'state': 'OFF',
    };

    if (widget.buttonId == null) {
      await _firestore.collection('buttons').add(data);
    } else {
      await _firestore.collection('buttons').doc(widget.buttonId).update(data);
    }
    if (mounted) {
      Navigator.pop(
          context); // Only call Navigator.pop if the widget is still mounted
    }
  }
}
