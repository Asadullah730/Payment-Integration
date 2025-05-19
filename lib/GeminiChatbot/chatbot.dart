import 'dart:io';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

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
    profileImage: 'assets/images/asad.jpg',
  );

  ChatUser geminiUser = ChatUser(
    id: '1',
    firstName: 'Gemini',
    profileImage: 'assets/images/bard.png',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gemini Chat',

          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(
        trailing: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () {
              _sendMedia();
            },
          ),
        ],
      ),
      currentUser: currentUser,
      onSend: _onSendMessage,
      messages: messages,
    );
  }

  void _onSendMessage(ChatMessage chatmessage) {
    setState(() {
      messages = [chatmessage, ...messages];
    });
    List<Uint8List>? image;
    if (chatmessage.medias != null && chatmessage.medias!.isNotEmpty) {
      image = [File(chatmessage.medias!.first.url).readAsBytesSync()];
    }

    StringBuffer responseBuffer = StringBuffer();
    gemini
        .streamGenerateContent(chatmessage.text, images: image)
        .listen(
          (event) {
            final parts = event.content?.parts;
            if (parts != null) {
              for (final part in parts) {
                if (part is TextPart) {
                  responseBuffer.write(part.text);
                }
              }
            }
          },
          onDone: () {
            String fullResponse = responseBuffer.toString().trim();

            if (kDebugMode) {
              print("Gemini full response: $fullResponse");
            }

            ChatMessage newMessage = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: fullResponse,
            );

            setState(() {
              messages = [newMessage, ...messages];
            });
          },
          onError: (e) {
            if (kDebugMode) {
              print("ERROR WHILE USER SEND MESSAGE : ${e.toString()}");
            }
          },
        );
  }

  void _sendMedia() async {
    // Implement media sending functionality here
    ImagePicker imagePicker = ImagePicker();
    XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ChatMessage mediaMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this image?",
        medias: [
          ChatMedia(type: MediaType.image, url: image.path, fileName: ''),
        ],
      );
      _onSendMessage(mediaMessage);
      print("Selected image path: ${image.path}");
    } else {
      print("No image selected");
    }
  }
}
