import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/entities/diary_entry.dart';
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
        ),
        _entries = <String, Map<String, DiaryEntry>>{} {
    _seedEntriesFromDiaries();
  }

  final List<Diary> _diaries;
  final Map<String, Map<String, DiaryEntry>> _entries;

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
    String? publicPassword,
  }) async {
    final hashedPassword = _buildHashedPassword(
      password: password,
      isPublic: isPublic,
    );
    final hashedPublicPassword = _buildHashedPublicPassword(
      publicPassword: publicPassword,
      isPublic: isPublic,
    );

    final diary = Diary(
      id: (_diaries.length + 1).toString(),
      name: name,
      content: '',
      password: hashedPassword,
      publicPassword: hashedPublicPassword,
      isPublic: isPublic,
    );
    _diaries.add(diary);
    return diary;
  }

  @override
  Future<DiaryEntry?> findEntryByDate({
    required String diaryId,
    required DateTime date,
  }) async {
    final diaryEntries = _entries[diaryId];
    if (diaryEntries == null) {
      return null;
    }

    return diaryEntries[_dateKey(date)];
  }

  @override
  Future<void> upsertDiaryEntry({
    required String diaryId,
    required DateTime date,
    required String content,
  }) async {
    final normalizedDate = _normalizeDate(date);
    final diaryEntries = _entries.putIfAbsent(
      diaryId,
      () => <String, DiaryEntry>{},
    );

    diaryEntries[_dateKey(normalizedDate)] = DiaryEntry(
      diaryId: diaryId,
      date: normalizedDate,
      content: content,
    );
  }

  @override
  Future<void> updateDiaryAccess({
    required String id,
    required bool isPublic,
    String? password,
    String? publicPassword,
  }) async {
    final index = _diaries.indexWhere((Diary diary) => diary.id == id);
    if (index == -1) {
      return;
    }

    final currentDiary = _diaries[index];
    final updatedPassword = _resolveUpdatedPassword(
      diary: currentDiary,
      isPublic: isPublic,
      password: password,
    );
    final updatedPublicPassword = _resolveUpdatedPublicPassword(
      diary: currentDiary,
      isPublic: isPublic,
      publicPassword: publicPassword,
    );

    _diaries[index] = _diaries[index].copyWith(
      isPublic: isPublic,
      password: updatedPassword,
      publicPassword: updatedPublicPassword,
    );
  }

  String? _buildHashedPassword({
    required String? password,
    required bool isPublic,
  }) {
    if (password == null || password.trim().isEmpty) {
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
      return diary.password;
    }

    final trimmedPassword = password?.trim();
    if (trimmedPassword != null && trimmedPassword.isNotEmpty) {
      return PasswordHasher.hash(trimmedPassword);
    }

    return diary.password;
  }

  String? _buildHashedPublicPassword({
    required String? publicPassword,
    required bool isPublic,
  }) {
    if (!isPublic || publicPassword == null || publicPassword.trim().isEmpty) {
      return null;
    }

    return PasswordHasher.hash(publicPassword);
  }

  String? _resolveUpdatedPublicPassword({
    required Diary diary,
    required bool isPublic,
    required String? publicPassword,
  }) {
    if (!isPublic) {
      return null;
    }

    final trimmedPassword = publicPassword?.trim();
    if (trimmedPassword == null || trimmedPassword.isEmpty) {
      if (diary.publicPassword == null) {
        throw ArgumentError(
          'publicPassword',
          'A senha pública é obrigatória para diário público.',
        );
      }

      return diary.publicPassword;
    }

    if (diary.hasPassword && diary.matchesPassword(trimmedPassword)) {
      throw ArgumentError(
        'publicPassword',
        'A senha pública deve ser diferente da senha mestre.',
      );
    }

    return PasswordHasher.hash(trimmedPassword);
  }

  void _seedEntriesFromDiaries() {
    final today = _normalizeDate(DateTime.now());
    final todayKey = _dateKey(today);

    for (final diary in _diaries) {
      if (diary.content.trim().isEmpty) {
        continue;
      }

      final diaryEntries = _entries.putIfAbsent(
        diary.id,
        () => <String, DiaryEntry>{},
      );
      diaryEntries[todayKey] = DiaryEntry(
        diaryId: diary.id,
        date: today,
        content: diary.content,
      );
    }
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _dateKey(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
