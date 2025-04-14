/// Modèle de données représentant un favori.
///
/// Cette classe correspond à l'entité "favori" dans la base de données
/// et sert de modèle pour manipuler les données des favoris de l'utilisateur.
class Favori {
  /// Identifiant unique du favori (auto-généré par la base de données)
  final int id;
  
  /// Identifiant du concept associé
  final String conceptoId;
  
  /// Date d'ajout aux favoris (format ISO 8601)
  final String fechaAgregado;
  
  /// Constructeur
  Favori({
    required this.id,
    required this.conceptoId,
    required this.fechaAgregado,
  });
  
  /// Crée une instance de Favori à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet Favori.
  factory Favori.fromMap(Map<String, dynamic> map) {
    return Favori(
      id: map['id'],
      conceptoId: map['concepto_id'],
      fechaAgregado: map['fecha_agregado'],
    );
  }
  
  /// Crée une instance de Favori à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet Favori.
  factory Favori.fromJson(Map<String, dynamic> json) {
    return Favori(
      id: json['id'] ?? 0,
      conceptoId: json['concepto_id'],
      fechaAgregado: json['fecha_agregado'] ?? DateTime.now().toIso8601String(),
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
      'fecha_agregado': fechaAgregado,
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
  Favori copyWith({
    int? id,
    String? conceptoId,
    String? fechaAgregado,
  }) {
    return Favori(
      id: id ?? this.id,
      conceptoId: conceptoId ?? this.conceptoId,
      fechaAgregado: fechaAgregado ?? this.fechaAgregado,
    );
  }
  
  /// Obtient la date d'ajout sous forme d'objet DateTime.
  DateTime get fechaAgregadoDateTime {
    return DateTime.parse(fechaAgregado);
  }
  
  @override
  String toString() {
    return 'Favori{id: $id, conceptoId: $conceptoId, fechaAgregado: $fechaAgregado}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Favori &&
      other.id == id &&
      other.conceptoId == conceptoId &&
      other.fechaAgregado == fechaAgregado;
  }
  
  @override
  int get hashCode => id.hashCode ^ conceptoId.hashCode ^ fechaAgregado.hashCode;
}