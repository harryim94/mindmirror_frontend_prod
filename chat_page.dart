import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emotion_history_page.dart';
import 'insightme.dart';
import 'package:mindmirror_app/config.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  const ChatPage({super.key, required this.userId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  Uint8List? _pendingImageBytes;
  html.File? _pendingImageFile;

  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _loadTodayChatHistory();
  }

  Future<void> _loadTodayChatHistory() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final res = await http.get(Uri.parse(
          '${AppConfig.baseUrl}/history/by-date?user_id=$_userId&date=$today'));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final grouped = json['grouped_history'] as Map<String, dynamic>;
        final List<dynamic> allChatEntries = [];

        if (grouped.containsKey(today)) {
          final entries = grouped[today];
          for (final entry in entries) {
            if (entry['source'] == 'chat') {
              allChatEntries.add(entry);
            }
          }
        }

        setState(() {
          _messages.clear();
          for (final entry in allChatEntries) {
            _messages.add({'role': 'user', 'text': entry["user_message"] ?? ""});
            _messages.add({'role': 'bot', 'text': entry["bot_reply"] ?? ""});
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Failed to load chat history: $e");
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage(String text) async {
    if (_pendingImageFile != null) {
      setState(() => _isLoading = true);

      final reader = html.FileReader();
      reader.readAsArrayBuffer(_pendingImageFile!);
      await reader.onLoad.first;

      final data = reader.result as List<int>;
      final uri = Uri.parse('${AppConfig.baseUrl}/upload_chat_image');
      final request = http.MultipartRequest("POST", uri);
      request.fields['user_id'] = _userId!;
      request.files.add(http.MultipartFile.fromBytes('file', data,
          filename: _pendingImageFile!.name));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final result = json.decode(body);

      final reply = result['reply'] ?? 'No response from MindMirror.';

      setState(() {
        _messages.add({
          'role': 'user_image',
          'text': '',
          'imageBytes': base64Encode(_pendingImageBytes!)
        });
        _messages.add({'role': 'bot', 'text': reply});
        _pendingImageBytes = null;
        _pendingImageFile = null;
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _userId, 'message': text}),
      );

      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        final reply = parsed['response'] ?? 'Something went wrong.';
        setState(() {
          _messages.add({'role': 'bot', 'text': reply});
        });
      } else {
        setState(() {
          _messages.add({'role': 'bot', 'text': 'A server error occurred.'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'No response from the server.'});
      });
    } finally {
      setState(() => _isLoading = false);
      _controller.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('MindMirror', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Emotion History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmotionHistoryPage(userId: _userId!),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: "InsightMe",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InsightMePage(userId: _userId!),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    final isBot = msg['role'] == 'bot';
                    final isImage = msg['role'] == 'user_image';

                    if (isImage && msg.containsKey('imageBytes')) {
                      final imageData = base64Decode(msg['imageBytes']!);
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.memory(imageData, width: 200),
                        ),
                      );
                    }

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg['text'] ?? ''),
                      ),
                    );
                  },
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () async {
                        html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
                        uploadInput.accept = 'image/*';
                        uploadInput.click();

                        uploadInput.onChange.listen((e) async {
                          final file = uploadInput.files!.first;
                          final reader = html.FileReader();

                          reader.readAsArrayBuffer(file);
                          await reader.onLoad.first;

                          final bytes = reader.result as Uint8List;

                          setState(() {
                            _pendingImageBytes = bytes;
                            _pendingImageFile = file;
                          });
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_pendingImageBytes != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  Image.memory(_pendingImageBytes!, height: 100),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _pendingImageBytes = null;
                                          _pendingImageFile = null;
                                        });
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TextField(
                            controller: _controller,
                            onSubmitted: sendMessage,
                            decoration: const InputDecoration(
                              hintText: 'Share your thoughts...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => sendMessage(_controller.text),
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_userId != null)
            Positioned(
              bottom: 4,
              right: 12,
              child: Text(
                "ID: $_userId",
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
