import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';

class InMemoryDiaryRepository implements DiaryRepository {
  InMemoryDiaryRepository({List<Diary>? seedDiaries})
      : _diaries = seedDiaries ??
            const <Diary>[
              Diary(id: '1', name: 'Viagem 2026'),
              Diary(id: '2', name: 'Trabalho'),
              Diary(id: '3', name: 'Diario Pessoal'),
            ];

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
}
