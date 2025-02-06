import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';


class User {
  final String uid;
  final String email;
  final String username;
  final List<String> groups;
  final List<String> invitedGroups;
  final String avatarUrl;

  User({
    required this.uid,
    required this.email,
    required this.username,
    required this.groups,
    required this.invitedGroups,
    required this.avatarUrl,
  });

  // Convert Realtime Database entry to User model
  factory User.fromRealtime(String uid, Map<dynamic, dynamic> data) {
    final groupsMap = data['groups'] as Map<dynamic, dynamic>? ?? {};
    final invitedGroupsMap = data['groups'] as Map<dynamic, dynamic>? ?? {};
    return User(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
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
      avatarUrl: '',
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
  
  static Future<User?> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return User(
        uid: user.uid,
        email: data['email'] ?? '',
        username: data['username'] ?? 'Unknown',
        avatarUrl: data['avatarUrl'] ?? '',
        groups: (data['groups'] as Map<dynamic, dynamic>?)?.keys.map((e) => e.toString()).toList() ?? [],
        invitedGroups: (data['invited_groups'] as Map<dynamic, dynamic>?)?.keys.map((e) => e.toString()).toList() ?? [],
      );
    }

    return null;
  }

  Future<void> updateUsername(String newUsername) async {
    final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$uid');
    await userRef.update({'username': newUsername});
  }

  Future<void> updateAvatar(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref('avatars/$uid');
      await storageRef.putFile(imageFile);

      final avatarUrl = await storageRef.getDownloadURL();
      final userRef = FirebaseDatabase.instance.ref('users/$uid');
      await userRef.update({'avatarUrl': avatarUrl});

      print('Avatar updated successfully: $avatarUrl');
    } catch (e) {
      print('Error updating avatar: $e');
    }
  }

  static Future<String?> getAvatarUrl(String userId) async {
    final DatabaseReference usersRef = FirebaseDatabase.instance.ref('users/$userId/avatarUrl');

    try {
      final snapshot = await usersRef.get();
      if (snapshot.exists) {
        return snapshot.value as String?;
      }
    } catch (e) {
      print('Error fetching avatar URL for user $userId: $e');
    }
    return null;
}

}
