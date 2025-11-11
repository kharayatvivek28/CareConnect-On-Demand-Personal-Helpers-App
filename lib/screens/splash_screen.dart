import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../auth/app_auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToAuth();
  }

  Future<void> _goToAuth() async {
    await Future.delayed(const Duration(seconds: 5)); // match animation length
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // or your theme color
      body: Center(
        child: Lottie.asset(
          'assets/animations/splash_logo.json', // 👈 your animation file\
          width: 250,
          height: 250,
          fit: BoxFit.contain,
          repeat: false, // play only once
        ),
      ),
    );
  }
}
