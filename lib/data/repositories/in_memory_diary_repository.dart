import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';
import 'package:my_diary/core/security/password_hasher.dart';

class InMemoryDiaryRepository implements DiaryRepository {
  InMemoryDiaryRepository({List<Diary>? seedDiaries})
      : _diaries = List<Diary>.from(
          seedDiaries ??
              <Diary>[
                const Diary(
                  id: '1',
                  name: 'Viagem 2026',
                  content: 'Planejar roteiro da viagem pela Europa.',
                  isPublic: true,
                ),
                Diary(
                  id: '2',
                  name: 'Trabalho',
                  content: 'Resumo da semana e próximos objetivos.',
                  password: PasswordHasher.hash('1234'),
                ),
                Diary(
                  id: '3',
                  name: 'Diario Pessoal',
                  content: 'Reflexões diárias.',
                  password: PasswordHasher.hash('segredo'),
                ),
              ],
        );

  final List<Diary> _diaries;

  @override
  Future<Diary?> findByName(String query) async {
    for (final diary in _diaries) {
      if (diary.name == query) {
        return diary;
      }
    }

    return null;
  }

  @override
  Future<Diary> createDiary({
    required String name,
    required String? password,
    required bool isPublic,
  }) async {
    final hashedPassword = _buildHashedPassword(
      password: password,
      isPublic: isPublic,
    );

    final diary = Diary(
      id: (_diaries.length + 1).toString(),
      name: name,
      content: '',
      password: hashedPassword,
      isPublic: isPublic,
    );
    _diaries.add(diary);
    return diary;
  }

  @override
  Future<void> updateDiaryContent({
    required String id,
    required String content,
  }) async {
    final index = _diaries.indexWhere((Diary diary) => diary.id == id);
    if (index == -1) {
      return;
    }

    _diaries[index] = _diaries[index].copyWith(content: content);
  }

  @override
  Future<void> updateDiaryAccess({
    required String id,
    required bool isPublic,
    String? password,
  }) async {
    final index = _diaries.indexWhere((Diary diary) => diary.id == id);
    if (index == -1) {
      return;
    }

    final updatedPassword = _resolveUpdatedPassword(
      diary: _diaries[index],
      isPublic: isPublic,
      password: password,
    );

    _diaries[index] = _diaries[index].copyWith(
      isPublic: isPublic,
      password: updatedPassword,
    );
  }

  String? _buildHashedPassword({
    required String? password,
    required bool isPublic,
  }) {
    if (isPublic || password == null || password.trim().isEmpty) {
      return null;
    }

    return PasswordHasher.hash(password);
  }

  String? _resolveUpdatedPassword({
    required Diary diary,
    required bool isPublic,
    required String? password,
  }) {
    if (isPublic) {
      return null;
    }

    final trimmedPassword = password?.trim();
    if (trimmedPassword != null && trimmedPassword.isNotEmpty) {
      return PasswordHasher.hash(trimmedPassword);
    }

    return diary.password;
  }
}
