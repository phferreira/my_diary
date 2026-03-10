import 'package:my_diary/core/entities/diary.dart';

abstract class DiaryRepository {
  Future<Diary?> findByName(String query);
}
