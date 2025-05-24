/// Modèle de données représentant une sous-catégorie avec support multilingue.
///
/// Cette classe correspond à l'entité "sub_categoria" dans la base de données
/// et sert de modèle pour manipuler les données des sous-catégories.
class SubCategoria {
  /// Identifiant unique de la sous-catégorie (format: SC-XXX)
  final String id;

  /// Identifiant de la catégorie parente
  String categoriaId;

  /// Nom de la sous-catégorie (traductions, peut être null)
  final Map<String, String>? nombreTraductions;

  /// Langue par défaut à utiliser
  static const String langueParDefaut = 'es';

  /// Constructeur
  SubCategoria({
    required this.id,
    required this.categoriaId,
    this.nombreTraductions,
  });

  /// Retourne le nom dans la langue spécifiée
  String? getNombre(String langCode) {
    if (nombreTraductions == null || nombreTraductions!.isEmpty) {
      return null;
    }

    return nombreTraductions![langCode] ??
        nombreTraductions![langueParDefaut] ??
        nombreTraductions!.values
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  }

  /// Accesseur de compatibilité avec l'ancien code (retourne la version espagnole)
  String? get nombre => getNombre(langueParDefaut);

  /// Vérifie si cette sous-catégorie a un nom défini.
  bool get hasNombre =>
      nombreTraductions != null && nombreTraductions!.isNotEmpty;

  /// Vérifie si cette sous-catégorie a un nom dans la langue spécifiée.
  bool hasNombreInLanguage(String langCode) {
    return nombreTraductions != null &&
        nombreTraductions!.containsKey(langCode) &&
        nombreTraductions![langCode]!.isNotEmpty;
  }

  /// Crée une instance de SubCategoria à partir d'une Map.
  factory SubCategoria.fromMap(Map<String, dynamic> map) {
    Map<String, String>? nombreTraductions;

    if (map['nombre_es'] != null ||
        map['nombre_fr'] != null ||
        map['nombre_en'] != null) {
      nombreTraductions = {};

      if (map['nombre_es'] != null) {
        nombreTraductions['es'] = map['nombre_es'] as String;
      }
      if (map['nombre_fr'] != null) {
        nombreTraductions['fr'] = map['nombre_fr'] as String;
      }
      if (map['nombre_en'] != null) {
        nombreTraductions['en'] = map['nombre_en'] as String;
      }
    } else if (map['nombre'] != null) {
      nombreTraductions = {'es': map['nombre'] as String};
    }

    return SubCategoria(
      id: map['id'] as String,
      categoriaId: map['categoria_id'] as String,
      nombreTraductions: nombreTraductions,
    );
  }

  /// Crée une instance de SubCategoria à partir d'un JSON.
  factory SubCategoria.fromJson(Map<String, dynamic> json) {
    Map<String, String>? nombreTraductions;
    var nombreData = json['nombre'];

    if (nombreData != null) {
      nombreTraductions = {};

      if (nombreData is String) {
        if (nombreData.isNotEmpty) {
          nombreTraductions['es'] = nombreData;
        }
      } else if (nombreData is Map<String, dynamic>) {
        nombreData.forEach((key, value) {
          if (value is String && value.isNotEmpty) {
            nombreTraductions![key] = value;
          }
        });
      }

      if (nombreTraductions.isEmpty) {
        nombreTraductions = null;
      }
    }

    return SubCategoria(
      id: json['id'] as String,
      categoriaId: (json['categoria_id'] as String?) ?? '',
      nombreTraductions: nombreTraductions,
    );
  }

  /// Convertit cette instance en Map.
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'categoria_id': categoriaId,
    };

    if (nombreTraductions != null) {
      for (var entry in nombreTraductions!.entries) {
        map['nombre_${entry.key}'] = entry.value;
      }

      map['nombre'] = getNombre(langueParDefaut) ?? '';
    }

    return map;
  }

  /// Convertit cette instance en Map JSON.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'categoria_id': categoriaId,
    };

    if (nombreTraductions != null) {
      json['nombre'] = nombreTraductions!.length == 1 &&
              nombreTraductions!.containsKey('es')
          ? nombreTraductions![
              'es'] // Si une seule traduction en espagnol, on renvoie la string
          : Map<String, String>.from(
              nombreTraductions!); // Sinon on renvoie la map complète
    }

    return json;
  }

  /// Crée une copie avec des champs modifiés.
  SubCategoria copyWith({
    String? id,
    String? categoriaId,
    Map<String, String>? nombreTraductions,
  }) {
    return SubCategoria(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      nombreTraductions: nombreTraductions ??
          (this.nombreTraductions != null
              ? Map<String, String>.from(this.nombreTraductions!)
              : null),
    );
  }

  @override
  String toString() {
    return 'SubCategoria{id: $id, categoriaId: $categoriaId, '
        'nombreTraductions: $nombreTraductions}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubCategoria &&
        other.id == id &&
        other.categoriaId == categoriaId &&
        mapsEqual(other.nombreTraductions, nombreTraductions);
  }

  @override
  int get hashCode =>
      id.hashCode ^ categoriaId.hashCode ^ nombreTraductions.hashCode;

  /// Utilitaire pour comparer deux maps
  static bool mapsEqual(Map<String, String>? map1, Map<String, String>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    return map1.entries
        .every((e) => map2.containsKey(e.key) && map2[e.key] == e.value);
  }
}
