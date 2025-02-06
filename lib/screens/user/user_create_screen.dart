import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserCreateScreen extends StatefulWidget {
  const UserCreateScreen({Key? key}) : super(key: key);

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  File? _avatarImage;

  final DatabaseReference _userRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _usernameRef =
      FirebaseDatabase.instance.ref('usernames');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  @override
  void dispose() {
    _usernameController.dispose();
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

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();

      try {
        print("Validating username...");
        final uid = _auth.currentUser?.uid ?? '';

        // Use a transaction to ensure atomicity
        final result = await FirebaseDatabase.instance
            .ref('usernames')
            .child(username)
            .runTransaction((data) {
          if (data != null) {
            return Transaction.abort();
          }
          return Transaction.success(uid);
        });

        if (result.committed) {
          print("Username is unique. Proceeding with user creation...");

          // Upload avatar if provided
          String? avatarUrl;
          if (_avatarImage != null) {
            final storageRef = _storage.ref().child('avatars/$uid');
            await storageRef.putFile(_avatarImage!);
            avatarUrl = await storageRef.getDownloadURL();
            print("Avatar uploaded to: $avatarUrl");
          }

          // Save user details
          await _userRef.child(uid).set({
            'username': username,
            'email': _auth.currentUser?.email ?? '',
            'avatarUrl': avatarUrl ?? '',
          });

          print("User created successfully with username: $username");
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          print("Username is already taken.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username is already taken.')),
          );
        }
      } catch (e) {
        print("Error creating user: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: $e')),
        );
      }
    } else {
      print("Form validation failed. Username is required.");
    }
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickAvatar,
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
        title: const Text('Create User'),
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
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _createUser,
                child: const Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
