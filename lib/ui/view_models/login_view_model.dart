import 'package:my_diary/core/usecases/find_diary_use_case.dart';

class LoginViewModel {
  LoginViewModel(this._findDiaryUseCase);

  final FindDiaryUseCase _findDiaryUseCase;

  Future<String> findDiaryMessage(String rawQuery) async {
    final diary = await _findDiaryUseCase(rawQuery);

    if (diary == null) {
      return 'Diário não encontrado';
    }

    return 'Diário encontrado: ${diary.name}';
  }
}
