import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF2E9D8A);
const Color kBackgroundColor = Color(0xFFF5F5DC);

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: kPrimaryColor,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor.withValues(alpha: 0.8), kPrimaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Icon(Icons.phone_android, size: 80, color: Colors.white),
                  SizedBox(height: 15),
                  Text(
                    "Digital Detox",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Balance your digital life and real life",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle("About the App"),
            const Text(
              "Our Digital Detox app helps you balance technology and real life. "
              "We aim to reduce screen addiction, improve mental health, "
              "and promote mindful usage of devices.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 25),

            _buildSectionTitle("Key Features"),
            const SizedBox(height: 10),
            FeatureTile(
              icon: Icons.timer,
              text: "Track and limit your screen time",
            ),
            FeatureTile(
              icon: Icons.schedule,
              text: "Set focus/break intervals",
            ),
            FeatureTile(
              icon: Icons.self_improvement,
              text: "Mindfulness reminders",
            ),
            FeatureTile(
              icon: Icons.show_chart,
              text: "Personal progress insights",
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                onPressed: () => Navigator.pop(context),
                label: const Text(
                  "Back",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
            letterSpacing: 0.5,
          ),
        ),
        const Divider(color: kPrimaryColor, thickness: 2, endIndent: 250),
        const SizedBox(height: 10),
      ],
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const FeatureTile({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: kPrimaryColor, size: 28),
        title: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
