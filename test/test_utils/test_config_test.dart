import 'package:flutter_test/flutter_test.dart';
import 'test_config.dart';
import 'package:taxasge/database/database_service.dart';
//import 'package:taxasge/database/dao/ministerio_dao.dart';

void main() {
  setUpAll(() async {
    await TestConfig.initialize(); // Initialisation globale du test
  });

  test('TestConfig should initialize database correctly', () async {
    final dbService = await TestConfig.initializeDatabase();

    // Vérifie que le service n'est pas null
    expect(dbService, isA<DatabaseService>());

    // Vérifie que le nombre de ministères test chargés est > 0
    final ministerios = await dbService.ministerioDao.getAll();
    expect(ministerios.length, greaterThan(0));
  });
}
