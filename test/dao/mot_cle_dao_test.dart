import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/mot_cle_dao.dart';
import 'package:taxasge/database/database_service.dart';
//import 'package:taxasge/models/mot_cle.dart';
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();
  group('MotCleDao Tests', () {
    late DatabaseService dbService;
    late MotCleDao motCleDao;
    const String testConceptoId = 'T-TEST';

    setUp(() async {
      dbService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      motCleDao = dbService.motCleDao;
    });
    tearDown(() async => await dbService.close());

    test('insert and getMotsClesByConceptoId', () async {
      // Les mots clés sont insérés via _importInitialData
      final motsCles = await motCleDao.getMotsClesByConceptoId(testConceptoId, langCode: 'es');
      expect(motsCles, isNotEmpty);
      expect(motsCles, contains('test'));
      expect(motsCles, contains('prueba'));
    });
    
    test('getMotsClesMultilinguesByConceptoId returns correct structure', () async {
      final motsClesMulti = await motCleDao.getMotsClesMultilinguesByConceptoId(testConceptoId);
      expect(motsClesMulti.motsClesByLang.containsKey('es'), isTrue);
      expect(motsClesMulti.motsClesByLang['es'], containsAll(['test', 'prueba']));
      // minimalTestJson provided in database_test_utils.dart for previous tasks also had fr and en keywords
      // "palabras_clave": { "es": "test_es,prueba_es", "fr": "test_fr,essai_fr", "en": "test_en,trial_en" }
      // However, the minimalTestJson in *this current task prompt* for files like ministerio_dao_test.dart only has 'es'.
      // Let's assume the minimalTestJson from database_test_utils.dart is the one used by getTestDatabaseService.
      // The one in this prompt for ministerio_dao_test.dart is:
      // "palabras_clave": { "es": "test,prueba" }
      // So for 'fr' and 'en' it should be empty or not present based on THIS specific minimalTestJson.
      // The minimalTestJson in database_test_utils.dart (as per turn 18) is:
      // "palabras_clave": { "es": "test,prueba" }
      // So, only 'es' keywords are expected.
      expect(motsClesMulti.motsClesByLang.containsKey('fr'), isFalse); // Based on current minimalTestJson
      expect(motsClesMulti.motsClesByLang.containsKey('en'), isFalse); // Based on current minimalTestJson
    });

    test('deleteByConceptoId removes keywords', () async {
      await motCleDao.deleteByConceptoId(testConceptoId);
      final motsCles = await motCleDao.getMotsClesByConceptoId(testConceptoId, langCode: 'es');
      expect(motsCles, isEmpty);
    });
  });
}
