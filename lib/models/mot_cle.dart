/// Modèle de données représentant un mot-clé avec support multilingue.
///
/// Cette classe correspond à l'entité "mot_cle" dans la base de données
/// et sert de modèle pour manipuler les données des mots-clés associés à une taxe.
class MotCle {
  /// Identifiant unique du mot-clé (auto-généré par la base de données)
  final int id;

  /// Identifiant du concept associé
  final String conceptoId;

  /// Mot-clé
  final String motCle;

  /// Code de langue du mot-clé
  final String langCode;

  /// Langue par défaut à utiliser
  static const String langueParDefaut = 'es';

  /// Constructeur
  MotCle({
    required this.id,
    required this.conceptoId,
    required this.motCle,
    required this.langCode,
  });

  /// Crée une instance de MotCle à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet MotCle.
  factory MotCle.fromMap(Map<String, dynamic> map) {
    return MotCle(
      id: map['id'],
      conceptoId: map['concepto_id'],
      motCle: map['mot_cle'],
      langCode: map['lang_code'] ?? langueParDefaut,
    );
  }

  /// Crée une instance de MotCle à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet MotCle.
  factory MotCle.fromJson(Map<String, dynamic> json) {
    return MotCle(
      id: json['id'] ?? 0,
      conceptoId: json['concepto_id'],
      motCle: json['mot_cle'],
      langCode: json['lang_code'] ?? langueParDefaut,
    );
  }

  /// Convertit cette instance en Map.
  ///
  /// Cette méthode est utilisée pour préparer l'objet à être stocké
  /// dans la base de données.
  Map<String, dynamic> toMap() {
    return {
      'id': id != 0 ? id : null, // Ne pas inclure l'ID s'il n'est pas défini
      'concepto_id': conceptoId,
      'mot_cle': motCle,
      'lang_code': langCode,
    };
  }

  /// Convertit cette instance en Map JSON.
  ///
  /// Cette méthode est utilisée pour sérialiser l'objet en JSON.
  Map<String, dynamic> toJson() {
    return toMap();
  }

  /// Crée une copie de cette instance avec les champs spécifiés remplacés.
  ///
  /// Cette méthode est utile pour créer une version modifiée d'un objet
  /// sans altérer l'original.
  MotCle copyWith({
    int? id,
    String? conceptoId,
    String? motCle,
    String? langCode,
  }) {
    return MotCle(
      id: id ?? this.id,
      conceptoId: conceptoId ?? this.conceptoId,
      motCle: motCle ?? this.motCle,
      langCode: langCode ?? this.langCode,
    );
  }

  @override
  String toString() {
    return 'MotCle{id: $id, conceptoId: $conceptoId, motCle: $motCle, langCode: $langCode}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MotCle &&
        other.id == id &&
        other.conceptoId == conceptoId &&
        other.motCle == motCle &&
        other.langCode == langCode;
  }

  @override
  int get hashCode =>
      id.hashCode ^ conceptoId.hashCode ^ motCle.hashCode ^ langCode.hashCode;
}

/// Classe utilitaire pour gérer des groupes de mots-clés multilingues
class MotsClesMultilingues {
  /// Map des mots-clés par langue
  final Map<String, List<String>> motsClesByLang;

  /// Identifiant du concept associé
  final String conceptoId;

  /// Langue par défaut à utiliser
  static const String langueParDefaut = 'es';

  /// Constructeur
  MotsClesMultilingues({
    required this.conceptoId,
    required this.motsClesByLang,
  });

  /// Crée un objet MotsClesMultilingues à partir d'une liste de MotCle
  factory MotsClesMultilingues.fromMotsCles(List<MotCle> motsCles) {
    final Map<String, List<String>> motsClesByLang = {};
    final String conceptoId =
        motsCles.isNotEmpty ? motsCles.first.conceptoId : '';

    for (final motCle in motsCles) {
      if (!motsClesByLang.containsKey(motCle.langCode)) {
        motsClesByLang[motCle.langCode] = [];
      }
      motsClesByLang[motCle.langCode]!.add(motCle.motCle);
    }

    return MotsClesMultilingues(
      conceptoId: conceptoId,
      motsClesByLang: motsClesByLang,
    );
  }

