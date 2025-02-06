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
        appBar: AppBar(),
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
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18, // Adjusted to match the "Groups" title size
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
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

                    return Container(
                      decoration: BoxDecoration(
                        color: notification.isRead
                            ? Colors.white
                            : Colors.grey[200], // Highlight unread notifications
                        border: Border(
                          top: BorderSide(
                              color: index == 0
                                  ? Colors.grey.shade300
                                  : Colors.transparent, // Line only on top of the first item
                              width: 1),
                          bottom: BorderSide(
                              color: Colors.grey.shade300, // Line at the bottom of every item
                              width: 1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      child: Text(notification.message),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
