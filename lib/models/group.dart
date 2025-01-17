import 'package:firebase_database/firebase_database.dart';

class Group {
  final String id;
  final String name;
  final String admin;
  final List<String> members;

  Group({
    required this.id,
    required this.name,
    required this.admin,
    required this.members,
  });

  // Factory to create Group from Realtime Database data
  factory Group.fromRealtime(String id, Map<dynamic, dynamic> data) {
    final membersMap = data['members'] as Map<dynamic, dynamic>? ?? {};
    return Group(
      id: id,
      name: data['name'] ?? 'Unnamed Group',
      admin: data['admin'] ?? 'Unknown Admin',
      members: membersMap.keys.map((key) => key.toString()).toList(),
    );
  }

  // Convert Group to Realtime Database format
  Map<String, dynamic> toRealtime() {
    final membersMap = {for (var member in members) member: true};
    return {
      'name': name,
      'admin': admin,
      'members': membersMap,
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
}
