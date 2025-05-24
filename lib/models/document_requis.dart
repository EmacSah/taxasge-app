/// Modèle de données représentant un document requis avec support multilingue.
///
/// Cette classe correspond à l'entité "documento_requerido" dans la base de données
/// et sert de modèle pour manipuler les données des documents requis pour une taxe.
class DocumentRequis {
  /// Identifiant unique du document (auto-généré par la base de données)
  final int id;

  /// Identifiant du concept associé
  final String conceptoId;

  /// Nom du document avec traductions
  final Map<String, String> nombreTraductions;

  /// Description du document avec traductions (peut être null)
  final Map<String, String>? descriptionTraductions;

  /// Langue par défaut à utiliser si la langue demandée n'est pas disponible
  static const String langueParDefaut = 'es';

  /// Constructeur
  DocumentRequis({
    required this.id,
    required this.conceptoId,
    required this.nombreTraductions,
    this.descriptionTraductions,
  });

  /// Retourne le nom dans la langue spécifiée
  /// Si la langue n'est pas disponible, essaie la langue par défaut
  /// Si la langue par défaut n'est pas disponible, prend la première traduction disponible
  String getNombre(String langCode) {
    if (nombreTraductions.containsKey(langCode)) {
      return nombreTraductions[langCode]!;
    }

    if (nombreTraductions.containsKey(langueParDefaut)) {
      return nombreTraductions[langueParDefaut]!;
    }

    return nombreTraductions.values.firstWhere(
      (value) => value.isNotEmpty,
      orElse: () => '',
    );
  }

  /// Accesseur de compatibilité avec l'ancien code (retourne la version espagnole)
  String get nombre => getNombre(langueParDefaut);

  /// Retourne la description dans la langue spécifiée
  /// Si la langue n'est pas disponible ou si descriptionTraductions est null, retourne null
  String? getDescription(String langCode) {
    if (descriptionTraductions == null) return null;

    if (descriptionTraductions!.containsKey(langCode)) {
      return descriptionTraductions![langCode];
    }

    if (descriptionTraductions!.containsKey(langueParDefaut)) {
      return descriptionTraductions![langueParDefaut];
    }

    return descriptionTraductions!.values.firstWhere(
      (value) => value.isNotEmpty,
      orElse: () => '',
    );
  }

  /// Accesseur de compatibilité avec l'ancien code (retourne la version espagnole)
  String? get description => getDescription(langueParDefaut);

  /// Crée une instance de DocumentRequis à partir d'une Map.
  factory DocumentRequis.fromMap(Map<String, dynamic> map) {
    // Obtenir le nom avec support pour le format normalisé (colonnes par langue)
    final Map<String, String> nombreTraductions = {};

    // Format standard de la base de données (colonnes pour chaque langue)
    if (map['nombre_es'] != null) {
      nombreTraductions['es'] = map['nombre_es'] as String;
    }
    if (map['nombre_fr'] != null) {
      nombreTraductions['fr'] = map['nombre_fr'] as String;
    }
    if (map['nombre_en'] != null) {
      nombreTraductions['en'] = map['nombre_en'] as String;
    }

    // Si aucune traduction trouvée, utiliser le champ 'nombre' comme valeur espagnole
    if (nombreTraductions.isEmpty && map['nombre'] != null) {
      nombreTraductions['es'] = map['nombre'] as String;
    }

    // Description - même logique
    Map<String, String>? descriptionTraductions;
    if (map['description_es'] != null ||
        map['description_fr'] != null ||
        map['description_en'] != null) {
      descriptionTraductions = {};

      if (map['description_es'] != null) {
        descriptionTraductions['es'] = map['description_es'] as String;
      }
      if (map['description_fr'] != null) {
        descriptionTraductions['fr'] = map['description_fr'] as String;
      }
      if (map['description_en'] != null) {
        descriptionTraductions['en'] = map['description_en'] as String;
      }

      // Si une seule traduction existe, l'utiliser comme valeur espagnole
      if (descriptionTraductions.isEmpty && map['description'] != null) {
        descriptionTraductions['es'] = map['description'] as String;
      }
    }

    return DocumentRequis(
      id: map['id'] as int,
      conceptoId: map['concepto_id'] as String,
      nombreTraductions: nombreTraductions,
      descriptionTraductions: descriptionTraductions,
    );
  }

