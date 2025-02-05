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
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref('users');

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Groups')),
        body: const Center(child: Text('You must be signed in to view groups.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: StreamBuilder<DatabaseEvent>(
        stream: _userRef.child(currentUser.uid).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No groups available.'));
          }

          final Map<dynamic, dynamic> userData =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};

          final invitedGroupIds =
              (userData['invited_groups'] as Map<dynamic, dynamic>?)
                      ?.keys
                      .toList() ??
                  [];
          final joinedGroupIds =
              (userData['groups'] as Map<dynamic, dynamic>?)
                      ?.keys
                      .toList() ??
                  [];

          return FutureBuilder<Map<String, List<Group>>>(
            future: _fetchGroups(invitedGroupIds, joinedGroupIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('No groups found.'));
              }

              final invitedGroups = snapshot.data!['invited']!;
              final joinedGroups = snapshot.data!['joined']!;

              return ListView(
                children: [
                  if (invitedGroups.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Invited Groups',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...invitedGroups.map((group) => _buildGroupTile(group, true)),
                    const Divider(),
                  ],
                  if (joinedGroups.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Groups',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...joinedGroups.map((group) => _buildGroupTile(group, false)),
                  ],
                ],
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

  Future<Map<String, List<Group>>> _fetchGroups(
      List<dynamic> invitedIds, List<dynamic> joinedIds) async {
    final List<Group> invitedGroups = [];
    final List<Group> joinedGroups = [];

    for (var groupId in invitedIds) {
      final snapshot =
          await FirebaseDatabase.instance.ref('groups/$groupId').get();
      if (snapshot.exists) {
        invitedGroups.add(Group.fromRealtime(groupId, snapshot.value as Map));
      }
    }

    for (var groupId in joinedIds) {
      final snapshot =
          await FirebaseDatabase.instance.ref('groups/$groupId').get();
      if (snapshot.exists) {
        joinedGroups.add(Group.fromRealtime(groupId, snapshot.value as Map));
      }
    }

    return {'invited': invitedGroups, 'joined': joinedGroups};
  }

  Widget _buildGroupTile(Group group, bool isInvited) {
    return FutureBuilder<String>(
      future: model.User.getUsername(group.admin),
      builder: (context, snapshot) {
        final adminUsername = snapshot.connectionState == ConnectionState.done
            ? snapshot.data ?? 'Unknown'
            : 'Loading...';

        return ListTile(
          title: Text(group.name),
          subtitle: Text('Admin: $adminUsername'),
          trailing: isInvited
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptInvite(group.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _declineInvite(group.id),
                    ),
                  ],
                )
              : null,
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
  }

  Future<void> _acceptInvite(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userId = currentUser.uid;

    final updates = {
      'groups/$groupId/invitees/$userId': null, // Remove from invitees
      'users/$userId/invited_groups/$groupId': null, // Remove from invited_groups
      'groups/$groupId/members/$userId': true, // Add to members
      'users/$userId/groups/$groupId': true, // Add to user's groups
    };

    await FirebaseDatabase.instance.ref().update(updates);

    // Notify user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have joined the group!')),
    );

    setState(() {}); // Refresh UI
  }


  Future<void> _declineInvite(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userId = currentUser.uid;

    final updates = {
      'groups/$groupId/invitees/$userId': null, // Remove from invitees
      'users/$userId/invited_groups/$groupId': null, // Remove from invited_groups
    };

    await FirebaseDatabase.instance.ref().update(updates);

    // Notify user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation declined.')),
    );

    setState(() {}); // Refresh UI
  }


}
