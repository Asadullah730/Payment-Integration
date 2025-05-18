import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(
    id: '0',
    firstName: 'User',
    // profileImage: 'https://example.com/user_profile_image.png',
  );

  ChatUser geminiUser = ChatUser(
    id: '1',
    firstName: 'Gemini',
    // profileImage: 'https://example.com/gemini_profile_image.png',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gemini Chatbot',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      currentUser: currentUser,
      onSend: _onSendMessage,
      messages: messages,
    );
  }

  void _onSendMessage(ChatMessage chatmessage) {
    setState(() {
      messages = [chatmessage, ...messages];
    });

    try {
      String question = chatmessage.text;
      gemini.streamGenerateContent(question).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
        } else {
          String response =
              event.content?.parts?.fold<String>(
                "",
                (previous, current) => "$previous${(current as TextPart).text}",
              ) ??
              "";
          ChatMessage newMessage = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: response,
          );

          setState(() {
            messages = [newMessage, ...messages];
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("ERROR WHILE USER SEND MESSAGE : ${e.toString()}");
      }
    }
  }
}
