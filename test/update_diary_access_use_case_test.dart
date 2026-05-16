import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';

void main() {
  group('UpdateDiaryAccessUseCase', () {
    test('define diário como privado e cria senha', () async {
      final repository = InMemoryDiaryRepository(
        seedDiaries: const <Diary>[
          Diary(id: '1', name: 'Diario', content: '', isPublic: true),
        ],
      );
      final useCase = UpdateDiaryAccessUseCase(repository);

      await useCase(diaryId: '1', isPublic: false, password: 'segredo');

      final updatedDiary = await repository.findByName('Diario');

      expect(updatedDiary, isNotNull);
      expect(updatedDiary!.isPublic, isFalse);
      expect(updatedDiary.password, isNotNull);
      expect(updatedDiary.publicPassword, isNull);
    });

    test('define diário como público com senha separada da mestre', () async {
      final repository = InMemoryDiaryRepository(
        seedDiaries: const <Diary>[
          Diary(
            id: '1',
            name: 'Diario',
            content: '',
            password: 'hash',
          ),
        ],
      );
      final useCase = UpdateDiaryAccessUseCase(repository);

      await useCase(
        diaryId: '1',
        isPublic: true,
        publicPassword: 'publica',
      );

      final updatedDiary = await repository.findByName('Diario');

      expect(updatedDiary, isNotNull);
      expect(updatedDiary!.isPublic, isTrue);
      expect(updatedDiary.password, isNotNull);
      expect(updatedDiary.publicPassword, isNotNull);
    });

    test('não aceita senha pública igual à senha mestre', () async {
      final repository = InMemoryDiaryRepository(
        seedDiaries: const <Diary>[
          Diary(
            id: '1',
            name: 'Diario',
            content: '',
            password: 'hash',
          ),
        ],
      );
      final useCase = UpdateDiaryAccessUseCase(repository);

      expect(
        () => useCase(
          diaryId: '1',
          isPublic: true,
          publicPassword: 'hash',
        ),
        throwsArgumentError,
      );
    });
  });
}
