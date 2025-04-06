/// Modèle de données représentant un ministère.
///
/// Cette classe correspond à l'entité "ministerio" dans la base de données
/// et sert de modèle pour manipuler les données des ministères.
class Ministerio {
  /// Identifiant unique du ministère (format: M-XXX)
  final String id;
  
  /// Nom du ministère
  final String nombre;
  
  /// Constructeur
  Ministerio({
    required this.id,
    required this.nombre,
  });
  
  /// Crée une instance de Ministerio à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet Ministerio.
  factory Ministerio.fromMap(Map<String, dynamic> map) {
    return Ministerio(
      id: map['id'],
      nombre: map['nombre'],
    );
  }
  
  /// Crée une instance de Ministerio à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet Ministerio.
  factory Ministerio.fromJson(Map<String, dynamic> json) {
    return Ministerio(
      id: json['id'],
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
  Ministerio copyWith({
    String? id,
    String? nombre,
  }) {
    return Ministerio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }
  
  @override
  String toString() {
    return 'Ministerio{id: $id, nombre: $nombre}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Ministerio &&
      other.id == id &&
      other.nombre == nombre;
  }
  
  @override
  int get hashCode => id.hashCode ^ nombre.hashCode;
}