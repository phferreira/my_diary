import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/entities/diary_entry.dart';

abstract class DiaryRepository {
  Future<Diary?> findByName(String query);

  Future<Diary> createDiary({
    required String name,
    required String? password,
    required bool isPublic,
  });

  Future<DiaryEntry?> findEntryByDate({
    required String diaryId,
    required DateTime date,
  });

  Future<void> upsertDiaryEntry({
    required String diaryId,
    required DateTime date,
    required String content,
  });

  Future<void> updateDiaryAccess({
    required String id,
    required bool isPublic,
    String? password,
  });
}
