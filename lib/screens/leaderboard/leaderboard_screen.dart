import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/group.dart';
import '../../models/user.dart' as model;
import 'package:firebase_auth/firebase_auth.dart' as auth;


class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Group> _groups = [];
  Group? _selectedGroup;
  Map<String, Map<String, int>> _leaderboardData = {};

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserGroups();
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    final groups = await Group.fetchUserGroups();
    if (groups.isNotEmpty) {
      setState(() {
        _groups = groups;
        _selectedGroup = groups.first;
      });
      _loadLeaderboard(groups.first);
    }
  }

  // Fetch leaderboard data for the selected group
  Future<void> _loadLeaderboard(Group group) async {
    final leaderboard = await group.getAllUserStats();
    setState(() {
      _leaderboardData = leaderboard;
    });
  }

  // Reward user when they visit
  Future<void> _rewardUser() async {
    final user = _auth.currentUser;
    if (user == null || _selectedGroup == null) return;

    await _selectedGroup!.incrementUserStats(user.uid, points: 10, streak: 4);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You've earned 10 points and a 4-day streak!")),
    );

    _loadLeaderboard(_selectedGroup!); // Refresh leaderboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leaderboard")),
      body: Column(
        children: [
          // Dropdown to Select Group
          if (_groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<Group>(
                  value: _selectedGroup,
                  items: _groups.map((Group group) {
                    return DropdownMenuItem<Group>(
                      value: group,
                      child: Text(group.name),
                    );
                  }).toList(),
                  onChanged: (Group? newGroup) {
                    if (newGroup != null) {
                      setState(() => _selectedGroup = newGroup);
                      _loadLeaderboard(newGroup);
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Leaderboard Table
          Expanded(
            child: _leaderboardData.isEmpty
                ? const Center(child: Text("No data available."))
                : ListView.builder(
                    itemCount: _leaderboardData.length,
                    itemBuilder: (context, index) {
                      final entry = _leaderboardData.entries.elementAt(index);
                      final isEvenRow = index % 2 == 0;

                      return Container(
                        color: isEvenRow ? Colors.grey[200] : Colors.white, // Alternating row colors
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: FutureBuilder<String>(
                          future: model.User.getUsername(entry.key),
                          builder: (context, usernameSnapshot) {
                            String username = usernameSnapshot.connectionState == ConnectionState.done
                                ? usernameSnapshot.data ?? "Unknown User"
                                : "Loading...";

                            return FutureBuilder<String?>(
                              future: model.User.getAvatarUrl(entry.key),
                              builder: (context, avatarSnapshot) {
                                String? avatarUrl = avatarSnapshot.data;

                                return ListTile(
                                  leading: 
                                    CircleAvatar(
                                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl) as ImageProvider
                                          : const AssetImage('assets/default_avatar.jpeg'),
                                      radius: 24,
                                    ),
                                  title: Text(username),
                                  subtitle: Text("Points: ${entry.value['points']} | Streak: ${entry.value['streak']}"),
                                  trailing: Text(
                                    "${entry.value['points']} pts",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),


        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _rewardUser,
        tooltip: "Claim Points",
        child: const Icon(Icons.star),
      ),
    );
  }
}
