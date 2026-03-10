import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/value_objects/diary_query.dart';

void main() {
  group('DiaryQuery.validate', () {
    test('retorna erro para texto vazio', () {
      expect(DiaryQuery.validate('   '), isNotNull);
    });

    test('retorna erro para mais de 40 caracteres', () {
      final value = 'a' * 41;
      expect(DiaryQuery.validate(value), 'Use no máximo 40 caracteres');
    });

    test('retorna erro para caracteres especiais', () {
      expect(
        DiaryQuery.validate('meu_diario!'),
        'Use apenas letras, números e espaço',
      );
    });

    test('aceita texto válido', () {
      expect(DiaryQuery.validate('Diario 2026'), isNull);
    });
  });
}
