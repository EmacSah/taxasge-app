import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message.dart';
import '../../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage chatMessage;
  final String currentLang;

  const MessageBubble({
    super.key,
    required this.chatMessage,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUserMessage = chatMessage.isUser;
    final alignment =
        isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bubbleDecoration = isUserMessage
        ? AppTheme.getUserChatBubbleDecoration(currentLang)
        : AppTheme.getChatbotBubbleDecoration(currentLang);
    final textColor = isUserMessage ? Colors.white : Colors.black;

    return Row(
      mainAxisAlignment: alignment,
      children: <Widget>[
        Flexible(
          // Added Flexible here to ensure the bubble itself can flex
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Column(
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 14.0),
                  decoration: bubbleDecoration,
                  child: Text(
                    // Removed Flexible from here as the parent Container and Row handle constraints
                    chatMessage.text,
                    style: TextStyle(color: textColor),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(top: 2.0, left: 8.0, right: 8.0),
                  child: Text(
                    DateFormat.Hm(currentLang).format(chatMessage.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
