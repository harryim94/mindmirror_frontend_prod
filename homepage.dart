import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // RouteObserver
import 'package:mindmirror_app/config.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver, RouteAware {
  double moodScore = 0.0;
  String emoji = "😐";
  int todayEntries = 0;
  DateTime lastUpdated = DateTime.now();
  bool surveyLimitReached = false;
  String? _highlight;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    if (_userId == null) {
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', _userId!);
    }

    _fetchMood();
    _fetchHighlight();
    Timer.periodic(const Duration(seconds: 15), (_) => _fetchMood());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    _fetchMood();
    _fetchHighlight();
  }

  Future<void> _fetchMood() async {
    if (_userId == null) return;
    try {
      final today = DateTime.now();
      final todayUtc = today.toUtc();  // UTC 변환 추가
      final start = DateFormat('yyyy-MM-dd').format(todayUtc);
      final url = '${AppConfig.baseUrl}/insight/summary?start=$start&end=$start&user_id=$_userId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final mood = data['mood'] as Map<String, dynamic>;
        final todayScore = mood[start];
        final totalEntries = data['summary']['total_entries'] ?? 0;

        setState(() {
          if (todayScore != null) {
            moodScore = (todayScore as num).toDouble();
            emoji = _getEmoji(moodScore);
          }
          todayEntries = totalEntries;
          lastUpdated = DateTime.now();
          surveyLimitReached = false; // 테스트 중엔 무조건 허용
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch mood/entries: $e");
    }
  }

  Future<void> _fetchHighlight() async {
    if (_userId == null) return;
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/insight/highlight?user_id=$_userId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _highlight = data["highlight"];
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch highlight: $e");
    }
  }

  String _getEmoji(double score) {
    if (score >= 0.6) return "😁";
    if (score >= 0.3) return "😊";
    if (score > 0.0) return "🙂";
    if (score == 0.0) return "😐";
    if (score > -0.3) return "😕";
    if (score > -0.6) return "😢";
    return "😭";
  }

  String getMoodDescription(double score) {
    if (score >= 0.6) return "joy";
    if (score >= 0.3) return "slight joy";
    if (score > 0.0) return "mildly positive";
    if (score == 0.0) return "neutral";
    if (score > -0.3) return "slight sadness";
    if (score > -0.6) return "sad";
    return "deep sadness";
  }

  void _handleSurveyPressed() {
    if (surveyLimitReached) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Limit reached"),
          content: const Text("You've reached the maximum of 3 surveys today."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      Navigator.pushNamed(context, "/survey");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MindMirror")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                const Text("Hi there 👋", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("How are you feeling today?", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.emoji_emotions),
                  label: const Text("Take Emotion Survey"),
                  onPressed: _handleSurveyPressed,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Chat with MindMirror"),
                  onPressed: () => Navigator.pushNamed(context, "/chat"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: const Text("Write a Diary"),
                  onPressed: () => Navigator.pushNamed(context, "/diary"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text("📊 Today’s mood trend: ${moodScore.toStringAsFixed(2)} ($emoji ${getMoodDescription(moodScore)})",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text("📅 Today’s entries: $todayEntries",
                    style: const TextStyle(fontSize: 14, color: Colors.teal)),
                const SizedBox(height: 2),
                Text("🕘 Last updated: ${DateFormat('h:mm a').format(lastUpdated)}",
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                if (_highlight != null) ...[
                  const SizedBox(height: 20),
                  const Text("🌟 Today’s emotional highlight:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _highlight!,
                      style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton.icon(
                  icon: const Icon(Icons.insights),
                  label: const Text("View My Insights"),
                  onPressed: () => Navigator.pushNamed(context, "/insight"),
                ),
              ],
            ),
          ),
          if (_userId != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Text(
                "user: $_userId",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
