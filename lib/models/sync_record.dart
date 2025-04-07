/// Modèle de données représentant un enregistrement de synchronisation.
///
/// Cette classe correspond à l'entité "sync_record" dans la base de données
/// et sert à suivre l'état de synchronisation des entités entre l'application
/// et le backend.
class SyncRecord {
  /// Identifiant unique de l'enregistrement (auto-généré par la base de données)
  final int id;
  
  /// Type de l'entité (ex: "ministerio", "concepto", etc.)
  final String entityType;
  
  /// Identifiant de l'entité concernée
  final String entityId;
  
  /// Timestamp de la dernière modification (en millisecondes depuis l'epoch)
  final int lastModified;
  
  /// Statut de synchronisation (ex: "pending", "synced", "conflict")
  final String syncStatus;
  
  /// Constructeur
  SyncRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.lastModified,
    required this.syncStatus,
  });
  
  /// Crée une instance de SyncRecord à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet SyncRecord.
  factory SyncRecord.fromMap(Map<String, dynamic> map) {
    return SyncRecord(
      id: map['id'],
      entityType: map['entity_type'],
      entityId: map['entity_id'],
      lastModified: map['last_modified'],
      syncStatus: map['sync_status'],
    );
  }
  
  /// Crée une instance de SyncRecord à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet SyncRecord.
  factory SyncRecord.fromJson(Map<String, dynamic> json) {
    return SyncRecord(
      id: json['id'] ?? 0,
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      lastModified: json['last_modified'] ?? DateTime.now().millisecondsSinceEpoch,
      syncStatus: json['sync_status'] ?? 'pending',
    );
  }
  
  /// Crée un nouvel enregistrement de synchronisation en attente.
  ///
  /// [entityType] : Le type de l'entité (ex: "ministerio", "concepto")
  /// [entityId] : L'identifiant de l'entité
  factory SyncRecord.pending({
    required String entityType,
    required String entityId,
  }) {
    return SyncRecord(
      id: 0,
      entityType: entityType,
      entityId: entityId,
      lastModified: DateTime.now().millisecondsSinceEpoch,
      syncStatus: 'pending',
    );
  }
  
  /// Convertit cette instance en Map.
  ///
  /// Cette méthode est utilisée pour préparer l'objet à être stocké
  /// dans la base de données.
  Map<String, dynamic> toMap() {
    return {
      'id': id != 0 ? id : null, // Ne pas inclure l'ID s'il n'est pas défini
      'entity_type': entityType,
      'entity_id': entityId,
      'last_modified': lastModified,
      'sync_status': syncStatus,
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
  SyncRecord copyWith({
    int? id,
    String? entityType,
    String? entityId,
    int? lastModified,
    String? syncStatus,
  }) {
    return SyncRecord(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      lastModified: lastModified ?? this.lastModified,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
  
  /// Convertit cette instance en une version "synchronisée".
  ///
  /// Cette méthode est utile pour marquer un enregistrement comme synchronisé
  /// après une opération de synchronisation réussie.
  SyncRecord toSynced() {
    return copyWith(
      syncStatus: 'synced',
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Convertit cette instance en une version avec "conflit".
  ///
  /// Cette méthode est utile pour marquer un enregistrement comme ayant un conflit
  /// lors d'une opération de synchronisation.
  SyncRecord toConflict() {
    return copyWith(
      syncStatus: 'conflict',
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Obtient la date de dernière modification sous forme d'objet DateTime.
  DateTime get lastModifiedDateTime {
    return DateTime.fromMillisecondsSinceEpoch(lastModified);
  }
  
  /// Vérifie si l'enregistrement est en attente de synchronisation.
  bool get isPending => syncStatus == 'pending';
  
  /// Vérifie si l'enregistrement est synchronisé.
  bool get isSynced => syncStatus == 'synced';
  
  /// Vérifie si l'enregistrement a un conflit.
  bool get hasConflict => syncStatus == 'conflict';
  
  @override
  String toString() {
    return 'SyncRecord{id: $id, entityType: $entityType, entityId: $entityId, lastModified: $lastModified, syncStatus: $syncStatus}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is SyncRecord &&
      other.id == id &&
      other.entityType == entityType &&
      other.entityId == entityId &&
      other.lastModified == lastModified &&
      other.syncStatus == syncStatus;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      entityType.hashCode ^
      entityId.hashCode ^
      lastModified.hashCode ^
      syncStatus.hashCode;
  }
}