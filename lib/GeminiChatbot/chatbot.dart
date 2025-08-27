import 'dart:io';
import 'dart:math';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _speechText = "";

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
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

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
    return Stack(
      children: [
        DashChat(
          inputOptions: InputOptions(
            alwaysShowSend: true,
            leading: [
              IconButton(icon: const Icon(Icons.image), onPressed: _sendMedia),
            ],
            autocorrect: true,
            cursorStyle: CursorStyle(color: Colors.blue),
          ),
          currentUser: currentUser,
          onSend: _onSendMessage,
          messages: messages,
        ),
        Positioned(
          bottom: 7,
          right: 45,
          child: IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.green : Colors.red,
            ),
            onPressed: _listen,
          ),
        ),
      ],
    );
  }

  /// Speech Recognition Start/Stop
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (kDebugMode) print("STATUS: $status");
          if (status == "done") {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          if (kDebugMode) print("ERROR: $error");
          setState(() {
            _isListening = false;
          });
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _speechText = val.recognizedWords;
            });

            // Automatically put recognized text into input
            if (val.finalResult && _speechText.isNotEmpty) {
              ChatMessage msg = ChatMessage(
                user: currentUser,
                createdAt: DateTime.now(),
                text: _speechText,
              );
              _onSendMessage(msg);
            }
          },
        );
      } else {
        if (kDebugMode) print("Speech recognition not available");
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
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
            if (kDebugMode) print("Gemini full response: $fullResponse");

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
            if (kDebugMode)
              print("ERROR WHILE USER SEND MESSAGE : ${e.toString()}");
          },
        );
  }

  void _sendMedia() async {
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
      if (kDebugMode) print("Selected image path: ${image.path}");
    } else {
      if (kDebugMode) print("No image selected");
    }
  }
}
