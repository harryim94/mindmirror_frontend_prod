import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'insight_trends.dart';
import 'pie_chart_widget.dart';
import 'package:mindmirror_app/config.dart';

class InsightMePage extends StatefulWidget {
  final String userId;
  const InsightMePage({super.key, required this.userId});

  @override
  State<InsightMePage> createState() => _InsightMePageState();
}

class _InsightMePageState extends State<InsightMePage> {
  Map<String, double> dailyMoodData = {};
  Map<String, dynamic>? summary;
  String coachingMessage = "";
  late String userId;
  bool _loading = true;

  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    endDate = DateTime(today.year, today.month, today.day);
    startDate = endDate.subtract(const Duration(days: 6));
    userId = widget.userId;
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchInsightSummary(start: startDate, end: endDate);
    await fetchCoachingMessage(start: startDate, end: endDate);
  }

  // 날짜를 로컬 기준 yyyy-MM-dd 문자열로 만들어 요청
  String _formatDateString(DateTime dt) {
    return "${dt.year.toString().padLeft(4,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";
  }

  Future<void> fetchInsightSummary({required DateTime start, required DateTime end}) async {
    final startStr = _formatDateString(start);
    final endStr = _formatDateString(end);

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/insight/summary?user_id=$userId&start=$startStr&end=$endStr'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      setState(() {
        summary = decoded["summary"];
        dailyMoodData = Map<String, double>.from(
          (decoded["mood"] as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
        );
        print("Loaded summary: $summary");
        print("Loaded dailyMoodData: $dailyMoodData");
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> fetchCoachingMessage({required DateTime start, required DateTime end}) async {
    final startStr = _formatDateString(start);
    final endStr = _formatDateString(end);

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/insight/coaching?user_id=$userId&start_date=$startStr&end_date=$endStr'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['coaching_message'];
        setState(() {
          coachingMessage = message ?? "No personalized insight available.";
        });
      } else {
        setState(() {
          coachingMessage = "No personalized insight available.";
        });
      }
    } catch (e) {
      setState(() {
        coachingMessage = "Failed to fetch insight.";
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        _loading = true;
      });
      await fetchInsightSummary(start: picked.start, end: picked.end);
      await fetchCoachingMessage(start: picked.start, end: picked.end);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}";
  }

  Widget buildCoachingMessageBox() {
    if (coachingMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              coachingMessage,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmotionStats() {
    if (summary == null ||
        summary!["top_emotions"] == null ||
        summary!["top_emotions"].isEmpty) {
      return const Text("No emotion data available.");
    }

    final emotions = List<Map<String, dynamic>>.from(summary!["top_emotions"]);
    final total = summary!["total_entries"] ?? 0;
    final mostFrequent = summary!["most_frequent"] ?? "none";
    final colors = [
      Colors.pink,
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Total Records: $total", style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text("Most Frequent: $mostFrequent", style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(emotions.length, (i) {
                final e = emotions[i];
                final color = colors[i % colors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        "${e["emotion"]} (${e["count"]} times, ${e["percentage"]}%)",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(width: 35),
            SizedBox(
              width: 110,
              height: 110,
              child: EmotionPieChart(
                emotionData: emotions,
                total: total,
                colors: colors,
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🧠 InsightMe - Emotion Summary")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SizedBox.expand(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            "${_formatDate(startDate)} - ${_formatDate(endDate)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text("📊 Emotion Statistics",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      buildEmotionStats(),
                      const SizedBox(height: 24),
                      const Text("📈 Mood Trend",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      dailyMoodData.isNotEmpty
                          ? DailyMoodChart(moodData: dailyMoodData)
                          : const Text("No mood data to display."),
                      const SizedBox(height: 24),
                      const Text("🧠 Emotion Insight Summary",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      buildCoachingMessageBox(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text(
                      "User ID: $userId",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
