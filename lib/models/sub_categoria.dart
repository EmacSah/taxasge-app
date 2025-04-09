/// Modèle de données représentant une sous-catégorie.
///
/// Cette classe correspond à l'entité "sub_categoria" dans la base de données
/// et sert de modèle pour manipuler les données des sous-catégories.
class SubCategoria {
  /// Identifiant unique de la sous-catégorie (format: SC-XXX)
  final String id;
  
  /// Identifiant de la catégorie parente
  String categoriaId;
  
  /// Nom de la sous-catégorie (peut être null)
  final String? nombre;
  
  /// Constructeur
  SubCategoria({
    required this.id,
    required this.categoriaId,
    this.nombre,
  });
  
  /// Crée une instance de SubCategoria à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet SubCategoria.
  factory SubCategoria.fromMap(Map<String, dynamic> map) {
    return SubCategoria(
      id: map['id'],
      categoriaId: map['categoria_id'],
      nombre: map['nombre'],
    );
  }
  
  /// Crée une instance de SubCategoria à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet SubCategoria.
  factory SubCategoria.fromJson(Map<String, dynamic> json) {
    return SubCategoria(
      id: json['id'],
      categoriaId: json['categoria_id'] ?? '',
      nombre: json['nombre'],
    );
  }
  
  /// Convertit cette instance en Map.
  ///
  /// Cette méthode est utilisée pour préparer l'objet à être stocké
  /// dans la base de données.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria_id': categoriaId,
      'nombre': nombre,
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
  SubCategoria copyWith({
    String? id,
    String? categoriaId,
    String? nombre,
  }) {
    return SubCategoria(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      nombre: nombre ?? this.nombre,
    );
  }
  
  @override
  String toString() {
    return 'SubCategoria{id: $id, categoriaId: $categoriaId, nombre: $nombre}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is SubCategoria &&
      other.id == id &&
      other.categoriaId == categoriaId &&
      other.nombre == nombre;
  }
  
  @override
  int get hashCode => id.hashCode ^ categoriaId.hashCode ^ nombre.hashCode;
}