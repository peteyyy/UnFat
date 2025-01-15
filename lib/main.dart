import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as firebase_ui_auth;
import 'screens/home_screen.dart';
import 'screens/user/user_create_screen.dart';
import 'screens/group/group_screen.dart';
import 'screens/group/group_creation_screen.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UnFat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/home': (context) => const MyHomePage(title: 'UnFat'),
        '/user_create': (context) => const UserCreateScreen(),
        '/group_screen': (context) => const GroupScreen(),
        '/group_create': (context) => const GroupCreationScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> isUserProfileComplete(firebase_auth.User? user) async {
    if (user == null) return false;

    final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    final snapshot = await userRef.get();

    // Check if profile data exists (username and/or avatar)
    return snapshot.exists && (snapshot.value as Map).containsKey('username');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final user = snapshot.data;

          return FutureBuilder<bool>(
            future: isUserProfileComplete(user),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (profileSnapshot.data == false) {
                // Navigate to UserCreationScreen if profile is incomplete
                return const UserCreateScreen();
              }

              // Load the main home screen if profile is complete
              return const MyHomePage(title: 'UnFat');
            },
          );
        } else {
          return firebase_ui_auth.SignInScreen(
            providers: [
              firebase_ui_auth.EmailAuthProvider(),
            ],
          );
        }
      },
    );
  }
}
