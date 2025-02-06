import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/user.dart';
import '../../models/user_notification.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({Key? key}) : super(key: key);

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _avatarImage;

  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('groups');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createGroup() async {
    final currentUser = firebaseAuth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to create a group!'),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        final groupKey = _databaseRef.push().key;

        if (groupKey == null) {
          throw Exception("Failed to generate group key");
        }

        String? avatarUrl;
        if (_avatarImage != null) {
          final storageRef =
              FirebaseStorage.instance.ref('group_avatars/$groupKey');
          await storageRef.putFile(_avatarImage!);
          avatarUrl = await storageRef.getDownloadURL();
        }

        await _databaseRef.child(groupKey).set({
          'name': _nameController.text.trim(),
          'admin': currentUser.uid,
          'createdAt': DateTime.now().toIso8601String(),
          'avatarUrl': avatarUrl ?? '',
        });

        await User.fromId(currentUser.uid).joinGroup(groupKey);

        final message = "You created a new group: ${_nameController.text.trim()}";
        await UserNotification.createUserNotification(
            currentUser.uid, message);

        if (mounted) {
          _nameController.clear();
          setState(() => _avatarImage = null);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully!')),
          );

          Navigator.pop(context);
        }
      } catch (e) {
        print("Error occurred: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickAvatar, // Opens image picker when tapped
      child: CircleAvatar(
        radius: 50,
        backgroundImage: _avatarImage != null
            ? FileImage(_avatarImage!) as ImageProvider
            : const AssetImage('assets/default_avatar.jpeg'),
      ),
    );
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatarPicker(), // Show avatar at the top
              const SizedBox(height: 16.0),
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
