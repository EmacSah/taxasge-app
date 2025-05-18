import 'mot_cle.dart';

/// Modèle de données représentant un concept (taxe) avec support multilingue.
///
/// Cette classe correspond à l'entité "concepto" dans la base de données
/// et sert de modèle pour manipuler les données des taxes.
/// Mise à jour pour déléguer les procédures à une entité séparée.
class Concepto {
  /// Identifiant unique du concept (format: T-XXX)
  final String id;

  /// Identifiant de la sous-catégorie parente
  String subCategoriaId;

  /// Nom ou libellé de la taxe (traductions)
  final Map<String, String> nombreTraductions;

  /// Montant de la taxe d'expédition
  final String tasaExpedicion;

  /// Montant de la taxe de renouvellement
  final String tasaRenovacion;

  /// Documents requis (traductions)
  /// Note: Ce champ est conservé pour compatibilité mais les documents sont maintenant
  /// stockés dans une table séparée
  final Map<String, String>? documentosRequeridosTraductions;

  /// Procédure à suivre (traductions)
  /// Note: Ce champ est conservé pour compatibilité mais les procédures sont maintenant
  /// stockées dans une table séparée
  final Map<String, String>? procedimientoTraductions;

  /// Langue par défaut à utiliser
  static const String langueParDefaut = 'es';

  /// Constructeur
  Concepto({
    required this.id,
    required this.subCategoriaId,
    required this.nombreTraductions,
    required this.tasaExpedicion,
    required this.tasaRenovacion,
    this.documentosRequeridosTraductions,
    this.procedimientoTraductions,
  });

  /// Retourne le nom dans la langue spécifiée
  String getNombre(String langCode) {
    return nombreTraductions[langCode] ??
        nombreTraductions[langueParDefaut] ??
        nombreTraductions.values
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  }

  /// Accesseur de compatibilité avec l'ancien code (retourne la version espagnole)
  String get nombre => getNombre(langueParDefaut);

  /// Retourne les documents requis dans la langue spécifiée
  /// Note: Ce champ est conservé pour compatibilité mais les documents sont maintenant
  /// stockés dans une table séparée
  String? getDocumentosRequeridos(String langCode) {
    if (documentosRequeridosTraductions == null ||
        documentosRequeridosTraductions!.isEmpty) {
      return null;
    }

    return documentosRequeridosTraductions![langCode] ??
        documentosRequeridosTraductions![langueParDefaut] ??
        documentosRequeridosTraductions!.values
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  }

  /// Retourne la procédure dans la langue spécifiée
  /// Note: Ce champ est conservé pour compatibilité mais les procédures sont maintenant
  /// stockées dans une table séparée et devraient être obtenues via ProcedureDao
  String? getProcedimiento(String langCode) {
    if (procedimientoTraductions == null || procedimientoTraductions!.isEmpty) {
      return null;
    }

    return procedimientoTraductions![langCode] ??
        procedimientoTraductions![langueParDefaut] ??
        procedimientoTraductions!.values
            .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  }

  /// Accesseur de compatibilité avec l'ancien code (retourne la version espagnole)
  String? get procedimiento => getProcedimiento(langueParDefaut);

