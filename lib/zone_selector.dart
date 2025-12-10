import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_model.dart';
import 'login.dart';

const Color kPrimaryColor = Color(0xFF2E9D8A);
const Color kBackgroundColor = Color(0xFFF5F5DC);

class ZoneSelectorPage extends StatefulWidget {
  const ZoneSelectorPage({super.key});

  @override
  State<ZoneSelectorPage> createState() => _ZoneSelectorPageState();
}

class _ZoneSelectorPageState extends State<ZoneSelectorPage> {
  bool _isLoading = false;

  Future<void> _selectZone(UserZone zone) async {
    print('🔵 Zone selected: ${zone.name}');

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_zone', zone.name);
      print('✅ Zone saved locally: ${zone.name}');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('🔵 User logged in, saving to Firestore...');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'zone': zone.name});
        print('✅ Zone saved to Firestore!');
      }

      if (!mounted) return;

      print('🔵 Navigating to login page...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      print('❌ Error selecting zone: $e');
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Kids Zone Card
                    _buildZoneCard(
                      context: context,
                      emoji: '🎨',
                      color: Colors.orange,
                      gradient: [
                        Colors.orange.shade400,
                        Colors.orange.shade600,
                      ],
                      onTap: () => _selectZone(UserZone.kids),
                    ),

                    const SizedBox(height: 40),

                    // Adult Zone Card
                    _buildZoneCard(
                      context: context,
                      emoji: '💼',
                      color: kPrimaryColor,
                      gradient: [
                        const Color(0xFF2E9D8A),
                        const Color(0xFF1F7A6A),
                      ],
                      onTap: () => _selectZone(UserZone.adult),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildZoneCard({
    required BuildContext context,
    required String emoji,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 100)),
        ),
      ),
    );
  }
}
