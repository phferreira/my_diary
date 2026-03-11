import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/usecases/create_diary_use_case.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';
import 'package:my_diary/ui/view_models/login_view_model.dart';

void main() {
  group('LoginViewModel', () {
    late InMemoryDiaryRepository repository;
    late LoginViewModel viewModel;

    setUp(() {
      repository = InMemoryDiaryRepository();
      viewModel = LoginViewModel(
        FindDiaryUseCase(repository),
        CreateDiaryUseCase(repository),
      );
    });

    test('retorna status de senha para diário protegido', () async {
      final result = await viewModel.findDiary('Trabalho');

      expect(result.status, DiaryLookupStatus.requiresPassword);
    });

    test('cria diário público sem senha', () async {
      final diary = await viewModel.createDiary(
        name: 'Publico',
        password: null,
        isPublic: true,
      );

      expect(diary.isPublic, isTrue);
      expect(diary.password, isNull);
    });
  });
}
