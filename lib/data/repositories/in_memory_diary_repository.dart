import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';

class InMemoryDiaryRepository implements DiaryRepository {
  InMemoryDiaryRepository({List<Diary>? seedDiaries})
      : _diaries = List<Diary>.from(
          seedDiaries ??
              const <Diary>[
                Diary(
                  id: '1',
                  name: 'Viagem 2026',
                  content: 'Planejar roteiro da viagem pela Europa.',
                  isPublic: true,
                ),
                Diary(
                  id: '2',
                  name: 'Trabalho',
                  content: 'Resumo da semana e próximos objetivos.',
                  password: '1234',
                ),
                Diary(
                  id: '3',
                  name: 'Diario Pessoal',
                  content: 'Reflexões diárias.',
                  password: 'segredo',
                ),
              ],
        );

  final List<Diary> _diaries;

  @override
  Future<Diary?> findByName(String query) async {
    for (final diary in _diaries) {
      if (diary.name.toLowerCase() == query.toLowerCase()) {
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
    final diary = Diary(
      id: (_diaries.length + 1).toString(),
      name: name,
      content: '',
      password: isPublic ? null : password,
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
}
