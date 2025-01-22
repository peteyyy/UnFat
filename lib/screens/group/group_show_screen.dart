import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/user.dart';

class GroupShowScreen extends StatelessWidget {
  const GroupShowScreen({Key? key}) : super(key: key);

  Future<void> _deleteGroup(
      BuildContext context, String groupId, String adminUid) async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    if (currentUser?.uid != adminUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the admin can delete this group.')),
      );
      return;
    }

    final DatabaseReference _databaseRef =
        FirebaseDatabase.instance.ref('groups/$groupId');

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this group?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await _databaseRef.remove();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting group: $e')),
        );
      }
    }
  }

  Future<void> _sendInvite(
    BuildContext context, String groupId, String username) async {
    try {
      // Check if the username exists
      final userExists = await User.usernameExists(username);

      if (!userExists) {
        // Show snackbar if user doesn't exist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User "$username" does not exist.')),
        );
        return;
      }

      // Fetch the user ID from the username mapping
      final DatabaseReference userRef =
          FirebaseDatabase.instance.ref('usernames/$username');
      final userSnapshot = await userRef.get();
      final userId = userSnapshot.value as String;

      // Add the user to the group's invitees list
      final DatabaseReference groupInviteesRef =
          FirebaseDatabase.instance.ref('groups/$groupId/invitees/$userId');
      final DatabaseReference userInvitesRef =
          FirebaseDatabase.instance.ref('users/$userId/invited_groups/$groupId');

      await groupInviteesRef.set(true);
      await userInvitesRef.set(true);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation sent to "$username".')),
      );
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending invite: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments == null || arguments is! Map<String, String>) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Invalid group data.'),
        ),
      );
    }

    final groupId = arguments['groupId']!;
    final adminUid = arguments['adminUid']!;

    final DatabaseReference groupRef =
        FirebaseDatabase.instance.ref('groups/$groupId');

    final TextEditingController _inviteController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
      ),
      body: FutureBuilder<DataSnapshot>(
        future: groupRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Group not found.'),
            );
          }

          final groupData = snapshot.data!.value as Map<dynamic, dynamic>;
          final groupName = groupData['name'] ?? 'Unnamed Group';
          final membersMap = groupData['members'] as Map<dynamic, dynamic>? ?? {};
          final members = membersMap.keys.map((key) => key.toString()).toList();
          final inviteesMap = groupData['invitees'] as Map<dynamic, dynamic>? ?? {};
          final invitees = inviteesMap.keys.map((key) => key.toString()).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Invite Members:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inviteController,
                        decoration: const InputDecoration(
                          hintText: 'Enter username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final username = _inviteController.text.trim();
                        if (username.isNotEmpty) {
                          _sendInvite(context, groupId, username);
                          _inviteController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a username.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Invite'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Members:',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final memberId = members[index];
                      return FutureBuilder<String>(
                        future: _fetchUsername(memberId),
                        builder: (context, snapshot) {
                          final memberName = snapshot.connectionState ==
                                  ConnectionState.done
                              ? snapshot.data ?? 'Unknown User'
                              : 'Loading...';

                          return ListTile(
                            title: Text(memberName),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Invitees:',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: invitees.length,
                    itemBuilder: (context, index) {
                      final inviteeId = invitees[index];
                      return FutureBuilder<String>(
                        future: _fetchUsername(inviteeId),
                        builder: (context, snapshot) {
                          final inviteeName = snapshot.connectionState ==
                                  ConnectionState.done
                              ? snapshot.data ?? 'Unknown User'
                              : 'Loading...';

                          return ListTile(
                            title: Text(inviteeName),
                          );
                        },
                      );
                    },
                  ),
                ),

                Center(
                  child: ElevatedButton(
                    onPressed: () => _deleteGroup(context, groupId, adminUid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete Group'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String> _fetchUsername(String userId) async {
    final DatabaseReference userRef =
        FirebaseDatabase.instance.ref('users/$userId');

    try {
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['username'] ?? 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }

    return 'Unknown';
  }
}
