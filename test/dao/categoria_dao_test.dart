import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/categoria_dao.dart';
import 'package:taxasge/database/database_service.dart';
//import 'package:taxasge/models/categoria.dart';
import 'package:taxasge/services/localization_service.dart';
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();
  group('CategoriaDao Tests', () {
    late DatabaseService dbService;
    late CategoriaDao categoriaDao;

    setUp(() async {
      dbService = await getTestDatabaseService(
          testJsonString: minimalTestJson, seedData: true);
      categoriaDao = dbService.categoriaDao;
      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });
    tearDown(() async => await dbService.close());

    test('insert and getById', () async {
      final item = await categoriaDao.getById('C-TEST');
      expect(item, isNotNull);
      expect(item!.getNombre('es'), 'CATEGORIA PRUEBA');
    });
    test('getBySectorId returns items', () async {
      final items = await categoriaDao.getBySectorId('S-TEST', langCode: 'es');
      expect(items.length, 1);
    });
  });
}
