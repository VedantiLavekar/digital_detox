import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final assets = [
    'assets/animations/happy_bird.json',
    'assets/animations/meditation.json',
    'assets/animations/kids_playing.json',
    'assets/animations/onoff.json'
  ];
  final titles = [
    'Breathe & Relax',
    'Meditate',
    'Play & Connect',
    'Have a Digital Detox'
  ];
  int idx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSequence());
  }

  Future<void> _runSequence() async {
    for (int i = 0; i < assets.length; i++) {
      setState(() => idx = i);
      await Future.delayed(const Duration(seconds: 2));
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFE9F7F1),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 300,
                  child: Lottie.asset(assets[idx], fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
                Text(
                  titles[idx],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E9D8A),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
