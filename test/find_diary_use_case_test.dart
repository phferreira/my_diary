import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';

void main() {
  group('FindDiaryUseCase', () {
    test('retorna diário quando nome existe', () async {
      final repository = InMemoryDiaryRepository(
        seedDiaries: const <Diary>[
          Diary(id: '1', name: 'Meu Diario', content: ''),
        ],
      );
      final useCase = FindDiaryUseCase(repository);

      final result = await useCase('Meu Diario');

      expect(result, isNotNull);
      expect(result?.name, 'Meu Diario');
    });

    test('retorna nulo para entrada inválida', () async {
      final repository = InMemoryDiaryRepository();
      final useCase = FindDiaryUseCase(repository);

      final result = await useCase('');

      expect(result, isNull);
    });


    test('retorna nulo quando há diferença entre maiúsculas e minúsculas', () async {
      final repository = InMemoryDiaryRepository(
        seedDiaries: const <Diary>[
          Diary(id: '1', name: 'Meu Diario', content: ''),
        ],
      );
      final useCase = FindDiaryUseCase(repository);

      final result = await useCase('meu diario');

      expect(result, isNull);
    });

    test('retorna nulo quando diário não existe', () async {
      final repository = InMemoryDiaryRepository();
      final useCase = FindDiaryUseCase(repository);

      final result = await useCase('Inexistente');

      expect(result, isNull);
    });
  });
}
