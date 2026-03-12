import 'package:my_diary/core/entities/diary.dart';

abstract class DiaryRepository {
  Future<Diary?> findByName(String query);

  Future<Diary> createDiary({
    required String name,
    required String? password,
    required bool isPublic,
  });

  Future<void> updateDiaryContent({
    required String id,
    required String content,
  });

  Future<void> updateDiaryAccess({
    required String id,
    required bool isPublic,
    String? password,
  });
}
