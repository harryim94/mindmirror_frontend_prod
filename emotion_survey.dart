import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mindmirror_app/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmotionTree {
  final List<SurveyQuestion> questions;
  EmotionTree({required this.questions});
}

class SurveyQuestion {
  final String prompt;
  final Map<String, String> options;
  SurveyQuestion({required this.prompt, required this.options});
}

class EmotionSurveyPage extends StatefulWidget {
  final String userId;
  const EmotionSurveyPage({super.key, required this.userId});

  @override
  State<EmotionSurveyPage> createState() => _EmotionSurveyPageState();
}

class _EmotionSurveyPageState extends State<EmotionSurveyPage> {
  String? _userId;
  String? selectedEmotion;
  int currentStep = 0;
  List<String> answers = [];

final Map<String, EmotionTree> emotionSurveyMap = {
"happy": EmotionTree(questions: [
    SurveyQuestion(prompt: "What made you feel happy?", options: {
        "Good news": "good_news",
        "Fun experience": "fun",
        "Social interaction": "social"
    }),
    SurveyQuestion(prompt: "Was it related to...", options: {
        "Achievement or success": "success",
        "Unexpected surprise": "surprise",
        "Spending time with loved ones": "connection"
    }),
    SurveyQuestion(prompt: "How did it make you feel inside?", options: {
        "Proud and confident": "proud",
        "Warm and grateful": "grateful",
        "Energetic and playful": "playful"
    }),
]),

"sad": EmotionTree(questions: [
    SurveyQuestion(prompt: "What made you feel sad?", options: {
        "Personal struggle": "personal",
        "Loss or disappointment": "loss",
        "Loneliness": "lonely"
    }),
    SurveyQuestion(prompt: "Was it caused by...", options: {
        "Relationship issue": "relationship",
        "Career or study stress": "career",
        "Old memory resurfacing": "memory"
    }),
    SurveyQuestion(prompt: "What did you need most in that moment?", options: {
        "Comfort or support": "comfort",
        "Understanding": "understanding",
        "Time alone": "solitude"
    }),
]),

"angry": EmotionTree(questions: [
    SurveyQuestion(prompt: "What triggered your anger?", options: {
        "Someone’s behavior": "someone",
        "Unfair situation": "unfair",
        "Internal frustration": "frustration"
    }),
    SurveyQuestion(prompt: "Was it because you felt...", options: {
        "Disrespected": "disrespect",
        "Ignored or dismissed": "ignored",
        "Out of control": "powerless"
    }),
    SurveyQuestion(prompt: "What did you want to do?", options: {
        "Speak up or argue": "speak_up",
        "Withdraw and avoid": "avoid",
        "Change the situation": "fix_it"
    }),
]),

"anxious": EmotionTree(questions: [
    SurveyQuestion(prompt: "What caused your anxiety?", options: {
        "Upcoming event": "event",
        "Health concern": "health",
        "Overthinking": "thinking"
    }),
    SurveyQuestion(prompt: "Were you afraid of...", options: {
        "Uncertain outcome": "uncertainty",
        "Being judged": "judgment",
        "Making a mistake": "mistake"
    }),
    SurveyQuestion(prompt: "What helped or could have helped?", options: {
        "Reassurance": "reassurance",
        "Distraction or activity": "distraction",
        "Talking to someone": "talking"
    }),
]),

"tired": EmotionTree(questions: [
    SurveyQuestion(prompt: "What made you tired?", options: {
        "Lack of sleep": "sleep",
        "Mental exhaustion": "mental",
        "Too much physical activity": "physical"
    }),
    SurveyQuestion(prompt: "Was it mostly from...", options: {
        "Work or responsibilities": "work",
        "Emotional burden": "emotional",
        "Health or illness": "health"
    }),
    SurveyQuestion(prompt: "What would help you most?", options: {
        "Rest and quiet": "rest",
        "Relaxing activity": "relax",
        "Support or help": "support"
    }),
]),

"neutral": EmotionTree(questions: [
    SurveyQuestion(prompt: "What caused your neutral feeling?", options: {
        "Nothing special happened": "nonevent",
        "Just a normal day": "routine",
        "Mixed or unclear emotions": "mixed"
    }),
    SurveyQuestion(prompt: "Did you feel more like...", options: {
        "Disconnected": "disconnected",
        "Calm and steady": "steady",
        "Bored or uninterested": "bored"
    }),
    SurveyQuestion(prompt: "What might shift your state?", options: {
        "Doing something creative": "creative",
        "Talking to someone": "talking",
        "Going outside": "outside"
    }),
]),

};


  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    if (_userId == null) {
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', _userId!);
    }
    setState(() {}); // to refresh UI with userId
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emotion Survey"),
        leading: currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    currentStep--;
                    answers.removeLast();
                  });
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: selectedEmotion == null
                ? _buildEmotionSelector()
                : _buildSurveyStep(),
          ),
          if (_userId != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Text(
                "ID: $_userId",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmotionSelector() {
    const emotions = {
      "😊": "happy",
      "😢": "sad",
      "😠": "angry",
      "😐": "neutral",
      "😰": "anxious",
      "😴": "tired"
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("How did you feel today?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: emotions.entries.map((entry) {
            return ChoiceChip(
              label: Text(entry.key),
              selected: selectedEmotion == entry.value,
              onSelected: (_) {
                if (!emotionSurveyMap.containsKey(entry.value)) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Error"),
                      content: Text("Survey for '${entry.value}' not available yet."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                } else {
                  setState(() {
                    selectedEmotion = entry.value;
                    currentStep = 0;
                    answers.clear();
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSurveyStep() {
    final tree = emotionSurveyMap[selectedEmotion]!;
    final question = tree.questions[currentStep];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.prompt,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: question.options.entries.map((entry) {
            return ChoiceChip(
              label: Text(entry.key),
              selected: false,
              onSelected: (_) {
                setState(() {
                  answers.add(entry.value);
                  if (currentStep < tree.questions.length - 1) {
                    currentStep++;
                  } else {
                    _submitSurvey();
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _submitSurvey() async {
    if (selectedEmotion == null || answers.isEmpty || _userId == null) return;

    final payload = {
      "user_id": _userId,
      "emotion": selectedEmotion,
      "answers": answers,
    };

    debugPrint("🚀 Sending survey: $payload");

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/survey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Survey saved: ${response.body}");
      } else {
        debugPrint("❌ Survey failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Network error: $e");
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("📝 Survey Completed"),
          content: const Text(
            "Thank you for checking in with yourself today 💙\n\n"
            "Feel free to come back later if you want to reflect more 🌱"
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.popUntil(context, ModalRoute.withName('/')),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
