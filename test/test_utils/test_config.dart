/// Obtient l'instance de la base de données
  Database get database {
    if (_db == null) {
      throw Exception('Database not initialized');
    }
    return _db!;
  }