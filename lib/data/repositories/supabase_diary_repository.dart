import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/entities/diary_entry.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';
import 'package:my_diary/core/security/password_hasher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDiaryRepository implements DiaryRepository {
  SupabaseDiaryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _tableName = 'tb_diaries';
  static const String _entriesTableName = 'tb_diary_entries';

  @override
  Future<Diary?> findByName(String query) async {
    final response = await _client
        .from(_tableName)
        .select('id, name, content, password, is_public')
        .eq('name', query)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _toDiary(response);
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

    final response = await _client
        .from(_tableName)
        .insert(<String, dynamic>{
          'name': name,
          'content': '',
          'password': hashedPassword,
          'is_public': isPublic,
        })
        .select('id, name, content, password, is_public')
        .single();

    return _toDiary(response);
  }

  @override
  Future<DiaryEntry?> findEntryByDate({
    required String diaryId,
    required DateTime date,
  }) async {
    final response = await _client
        .from(_entriesTableName)
        .select('diary_id, entry_date, content')
        .eq('diary_id', diaryId)
        .eq('entry_date', _formatDate(date))
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return DiaryEntry(
      diaryId: response['diary_id'].toString(),
      date: _parseDate(response['entry_date']),
      content: (response['content'] as String?) ?? '',
    );
  }

  @override
  Future<void> upsertDiaryEntry({
    required String diaryId,
    required DateTime date,
    required String content,
  }) {
    return _client.from(_entriesTableName).upsert(
      <String, dynamic>{
        'diary_id': diaryId,
        'entry_date': _formatDate(date),
        'content': content,
      },
      onConflict: 'diary_id,entry_date',
    );
  }

  Diary _toDiary(Map<String, dynamic> json) {
    return Diary(
      id: json['id'].toString(),
      name: json['name'] as String,
      content: (json['content'] as String?) ?? '',
      password: json['password'] as String?,
      isPublic: (json['is_public'] as bool?) ?? false,
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

  DateTime _parseDate(Object? value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _formatDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}
