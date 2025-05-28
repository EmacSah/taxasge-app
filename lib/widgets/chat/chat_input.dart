import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Future<void> Function(String message) onSendMessage;

  const ChatInput({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late final TextEditingController _textController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String message = _textController.text.trim();
    if (message.isNotEmpty && !_isSending) {
      setState(() {
        _isSending = true;
      });

      try {
        await widget.onSendMessage(message);
        _textController.clear();
      } finally {
        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText:
                    'Écrire un message...', // This will be localized later
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  // Adding some padding inside the text field
                ),
                filled:
                    true, // To make the background color visible if specified in theme
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: (_isSending || _textController.text.trim().isEmpty)
                ? null
                : _sendMessage,
            tooltip: 'Envoyer', // This will be localized later
          ),
        ],
      ),
    );
  }
}
