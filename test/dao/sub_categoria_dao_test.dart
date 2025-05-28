import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/sub_categoria_dao.dart';
import 'package:taxasge/database/database_service.dart';
//import 'package:taxasge/models/sub_categoria.dart';
import 'package:taxasge/services/localization_service.dart';
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();
  group('SubCategoriaDao Tests', () {
    late DatabaseService dbService;
    late SubCategoriaDao subCategoriaDao;

    setUp(() async {
      dbService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      subCategoriaDao = dbService.subCategoriaDao;
      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });
    tearDown(() async => await dbService.close());

    test('insert and getById', () async {
      final item = await subCategoriaDao.getById('SC-TEST');
      expect(item, isNotNull);
      expect(item!.getNombre('es'), 'SUBCATEGORIA PRUEBA');
    });
    test('getByCategoriaId returns items', () async {
      final items = await subCategoriaDao.getByCategoriaId('C-TEST', langCode: 'es');
      expect(items.length, 1);
    });
  });
}
