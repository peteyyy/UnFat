import 'package:firebase_database/firebase_database.dart';

class User {
  final String uid;
  final String email;
  final String username;
  final List<String> groups;
  final List<String> invitedGroups;

  User({
    required this.uid,
    required this.email,
    required this.username,
    required this.groups,
    required this.invitedGroups,
  });

  // Convert Realtime Database entry to User model
  factory User.fromRealtime(String uid, Map<dynamic, dynamic> data) {
    final groupsMap = data['groups'] as Map<dynamic, dynamic>? ?? {};
    final invitedGroupsMap = data['groups'] as Map<dynamic, dynamic>? ?? {};
    return User(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      groups: groupsMap.keys.map((key) => key.toString()).toList(),
      invitedGroups: invitedGroupsMap.keys.map((key) => key.toString()).toList(),
      
    );
  }

  // Convert User model to Realtime Database entry
  Map<String, dynamic> toRealtime() {
    final groupsMap = {for (var group in groups) group: true};
    return {
      'email': email,
      'username': username,
      'groups': groupsMap,
      'invitedGroups': invitedGroups,
    };
  }

  // Static method to fetch a username by user ID
  static Future<String> getUsername(String userId) async {
    final DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');

    try {
      final snapshot = await usersRef.child(userId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['username'] ?? 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
    return 'Unknown';
  }

  factory User.fromId(String uid) {
    return User(
      uid: uid,
      email: '',
      username: '',
      groups: [],
      invitedGroups: [],
    );
  }

  static Future<bool> usernameExists(String username) async {
    final DatabaseReference usernameRef = FirebaseDatabase.instance.ref('usernames/$username');

    final snapshot = await usernameRef.get();
    return snapshot.exists;
  }


  Future<void> leaveGroup(String groupId) async {
    final DatabaseReference userGroupRef = FirebaseDatabase.instance.ref('users/$uid/groups/$groupId');
    final DatabaseReference groupMemberRef = FirebaseDatabase.instance.ref('groups/$groupId/members/$uid');

    await userGroupRef.remove();
    await groupMemberRef.remove();
  }

  Future<void> joinGroup(String groupId) async {
    final DatabaseReference userGroupRef = FirebaseDatabase.instance.ref('users/$uid/groups/$groupId');
    final DatabaseReference groupMemberRef = FirebaseDatabase.instance.ref('groups/$groupId/members/$uid');

    await userGroupRef.set(true);
    await groupMemberRef.set(true);
  }

  Future<void> acceptInvite(String groupId) async {
    await joinGroup(groupId);
    final DatabaseReference userInvitesRef = FirebaseDatabase.instance.ref('users/$uid/invited_groups/$groupId');
    final DatabaseReference groupInviteesRef = FirebaseDatabase.instance.ref('groups/$groupId/invitees/$uid');

    await userInvitesRef.remove();
    await groupInviteesRef.remove();
  }

  Future<void> declineInvite(String groupId) async {
    final DatabaseReference userInvitesRef = FirebaseDatabase.instance.ref('users/$uid/invited_groups/$groupId');
    final DatabaseReference groupInviteesRef = FirebaseDatabase.instance.ref('groups/$groupId/invitees/$uid');

    await userInvitesRef.remove();
    await groupInviteesRef.remove();
  }
}