  /// Crée un objet MotsClesMultilingues à partir d'un objet JSON
  ///
  /// Supporte à la fois le format chaîne (ancien) et le format objet/tableau (nouveau)
  factory MotsClesMultilingues.fromJson(String conceptoId, dynamic json) {
    final Map<String, List<String>> motsClesByLang = {};

    if (json is String) {
      // Ancien format : chaîne simple séparée par des virgules (considérée comme espagnol)
      motsClesByLang[langueParDefaut] = json
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json is Map) {
      // Nouveau format : objet avec codes de langue
      json.forEach((key, value) {
        if (value is String) {
          // Chaîne séparée par des virgules
          motsClesByLang[key] = value
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else if (value is List) {
          // Tableau de mots-clés
          motsClesByLang[key] = value
              .where((e) => e is String && e.isNotEmpty)
              .map((e) => e.toString())
              .toList();
        }
      });
    }

    return MotsClesMultilingues(
      conceptoId: conceptoId,
      motsClesByLang: motsClesByLang,
    );
  }

  /// Obtient les mots-clés dans la langue spécifiée
  List<String> getMotsCles(String langCode) {
    return motsClesByLang[langCode] ??
        motsClesByLang[langueParDefaut] ??
        (motsClesByLang.isNotEmpty ? motsClesByLang.values.first : []);
  }

  /// Obtient les mots-clés sous forme de chaîne séparée par des virgules
  String getMotsClesAsString(String langCode) {
    return getMotsCles(langCode).join(', ');
  }

  /// Vérifie si des mots-clés existent pour une langue spécifique
  bool hasMotsClesForLanguage(String langCode) {
    return motsClesByLang.containsKey(langCode) &&
        motsClesByLang[langCode]!.isNotEmpty;
  }

  /// Convertit en liste de MotCle pour stockage en base de données
  List<MotCle> toMotsCles() {
    final List<MotCle> result = [];

    motsClesByLang.forEach((langCode, motsCles) {
      for (final motCle in motsCles) {
        result.add(MotCle(
          id: 0, // ID sera généré par la base de données
          conceptoId: conceptoId,
          motCle: motCle,
          langCode: langCode,
        ));
      }
    });

    return result;
  }

  /// Convertit en Map pour sérialisation JSON
  Map<String, dynamic> toJson() {
    return motsClesByLang;
  }

  /// Ajoute ou met à jour les mots-clés pour une langue spécifique
  MotsClesMultilingues withMotsCles(String langCode, List<String> motsCles) {
    final newMotsClesByLang = Map<String, List<String>>.from(motsClesByLang);
    newMotsClesByLang[langCode] = motsCles;

    return MotsClesMultilingues(
      conceptoId: conceptoId,
      motsClesByLang: newMotsClesByLang,
    );
  }

  /// Ajoute un mot-clé pour une langue spécifique
  MotsClesMultilingues addMotCle(String langCode, String motCle) {
    final newMotsClesByLang = Map<String, List<String>>.from(motsClesByLang);

    if (!newMotsClesByLang.containsKey(langCode)) {
      newMotsClesByLang[langCode] = [];
    }

    // Vérifier que le mot-clé n'existe pas déjà
    if (!newMotsClesByLang[langCode]!.contains(motCle)) {
      newMotsClesByLang[langCode]!.add(motCle);
    }

    return MotsClesMultilingues(
      conceptoId: conceptoId,
      motsClesByLang: newMotsClesByLang,
    );
  }

  /// Supprime un mot-clé pour une langue spécifique
  MotsClesMultilingues removeMotCle(String langCode, String motCle) {
    if (!motsClesByLang.containsKey(langCode)) {
      return this;
    }

    final newMotsClesByLang = Map<String, List<String>>.from(motsClesByLang);
    newMotsClesByLang[langCode] =
        newMotsClesByLang[langCode]!.where((m) => m != motCle).toList();

    // Si la liste est vide, supprimer l'entrée de langue
    if (newMotsClesByLang[langCode]!.isEmpty) {
      newMotsClesByLang.remove(langCode);
    }

    return MotsClesMultilingues(
      conceptoId: conceptoId,
      motsClesByLang: newMotsClesByLang,
    );
  }

  @override
  String toString() {
    return 'MotsClesMultilingues{conceptoId: $conceptoId, motsClesByLang: $motsClesByLang}';
  }
}
