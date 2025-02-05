import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth; // Prefix for FirebaseAuth
import 'package:firebase_database/firebase_database.dart';
import '../../models/user.dart' as model; // Prefix for custom User model
import '../../models/group.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final DatabaseReference _userGroupsRef =
      FirebaseDatabase.instance.ref('users');

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Groups'),
        ),
        body: const Center(
          child: Text('You must be signed in to view groups.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _userGroupsRef.child(currentUser.uid).child('groups').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('You are not part of any groups.'),
            );
          }

          final Map<dynamic, dynamic> userGroupsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final groupIds = userGroupsMap.keys.toList();

          return FutureBuilder<List<Group>>(
            future: _fetchGroups(groupIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No groups found.'));
              }

              final groups = snapshot.data!;

              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return FutureBuilder<String>(
                    future: model.User.getUsername(group.admin),
                    builder: (context, snapshot) {
                      final adminUsername =
                          snapshot.connectionState == ConnectionState.done
                              ? snapshot.data ?? 'Unknown'
                              : 'Loading...';

                      return ListTile(
                        title: Text(group.name),
                        subtitle: Text('Admin: $adminUsername'),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/group_show',
                            arguments: {
                              'groupId': group.id,
                              'adminUid': group.admin,
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/group_create');
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Group',
      ),
    );
  }

  Future<List<Group>> _fetchGroups(List<dynamic> groupIds) async {
    final List<Group> groups = [];
    for (var groupId in groupIds) {
      final snapshot =
          await FirebaseDatabase.instance.ref('groups/$groupId').get();
      if (snapshot.exists) {
        groups.add(Group.fromRealtime(groupId, snapshot.value as Map));
      }
    }
    return groups;
  }
}
