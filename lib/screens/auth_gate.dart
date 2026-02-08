import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'onboarding_screen.dart';
import 'home_shell.dart';
import 'splash_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<void>? _seedFuture;
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          _seedFuture = null;
          _lastUid = null;
          return const OnboardingScreen();
        }
        if (_lastUid != user.uid) {
          _lastUid = user.uid;
          _seedFuture = DatabaseService.instance.ensureUserSeed(user);
        }
        return FutureBuilder<void>(
          future: _seedFuture,
          builder: (context, seedSnapshot) {
            if (seedSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            return const HomeShell();
          },
        );
      },
    );
  }
}
