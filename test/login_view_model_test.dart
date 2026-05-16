import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/usecases/create_diary_use_case.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/core/security/password_hasher.dart';
import 'package:my_diary/core/entities/diary.dart';
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

    test('desbloqueia diário protegido com senha correta', () async {
      final result = await viewModel.findDiary('Trabalho');
      final diary = result.diary;

      expect(diary, isNotNull);

      final unlockedDiary = await viewModel.unlockDiary(
        diary: diary!,
        password: '1234',
      );

      expect(unlockedDiary, isNotNull);
      expect(unlockedDiary!.canEdit, isTrue);
    });

    test('não desbloqueia diário protegido com senha incorreta', () async {
      final result = await viewModel.findDiary('Trabalho');
      final diary = result.diary;

      expect(diary, isNotNull);

      final unlockedDiary = await viewModel.unlockDiary(
        diary: diary!,
        password: 'senha-invalida',
      );

      expect(unlockedDiary, isNull);
    });

    test('desbloqueia diário público em modo somente leitura', () async {
      final publicRepository = InMemoryDiaryRepository(
        seedDiaries: <Diary>[
          Diary(
            id: '1',
            name: 'Leitura',
            content: '',
            password: PasswordHasher.hash('mestre'),
            publicPassword: PasswordHasher.hash('publica'),
            isPublic: true,
          ),
        ],
      );
      final publicViewModel = LoginViewModel(
        FindDiaryUseCase(publicRepository),
        CreateDiaryUseCase(publicRepository),
      );

      final result = await publicViewModel.findDiary('Leitura');
      expect(result.status, DiaryLookupStatus.requiresPassword);

      final diary = result.diary;
      expect(diary, isNotNull);

      final unlockedDiary = await publicViewModel.unlockDiary(
        diary: diary!,
        password: 'publica',
      );

      expect(unlockedDiary, isNotNull);
      expect(unlockedDiary!.canEdit, isFalse);
    });

    test('cria diário privado salvando senha criptografada', () async {
      final diary = await viewModel.createDiary(
        name: 'Privado',
        password: 'minhaSenha',
      );

      expect(diary.password, isNot('minhaSenha'));
      expect(diary.matchesPassword('minhaSenha'), isTrue);
      expect(diary.isPublic, isFalse);
    });
  });
}
