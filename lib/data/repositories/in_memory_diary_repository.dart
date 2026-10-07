import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/entities/diary_access.dart';
import 'package:my_diary/core/entities/diary_entry.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';

class InMemoryDiaryCredentials {
  const InMemoryDiaryCredentials({this.masterPassword, this.publicPassword});
  final String? masterPassword;
  final String? publicPassword;
}

class InMemoryDiaryRepository implements DiaryRepository {
  InMemoryDiaryRepository(
      {List<Diary>? seedDiaries,
      Map<String, InMemoryDiaryCredentials>? seedCredentials})
      : _diaries = List<Diary>.from(seedDiaries ?? _defaultDiaries),
        _credentials = Map<String, InMemoryDiaryCredentials>.from(
            seedCredentials ?? _defaultCredentials),
        _entries = <String, Map<String, DiaryEntry>>{} {
    _seedEntriesFromDiaries();
  }

  static final List<Diary> _defaultDiaries = <Diary>[
    const Diary(
        id: '1',
        name: 'Viagem 2026',
        content: 'Planejar roteiro da viagem pela Europa.',
        isPublic: true),
    const Diary(
        id: '2',
        name: 'Trabalho',
        content: 'Resumo da semana e próximos objetivos.',
        accessRequired: true),
    const Diary(
        id: '3',
        name: 'Diario Pessoal',
        content: 'Reflexões diárias.',
        accessRequired: true),
  ];
  static const Map<String, InMemoryDiaryCredentials> _defaultCredentials = {
    '2': InMemoryDiaryCredentials(masterPassword: '1234'),
    '3': InMemoryDiaryCredentials(masterPassword: 'segredo'),
  };

  final List<Diary> _diaries;
  final Map<String, InMemoryDiaryCredentials> _credentials;
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
  Future<DiaryAccess?> unlockDiary(
      {required Diary diary, required String password}) async {
    final index = _diaries.indexWhere((item) => item.id == diary.id);
    if (index == -1) return null;
    final current = _diaries[index];
    final credentials = _credentials[current.id];
    if (credentials?.masterPassword == password.trim()) {
      return DiaryAccess(diaryId: current.id, canEdit: true);
    }
    if (current.isPublic && credentials?.publicPassword == password.trim()) {
      return DiaryAccess(diaryId: current.id, canEdit: false);
    }
    return null;
  }

  @override
  Future<Diary> createDiary(
      {required String name,
      required String? password,
      required bool isPublic,
      String? publicPassword}) async {
    final master = _normalizeCredential(password);
    final public = isPublic ? _normalizeCredential(publicPassword) : null;
    _validateAccess(isPublic, master, public);
    final diary = Diary(
        id: (_diaries.length + 1).toString(),
        name: name,
        content: '',
        isPublic: isPublic,
        accessRequired: master != null || public != null);
    _diaries.add(diary);
    _credentials[diary.id] = InMemoryDiaryCredentials(
        masterPassword: master, publicPassword: public);
    return diary;
  }

  @override
  Future<DiaryEntry?> findEntryByDate(
          {required String diaryId, required DateTime date}) async =>
      _entries[diaryId]?[_dateKey(date)];

  @override
  Future<void> upsertDiaryEntry(
      {required String diaryId,
      required DateTime date,
      required String content}) async {
    final normalizedDate = _normalizeDate(date);
    final diaryEntries =
        _entries.putIfAbsent(diaryId, () => <String, DiaryEntry>{});
    diaryEntries[_dateKey(normalizedDate)] =
        DiaryEntry(diaryId: diaryId, date: normalizedDate, content: content);
  }

  @override
  Future<void> updateDiaryAccess(
      {required String id,
      required bool isPublic,
      String? password,
      String? publicPassword}) async {
    final index = _diaries.indexWhere((diary) => diary.id == id);
    if (index == -1) return;
    final current = _diaries[index];
    final existing = _credentials[id] ?? const InMemoryDiaryCredentials();
    final master = password == null
        ? existing.masterPassword
        : _normalizeCredential(password);
    final public = !isPublic
        ? null
        : publicPassword == null
            ? existing.publicPassword
            : _normalizeCredential(publicPassword);
    _validateAccess(isPublic, master, public);
    _credentials[id] = InMemoryDiaryCredentials(
        masterPassword: master, publicPassword: public);
    _diaries[index] = current.copyWith(
        isPublic: isPublic, accessRequired: master != null || public != null);
  }

  static String? _normalizeCredential(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static void _validateAccess(bool isPublic, String? master, String? public) {
    if (isPublic && public == null) {
      throw ArgumentError('A public password is required.');
    }
    if (isPublic && master != null && master == public) {
      throw ArgumentError('Public and master passwords must differ.');
    }
  }

  void _seedEntriesFromDiaries() {
    final today = _normalizeDate(DateTime.now());
    final todayKey = _dateKey(today);
    for (final diary in _diaries) {
      if (diary.content.trim().isEmpty) continue;
      final diaryEntries =
          _entries.putIfAbsent(diary.id, () => <String, DiaryEntry>{});
      diaryEntries[todayKey] =
          DiaryEntry(diaryId: diary.id, date: today, content: diary.content);
    }
  }

  static DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static String _dateKey(DateTime date) =>
      date.toIso8601String().split('T').first;
}
