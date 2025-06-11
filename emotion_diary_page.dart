import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mindmirror_app/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryPage extends StatefulWidget {
  final String userId;
  const DiaryPage({super.key, required this.userId});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final TextEditingController _controller = TextEditingController();
  String? _userId;
  DateTime _selectedDate = DateTime.now();
  bool _isEditing = true;
  bool _isSaving = false;
  String? _currentEmotion;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadDiary();
  }

  Future<void> _initUserAndLoadDiary() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? widget.userId;
    _loadDiaryForDate(_selectedDate);
  }

  Future<void> _loadDiaryForDate(DateTime date) async {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse('${AppConfig.baseUrl}/diary/by-date?user_id=$_userId&date=$formatted');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body["user_message"] != null) {
        _controller.text = body["user_message"];
        _currentEmotion = body["summary"];
        _isEditing = _isToday(date);
      } else {
        _controller.clear();
        _currentEmotion = null;
        _isEditing = _isToday(date);
      }
    } else {
      _controller.clear();
      _currentEmotion = null;
      _isEditing = _isToday(date);
    }

    setState(() {});
  }

  Future<void> _submitDiary() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Nothing to Save"),
          content: const Text("Please write something before saving your reflection."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/diary/submit?date=$dateString'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "message": text,
        "user_id": _userId,
      }),
    );

    setState(() => _isSaving = false);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      _currentEmotion = body["emotion"];

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Saved", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Your reflection was saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              )
            ],
          );
        },
      );
    } else {
      // 실패 시 간단히 알림
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text("Failed to save diary. (${res.statusCode})"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              )
            ],
          );
        },
      );
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _selectedDate = picked;
      _isEditing = _isToday(picked);
      _loadDiaryForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat.yMMMMd().format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🌙 Emotional Diary"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Text(
                    "Date · $today",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  maxLines: 12,
                  readOnly: !_isEditing,
                  decoration: InputDecoration(
                    hintText: _isEditing ? "Write from your heart..." : "",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_isEditing && !_isToday(_selectedDate))
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _isEditing = true);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit this memory"),
                    ),
                  ),
                if (_isEditing)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submitDiary,
                      icon: const Icon(Icons.save),
                      label: Text(_isSaving ? "Saving..." : "Save My Reflection"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if ((_userId ?? widget.userId).isNotEmpty)
            Positioned(
              bottom: 8,
              right: 12,
              child: Text(
                "ID: ${_userId ?? widget.userId}",
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
}
