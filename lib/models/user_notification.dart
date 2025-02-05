import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserNotification {
  final String id; // Add the id property
  final String userId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  // Factory to create UserNotification from Firebase Realtime Database data
  factory UserNotification.fromRealtime(String id, Map<dynamic, dynamic> data) {
    return UserNotification(
      id: id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert UserNotification to Firebase Realtime Database data
  Map<String, dynamic> toRealtime() {
    return {
      'userId': userId,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Function to create a notification for a user
  static Future<void> createUserNotification(String userId, String message) async {
    final DatabaseReference _notificationRef =
        FirebaseDatabase.instance.ref('user_notifications');
    await _notificationRef.push().set({
      'userId': userId,
      'message': message,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Function to get the count of unread notifications for the current user
  static Stream<int> getUnreadNotificationsCount() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Stream.value(0);
    }

    return FirebaseDatabase.instance
        .ref('user_notifications')
        .orderByChild('userId')
        .equalTo(currentUser.uid)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return 0;

      final Map<dynamic, dynamic> notifications =
          event.snapshot.value as Map<dynamic, dynamic>;

      return notifications.values
          .where((notification) => notification['isRead'] == false)
          .length;
    });
  }

  // **New Function**: Mark all notifications as read for the user
  static Future<void> markAllAsRead(String userId) async {
    final ref = FirebaseDatabase.instance
        .ref('user_notifications')
        .orderByChild('userId')
        .equalTo(userId);

    final snapshot = await ref.get();
    if (snapshot.value != null) {
      final Map<dynamic, dynamic> notifications =
          snapshot.value as Map<dynamic, dynamic>;
      for (var entry in notifications.entries) {
        final id = entry.key;
        final notification = entry.value;
        if (notification['isRead'] == false) {
          FirebaseDatabase.instance
              .ref('user_notifications/$id')
              .update({'isRead': true});
        }
      }
    }
  }
}
