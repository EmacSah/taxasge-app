/// Modèle de données représentant un secteur.
///
/// Cette classe correspond à l'entité "sector" dans la base de données
/// et sert de modèle pour manipuler les données des secteurs.
class Sector {
  /// Identifiant unique du secteur (format: S-XXX)
  final String id;
  
  /// Identifiant du ministère parent
  String ministerioId;
  
  /// Nom du secteur
  final String nombre;
  
  /// Constructeur
  Sector({
    required this.id,
    required this.ministerioId,
    required this.nombre,
  });
  
  /// Crée une instance de Sector à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet Sector.
  factory Sector.fromMap(Map<String, dynamic> map) {
    return Sector(
      id: map['id'],
      ministerioId: map['ministerio_id'],
      nombre: map['nombre'],
    );
  }
  
  /// Crée une instance de Sector à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet Sector.
  factory Sector.fromJson(Map<String, dynamic> json) {
    return Sector(
      id: json['id'],
      ministerioId: json['ministerio_id'] ?? '',
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
      'ministerio_id': ministerioId,
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
  Sector copyWith({
    String? id,
    String? ministerioId,
    String? nombre,
  }) {
    return Sector(
      id: id ?? this.id,
      ministerioId: ministerioId ?? this.ministerioId,
      nombre: nombre ?? this.nombre,
    );
  }
  
  @override
  String toString() {
    return 'Sector{id: $id, ministerioId: $ministerioId, nombre: $nombre}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Sector &&
      other.id == id &&
      other.ministerioId == ministerioId &&
      other.nombre == nombre;
  }
  
  @override
  int get hashCode => id.hashCode ^ ministerioId.hashCode ^ nombre.hashCode;
}