  /// Crée une instance de Concepto à partir d'une Map.
  ///
  /// Cette méthode est utilisée pour convertir les données de la base de données
  /// en objet Concepto.
  factory Concepto.fromMap(Map<String, dynamic> map) {
    // Traiter les traductions du nom
    final Map<String, String> nombreTraductions = {};

    // Format standard de la base de données (colonnes pour chaque langue)
    if (map['nombre_es'] != null) nombreTraductions['es'] = map['nombre_es'];
    if (map['nombre_fr'] != null) nombreTraductions['fr'] = map['nombre_fr'];
    if (map['nombre_en'] != null) nombreTraductions['en'] = map['nombre_en'];

    // Si aucune traduction trouvée, utiliser le champ 'nombre' comme valeur espagnole
    if (nombreTraductions.isEmpty && map['nombre'] != null) {
      nombreTraductions['es'] = map['nombre'];
    }

    // Traiter les traductions des documents requis
    Map<String, String>? documentosRequeridosTraductions;

    if (map['documentos_requeridos_es'] != null ||
        map['documentos_requeridos_fr'] != null ||
        map['documentos_requeridos_en'] != null) {
      documentosRequeridosTraductions = {};

      if (map['documentos_requeridos_es'] != null) {
        documentosRequeridosTraductions['es'] = map['documentos_requeridos_es'];
      }
      if (map['documentos_requeridos_fr'] != null) {
        documentosRequeridosTraductions['fr'] = map['documentos_requeridos_fr'];
      }
      if (map['documentos_requeridos_en'] != null) {
        documentosRequeridosTraductions['en'] = map['documentos_requeridos_en'];
      }
    } else if (map['documentos_requeridos'] != null) {
      // Si aucune traduction mais champ original présent
      documentosRequeridosTraductions = {'es': map['documentos_requeridos']};
    }

    // Traiter les traductions de la procédure
    Map<String, String>? procedimientoTraductions;

    if (map['procedimiento_es'] != null ||
        map['procedimiento_fr'] != null ||
        map['procedimiento_en'] != null) {
      procedimientoTraductions = {};

      if (map['procedimiento_es'] != null) {
        procedimientoTraductions['es'] = map['procedimiento_es'];
      }
      if (map['procedimiento_fr'] != null) {
        procedimientoTraductions['fr'] = map['procedimiento_fr'];
      }
      if (map['procedimiento_en'] != null) {
        procedimientoTraductions['en'] = map['procedimiento_en'];
      }
    } else if (map['procedimiento'] != null) {
      // Si aucune traduction mais champ original présent
      procedimientoTraductions = {'es': map['procedimiento']};
    }

    return Concepto(
      id: map['id'],
      subCategoriaId: map['sub_categoria_id'],
      nombreTraductions: nombreTraductions,
      tasaExpedicion: map['tasa_expedicion'] ?? '',
      tasaRenovacion: map['tasa_renovacion'] ?? '',
      documentosRequeridosTraductions: documentosRequeridosTraductions,
      procedimientoTraductions: procedimientoTraductions,
    );
  }

  /// Crée une instance de Concepto à partir d'un JSON.
  ///
  /// Cette méthode est utilisée pour convertir les données JSON
  /// en objet Concepto avec support du format multilingue.
  factory Concepto.fromJson(Map<String, dynamic> json) {
    // Traiter les traductions du nom
    Map<String, String> nombreTraductions = {};
    var nombreData = json['nombre'];

    if (nombreData is String) {
      // Ancien format (chaîne simple) - considéré comme espagnol
      nombreTraductions['es'] = nombreData;
    } else if (nombreData is Map) {
      // Nouveau format (objet de traduction)
      nombreData.forEach((key, value) {
        if (value is String) {
          nombreTraductions[key] = value;
        }
      });
    }

    // Traiter les traductions des documents requis
    Map<String, String>? documentosRequeridosTraductions;
    var docsData = json['documentos_requeridos'];

    if (docsData != null) {
      documentosRequeridosTraductions = {};

      if (docsData is String) {
        // Ancien format (chaîne simple) - considéré comme espagnol
        if (docsData.isNotEmpty) {
          documentosRequeridosTraductions['es'] = docsData;
        }
      } else if (docsData is Map) {
        // Nouveau format (objet de traduction)
        docsData.forEach((key, value) {
          if (value is String && value.isNotEmpty) {
            documentosRequeridosTraductions![key] = value;
          }
        });
      }

      // Si aucune traduction n'a été ajoutée, mettre à null
      if (documentosRequeridosTraductions.isEmpty) {
        documentosRequeridosTraductions = null;
      }
    }

    // Traiter les traductions de la procédure
    Map<String, String>? procedimientoTraductions;
    var procData = json['procedimiento'];

    if (procData != null) {
      procedimientoTraductions = {};

      if (procData is String) {
        // Ancien format (chaîne simple) - considéré comme espagnol
        if (procData.isNotEmpty) {
          procedimientoTraductions['es'] = procData;
        }
      } else if (procData is Map) {
        // Nouveau format (objet de traduction)
        procData.forEach((key, value) {
          if (value is String && value.isNotEmpty) {
            procedimientoTraductions![key] = value;
          }
        });
      }

      // Si aucune traduction n'a été ajoutée, mettre à null
      if (procedimientoTraductions.isEmpty) {
        procedimientoTraductions = null;
      }
    }

    return Concepto(
      id: json['id'],
      subCategoriaId: json['sub_categoria_id'] ?? '',
      nombreTraductions: nombreTraductions,
      tasaExpedicion: json['tasa_expedicion'] ?? '',
      tasaRenovacion: json['tasa_renovacion'] ?? '',
      documentosRequeridosTraductions: documentosRequeridosTraductions,
      procedimientoTraductions: procedimientoTraductions,
    );
  }