  /// Crée une instance de DocumentRequis à partir d'un JSON.
  factory DocumentRequis.fromJson(Map<String, dynamic> json) {
    // Valeurs par défaut
    final Map<String, String> nombreTraductions = {};
    Map<String, String>? descriptionTraductions;

    // Traitement du champ 'nombre'
    var nombreData = json['nombre'];
    if (nombreData is String) {
      // Ancien format (chaîne simple) - considéré comme espagnol
      nombreTraductions['es'] = nombreData;
    } else if (nombreData is Map) {
      // Nouveau format (objet de traduction)
      nombreData.forEach((key, value) {
        if (value is String) {
          nombreTraductions[key] = value;
        }
      });
    }

    // Traitement du champ 'description'
    var descriptionData = json['description'];
    if (descriptionData != null) {
      descriptionTraductions = {};

      if (descriptionData is String) {
        // Ancien format (chaîne simple) - considéré comme espagnol
        descriptionTraductions['es'] = descriptionData;
      } else if (descriptionData is Map<String, dynamic>) {
        // Nouveau format (objet de traduction)
        descriptionData.forEach((key, value) {
          if (value is String) {
            descriptionTraductions![key] = value;
          }
        });
      }

      // Si aucune traduction n'a été ajoutée, mettre à null
      if (descriptionTraductions.isEmpty) {
        descriptionTraductions = null;
      }
    }

    return DocumentRequis(
      id: json['id'] ?? 0,
      conceptoId: json['concepto_id'] as String,
      nombreTraductions: nombreTraductions,
      descriptionTraductions: descriptionTraductions,
    );
  }

  /// Convertit cette instance en Map.
  Map<String, dynamic> toMap() {
    final map = {
      'id': id != 0 ? id : null, // Ne pas inclure l'ID s'il n'est pas défini
      'concepto_id': conceptoId,
    };

    // Ajouter les traductions de nom
    nombreTraductions.forEach((langCode, value) {
      map['nombre_$langCode'] = value;
    });

    // Compatibilité avec l'ancien format
    map['nombre'] = nombre;

    // Ajouter les traductions de description si présentes
    if (descriptionTraductions != null) {
      descriptionTraductions!.forEach((langCode, value) {
        map['description_$langCode'] = value;
      });

      // Compatibilité avec l'ancien format
      map['description'] = description;
    } else {
      map['description'] = null;
    }

    return map;
  }

  /// Convertit cette instance en Map JSON avec format multilingue.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'concepto_id': conceptoId,
      'nombre': Map<String, String>.from(nombreTraductions),
    };

    if (descriptionTraductions != null) {
      map['description'] = Map<String, String>.from(descriptionTraductions!);
    }

    return map;
  }

  /// Crée une copie de cette instance avec les champs spécifiés remplacés.
  DocumentRequis copyWith({
    int? id,
    String? conceptoId,
    Map<String, String>? nombreTraductions,
    Map<String, String>? descriptionTraductions,
  }) {
    return DocumentRequis(
      id: id ?? this.id,
      conceptoId: conceptoId ?? this.conceptoId,
      nombreTraductions: nombreTraductions ?? Map.from(this.nombreTraductions),
      descriptionTraductions:
          descriptionTraductions ?? this.descriptionTraductions,
    );
  }

  /// Ajoute ou met à jour une traduction du nom
  DocumentRequis withNombreTraduction(String langCode, String value) {
    final newTraductions = Map<String, String>.from(nombreTraductions);
    newTraductions[langCode] = value;
    return copyWith(nombreTraductions: newTraductions);
  }

  /// Ajoute ou met à jour une traduction de la description
  DocumentRequis withDescriptionTraduction(String langCode, String value) {
    final newTraductions =
        Map<String, String>.from(descriptionTraductions ?? {});
    newTraductions[langCode] = value;
    return copyWith(descriptionTraductions: newTraductions);
  }

  /// Vérifie si ce document a une description (dans n'importe quelle langue).
  bool get hasDescription =>
      descriptionTraductions != null && descriptionTraductions!.isNotEmpty;

  /// Vérifie si ce document a une description dans la langue spécifiée.
  bool hasDescriptionInLanguage(String langCode) {
    return descriptionTraductions?.containsKey(langCode) == true &&
        descriptionTraductions![langCode]!.isNotEmpty;
  }

  @override
  String toString() {
    return 'DocumentRequis{id: $id, conceptoId: $conceptoId, nombreTraductions: $nombreTraductions, descriptionTraductions: $descriptionTraductions}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DocumentRequis &&
        other.id == id &&
        other.conceptoId == conceptoId &&
        _mapsEqual(other.nombreTraductions, nombreTraductions) &&
        _mapsEqual(other.descriptionTraductions, descriptionTraductions);
  }

  /// Utilitaire pour comparer deux maps
  bool _mapsEqual(Map<String, String>? map1, Map<String, String>? map2) {
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
      id.hashCode ^
      conceptoId.hashCode ^
      nombreTraductions.hashCode ^
      descriptionTraductions.hashCode;
}
