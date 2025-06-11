import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mindmirror_app/config.dart';


class ExternalLogPage extends StatefulWidget {
  const ExternalLogPage({super.key});

  @override
  State<ExternalLogPage> createState() => _ExternalLogPageState();
}

class _ExternalLogPageState extends State<ExternalLogPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> submitExternalLog() async {
    if (_textController.text.isEmpty) {
      setState(() => _statusMessage = 'Please paste the conversation log.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/external_log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'external_log',
          'raw_text': _textController.text,
          'tag': _tagController.text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = '✅ Log saved successfully!';
          _textController.clear();
          _tagController.clear();
        });
      } else {
        setState(() => _statusMessage = '❌ Failed to save log.');
      }
    } catch (e) {
      setState(() => _statusMessage = '⚠️ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📥 External Chat Log')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "📌 Guide: Ask your chatbot to summarize your emotions and personality from past conversations.",
              ),
              const SizedBox(height: 8),
              const Text(
                '💬 Copy-paste response here and optionally add a tag (e.g., "GPT 대화" or "연애고민").',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _textController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Paste external conversation summary here',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Tag (optional)',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : submitExternalLog,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('📤 Save Log'),
              ),
              const SizedBox(height: 16),
              if (_statusMessage.isNotEmpty)
                Text(
                  _statusMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
