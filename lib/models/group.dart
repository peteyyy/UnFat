import 'package:firebase_database/firebase_database.dart';

class Group {
  final String id;
  final String name;
  final String admin;
  final List<String> members;
  final List<String> invitees;

  Group({
    required this.id,
    required this.name,
    required this.admin,
    required this.members,
    required this.invitees,
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
}
