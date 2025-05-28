import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/sector_dao.dart';
import 'package:taxasge/database/database_service.dart';
//import 'package:taxasge/models/sector.dart';
import 'package:taxasge/services/localization_service.dart';
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();
  group('SectorDao Tests', () {
    late DatabaseService dbService;
    late SectorDao sectorDao;

    setUp(() async {
      dbService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      sectorDao = dbService.sectorDao;
      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });
    tearDown(() async => await dbService.close());

    test('insert and getById', () async {
      final item = await sectorDao.getById('S-TEST');
      expect(item, isNotNull);
      expect(item!.getNombre('es'), 'SECTOR PRUEBA');
    });
    test('getByMinisterioId returns items', () async {
      final items = await sectorDao.getByMinisterioId('M-TEST', langCode: 'es');
      expect(items.length, 1);
    });
  });
}
