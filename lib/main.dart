import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_page.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CampusFireApp());
}

class CampusFireApp extends StatelessWidget {
  const CampusFireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CampusFire',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5A3C)),
          useMaterial3: true,
        ),
        home: const AuthChecker(),
      ),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final user = authSnapshot.data;

        // opening login when nobody is signed in
        if (user == null) {
          return const LoginPage();
        }

        // stopping unverified users from opening the dashboard
        if (!user.emailVerified) {
          return const LoginPage();
        }

        // reading the signed-in user's role
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            if (userSnapshot.hasError) {
              return const ErrorScreen();
            }

            final userData = userSnapshot.data?.data();

            final role = userData?['role']?.toString().trim().toLowerCase();

            final isAdmin = role == 'campus admin';

            // opening the shared dashboard structure
            return DashboardPage(isAdmin: isAdmin);
          },
        );
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFFF5A3C))),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      body: Center(
        child: Text(
          'We could not load your account.',
          style: TextStyle(
            color: Color(0xFF12385F),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
