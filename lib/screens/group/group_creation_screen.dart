import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for user authentication
import 'package:firebase_database/firebase_database.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({Key? key}) : super(key: key);

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Reference to the Realtime Database
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('groups');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    print("Create group initiated");
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be signed in to create a group!')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        print("Form validated. Adding group to Realtime Database...");

        // Add the group to the Realtime Database
        await _databaseRef.push().set({
          'name': _nameController.text,
          'admin': currentUser.uid, // Add the admin field
          'createdAt': DateTime.now().toIso8601String(),
        });

        print("Group successfully added to Realtime Database");

        if (mounted) {
          // Clear the input field
          _nameController.clear();

          // Show the SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully!')),
          );

          // Navigate back to GroupScreen
          Navigator.pop(context);
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
