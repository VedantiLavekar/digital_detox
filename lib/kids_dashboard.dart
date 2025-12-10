import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page_new.dart';
import 'mental_health_tools.dart';
import 'detox_buddy.dart';
import 'healthy_life_support.dart';
import 'detox_mode_new.dart';
import 'landing_page.dart';
import 'zone_selector.dart';

const Color kKidsPrimaryColor = Color(0xFFFF9800);
const Color kBackgroundColor = Color(0xFFFFF9E6);

class KidsDashboardPage extends StatelessWidget {
  const KidsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kKidsPrimaryColor,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '🎨 Kids Zone',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kKidsPrimaryColor, Colors.orange.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Kids Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: kKidsPrimaryColor),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: kKidsPrimaryColor),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: kKidsPrimaryColor),
              title: const Text('Switch to Adult Zone'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ZoneSelectorPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: kKidsPrimaryColor),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);

                // Clear mode selection so user can choose again
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('mode_selected');
                await prefs.remove('selected_mode');

                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LandingPage(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kKidsPrimaryColor, Colors.orange.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text('🌟', style: TextStyle(fontSize: 50)),
                    SizedBox(height: 10),
                    Text(
                      'Let\'s Have Fun & Stay Healthy!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Choose an activity below',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _KidsCard(
                    emoji: '📱',
                    title: 'Screen Time',
                    subtitle: 'Track & limits',
                    colors: [Colors.purple.shade300, Colors.purple.shade500],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DetoxModeNewPage(),
                        ),
                      );
                    },
                  ),
                  _KidsCard(
                    emoji: '⭐',
                    title: 'My Habits',
                    subtitle: 'Daily tasks',
                    colors: [Colors.amber.shade300, Colors.amber.shade600],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Habit Builder coming soon! 🌟'),
                          backgroundColor: kKidsPrimaryColor,
                        ),
                      );
                    },
                  ),
                  _KidsCard(
                    emoji: '🧘',
                    title: 'Yoga & Play',
                    subtitle: 'Fun exercises',
                    colors: [Colors.green.shade300, Colors.green.shade500],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MentalHealthToolsPage(),
                        ),
                      );
                    },
                  ),
                  _KidsCard(
                    emoji: '💧',
                    title: 'Water Track',
                    subtitle: 'Stay hydrated',
                    colors: [Colors.blue.shade300, Colors.blue.shade500],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Water Tracker coming soon! 💧'),
                          backgroundColor: kKidsPrimaryColor,
                        ),
                      );
                    },
                  ),
                  _KidsCard(
                    emoji: '👥',
                    title: 'My Buddy',
                    subtitle: 'Find friends',
                    colors: [Colors.pink.shade300, Colors.pink.shade500],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DetoxBuddyPage(),
                        ),
                      );
                    },
                  ),
                  _KidsCard(
                    emoji: '🍎',
                    title: 'Healthy Life',
                    subtitle: 'Tips & food',
                    colors: [Colors.red.shade300, Colors.red.shade500],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HealthyLifeSupportPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kKidsPrimaryColor, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      '💡 Daily Tip',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kKidsPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Remember to take breaks from your screen every 20 minutes! '
                      'Look at something far away to rest your eyes. 👀',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KidsCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  const _KidsCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[1].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
