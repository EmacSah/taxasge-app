/// Modèle de données représentant une procédure avec support multilingue.
///
/// Cette classe correspond à l'entité "procedimiento" dans la base de données
/// et sert de modèle pour manipuler les données des procédures associées à une taxe.
class Procedure {
  /// Identifiant unique de la procédure (auto-généré par la base de données)
  final int id;
  
  /// Identifiant du concept associé
  final String conceptoId;
  
  /// Description de la procédure avec traductions
  final Map<String, String> descriptionTraductions;
  
  /// Ordre de la procédure (pour des procédures en plusieurs étapes)
  final int? orden;
  
  /// Langue par défaut à utiliser
  static const String langueParDefaut = 'es';
  
  /// Constructeur
  Procedure({
    required this.id,
    required this.conceptoId,
    required this.descriptionTraductions,
    this.orden,
  });
  
  /// Retourne la description dans la langue spécifiée
  String getDescription(String langCode) {
    return descriptionTraductions[langCode] ?? 
           descriptionTraductions[langueParDefaut] ?? 
           descriptionTraductions.values.firstWhere(
             (value) => value.isNotEmpty,
             orElse: () => ''
           );
  }
  
  /// Accesseur de compatibilité avec l'ancien code (retourne la version espagnole)
  String get procedimiento => getDescription(langueParDefaut);
  
  /// Crée une instance de Procedure à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet Procedure.
  factory Procedure.fromMap(Map<String, dynamic> map) {
    // Traiter les traductions de la description
    final Map<String, String> descriptionTraductions = {};
    
    // Format standard de la base de données (colonnes pour chaque langue)
    if (map['description_es'] != null) descriptionTraductions['es'] = map['description_es'];
    if (map['description_fr'] != null) descriptionTraductions['fr'] = map['description_fr'];
    if (map['description_en'] != null) descriptionTraductions['en'] = map['description_en'];
    
    // Si aucune traduction trouvée, utiliser le champ 'procedimiento' comme valeur espagnole
    if (descriptionTraductions.isEmpty && map['description'] != null) {
      descriptionTraductions['es'] = map['description'];
    }
    
    return Procedure(
      id: map['id'],
      conceptoId: map['concepto_id'],
      descriptionTraductions: descriptionTraductions,
      orden: map['orden'],
    );
  }
  
  /// Crée une instance de Procedure à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet Procedure avec support du format multilingue.
  factory Procedure.fromJson(Map<String, dynamic> json) {
    Map<String, String> descriptionTraductions = {};
    var descriptionData = json['description'];
    
    if (descriptionData is String) {
      // Ancien format (chaîne simple) - considéré comme espagnol
      descriptionTraductions['es'] = descriptionData;
    } else if (descriptionData is Map) {
      // Nouveau format (objet de traduction)
      descriptionData.forEach((key, value) {
        if (value is String) {
          descriptionTraductions[key] = value;
        }
      });
    }
    
    return Procedure(
      id: json['id'] ?? 0,
      conceptoId: json['concepto_id'],
      descriptionTraductions: descriptionTraductions,
      orden: json['orden'],
    );
  }
  
  /// Convertit cette instance en Map.
  ///
  /// Cette méthode est utilisée pour préparer l'objet à être stocké
  /// dans la base de données.
  Map<String, dynamic> toMap() {
    final map = {
      'id': id != 0 ? id : null, // Ne pas inclure l'ID s'il n'est pas défini
      'concepto_id': conceptoId,
      'orden': orden,
    };
    
    // Ajouter les traductions de la description
    descriptionTraductions.forEach((langCode, value) {
      map['description_$langCode'] = value;
    });
    
    // Compatibilité avec l'ancien format
    map['description'] = procedimiento;
    
    return map;
  }
  
  /// Convertit cette instance en Map JSON avec support multilingue.
  ///
  /// Cette méthode est utilisée pour sérialiser l'objet en JSON.
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'concepto_id': conceptoId,
      'description': descriptionTraductions,
    };
    
    if (orden != null) {
      json['orden'] = orden.toString();
    }
    
    return json;
  }
  
  /// Crée une copie de cette instance avec les champs spécifiés remplacés.
  ///
  /// Cette méthode est utile pour créer une version modifiée d'un objet
  /// sans altérer l'original.
  Procedure copyWith({
    int? id,
    String? conceptoId,
    Map<String, String>? descriptionTraductions,
    int? orden,
  }) {
    return Procedure(
      id: id ?? this.id,
      conceptoId: conceptoId ?? this.conceptoId,
      descriptionTraductions: descriptionTraductions ?? Map.from(this.descriptionTraductions),
      orden: orden ?? this.orden,
    );
  }
  
  /// Ajoute ou met à jour une traduction de la description
  Procedure withDescriptionTraduction(String langCode, String value) {
    final newTraductions = Map<String, String>.from(descriptionTraductions);
    newTraductions[langCode] = value;
    return copyWith(descriptionTraductions: newTraductions);
  }
  
  /// Supprime une traduction de la description
  Procedure removeDescriptionTraduction(String langCode) {
    if (!descriptionTraductions.containsKey(langCode)) {
      return this;
    }
    
    final newTraductions = Map<String, String>.from(descriptionTraductions);
    newTraductions.remove(langCode);
    
    // Assurer qu'il reste au moins une traduction
    if (newTraductions.isEmpty) {
      newTraductions[langueParDefaut] = '';
    }
    
    return copyWith(descriptionTraductions: newTraductions);
  }
  
  /// Vérifie si cette procédure a une description dans la langue spécifiée.
  bool hasDescriptionInLanguage(String langCode) {
    return descriptionTraductions.containsKey(langCode) && 
           descriptionTraductions[langCode]!.isNotEmpty;
  }
  
  @override
  String toString() {
    return 'Procedure{id: $id, conceptoId: $conceptoId, descriptionTraductions: $descriptionTraductions, orden: $orden}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Procedure &&
      other.id == id &&
      other.conceptoId == conceptoId &&
      _mapsEqual(other.descriptionTraductions, descriptionTraductions) &&
      other.orden == orden;
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
  int get hashCode => id.hashCode ^ conceptoId.hashCode ^ descriptionTraductions.hashCode ^ orden.hashCode;
}