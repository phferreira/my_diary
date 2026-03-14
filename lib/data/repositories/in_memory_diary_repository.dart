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

  String? _buildHashedPassword({
    required String? password,
    required bool isPublic,
  }) {
    if (isPublic || password == null || password.trim().isEmpty) {
      return null;
    }

    return PasswordHasher.hash(password);
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
