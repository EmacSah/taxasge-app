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
  /// Si le nom est null ou si la langue n'est pas disponible, retourne null
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
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet SubCategoria.
  factory SubCategoria.fromMap(Map<String, dynamic> map) {
    // Traiter les traductions du nom
    Map<String, String>? nombreTraductions;

    if (map['nombre_es'] != null ||
        map['nombre_fr'] != null ||
        map['nombre_en'] != null) {
      nombreTraductions = {};

      if (map['nombre_es'] != null) nombreTraductions['es'] = map['nombre_es'];
      if (map['nombre_fr'] != null) nombreTraductions['fr'] = map['nombre_fr'];
      if (map['nombre_en'] != null) nombreTraductions['en'] = map['nombre_en'];
    } else if (map['nombre'] != null) {
      // Si aucune traduction trouvée mais nom présent, utiliser comme valeur espagnole
      nombreTraductions = {'es': map['nombre']};
    }

    return SubCategoria(
      id: map['id'],
      categoriaId: map['categoria_id'],
      nombreTraductions: nombreTraductions,
    );
  }

  /// Crée une instance de SubCategoria à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet SubCategoria avec support du format multilingue.
  factory SubCategoria.fromJson(Map<String, dynamic> json) {
    Map<String, String>? nombreTraductions;
    var nombreData = json['nombre'];

    if (nombreData != null) {
      nombreTraductions = {};

      if (nombreData is String) {
        // Ancien format (chaîne simple) - considéré comme espagnol
        if (nombreData.isNotEmpty) {
          nombreTraductions['es'] = nombreData;
        }
      } else if (nombreData is Map) {
        // Nouveau format (objet de traduction)
        nombreData.forEach((key, value) {
          if (value is String && value.isNotEmpty) {
            nombreTraductions![key] = value;
          }
        });
      }

      // Si aucune traduction n'a été ajoutée, mettre à null
      if (nombreTraductions.isEmpty) {
        nombreTraductions = null;
      }
    }

    return SubCategoria(
      id: json['id'],
      categoriaId: json['categoria_id'] ?? '',
      nombreTraductions: nombreTraductions,
    );
  }

  /// Convertit cette instance en Map.
  ///
  /// Cette méthode est utilisée pour préparer l'objet à être stocké
  /// dans la base de données.
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'categoria_id': categoriaId,
    };

    // Ajouter les traductions du nom si présentes
    if (nombreTraductions != null) {
      nombreTraductions!.forEach((langCode, value) {
        map['nombre_$langCode'] = value;
      });

      // Compatibilité avec l'ancien format
      map['nombre'] = nombre;
    } else {
      map['nombre'] = null;
    }

    return map;
  }

  /// Convertit cette instance en Map JSON avec support multilingue.
  ///
  /// Cette méthode est utilisée pour sérialiser l'objet en JSON.
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'categoria_id': categoriaId,
    };

    if (nombreTraductions != null) {
      json['nombre'] = nombreTraductions;
    }

    return json;
  }

  /// Crée une copie de cette instance avec les champs spécifiés remplacés.
  ///
  /// Cette méthode est utile pour créer une version modifiée d'un objet
  /// sans altérer l'original.
  SubCategoria copyWith({
    String? id,
    String? categoriaId,
    Map<String, String>? nombreTraductions,
  }) {
    return SubCategoria(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      nombreTraductions: nombreTraductions ?? this.nombreTraductions,
    );
  }

  /// Ajoute ou met à jour une traduction du nom
  SubCategoria withNombreTraduction(String langCode, String value) {
    final newTraductions = Map<String, String>.from(nombreTraductions ?? {});
    newTraductions[langCode] = value;
    return copyWith(nombreTraductions: newTraductions);
  }

  /// Supprime une traduction du nom
  SubCategoria removeNombreTraduction(String langCode) {
    if (nombreTraductions == null ||
        !nombreTraductions!.containsKey(langCode)) {
      return this;
    }

    final newTraductions = Map<String, String>.from(nombreTraductions!);
    newTraductions.remove(langCode);

    // Si toutes les traductions ont été supprimées, mettre à null
    return copyWith(
        nombreTraductions: newTraductions.isEmpty ? null : newTraductions);
  }

  @override
  String toString() {
    return 'SubCategoria{id: $id, categoriaId: $categoriaId, nombreTraductions: $nombreTraductions}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubCategoria &&
        other.id == id &&
        other.categoriaId == categoriaId &&
        _mapsEqual(other.nombreTraductions, nombreTraductions);
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
      id.hashCode ^ categoriaId.hashCode ^ nombreTraductions.hashCode;
}
