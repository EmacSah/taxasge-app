/// Modèle de données représentant un document requis.
///
/// Cette classe correspond à l'entité "documento_requerido" dans la base de données
/// et sert de modèle pour manipuler les données des documents requis pour une taxe.
class DocumentRequis {
  /// Identifiant unique du document (auto-généré par la base de données)
  final int id;
  
  /// Identifiant du concept associé
  final String conceptoId;
  
  /// Nom du document
  final String nombre;
  
  /// Description du document (peut être null)
  final String? description;
  
  /// Constructeur
  DocumentRequis({
    required this.id,
    required this.conceptoId,
    required this.nombre,
    this.description,
  });
  
  /// Crée une instance de DocumentRequis à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet DocumentRequis.
  factory DocumentRequis.fromMap(Map<String, dynamic> map) {
    return DocumentRequis(
      id: map['id'],
      conceptoId: map['concepto_id'],
      nombre: map['nombre'],
      description: map['description'],
    );
  }
  
  /// Crée une instance de DocumentRequis à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet DocumentRequis.
  factory DocumentRequis.fromJson(Map<String, dynamic> json) {
    return DocumentRequis(
      id: json['id'] ?? 0,
      conceptoId: json['concepto_id'],
      nombre: json['nombre'],
      description: json['description'],
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
      'nombre': nombre,
      'description': description,
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
  DocumentRequis copyWith({
    int? id,
    String? conceptoId,
    String? nombre,
    String? description,
  }) {
    return DocumentRequis(
      id: id ?? this.id,
      conceptoId: conceptoId ?? this.conceptoId,
      nombre: nombre ?? this.nombre,
      description: description ?? this.description,
    );
  }
  
  /// Vérifie si ce document a une description.
  bool get hasDescription => description != null && description!.isNotEmpty;
  
  @override
  String toString() {
    return 'DocumentRequis{id: $id, conceptoId: $conceptoId, nombre: $nombre, description: $description}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DocumentRequis &&
      other.id == id &&
      other.conceptoId == conceptoId &&
      other.nombre == nombre &&
      other.description == description;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      conceptoId.hashCode ^
      nombre.hashCode ^
      description.hashCode;
  }
}