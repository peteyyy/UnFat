import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class GroupShowScreen extends StatelessWidget {
  const GroupShowScreen({Key? key}) : super(key: key);

  Future<void> _deleteGroup(
      BuildContext context, String groupId, String adminUid) async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    // Ensure only the admin can delete the group
    if (currentUser?.uid != adminUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the admin can delete this group.')),
      );
      return;
    }

    final DatabaseReference _databaseRef =
        FirebaseDatabase.instance.ref('groups/$groupId');

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this group?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Do not delete
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Confirm delete
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

        // Use Navigator.pop to return to the previous screen (GroupScreen)
        Navigator.pop(context); // Pops back to the previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;

    // Ensure arguments are provided and of the expected type
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Details for Group ID: $groupId'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _deleteGroup(context, groupId, adminUid),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete Group'),
            ),
          ],
        ),
      ),
    );
  }
}
