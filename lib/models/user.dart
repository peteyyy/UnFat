import 'package:firebase_database/firebase_database.dart';

class User {
  final String uid;
  final String email;
  final String username;
  final List<String> groups; // Tracks user's groups

  User({
    required this.uid,
    required this.email,
    required this.username,
    required this.groups,
  });

  // Convert Realtime Database entry to User model
  factory User.fromRealtime(String uid, Map<dynamic, dynamic> data) {
    final groupsMap = data['groups'] as Map<dynamic, dynamic>? ?? {};
    return User(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      groups: groupsMap.keys.map((key) => key.toString()).toList(),
    );
  }

  // Convert User model to Realtime Database entry
  Map<String, dynamic> toRealtime() {
    final groupsMap = {for (var group in groups) group: true};
    return {
      'email': email,
      'username': username,
      'groups': groupsMap,
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
    return User(uid: uid, email: '', username: '', groups: []);
  }

  // Leave a group: Removes the group from the user's group list and removes the user from the group's member list
  Future<void> leaveGroup(String groupId) async {
    final DatabaseReference userGroupRef = FirebaseDatabase.instance.ref('users/$uid/groups/$groupId');
    final DatabaseReference groupMemberRef = FirebaseDatabase.instance.ref('groups/$groupId/members/$uid');

    await userGroupRef.remove();
    await groupMemberRef.remove();
  }

  // Join a group: Adds the group to the user's group list and adds the user to the group's member list
  Future<void> joinGroup(String groupId) async {
    final DatabaseReference userGroupRef = FirebaseDatabase.instance.ref('users/$uid/groups/$groupId');
    final DatabaseReference groupMemberRef = FirebaseDatabase.instance.ref('groups/$groupId/members/$uid');

    await userGroupRef.set(true);
    await groupMemberRef.set(true);
  }
}
