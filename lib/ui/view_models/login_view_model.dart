import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/create_diary_use_case.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/core/usecases/unlock_diary_use_case.dart';

class LoginViewModel {
  LoginViewModel(this._findDiaryUseCase, this._createDiaryUseCase,
      this._unlockDiaryUseCase);

  final FindDiaryUseCase _findDiaryUseCase;
  final CreateDiaryUseCase _createDiaryUseCase;
  final UnlockDiaryUseCase _unlockDiaryUseCase;

  Future<DiaryLookupResult> findDiary(String rawQuery) async {
    final diary = await _findDiaryUseCase(rawQuery);

    if (diary == null) {
      return const DiaryLookupResult.notFound();
    }

    if (diary.requiresPassword) {
      return DiaryLookupResult.requiresPassword(diary);
    }

    return DiaryLookupResult.open(diary);
  }

  Future<DiaryUnlockResult?> unlockDiary({
    required Diary diary,
    required String password,
  }) async {
    final access = await _unlockDiaryUseCase(diary: diary, password: password);
    if (access == null) return null;
    return DiaryUnlockResult(diary: diary, canEdit: access.canEdit);
  }

  Future<Diary> createDiary({
    required String name,
    required String? password,
  }) {
    return _createDiaryUseCase(name: name, password: password);
  }
}

class DiaryUnlockResult {
  const DiaryUnlockResult({
    required this.diary,
    required this.canEdit,
  });

  final Diary diary;
  final bool canEdit;
}

class DiaryLookupResult {
  const DiaryLookupResult._({this.diary, required this.status});

  const DiaryLookupResult.notFound()
      : this._(status: DiaryLookupStatus.notFound);

  const DiaryLookupResult.requiresPassword(Diary this.diary)
      : status = DiaryLookupStatus.requiresPassword;

  const DiaryLookupResult.open(Diary this.diary)
      : status = DiaryLookupStatus.open;

  final Diary? diary;
  final DiaryLookupStatus status;
}

enum DiaryLookupStatus { notFound, requiresPassword, open }
