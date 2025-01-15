import 'package:firebase_database/firebase_database.dart';

class UserNotification {
  final String userId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  UserNotification({
    required this.userId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  // Factory to create UserNotification from Firebase Realtime Database data
  factory UserNotification.fromRealtime(String id, Map<dynamic, dynamic> data) {
    return UserNotification(
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

  // Function to create a user notification
  static Future<void> createUserNotification(
      String userId, String message) async {
    final DatabaseReference _userNotificationRef =
        FirebaseDatabase.instance.ref('user_notifications');
    await _userNotificationRef.push().set({
      'userId': userId,
      'message': message,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
