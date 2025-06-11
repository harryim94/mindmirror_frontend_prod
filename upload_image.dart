import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mindmirror_app/config.dart';

class UploadChatImageScreen extends StatefulWidget {
  @override
  _UploadChatImageScreenState createState() => _UploadChatImageScreenState();
}

class _UploadChatImageScreenState extends State<UploadChatImageScreen> {
  File? _image;
  String? _extractedText;
  String? _emotion;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _extractedText = null;
        _emotion = null;
      });
      await _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id") ?? "unknown_user";

    final uri = Uri.parse("${AppConfig.baseUrl}/upload_chat_image");
    final request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    request.fields['user_id'] = userId;  // ✅ Add this line

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final data = json.decode(body);

        setState(() {
          _extractedText = data['text'];
          _emotion = data['summary'] ?? "None";
        });
      } else {
        setState(() {
          _extractedText = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _extractedText = "Upload failed: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🖼 Upload Chat Screenshot")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: const Text("Select Screenshot"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 20),
            if (_image != null) Image.file(_image!, height: 220),
            if (_loading) const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            ),
            if (_extractedText != null && !_loading) ...[
              const SizedBox(height: 24),
              const Text("📝 Extracted Text:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_extractedText ?? "", style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Text("💡 Detected Emotion: $_emotion",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}
