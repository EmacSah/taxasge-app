/// Modèle de données représentant un mot-clé.
///
/// Cette classe correspond à l'entité "mot_cle" dans la base de données
/// et sert de modèle pour manipuler les données des mots-clés associés à une taxe.
class MotCle {
  /// Identifiant unique du mot-clé (auto-généré par la base de données)
  final int id;
  
  /// Identifiant du concept associé
  final String conceptoId;
  
  /// Mot-clé
  final String motCle;
  
  /// Constructeur
  MotCle({
    required this.id,
    required this.conceptoId,
    required this.motCle,
  });
  
  /// Crée une instance de MotCle à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet MotCle.
  factory MotCle.fromMap(Map<String, dynamic> map) {
    return MotCle(
      id: map['id'],
      conceptoId: map['concepto_id'],
      motCle: map['mot_cle'],
    );
  }
  
  /// Crée une instance de MotCle à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet MotCle.
  factory MotCle.fromJson(Map<String, dynamic> json) {
    return MotCle(
      id: json['id'] ?? 0,
      conceptoId: json['concepto_id'],
      motCle: json['mot_cle'],
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
      'mot_cle': motCle,
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
  MotCle copyWith({
    int? id,
    String? conceptoId,
    String? motCle,
  }) {
    return MotCle(
      id: id ?? this.id,
      conceptoId: conceptoId ?? this.conceptoId,
      motCle: motCle ?? this.motCle,
    );
  }
  
  @override
  String toString() {
    return 'MotCle{id: $id, conceptoId: $conceptoId, motCle: $motCle}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is MotCle &&
      other.id == id &&
      other.conceptoId == conceptoId &&
      other.motCle == motCle;
  }
  
  @override
  int get hashCode => id.hashCode ^ conceptoId.hashCode ^ motCle.hashCode;
}