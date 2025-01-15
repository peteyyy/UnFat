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
      try {
        print("Creating user...");
        String? avatarUrl;
        if (_avatarImage != null) {
          final uid = _auth.currentUser?.uid ?? '';
          final storageRef = _storage.ref().child('avatars/$uid');
          await storageRef.putFile(_avatarImage!);
          avatarUrl = await storageRef.getDownloadURL();
          print("Avatar uploaded to: $avatarUrl");
        }

        final uid = _auth.currentUser?.uid ?? '';
        await _userRef.child(uid).set({
          'username': _usernameController.text,
          'email': _auth.currentUser?.email ?? '',
          'avatarUrl': avatarUrl ?? '',
        });

        print(
            "User created successfully with username: ${_usernameController.text}");
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        print("Error creating user: $e");
      }
    } else {
      print("Form validation failed. Username is required.");
    }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickAvatar,
                    child: const Text('Pick Avatar'),
                  ),
                  const SizedBox(width: 16.0),
                  if (_avatarImage != null)
                    CircleAvatar(
                      backgroundImage: FileImage(_avatarImage!),
                      radius: 30,
                    ),
                ],
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
