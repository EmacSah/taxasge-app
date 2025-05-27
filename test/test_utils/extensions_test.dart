import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:taxasge/theme/extensions.dart';

void main() {
  group('String Extension - Texte', () {
    test('capitalize() should capitalize each word', () {
      expect('ministère de la culture'.capitalize(), 'Ministère De La Culture');
      expect(''.capitalize(), '');
    });

    test('truncate() should truncate and add "..." when needed', () {
      expect('1234567890'.truncate(5), '12345...');
      expect('abcd'.truncate(10), 'abcd');
    });
  });

  group('MinistryColorExtension', () {
    test('getMinistryColor returns a Color', () {
      final color = 'TRANSPORTE'.getMinistryColor();
      expect(color, isA<Color>());
    });

    test('getLightMinistryColor returns a less opaque Color', () {
      final base = 'COMERCIO'.getMinistryColor();
      final light = 'COMERCIO'.getLightMinistryColor(0.2);

      expect(light.a, closeTo(51.0, 2)); // 0.2 * 255 = 51, tolérance = ±2
      expect(light.r, equals(base.r)); // red   -> r
      expect(light.g, equals(base.g)); // green -> g
      expect(light.b, equals(base.b)); // blue  -> b
      debugPrint('base alpha: ${base.a}, light alpha: ${light.a}');
    });
  });

  group('TranslationMapExtension', () {
    test('getTranslation returns correct translation with fallback', () {
      final map = {'fr': 'Bonjour', 'es': 'Hola'};
      expect(map.getTranslation('en', fallbackLang: 'fr'), 'Bonjour');
    });

    test('hasTranslation returns true only if value is non-empty', () {
      final map = {'fr': 'Bonjour', 'en': ''};
      expect(map.hasTranslation('fr'), true);
      expect(map.hasTranslation('en'), false);
    });

    test('hasAnyTranslation works correctly', () {
      final map = {'en': '', 'fr': 'Salut'};
      expect(map.hasAnyTranslation, true);

      final emptyMap = {'en': '', 'fr': ''};
      expect(emptyMap.hasAnyTranslation, false);
    });
  });
}
