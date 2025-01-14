import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/group.dart';
import 'group_creation_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('groups');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No groups found.'));
          }

          final Map<dynamic, dynamic> groupsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final groups = groupsMap.entries
              .map((entry) => Group.fromRealtime(entry.key, entry.value))
              .toList();

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                title: Text(group.name),
                subtitle: Text('Admin: ${group.admin}'), // Display admin
                onTap: () {
                  // Handle group click
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GroupCreationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Group',
      ),
    );
  }
}
