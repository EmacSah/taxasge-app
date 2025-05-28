import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/ministerio_dao.dart';
import 'package:taxasge/database/database_service.dart';
//import 'package:taxasge/models/ministerio.dart';
import 'package:taxasge/services/localization_service.dart';
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();
  group('MinisterioDao Tests', () {
    late DatabaseService dbService;
    late MinisterioDao ministerioDao;

    setUp(() async {
      dbService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      ministerioDao = dbService.ministerioDao;
      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });
    tearDown(() async => await dbService.close());

    test('insert and getById', () async {
      final item = await ministerioDao.getById('M-TEST');
      expect(item, isNotNull);
      expect(item!.getNombre('es'), 'MINISTERIO DE PRUEBA');
    });
    test('getAll returns items', () async {
      final items = await ministerioDao.getAll(langCode: 'es');
      expect(items.length, 1);
    });
    test('update an item', () async {
      final item = (await ministerioDao.getById('M-TEST'))!;
      final updated = item.copyWith(nombreTraductions: {'es': 'Nuevo Nombre ES', 'fr': 'Nouveau Nom FR'});
      await ministerioDao.update(updated);
      final fetched = await ministerioDao.getById('M-TEST');
      expect(fetched!.getNombre('es'), 'Nuevo Nombre ES');
      expect(fetched.getNombre('fr'), 'Nouveau Nom FR');
    });
    test('delete an item', () async {
      await ministerioDao.delete('M-TEST');
      expect(await ministerioDao.getById('M-TEST'), isNull);
    });
    test('count items', () async {
      expect(await ministerioDao.count(), 1);
    });
  });
}
