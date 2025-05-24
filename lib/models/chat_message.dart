/// Modèle de données représentant un message dans la conversation du chatbot.
class ChatMessage {
  /// Texte du message
  final String text;

  /// Indique si le message provient de l'utilisateur (true) ou du chatbot (false)
  final bool isUser;

  /// Horodatage du message
  final DateTime timestamp;

  /// Métadonnées additionnelles (intent, concept, erreur, etc.)
  final Map<String, dynamic>? metadata;

  /// Constructeur
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.metadata,
  });

  /// Crée une copie du message avec les champs spécifiés remplacés
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ChatMessage{text: $text, isUser: $isUser, timestamp: $timestamp, metadata: $metadata}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        _mapsEqual(other.metadata, metadata);
  }

  /// Utilitaire pour comparer deux maps
  bool _mapsEqual(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode =>
      text.hashCode ^ isUser.hashCode ^ timestamp.hashCode ^ metadata.hashCode;
}
