/// Modèle de données représentant un concept (taxe).
///
/// Cette classe correspond à l'entité "concepto" dans la base de données
/// et sert de modèle pour manipuler les données des taxes.
class Concepto {
  /// Identifiant unique du concept (format: T-XXX)
  final String id;
  
  /// Identifiant de la sous-catégorie parente
  String subCategoriaId;
  
  /// Nom ou libellé de la taxe
  final String nombre;
  
  /// Montant de la taxe d'expédition
  final String tasaExpedicion;
  
  /// Montant de la taxe de renouvellement
  final String tasaRenovacion;
  
  /// Procédure à suivre (peut être null)
  final String? procedimiento;
  
  /// Constructeur
  Concepto({
    required this.id,
    required this.subCategoriaId,
    required this.nombre,
    required this.tasaExpedicion,
    required this.tasaRenovacion,
    this.procedimiento,
  });
  
  /// Crée une instance de Concepto à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet Concepto.
  factory Concepto.fromMap(Map<String, dynamic> map) {
    return Concepto(
      id: map['id'],
      subCategoriaId: map['sub_categoria_id'],
      nombre: map['nombre'],
      tasaExpedicion: map['tasa_expedicion'],
      tasaRenovacion: map['tasa_renovacion'],
      procedimiento: map['procedimiento'],
    );
  }
  
  /// Crée une instance de Concepto à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet Concepto.
  factory Concepto.fromJson(Map<String, dynamic> json) {
    return Concepto(
      id: json['id'],
      subCategoriaId: json['sub_categoria_id'] ?? '',
      nombre: json['nombre'],
      tasaExpedicion: json['tasa_expedicion'] ?? '',
      tasaRenovacion: json['tasa_renovacion'] ?? '',
      procedimiento: json['procedimiento'],
    );
  }
  
  /// Convertit cette instance en Map.
  ///
  /// Cette méthode est utilisée pour préparer l'objet à être stocké
  /// dans la base de données.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sub_categoria_id': subCategoriaId,
      'nombre': nombre,
      'tasa_expedicion': tasaExpedicion,
      'tasa_renovacion': tasaRenovacion,
      'procedimiento': procedimiento,
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
  Concepto copyWith({
    String? id,
    String? subCategoriaId,
    String? nombre,
    String? tasaExpedicion,
    String? tasaRenovacion,
    String? procedimiento,
  }) {
    return Concepto(
      id: id ?? this.id,
      subCategoriaId: subCategoriaId ?? this.subCategoriaId,
      nombre: nombre ?? this.nombre,
      tasaExpedicion: tasaExpedicion ?? this.tasaExpedicion,
      tasaRenovacion: tasaRenovacion ?? this.tasaRenovacion,
      procedimiento: procedimiento ?? this.procedimiento,
    );
  }
  
  /// Vérifie si cette taxe a un montant d'expédition.
  bool get hasExpedicion => tasaExpedicion.isNotEmpty;
  
  /// Vérifie si cette taxe a un montant de renouvellement.
  bool get hasRenovacion => tasaRenovacion.isNotEmpty;
  
  /// Vérifie si cette taxe a une procédure.
  bool get hasProcedimiento => procedimiento != null && procedimiento!.isNotEmpty;
  
  /// Récupère le montant d'expédition sous forme textuelle formatée.
  ///
  /// Retourne "N/A" si aucun montant n'est spécifié.
  String getFormattedExpedicionAmount() {
    if (!hasExpedicion) return 'N/A';
    return tasaExpedicion;
  }
  
  /// Récupère le montant de renouvellement sous forme textuelle formatée.
  ///
  /// Retourne "N/A" si aucun montant n'est spécifié.
  String getFormattedRenovacionAmount() {
    if (!hasRenovacion) return 'N/A';
    return tasaRenovacion;
  }
  
  @override
  String toString() {
    return 'Concepto{id: $id, subCategoriaId: $subCategoriaId, nombre: $nombre, tasaExpedicion: $tasaExpedicion, tasaRenovacion: $tasaRenovacion, procedimiento: $procedimiento}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Concepto &&
      other.id == id &&
      other.subCategoriaId == subCategoriaId &&
      other.nombre == nombre &&
      other.tasaExpedicion == tasaExpedicion &&
      other.tasaRenovacion == tasaRenovacion &&
      other.procedimiento == procedimiento;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      subCategoriaId.hashCode ^
      nombre.hashCode ^
      tasaExpedicion.hashCode ^
      tasaRenovacion.hashCode ^
      procedimiento.hashCode;
  }
}