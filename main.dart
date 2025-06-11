import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'chat_page.dart';
import 'homepage.dart';
import 'emotion_survey.dart';
import 'emotion_diary_page.dart';
import 'insightme.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

String? globalUserId;

Future<void> initUserId() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey("user_id")) {
    final uuid = const Uuid().v4();
    await prefs.setString("user_id", uuid);
  }
  globalUserId = prefs.getString("user_id");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initUserId(); // ✅ user_id 초기화
  runApp(const MindMirrorApp());
}

class MindMirrorApp extends StatelessWidget {
  const MindMirrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: Stack(
        children: [
          HomePage(userId: globalUserId!), // ✅ userId 넘김
          Positioned(
            bottom: 8,
            right: 8,
            child: Opacity(
              opacity: 0.5,
              child: Text(
                "🆔 $globalUserId",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      routes: {
        '/chat': (context) => ChatPage(userId: globalUserId!),      // ✅ 수정
        '/survey': (context) => EmotionSurveyPage(userId: globalUserId!), // ✅ 수정
        '/diary': (context) => DiaryPage(userId: globalUserId!),    // ✅ 수정
        '/insight': (context) => InsightMePage(userId: globalUserId!), // ✅ 수정
      },
    );
  }
}
