import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:firebase_database/firebase_database.dart';
import '../../models/user_notification.dart'; // Import the UserNotification model

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({Key? key}) : super(key: key);

  @override
  State<UserNotificationScreen> createState() =>
      _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  @override
  void initState() {
    super.initState();
    _markAllNotificationsAsRead();
  }

  Future<void> _markAllNotificationsAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return; // No user is signed in
    }

    final Query userNotificationsQuery = FirebaseDatabase.instance
        .ref('user_notifications')
        .orderByChild('userId')
        .equalTo(currentUser.uid);

    final snapshot = await userNotificationsQuery.get();

    if (snapshot.value != null) {
      final Map<dynamic, dynamic> notificationsMap =
          Map<dynamic, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      for (var entry in notificationsMap.entries) {
        final notificationId = entry.key;
        final notification = entry.value;

        if (notification['isRead'] == false) {
          // Mark the notification as read
          await FirebaseDatabase.instance
              .ref('user_notifications/$notificationId')
              .update({'isRead': true});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if the user is signed in
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
              Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>);
          final notifications = notificationsMap.entries
              .map((entry) =>
                  UserNotification.fromRealtime(entry.key, entry.value))
              .toList();

          // Sort notifications by createdAt descending
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                title: Text(notification.message),
                subtitle: Text(
                  'Created at: ${notification.createdAt.toLocal()}',
                ),
                trailing: Icon(
                  notification.isRead
                      ? Icons.check_circle
                      : Icons.circle_notifications,
                  color: notification.isRead ? Colors.green : Colors.red,
                ),
                onTap: () async {
                  // Mark the notification as read
                  await FirebaseDatabase.instance
                      .ref('user_notifications/${notification.id}')
                      .update({'isRead': true});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification marked as read')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
