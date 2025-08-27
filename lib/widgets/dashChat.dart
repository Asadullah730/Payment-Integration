import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

Widget buildUI(_sendMedia, currentUser, _onSendMessage, messages) {
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
