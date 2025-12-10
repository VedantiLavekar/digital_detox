import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _entries = [];
  final List<String> _prompts = [
    "What made you smile today?",
    "Describe a moment you felt proud of yourself.",
    "Write about something you’re grateful for.",
    "How did you overcome a challenge recently?",
    "What’s one thing you want to improve tomorrow?",
    "Describe your mood in one word and why.",
    "Write a message to your future self.",
    "What’s a small win you had today?",
    "Write a thank you note to a friend or family member.",
    "What is something new you learned today?",
  ];

  String _currentPrompt = "";

  @override
  void initState() {
    super.initState();
    _showRandomPrompt();
  }

  void _showRandomPrompt() {
    _currentPrompt = (_prompts..shuffle()).first;
  }

  void _saveEntry() {
    if (_controller.text.trim().isEmpty) return;

    final now = DateTime.now();
    final formatted = DateFormat('yyyy-MM-dd – hh:mm a').format(now);

    setState(() {
      _entries.insert(0, {
        "text": _controller.text.trim(),
        "date": formatted,
        "prompt": _currentPrompt,
      });
      _controller.clear();
      _showRandomPrompt();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Entry saved! 🌱"),
        backgroundColor: const Color(0xFFB2DFDB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgGradient = LinearGradient(
      colors: [Color(0xFFE0F7FA), Color(0xFFF5F5DC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "My Journal",
          style: TextStyle(
            color: Color(0xFF2E9D8A),
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2E9D8A)),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.lightbulb, color: Color(0xFF2E9D8A)),
                          SizedBox(width: 8),
                          Text(
                            "Prompt for you:",
                            style: TextStyle(
                              color: Color(0xFF2E9D8A),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentPrompt,
                        style: TextStyle(
                          color: Colors.teal.shade700,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controller,
                        maxLines: 5,
                        minLines: 3,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: "Write your thoughts here...",
                          hintStyle: TextStyle(
                            color: Colors.teal.shade200,
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.spa_rounded, size: 22),
              label: const Text(
                "Save Entry",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E9D8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                shadowColor: Colors.teal.shade100,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _entries.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.self_improvement,
                          color: Color(0xFFB2DFDB),
                          size: 60,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No entries yet.\nStart journaling to relax your mind 🌱",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.teal.shade300,
                            fontSize: 17,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _entries.length,
                      itemBuilder: (_, i) => Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withValues(alpha: 0.07),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFB2DFDB),
                            child: const Icon(
                              Icons.note_rounded,
                              color: Color(0xFF2E9D8A),
                            ),
                          ),
                          title: Text(
                            _entries[i]["text"]!,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _entries[i]["date"]!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              if (_entries[i]["prompt"] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    "Prompt: ${_entries[i]["prompt"]!}",
                                    style: TextStyle(
                                      color: Colors.teal.shade300,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
