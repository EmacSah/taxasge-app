/// Modèle de données représentant une catégorie avec support multilingue.
///
/// Cette classe correspond à l'entité "categoria" dans la base de données
/// et sert de modèle pour manipuler les données des catégories.
class Categoria {
  /// Identifiant unique de la catégorie (format: C-XXX)
  final String id;

  /// Identifiant du secteur parent
  String sectorId;

  /// Nom de la catégorie (traductions)
  final Map<String, String> nombreTraductions;

  /// Langue par défaut à utiliser
  static const String langueParDefaut = 'es';

  /// Constructeur
  Categoria({
    required this.id,
    required this.sectorId,
    required this.nombreTraductions,
  });

  /// Retourne le nom dans la langue spécifiée
  String getNombre(String langCode) {
    return nombreTraductions[langCode] ??
        nombreTraductions[langueParDefaut] ??
        nombreTraductions.values
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  }

  /// Accesseur de compatibilité avec l'ancien code (retourne la version espagnole)
  String get nombre => getNombre(langueParDefaut);

  /// Vérifie si cette catégorie a un nom dans la langue spécifiée.
  bool hasNombreInLanguage(String langCode) {
    return nombreTraductions.containsKey(langCode) &&
        nombreTraductions[langCode]!.isNotEmpty;
  }

  /// Crée une instance de Categoria à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet Categoria.
  factory Categoria.fromMap(Map<String, dynamic> map) {
    // Traiter les traductions du nom
    final Map<String, String> nombreTraductions = {};

    // Format standard de la base de données (colonnes pour chaque langue)
    if (map['nombre_es'] != null) nombreTraductions['es'] = map['nombre_es'];
    if (map['nombre_fr'] != null) nombreTraductions['fr'] = map['nombre_fr'];
    if (map['nombre_en'] != null) nombreTraductions['en'] = map['nombre_en'];

    // Si aucune traduction trouvée, utiliser le champ 'nombre' comme valeur espagnole
    if (nombreTraductions.isEmpty && map['nombre'] != null) {
      nombreTraductions['es'] = map['nombre'];
    }

    return Categoria(
      id: map['id'],
      sectorId: map['sector_id'],
      nombreTraductions: nombreTraductions,
    );
  }

  /// Crée une instance de Categoria à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet Categoria avec support du format multilingue.
  factory Categoria.fromJson(Map<String, dynamic> json) {
    Map<String, String> nombreTraductions = {};
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

    return Categoria(
      id: json['id'],
      sectorId: json['sector_id'] ?? '',
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
      'sector_id': sectorId,
    };

    // Ajouter les traductions du nom
    nombreTraductions.forEach((langCode, value) {
      map['nombre_$langCode'] = value;
    });

    // Compatibilité avec l'ancien format
    map['nombre'] = nombre;

    return map;
  }

  /// Convertit cette instance en Map JSON avec support multilingue.
  ///
  /// Cette méthode est utilisée pour sérialiser l'objet en JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sector_id': sectorId,
      'nombre': nombreTraductions,
    };
  }

  /// Crée une copie de cette instance avec les champs spécifiés remplacés.
  ///
  /// Cette méthode est utile pour créer une version modifiée d'un objet
  /// sans altérer l'original.
  Categoria copyWith({
    String? id,
    String? sectorId,
    Map<String, String>? nombreTraductions,
  }) {
    return Categoria(
      id: id ?? this.id,
      sectorId: sectorId ?? this.sectorId,
      nombreTraductions: nombreTraductions ?? Map.from(this.nombreTraductions),
    );
  }

  /// Ajoute ou met à jour une traduction du nom
  Categoria withNombreTraduction(String langCode, String value) {
    final newTraductions = Map<String, String>.from(nombreTraductions);
    newTraductions[langCode] = value;
    return copyWith(nombreTraductions: newTraductions);
  }

  /// Supprime une traduction du nom
  Categoria removeNombreTraduction(String langCode) {
    if (!nombreTraductions.containsKey(langCode)) {
      return this;
    }

    final newTraductions = Map<String, String>.from(nombreTraductions);
    newTraductions.remove(langCode);

    // Assurer qu'il reste au moins une traduction
    if (newTraductions.isEmpty) {
      newTraductions[langueParDefaut] = '';
    }

    return copyWith(nombreTraductions: newTraductions);
  }

  @override
  String toString() {
    return 'Categoria{id: $id, sectorId: $sectorId, nombreTraductions: $nombreTraductions}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Categoria &&
        other.id == id &&
        other.sectorId == sectorId &&
        _mapsEqual(other.nombreTraductions, nombreTraductions);
  }

  /// Utilitaire pour comparer deux maps
  bool _mapsEqual(Map<String, String> map1, Map<String, String> map2) {
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
      id.hashCode ^ sectorId.hashCode ^ nombreTraductions.hashCode;
}
