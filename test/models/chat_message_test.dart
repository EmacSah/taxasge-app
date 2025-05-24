import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('création avec paramètres minimaux', () {
      final message = ChatMessage(
        text: 'Test message',
        isUser: true,
        timestamp: DateTime(2025, 1, 1),
      );

      expect(message.text, 'Test message');
      expect(message.isUser, true);
      expect(message.timestamp, DateTime(2025, 1, 1));
      expect(message.metadata, null);
    });

    test('création avec métadonnées', () {
      final metadata = {'intent': 'test', 'concept': 'passeport'};
      final message = ChatMessage(
        text: 'Test message',
        isUser: false,
        timestamp: DateTime(2025, 1, 1),
        metadata: metadata,
      );

      expect(message.metadata, metadata);
    });

    test('copyWith crée une nouvelle instance avec les modifications', () {
      final original = ChatMessage(
        text: 'Original',
        isUser: true,
        timestamp: DateTime(2025, 1, 1),
      );

      final copied = original.copyWith(
        text: 'Modified',
        isUser: false,
      );

      expect(copied.text, 'Modified');
      expect(copied.isUser, false);
      expect(copied.timestamp, original.timestamp);
      expect(copied.metadata, original.metadata);
    });

    test('equals compare correctement deux messages', () {
      final timestamp = DateTime(2025, 1, 1);
      final metadata = {'test': 'value'};

      final message1 = ChatMessage(
        text: 'Test',
        isUser: true,
        timestamp: timestamp,
        metadata: metadata,
      );

      final message2 = ChatMessage(
        text: 'Test',
        isUser: true,
        timestamp: timestamp,
        metadata: Map.from(metadata),
      );

      final message3 = ChatMessage(
        text: 'Different',
        isUser: true,
        timestamp: timestamp,
        metadata: metadata,
      );

      expect(message1 == message2, true);
      expect(message1 == message3, false);
    });

    test('toString retourne une représentation valide', () {
      final message = ChatMessage(
        text: 'Test',
        isUser: true,
        timestamp: DateTime(2025, 1, 1),
      );

      expect(message.toString(), contains('Test'));
      expect(message.toString(), contains('true'));
    });
  });
}
