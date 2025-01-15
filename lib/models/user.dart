import 'package:firebase_database/firebase_database.dart';

class User {
  final String uid;
  final String email;
  final String username;

  User({
    required this.uid,
    required this.email,
    required this.username,
  });

  // Convert Realtime Database entry to User model
  factory User.fromRealtime(String uid, Map<dynamic, dynamic> data) {
    return User(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
    );
  }

  // Convert User model to Realtime Database entry
  Map<String, dynamic> toRealtime() {
    return {
      'email': email,
      'username': username,
    };
  }

  // Static method to fetch a username by user ID
  static Future<String> getUsername(String userId) async {
    final DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');

    try {
      final snapshot = await usersRef.child(userId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['username'] ?? 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
    return 'Unknown';
  }
}
