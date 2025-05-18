/// Modèle de données représentant un favori.
///
/// Cette classe correspond à l'entité "favori" dans la base de données
/// et sert de modèle pour manipuler les favoris des utilisateurs.
/// Bien que cette classe ne contienne pas directement de contenu multilingue,
/// elle fait référence à des concepts qui peuvent être traduits.
class Favori {
  /// Identifiant unique du favori (auto-généré par la base de données)
  final int id;

  /// Identifiant du concept associé
  final String conceptoId;

  /// Date d'ajout au format ISO8601
  final String fechaAgregado;

  /// Langue par défaut à utiliser
  static const String langueParDefaut = 'es';

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

  /// Convertit une date ISO8601 en DateTime
  DateTime get dateTime => DateTime.parse(fechaAgregado);

  /// Formate la date d'ajout dans la langue spécifiée
  /// Note: Cette méthode sera utile lorsque l'application aura un système de formatage localisé complet
  String getLocalizedDate(String langCode) {
    final date = dateTime;

    // Pour l'instant, retourne un format simple mais pourrait être étendu
    // pour gérer les formats de date spécifiques à chaque langue
    switch (langCode) {
      case 'fr':
        return '${date.day}/${date.month}/${date.year}';
      case 'en':
        return '${date.month}/${date.day}/${date.year}';
      case 'es':
      default:
        return '${date.day}/${date.month}/${date.year}';
    }
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
  int get hashCode =>
      id.hashCode ^ conceptoId.hashCode ^ fechaAgregado.hashCode;
}
