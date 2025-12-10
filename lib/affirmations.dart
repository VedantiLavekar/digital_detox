import 'dart:math';
import 'package:flutter/material.dart';

class AffirmationsPage extends StatefulWidget {
  const AffirmationsPage({super.key});

  @override
  State<AffirmationsPage> createState() => _AffirmationsPageState();
}

class _AffirmationsPageState extends State<AffirmationsPage> {
  final List<String> _affirmations = [
    "I am calm, relaxed, and in control.",
    "I choose positivity over negativity.",
    "I am grateful for this moment.",
    "I have the power to create change.",
    "I am enough, just as I am.",
    "I radiate peace and love.",
    "My mind is clear and focused.",
    "Every day is a fresh start.",
    "I am proud of who I am becoming.",
    "I trust myself and my decisions.",
  ];

  final List<String> _jokes = [
    "Why did the smartphone go to therapy? Because it lost its sense of touch!",
    "Why did the computer catch cold? Because it left its Windows open!",
    "Why don’t skeletons fight each other? They don’t have the guts!",
    "Why did the student eat his homework? Because the teacher said it was a piece of cake!",
    "Why did the scarecrow win an award? Because he was outstanding in his field!",
  ];

  final List<String> _thoughts = [
    "Small steps every day lead to big changes.",
    "Your mind is a garden. Your thoughts are the seeds.",
    "The best time for new beginnings is now.",
    "You are stronger than you think.",
    "Progress, not perfection.",
    "Let go of what you can't control.",
    "Be kind to yourself today.",
    "Growth is a journey, not a race.",
    "You are allowed to take a break.",
    "Every day is a chance to learn something new.",
  ];

  String _current = "";
  String _currentType = "Affirmation";

  void _showNew(String type) {
    final random = Random();
    setState(() {
      _currentType = type;
      if (type == "Affirmation") {
        _current = _affirmations[random.nextInt(_affirmations.length)];
      } else if (type == "Joke") {
        _current = _jokes[random.nextInt(_jokes.length)];
      } else if (type == "Thought") {
        _current = _thoughts[random.nextInt(_thoughts.length)];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _showNew("Affirmation");
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    IconData icon;
    Color iconColor;
    if (_currentType == "Affirmation") {
      bgColor = const Color(0xFFE0F7FA);
      icon = Icons.spa_rounded;
      iconColor = const Color(0xFF2E9D8A);
    } else if (_currentType == "Joke") {
      bgColor = const Color(0xFFFFF8E1);
      icon = Icons.emoji_emotions;
      iconColor = Colors.orangeAccent;
    } else {
      bgColor = const Color(0xFFF5F5DC);
      icon = Icons.lightbulb_outline;
      iconColor = Colors.amber.shade700;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Feel Good Zone",
          style: TextStyle(
            color: Color(0xFF2E9D8A),
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.1,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2E9D8A)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Affirmation"),
                    selected: _currentType == "Affirmation",
                    selectedColor: const Color(0xFF2E9D8A),
                    labelStyle: TextStyle(
                      color: _currentType == "Affirmation" ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => _showNew("Affirmation"),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text("Joke"),
                    selected: _currentType == "Joke",
                    selectedColor: Colors.orangeAccent,
                    labelStyle: TextStyle(
                      color: _currentType == "Joke" ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => _showNew("Joke"),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text("Thought"),
                    selected: _currentType == "Thought",
                    selectedColor: Colors.amber,
                    labelStyle: TextStyle(
                      color: _currentType == "Thought" ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => _showNew("Thought"),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                child: Column(
                  key: ValueKey(_current + _currentType),
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: 48,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _current,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _currentType == "Joke" ? 22 : 24,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                        fontFamily: _currentType == "Joke" ? "Comic Sans MS" : null,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_currentType == "Joke")
                      const Text(
                        "😄 Take a break, laugh a little!",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (_currentType == "Affirmation")
                      const Text(
                        "🌱 Breathe in, believe in yourself.",
                        style: TextStyle(
                          color: Color(0xFF2E9D8A),
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      const Text(
                        "💡 Reflect and grow.",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: Colors.teal.shade100,
                ),
                onPressed: () => _showNew(_currentType),
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: Text(
                  "Show Another",
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Choose what you need right now.",
                style: TextStyle(
                  color: Colors.teal.shade300,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}