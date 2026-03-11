import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/create_diary_use_case.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';

class LoginViewModel {
  LoginViewModel(this._findDiaryUseCase, this._createDiaryUseCase);

  final FindDiaryUseCase _findDiaryUseCase;
  final CreateDiaryUseCase _createDiaryUseCase;

  Future<DiaryLookupResult> findDiary(String rawQuery) async {
    final diary = await _findDiaryUseCase(rawQuery);

    if (diary == null) {
      return const DiaryLookupResult.notFound();
    }

    if (diary.isProtected) {
      return DiaryLookupResult.requiresPassword(diary);
    }

    return DiaryLookupResult.open(diary);
  }

  Future<Diary?> unlockDiary({
    required Diary diary,
    required String password,
  }) async {
    if (diary.matchesPassword(password.trim())) {
      return diary;
    }

    return null;
  }

  Future<Diary> createDiary({
    required String name,
    required String? password,
    required bool isPublic,
  }) {
    return _createDiaryUseCase(
      name: name,
      password: password,
      isPublic: isPublic,
    );
  }
}

class DiaryLookupResult {
  const DiaryLookupResult._({this.diary, required this.status});

  const DiaryLookupResult.notFound() : this._(status: DiaryLookupStatus.notFound);

  const DiaryLookupResult.requiresPassword(Diary this.diary)
      : status = DiaryLookupStatus.requiresPassword;

  const DiaryLookupResult.open(Diary this.diary) : status = DiaryLookupStatus.open;

  final Diary? diary;
  final DiaryLookupStatus status;
}

enum DiaryLookupStatus { notFound, requiresPassword, open }
