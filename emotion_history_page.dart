import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mindmirror_app/config.dart';

class EmotionHistoryPage extends StatefulWidget {
  final String userId;
  const EmotionHistoryPage({super.key, required this.userId});

  @override
  _EmotionHistoryPageState createState() => _EmotionHistoryPageState();
}

class _EmotionHistoryPageState extends State<EmotionHistoryPage> {
  Map<String, List<Map<String, dynamic>>> groupedByDate = {};
  String? selectedDate;
  bool isLoading = true;
  late String _userId;

  final Map<String, String> emotionEmojis = {
    "admiration": "👏", "amusement": "😄", "anger": "😠", "annoyance": "😒",
    "approval": "👍", "caring": "🤗", "confusion": "😕", "curiosity": "🧐",
    "desire": "😍", "disappointment": "😞", "disapproval": "👎", "disgust": "🤢",
    "embarrassment": "😳", "excitement": "🤩", "fear": "😨", "gratitude": "🙏",
    "grief": "😭", "joy": "😊", "love": "❤️", "nervousness": "😬", "optimism": "🌈",
    "pride": "🏆", "realization": "💡", "relief": "😌", "remorse": "😔",
    "sadness": "😢", "surprise": "😲", "neutral": "😐"
  };

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    fetchGroupedHistory();
  }

  Future<void> fetchGroupedHistory() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/history/by-date?user_id=$_userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final raw = data['grouped_history'] as Map<String, dynamic>;

        final parsed = raw.map((date, logs) {
          final typedLogs = (logs as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          return MapEntry(date, typedLogs);
        });

        setState(() {
          groupedByDate = parsed;
          selectedDate ??= parsed.keys.isNotEmpty ? parsed.keys.last : null;
        });
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      print('Error fetching history: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = selectedDate != null && groupedByDate.containsKey(selectedDate!)
        ? groupedByDate[selectedDate!]!.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(title: const Text('📜 Emotion History')),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : groupedByDate.isEmpty
                  ? const Center(child: Text('No history found'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: const Text("Pick a date"),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2024, 1, 1),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                final key =
                                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                setState(() => selectedDate = key);
                              }
                            },
                          ),
                        ),
                        if (logs.isNotEmpty)
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: fetchGroupedHistory,
                              child: ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                children: _buildGroupedByEmotion(logs),
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text("No records found for the selected date 😶"),
                          ),
                      ],
                    ),
          Positioned(
            bottom: 8,
            right: 12,
            child: Text(
              "ID: $_userId",
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedByEmotion(List<Map<String, dynamic>> logs) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final log in logs) {
      final emotion = (log['summary'] ?? 'neutral').toString().toLowerCase();
      grouped.putIfAbsent(emotion, () => []).add(log);
    }

    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return sorted.map((entry) {
      final emotion = entry.key;
      final emoji = emotionEmojis[emotion] ?? "❓";
      final entries = entry.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$emoji ${emotion[0].toUpperCase()}${emotion.substring(1)}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...entries.map((log) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🧍 ${log['user_message']}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("🤖 ${log['bot_reply']}"),
                    const SizedBox(height: 6),
                    Text("🕒 ${log['timestamp']}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],
      );
    }).toList();
  }
}
