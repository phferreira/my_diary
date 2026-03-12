import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';
import 'package:my_diary/core/security/password_hasher.dart';
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
  Future<void> updateDiaryContent({
    required String id,
    required String content,
  }) {
    return _client
        .from(_tableName)
        .update(<String, dynamic>{'content': content}).eq('id', id);
  }

  @override
  Future<void> updateDiaryAccess({
    required String id,
    required bool isPublic,
    String? password,
  }) {
    final updatedPassword = _resolveUpdatedPassword(
      isPublic: isPublic,
      password: password,
    );

    final payload = <String, dynamic>{'is_public': isPublic};
    if (updatedPassword != _omitPasswordUpdate) {
      payload['password'] = updatedPassword;
    }

    return _client.from(_tableName).update(payload).eq('id', id);
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

  String? _resolveUpdatedPassword({
    required bool isPublic,
    required String? password,
  }) {
    if (isPublic) {
      return null;
    }

    final trimmedPassword = password?.trim();
    if (trimmedPassword == null) {
      return _omitPasswordUpdate;
    }

    if (trimmedPassword.isEmpty) {
      return null;
    }

    return PasswordHasher.hash(trimmedPassword);
  }

  static const String _omitPasswordUpdate = '__omit_password_update__';
}
