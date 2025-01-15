import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:firebase_database/firebase_database.dart';
import '../../models/user_notification.dart'; // Import the UserNotification model

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: const Center(
          child: Text('You must be signed in to view notifications.'),
        ),
      );
    }

    // Query for the current user's notifications
    final Query userNotificationsQuery = FirebaseDatabase.instance
        .ref('user_notifications')
        .orderByChild('userId')
        .equalTo(currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: userNotificationsQuery.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('No notifications found.'),
            );
          }

          final Map<dynamic, dynamic> notificationsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final notifications = notificationsMap.entries
              .map((entry) =>
                  UserNotification.fromRealtime(entry.key, entry.value))
              .toList();

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                title: Text(notification.message),
                subtitle: Text(notification.createdAt.toString()),
                trailing: Icon(
                  notification.isRead
                      ? Icons.check_circle
                      : Icons.circle_notifications,
                  color: notification.isRead ? Colors.green : Colors.red,
                ),
                onTap: () {
                  // Mark notification as read
                  FirebaseDatabase.instance
                      .ref('user_notifications/${notification.userId}')
                      .update({'isRead': true});
                },
              );
            },
          );
        },
      ),
    );
  }
}
