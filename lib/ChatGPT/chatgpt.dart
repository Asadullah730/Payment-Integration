import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:payment_integration/ChatGPT/gptmethods.dart';

class ChatScreen extends StatefulWidget {
  final String apiKey;

  const ChatScreen({required this.apiKey, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> messages = [];
  final ChatUser user = ChatUser(id: 'user');
  final ChatUser bot = ChatUser(id: 'bot', firstName: 'AI');
  late OpenAIService openAI;

  @override
  void initState() {
    super.initState();
    openAI = OpenAIService(widget.apiKey);
  }

  void handleSend(ChatMessage message) async {
    setState(() => messages.insert(0, message));

    final botReply = await openAI.sendMessage(message.text);

    final response = ChatMessage(
      text: botReply,
      user: bot,
      createdAt: DateTime.now(),
    );

    setState(() => messages.insert(0, response));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat with OpenAI")),
      body: DashChat(
        currentUser: user,
        onSend: handleSend,
        messages: messages,
        inputOptions: const InputOptions(alwaysShowSend: true),
      ),
    );
  }
}