  /// Convertit cette instance en Map.
  ///
  /// Cette méthode est utilisée pour préparer l'objet à être stocké
  /// dans la base de données.
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'sub_categoria_id': subCategoriaId,
      'tasa_expedicion': tasaExpedicion,
      'tasa_renovacion': tasaRenovacion,
    };

    // Ajouter les traductions du nom
    nombreTraductions.forEach((langCode, value) {
      map['nombre_$langCode'] = value;
    });

    // Compatibilité avec l'ancien format
    map['nombre'] = nombre;

    // Ajouter les traductions des documents requis si présentes
    if (documentosRequeridosTraductions != null) {
      documentosRequeridosTraductions!.forEach((langCode, value) {
        map['documentos_requeridos_$langCode'] = value;
      });

      // Compatibilité avec l'ancien format
      map['documentos_requeridos'] = getDocumentosRequeridos(langueParDefaut);
    } else {
      map['documentos_requeridos'] = null;
    }

    // Ajouter les traductions de la procédure si présentes
    if (procedimientoTraductions != null) {
      procedimientoTraductions!.forEach((langCode, value) {
        map['procedimiento_$langCode'] = value;
      });

      // Compatibilité avec l'ancien format
      map['procedimiento'] = procedimiento;
    } else {
      map['procedimiento'] = null;
    }

    return map;
  }

  /// Convertit cette instance en Map JSON avec support multilingue.
  ///
  /// Cette méthode est utilisée pour sérialiser l'objet en JSON.
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'sub_categoria_id': subCategoriaId,
      'nombre': nombreTraductions,
      'tasa_expedicion': tasaExpedicion,
      'tasa_renovacion': tasaRenovacion,
    };

    if (documentosRequeridosTraductions != null) {
      json['documentos_requeridos'] = documentosRequeridosTraductions;
    }

    if (procedimientoTraductions != null) {
      json['procedimiento'] = procedimientoTraductions;
    }

    return json;
  }

  /// Crée une copie de cette instance avec les champs spécifiés remplacés.
  ///
  /// Cette méthode est utile pour créer une version modifiée d'un objet
  /// sans altérer l'original.
  Concepto copyWith({
    String? id,
    String? subCategoriaId,
    Map<String, String>? nombreTraductions,
    String? tasaExpedicion,
    String? tasaRenovacion,
    Map<String, String>? documentosRequeridosTraductions,
    Map<String, String>? procedimientoTraductions,
  }) {
    return Concepto(
      id: id ?? this.id,
      subCategoriaId: subCategoriaId ?? this.subCategoriaId,
      nombreTraductions: nombreTraductions ?? Map.from(this.nombreTraductions),
      tasaExpedicion: tasaExpedicion ?? this.tasaExpedicion,
      tasaRenovacion: tasaRenovacion ?? this.tasaRenovacion,
      documentosRequeridosTraductions: documentosRequeridosTraductions ??
          this.documentosRequeridosTraductions,
      procedimientoTraductions:
          procedimientoTraductions ?? this.procedimientoTraductions,
    );
  }

  /// Ajoute ou met à jour une traduction du nom
  Concepto withNombreTraduction(String langCode, String value) {
    final newTraductions = Map<String, String>.from(nombreTraductions);
    newTraductions[langCode] = value;
    return copyWith(nombreTraductions: newTraductions);
  }

  /// Ajoute ou met à jour une traduction des documents requis
  /// Note: Cette méthode est maintenue pour compatibilité, mais il est préférable
  /// d'utiliser DocumentRequisDao pour gérer les documents directement
  Concepto withDocumentosRequeridosTraduction(String langCode, String value) {
    final newTraductions =
        Map<String, String>.from(documentosRequeridosTraductions ?? {});
    newTraductions[langCode] = value;
    return copyWith(documentosRequeridosTraductions: newTraductions);
  }

  /// Ajoute ou met à jour une traduction de la procédure
  /// Note: Cette méthode est maintenue pour compatibilité, mais il est préférable
  /// d'utiliser ProcedureDao pour gérer les procédures directement
  Concepto withProcedimientoTraduction(String langCode, String value) {
    final newTraductions =
        Map<String, String>.from(procedimientoTraductions ?? {});
    newTraductions[langCode] = value;
    return copyWith(procedimientoTraductions: newTraductions);
  }

  /// Vérifie si cette taxe a un montant d'expédition.
  bool get hasExpedicion => tasaExpedicion.isNotEmpty && tasaExpedicion != '-';

  /// Vérifie si cette taxe a un montant de renouvellement.
  bool get hasRenovacion => tasaRenovacion.isNotEmpty && tasaRenovacion != '-';

  /// Vérifie si cette taxe a une procédure dans n'importe quelle langue.
  /// Note: Cette méthode est maintenue pour compatibilité, mais il est préférable
  /// d'utiliser ProcedureDao pour vérifier si des procédures existent pour ce concept
  bool get hasProcedimiento =>
      procedimientoTraductions != null && procedimientoTraductions!.isNotEmpty;

  /// Vérifie si cette taxe a une procédure dans la langue spécifiée.
  /// Note: Cette méthode est maintenue pour compatibilité, mais il est préférable
  /// d'utiliser ProcedureDao pour vérifier si des procédures existent pour ce concept
  bool hasProcedimientoInLanguage(String langCode) {
    return procedimientoTraductions != null &&
        procedimientoTraductions!.containsKey(langCode) &&
        procedimientoTraductions![langCode]!.isNotEmpty;
  }

  /// Vérifie si cette taxe a des documents requis dans n'importe quelle langue.
  /// Note: Cette méthode est maintenue pour compatibilité, mais il est préférable
  /// d'utiliser DocumentRequisDao pour vérifier si des documents existent pour ce concept
  bool get hasDocumentosRequeridos =>
      documentosRequeridosTraductions != null &&
      documentosRequeridosTraductions!.isNotEmpty;

  /// Vérifie si cette taxe a des documents requis dans la langue spécifiée.
  /// Note: Cette méthode est maintenue pour compatibilité, mais il est préférable
  /// d'utiliser DocumentRequisDao pour vérifier si des documents existent pour ce concept
  bool hasDocumentosRequeridosInLanguage(String langCode) {
    return documentosRequeridosTraductions != null &&
        documentosRequeridosTraductions!.containsKey(langCode) &&
        documentosRequeridosTraductions![langCode]!.isNotEmpty;
  }

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
    return 'Concepto{id: $id, subCategoriaId: $subCategoriaId, nombreTraductions: $nombreTraductions, tasaExpedicion: $tasaExpedicion, tasaRenovacion: $tasaRenovacion, documentosRequeridosTraductions: $documentosRequeridosTraductions, procedimientoTraductions: $procedimientoTraductions}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Concepto &&
        other.id == id &&
        other.subCategoriaId == subCategoriaId &&
        _mapsEqual(other.nombreTraductions, nombreTraductions) &&
        other.tasaExpedicion == tasaExpedicion &&
        other.tasaRenovacion == tasaRenovacion &&
        _mapsEqual(other.documentosRequeridosTraductions,
            documentosRequeridosTraductions) &&
        _mapsEqual(other.procedimientoTraductions, procedimientoTraductions);
  }

  /// Utilitaire pour comparer deux maps
  bool _mapsEqual(Map<String, String>? map1, Map<String, String>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        subCategoriaId.hashCode ^
        nombreTraductions.hashCode ^
        tasaExpedicion.hashCode ^
        tasaRenovacion.hashCode ^
        documentosRequeridosTraductions.hashCode ^
        procedimientoTraductions.hashCode;
  }

  /// Crée un objet de mots-clés multilingues à partir de l'ID du concept et des données JSON
  static MotsClesMultilingues createMotsClesMultilingues(
      String conceptoId, dynamic json) {
    return MotsClesMultilingues.fromJson(conceptoId, json);
  }
}
