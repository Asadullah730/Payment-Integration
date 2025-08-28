import 'dart:io';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
    firstName: ' Tinni Response',
    profileImage: 'assets/images/asad.jpg',
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0XFF222222),
        appBar: AppBar(
          title: const Text(
            'Tinni Chatbot',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0XFF2C2C2C),
        ),
        body: _buildUI(),
      ),
    );
  }

  Widget _buildUI() {
    final size = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: DashChat(
                messageListOptions: MessageListOptions(
                  dateSeparatorBuilder: (date) {
                    String formattedDate = DateFormat(
                      'MMMM dd, yyyy',
                    ).format(date);

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: constraints.maxHeight * 0.01,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.7,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: constraints.maxHeight * 0.004,
                              horizontal: constraints.maxWidth * 0.03,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0XFF2D2D2D),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              formattedDate,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: constraints.maxWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                inputOptions: InputOptions(
                  inputTextStyle: const TextStyle(color: Colors.white),
                  cursorStyle: const CursorStyle(color: Colors.greenAccent),
                  inputDecoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF121B22),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: size.height * 0.012,
                      horizontal: size.width * 0.04,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    hintText: "Say Something to Tinni...",
                    hintStyle: TextStyle(
                      color: Colors.white70,
                      fontSize: size.width * 0.04,
                    ),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.camera),
                      onPressed: _sendMedia,
                      iconSize: size.width * 0.07,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.green : Colors.white54,
                        size: size.width * 0.075,
                      ),
                      onPressed: _listen,
                    ),
                  ),
                  autocorrect: true,
                ),
                currentUser: currentUser,
                onSend: _onSendMessage,
                messages: messages,
                messageOptions: const MessageOptions(
                  showTime: true,
                  currentUserTimeTextColor: Colors.white,
                  currentUserContainerColor: Color(0XFF005C4B),
                  currentUserTextColor: Colors.white,
                  containerColor: Color(0XFF353535),

                  textColor: Colors.white,
                  // showCurrentUserAvatar: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
          if (kDebugMode) {
            print("ERROR: $error");
          }
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
        if (kDebugMode) {
          print("Speech recognition not available");
        }
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
            if (kDebugMode) print("Tinni full response: $fullResponse");

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
      if (kDebugMode) {
        print("Selected image path: ${image.path}");
      }
    } else {
      if (kDebugMode) {
        print("No image selected");
      }
    }
  }
}
