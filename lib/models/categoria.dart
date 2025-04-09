/// Modèle de données représentant une catégorie.
///
/// Cette classe correspond à l'entité "categoria" dans la base de données
/// et sert de modèle pour manipuler les données des catégories.
class Categoria {
  /// Identifiant unique de la catégorie (format: C-XXX)
  final String id;
  
  /// Identifiant du secteur parent
  String sectorId;
  
  /// Nom de la catégorie
  final String nombre;
  
  /// Constructeur
  Categoria({
    required this.id,
    required this.sectorId,
    required this.nombre,
  });
  
  /// Crée une instance de Categoria à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet Categoria.
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      sectorId: map['sector_id'],
      nombre: map['nombre'],
    );
  }
  
  /// Crée une instance de Categoria à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet Categoria.
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      sectorId: json['sector_id'] ?? '',
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
      'sector_id': sectorId,
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
  Categoria copyWith({
    String? id,
    String? sectorId,
    String? nombre,
  }) {
    return Categoria(
      id: id ?? this.id,
      sectorId: sectorId ?? this.sectorId,
      nombre: nombre ?? this.nombre,
    );
  }
  
  @override
  String toString() {
    return 'Categoria{id: $id, sectorId: $sectorId, nombre: $nombre}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Categoria &&
      other.id == id &&
      other.sectorId == sectorId &&
      other.nombre == nombre;
  }
  
  @override
  int get hashCode => id.hashCode ^ sectorId.hashCode ^ nombre.hashCode;
}