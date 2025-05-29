import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chatbot_service.dart';
import '../services/localization_service.dart';
// import '../models/chat_message.dart'; // Not directly used here, MessageBubble handles ChatMessage
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/chat_input.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late final ChatbotService _chatbotService;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Assuming ChatbotService is a ChangeNotifier and provided above this widget.
    // For direct instance usage as per instructions:
    _chatbotService = ChatbotService.instance; 
    _scrollController = ScrollController();

    // Add listener to ChatbotService (which is a ChangeNotifier)
    _chatbotService.addListener(_onChatbotServiceChanged);
    
    // Initial scroll to bottom if messages are already present (e.g. loaded from history)
    // Needs to be post-frame to ensure layout is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _chatbotService.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });
  }

  void _onChatbotServiceChanged() {
    // This method will be called when ChatbotService notifies its listeners.
    // We can check if new messages were added or if processing state changed.
    // For now, simply scroll to bottom, assuming any notification might mean new messages.
    // More sophisticated logic could check message count changes.
    _scrollToBottom();
  }

  @override
  void dispose() {
    _chatbotService.removeListener(_onChatbotServiceChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Schedule the scroll for after the current frame is built
      // This ensures that the ListView has updated its layout with new items
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) { // Check again in case it was disposed during the frame
            _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using Provider.of<ChatbotService>(context, listen: false) for sending messages
    // and Consumer<ChatbotService> for reactive UI updates.
    // However, the subtask said "use ChatbotService.instance for now".
    // I will stick to _chatbotService (which is ChatbotService.instance) for sending messages
    // and use Consumer<ChatbotService> for reactive parts as specified.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant TaxasGE'), // Localization will be handled later
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Consumer<ChatbotService>(
              builder: (context, chatbotService, child) {
                // The listener _onChatbotServiceChanged should handle scrolling.
                // If messages are added, the consumer rebuilds, and the listener is notified.
                // An explicit call to _scrollToBottom() here might be redundant or cause too many scrolls.
                // However, if the list rebuilds due to message changes, it's a good place to ensure.
                // Let's rely on the listener primarily, but this ensures if Consumer rebuilds due to messages, we scroll.
                // This was also mentioned in previous attempt, let's ensure it's efficient.
                // The listener on _chatbotService should be sufficient.
                // This will trigger a scroll on *every* rebuild of this consumer, which might be too often.
                // The listener `_onChatbotServiceChanged` is more targeted.
                // However, if initial messages are loaded and the listener isn't triggered for that specific event,
                // scrolling on first build with messages is useful. This is now handled in initState.
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: chatbotService.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatbotService.messages[index];
                    // Assuming LocalizationService is a ChangeNotifier and provided.
                    // Or using instance directly as per instructions for ChatbotService.
                    final langService = Provider.of<LocalizationService>(context);
                    return MessageBubble(
                      chatMessage: message,
                      currentLang: langService.currentLanguage,
                    );
                  },
                );
              },
            ),
          ),
          Consumer<ChatbotService>(
            builder: (context, chatbotService, child) {
              if (chatbotService.isProcessing) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.0),
                      SizedBox(width: 8.0),
                      Text("L'assistant réfléchit..."), // Localization later
                    ],
                  ),
                );
              } else if (chatbotService.getSuggestions().isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    alignment: WrapAlignment.start,
                    children: chatbotService.getSuggestions().map((suggestion) {
                      return ActionChip(
                        label: Text(suggestion),
                        onPressed: () => _chatbotService.sendMessage(suggestion), // Use _chatbotService as per instruction
                      );
                    }).toList(),
                  ),
                );
              } else {
                return const SizedBox.shrink(); // No suggestions, no processing indicator
              }
            },
          ),
          ChatInput(
            onSendMessage: (message) async {
              await _chatbotService.sendMessage(message); // Use _chatbotService as per instruction
            },
          ),
        ],
      ),
    );
  }
}
