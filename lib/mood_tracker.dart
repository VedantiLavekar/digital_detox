import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'database_helper.dart';

const Color kPrimaryColor = Color(0xFF2E9D8A);
const Color kBackgroundColor = Color(0xFFF5F5DC);

class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage>
    with TickerProviderStateMixin {
  final Color green = kPrimaryColor;
  final Color bgColor = kBackgroundColor;

  final Map<String, Map<String, dynamic>> moods = {
    "Happy": {
      "emoji": "😃",
      "label": "Happy",
      "animation": "assets/animations/happy_bird.json",
      "color": Colors.green,
      "message": "That's wonderful! Keep the positive energy flowing! ✨",
      "suggestions": [
        "Share your happiness with someone special",
        "Practice gratitude meditation",
        "Take a joyful nature walk",
        "Listen to your favorite uplifting music",
      ],
      "actions": [
        {
          "title": "Gratitude Journal",
          "icon": Icons.book,
          "description": "Write down 3 things you're grateful for",
        },
        {
          "title": "Share Joy",
          "icon": Icons.share,
          "description": "Spread happiness to others",
        },
        {
          "title": "Dance Break",
          "icon": Icons.music_note,
          "description": "Move your body to feel even better",
        },
      ],
    },
    "Neutral": {
      "emoji": "😐",
      "label": "Neutral",
      "animation": "assets/animations/onoff.json",
      "color": Colors.grey,
      "message": "Feeling balanced. Let's add some spark to your day! 🌟",
      "suggestions": [
        "Try learning something new",
        "Call a friend or family member",
        "Do some light exercise or stretching",
        "Practice a few minutes of mindfulness",
      ],
      "actions": [
        {
          "title": "Mood Boost",
          "icon": Icons.trending_up,
          "description": "Try activities to lift your spirits",
        },
        {
          "title": "Quick Exercise",
          "icon": Icons.fitness_center,
          "description": "Get your body moving",
        },
        {
          "title": "Mindful Moment",
          "icon": Icons.self_improvement,
          "description": "Center yourself with breathing",
        },
      ],
    },
    "Sad": {
      "emoji": "😔",
      "label": "Sad",
      "animation": "assets/animations/kids_playing.json",
      "color": Colors.blue,
      "message":
          "It's okay to feel sad. You're not alone, and this will pass. 💙",
      "suggestions": [
        "Talk to someone you trust about your feelings",
        "Practice gentle deep breathing exercises",
        "Watch something funny or heartwarming",
        "Take a warm, relaxing bath",
      ],
      "actions": [
        {
          "title": "Comfort Zone",
          "icon": Icons.favorite,
          "description": "Do something that brings you comfort",
        },
        {
          "title": "Breathing Exercise",
          "icon": Icons.air,
          "description": "Calm your mind with breath work",
        },
        {
          "title": "Feel-Good Content",
          "icon": Icons.video_library,
          "description": "Watch uplifting videos or movies",
        },
      ],
    },
    "Angry": {
      "emoji": "😡",
      "label": "Angry",
      "animation": "assets/animations/onoff.json",
      "color": Colors.red,
      "message": "Let's channel that energy into something positive! 🔥➡️💪",
      "suggestions": [
        "Try physical exercise to release tension",
        "Practice slow, calming breathing",
        "Write your feelings in a journal",
        "Listen to calming or empowering music",
      ],
      "actions": [
        {
          "title": "Release Tension",
          "icon": Icons.sports_martial_arts,
          "description": "Physical activity to blow off steam",
        },
        {
          "title": "Cool Down",
          "icon": Icons.ac_unit,
          "description": "Breathing exercises to calm down",
        },
        {
          "title": "Express Feelings",
          "icon": Icons.edit,
          "description": "Write about what's bothering you",
        },
      ],
    },
    "Tired": {
      "emoji": "😴",
      "label": "Tired",
      "animation": "assets/animations/meditation.json",
      "color": Colors.purple,
      "message": "Time to recharge! Your wellbeing matters. 🔋",
      "suggestions": [
        "Take a short power nap (20-30 minutes)",
        "Drink some water to stay hydrated",
        "Do gentle stretching or yoga",
        "Practice relaxation techniques",
      ],
      "actions": [
        {
          "title": "Energy Boost",
          "icon": Icons.battery_charging_full,
          "description": "Quick ways to restore energy",
        },
        {
          "title": "Hydrate",
          "icon": Icons.local_drink,
          "description": "Drink water or herbal tea",
        },
        {
          "title": "Rest Time",
          "icon": Icons.bed,
          "description": "Take a restorative break",
        },
      ],
    },
  };

  String? selectedMood;
  bool showAnimation = false;
  bool showSuggestions = false;
  String animationPath = "";
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  List<Map<String, dynamic>> _moodHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadMoods();
  }
  
  Future<void> _loadMoods() async {
    setState(() => _isLoading = true);
    try {
      final moods = await DatabaseHelper().getMoods();
      if (mounted) {
        setState(() {
          _moodHistory = moods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _logMood(String moodKey, String animation) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final now = DateTime.now();
    final formatted = DateFormat('yyyy-MM-dd – hh:mm a').format(now);

    try {
      await DatabaseHelper().insertMood({
        'mood': moodKey,
        'time': formatted,
        'timestamp': now.millisecondsSinceEpoch,
      });
      
      await _loadMoods(); // Refresh the list

      if (mounted) {
        setState(() {
          selectedMood = moodKey;
          showAnimation = true;
          showSuggestions = true;
          animationPath = animation;
        });
      }

      // Start pulse animation
      _pulseController.repeat(reverse: true);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Mood '$moodKey' logged ✅"),
          duration: const Duration(seconds: 2),
          backgroundColor: green,
        ),
      );

      // Hide animation after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            showAnimation = false;
          });
          _pulseController.stop();
        }
      });
    } catch (e) {
       scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Failed to save mood"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performMoodAction(String moodKey, Map<String, dynamic> action) {
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${action['description']}'),
        duration: const Duration(seconds: 3),
        backgroundColor: moods[moodKey]!['color'],
        action: SnackBarAction(
          label: 'Got it!',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildMoodButton(String moodKey, Map<String, dynamic> moodData) {
    return GestureDetector(
      onTap: () => _logMood(moodKey, moodData["animation"]!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(moodData["emoji"]!, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 5),
          Text(
            moodData["label"]!,
            style: TextStyle(fontSize: 14, color: green),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: green,
        title: const Text(
          "Mood Tracker",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "How are you feeling today?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E9D8A),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 15,
                children: moods.entries
                    .map((entry) => _buildMoodButton(entry.key, entry.value))
                    .toList(),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _isLoading 
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(green),
                    ),
                  )
                : _moodHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mood, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No mood entries yet.\nTrack your first mood above!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _moodHistory.length,
                      itemBuilder: (_, i) {
                        final data = _moodHistory[i];
                        final moodKey = data['mood'] as String;
                        final emoji = moods.containsKey(moodKey)
                            ? moods[moodKey]!["emoji"]
                            : "🙂";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: moods.containsKey(moodKey)
                                    ? moods[moodKey]!["color"].withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.grey.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            title: Text(
                              moodKey,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: moods.containsKey(moodKey)
                                    ? moods[moodKey]!["color"]
                                    : Colors.grey[700],
                              ),
                            ),
                            subtitle: Text(
                              data['time'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),

          // Mood Suggestions Panel
          if (showSuggestions && selectedMood != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        moods[selectedMood!]!["emoji"],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          moods[selectedMood!]!["message"],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: moods[selectedMood!]!["color"],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            showSuggestions = false;
                            selectedMood = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Suggestions
                  Text(
                    "Suggestions for you:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...moods[selectedMood!]!["suggestions"]
                      .map<Widget>(
                        (suggestion) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Text(
                    "Quick Actions:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: moods[selectedMood!]!["actions"]
                        .map<Widget>(
                          (action) => AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _performMoodAction(selectedMood!, action),
                                  icon: Icon(action["icon"], size: 18),
                                  label: Text(
                                    action["title"],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        moods[selectedMood!]!["color"]
                                            .withValues(alpha: 0.1),
                                    foregroundColor:
                                        moods[selectedMood!]!["color"],
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          if (showAnimation)
            Center(
              child: Lottie.asset(
                animationPath,
                width: 200,
                height: 200,
                repeat: false,
              ),
            ),
        ],
      ),
    );
  }
}
