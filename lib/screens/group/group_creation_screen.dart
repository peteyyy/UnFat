import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Realtime Database package

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({Key? key}) : super(key: key);

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Reference to the Realtime Database
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('groups');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    print("Create group initiated");
    if (_formKey.currentState!.validate()) {
      try {
        print("Form validated. Adding group to Realtime Database...");

        // Add the group to the Realtime Database
        await _databaseRef.push().set({
          'name': _nameController.text,
          'createdAt': DateTime.now().toIso8601String(),
        });

        print("Group successfully added to Realtime Database");

        if (mounted) {
          // Clear the input field
          print("Widget is mounted. Clearing input field...");
          _nameController.clear();
          print("Input field cleared");

          // Show the SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully!')),
          );

          print("Navigating back to GroupScreen...");
          Navigator.pop(context);
        } else {
          print("Widget is no longer mounted. Skipping further actions.");
        }
      } catch (e) {
        print("Error occurred: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating group: $e')),
          );
        }
      }
    } else {
      print("Form validation failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _createGroup,
                child: const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
