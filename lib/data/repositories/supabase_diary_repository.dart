import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDiaryRepository implements DiaryRepository {
  SupabaseDiaryRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _tableName = 'diaries';

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
    final response = await _client
        .from(_tableName)
        .insert(<String, dynamic>{
          'name': name,
          'content': '',
          'password': isPublic ? null : password,
          'is_public': isPublic,
        })
        .select('id, name, content, password, is_public')
        .single();

    return _toDiary(response);
  }

  @override
  Future<void> updateDiaryContent({
    required String id,
    required String content,
  }) {
    return _client
        .from(_tableName)
        .update(<String, dynamic>{'content': content})
        .eq('id', id);
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
}
