import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';


class Group {
  final String id;
  final String name;
  final String admin;
  final List<String> members;
  final List<String> invitees;
  final String avatarUrl;

  Group({
    required this.id,
    required this.name,
    required this.admin,
    required this.members,
    required this.invitees,
    required this.avatarUrl,
  });

  // Factory to create Group from Realtime Database data
  factory Group.fromRealtime(String id, Map<dynamic, dynamic> data) {
    final membersMap = data['members'] as Map<dynamic, dynamic>? ?? {};
    final inviteesMap = data['invitees'] as Map<dynamic, dynamic>? ?? {};
    return Group(
      id: id,
      name: data['name'] ?? 'Unnamed Group',
      admin: data['admin'] ?? 'Unknown Admin',
      members: membersMap.keys.map((key) => key.toString()).toList(),
      invitees: inviteesMap.keys.map((key) => key.toString()).toList(),
      avatarUrl: data['avatarUrl'] ?? '',
    );
  }

  // Convert Group to Realtime Database format
  Map<String, dynamic> toRealtime() {
    final membersMap = {for (var member in members) member: true};
    return {
      'name': name,
      'admin': admin,
      'members': membersMap,
      'avatarUrl': avatarUrl,
    };
  }

  // Remove a member from the group
  Future<void> removeMember(String userId) async {
    final DatabaseReference groupRef = FirebaseDatabase.instance.ref('groups/$id/members/$userId');
    await groupRef.remove(); // Remove the user from the group's members list

    // Remove the group from the user's groups list
    final DatabaseReference userGroupsRef = FirebaseDatabase.instance.ref('users/$userId/groups/$id');
    await userGroupsRef.remove();
  }
  Future<void> addInvitee(String userId) async {
    final DatabaseReference inviteesRef = FirebaseDatabase.instance.ref('groups/$id/invitees/$userId');
    await inviteesRef.set(true);

    final DatabaseReference userInvitesRef = FirebaseDatabase.instance.ref('users/$userId/invited_groups/$id');
    await userInvitesRef.set(true);
  }
  
  Future<void> removeInvitee(String userId) async {
    final DatabaseReference inviteesRef = FirebaseDatabase.instance.ref('groups/$id/invitees/$userId');
    await inviteesRef.remove();

    final DatabaseReference userInvitesRef = FirebaseDatabase.instance.ref('users/$userId/invited_groups/$id');
    await userInvitesRef.remove();
  }

  // Referring to user/group data
  Future<void> updateUserStats(String userId, int points, int streak) async {
    final DatabaseReference userStatsRef =
        FirebaseDatabase.instance.ref('groups/$id/user_data/$userId');

    await userStatsRef.set({
      "points": points,
      "streak": streak
    });
  }

  Future<void> incrementUserStats(String userId, {int points = 0, int streak = 0}) async {
    final DatabaseReference userStatsRef =
        FirebaseDatabase.instance.ref('groups/$id/user_data/$userId');

    final snapshot = await userStatsRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      int currentPoints = data["points"] ?? 0;
      int currentStreak = data["streak"] ?? 0;

      await userStatsRef.update({
        "points": currentPoints + points,
        "streak": currentStreak + streak
      });
    } else {
      await userStatsRef.set({
        "points": points,
        "streak": streak
      });
    }
  }

  Future<Map<String, int>> getUserStats(String userId) async {
    final DatabaseReference userStatsRef =
        FirebaseDatabase.instance.ref('groups/$id/user_data/$userId');

    final snapshot = await userStatsRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return {
        "points": data["points"] ?? 0,
        "streak": data["streak"] ?? 0
      };
    }
    return {"points": 0, "streak": 0};
  }

  Future<Map<String, Map<String, int>>> getAllUserStats() async {
    final DatabaseReference groupStatsRef =
        FirebaseDatabase.instance.ref('groups/$id/user_data');

    final snapshot = await groupStatsRef.get();
    if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      // Ensure proper type conversion
      final sortedEntries = data.entries
          .where((entry) => entry.value is Map<dynamic, dynamic>) // Filter invalid entries
          .map((entry) {
            final stats = entry.value as Map<dynamic, dynamic>;
            return MapEntry(entry.key.toString(), {
              "points": (stats["points"] as int?) ?? 0,
              "streak": (stats["streak"] as int?) ?? 0
            });
          })
          .toList();

      // Sort by points in descending order
      sortedEntries.sort((a, b) => b.value['points']!.compareTo(a.value['points']!));

      return Map.fromEntries(sortedEntries);
    }

    return {}; // Return empty map if no data exists
  }



  // Added method to fetch user's groups dynamically
  static Future<List<Group>> fetchUserGroups() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final DatabaseReference userRef =
        FirebaseDatabase.instance.ref('users/${user.uid}/groups');
    final snapshot = await userRef.get();

    if (!snapshot.exists) return [];

    List<Group> groups = [];
    for (var entry in (snapshot.value as Map<dynamic, dynamic>).keys) {
      final groupSnapshot =
          await FirebaseDatabase.instance.ref('groups/$entry').get();
      if (groupSnapshot.exists) {
        groups.add(Group.fromRealtime(entry, groupSnapshot.value as Map));
      }
    }
    return groups;
  }

  Future<int> getMemberCount() async {
    final snapshot = await FirebaseDatabase.instance.ref('groups/$id/members').get();
    if (snapshot.exists && snapshot.value is Map) {
      return (snapshot.value as Map).length;
    }
    return 0;
  }

  Future<void> updateAvatar(String groupId, File avatarFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref('group_avatars/$groupId');
      await storageRef.putFile(avatarFile);

      final avatarUrl = await storageRef.getDownloadURL();
      final groupRef = FirebaseDatabase.instance.ref('groups/$groupId');
      await groupRef.update({'avatarUrl': avatarUrl});
    } catch (e) {
      print('Error updating group avatar: $e');
    }
  }


}
