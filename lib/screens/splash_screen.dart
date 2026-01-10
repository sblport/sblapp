import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for at least 2 seconds for the splash effect
    final minDelay = Future.delayed(const Duration(seconds: 2));
    
    // Try to auto-login
    final authResult = Provider.of<AuthService>(context, listen: false).tryAutoLogin();

    // Wait for both
    await Future.wait([minDelay, authResult]);

    // Get the result of auto-login
    final isLoggedIn = await authResult;

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, isLoggedIn ? '/main' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              width: 250,
            ),
          ],
        ),
      ),
    );
  }
}
