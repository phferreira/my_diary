import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/entities/diary_access.dart';
import 'package:my_diary/core/entities/diary_entry.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';
import 'package:my_diary/data/clients/dio_diary_api_client.dart';
import 'package:my_diary/data/clients/diary_api_client.dart';

class BackendDiaryRepository implements DiaryRepository {
  BackendDiaryRepository(this._client);

  final DiaryApiClient _client;
  String? _activeDiaryId;
  String? _accessToken;

  void clearSession() {
    _activeDiaryId = null;
    _accessToken = null;
  }

  @override
  Future<Diary?> findByName(String query) async {
    try {
      final response = await _client.post(
        '/api/v1/diaries/lookup',
        body: <String, dynamic>{'name': query.trim()},
      );
      final diary = _diaryFrom(response['diary']);
      _activate(diary.id);
      final token = response['access_token'];
      if (token is String && token.isNotEmpty) _accessToken = token;
      return diary;
    } on BackendFailure catch (error) {
      if (error.code == 'diary_not_found') return null;
      rethrow;
    }
  }

  @override
  Future<DiaryAccess?> unlockDiary(
      {required Diary diary, required String password}) async {
    _activate(diary.id);
    try {
      final response = await _client.post(
        '/api/v1/diaries/${Uri.encodeComponent(diary.id)}/unlock',
        body: <String, dynamic>{'password': password.trim()},
      );
      _accessToken = _readToken(response);
      return DiaryAccess(
          diaryId: diary.id, canEdit: response['can_edit'] == true);
    } on BackendFailure catch (error) {
      if (error.code == 'invalid_password') return null;
      rethrow;
    }
  }

  @override
  Future<Diary> createDiary({
    required String name,
    required String? password,
    required bool isPublic,
    String? publicPassword,
  }) async {
    final body = <String, dynamic>{'name': name.trim(), 'is_public': isPublic};
    if (password != null) body['password'] = password.trim();
    if (publicPassword != null) body['public_password'] = publicPassword.trim();
    final response = await _client.post('/api/v1/diaries', body: body);
    final diary = _diaryFrom(response['diary']);
    _activate(diary.id);
    _accessToken = _readToken(response);
    return diary;
  }

  @override
  Future<DiaryEntry?> findEntryByDate(
      {required String diaryId, required DateTime date}) async {
    final response = await _client.get(
      '/api/v1/diaries/${Uri.encodeComponent(diaryId)}/entries/${_formatDate(date)}',
      accessToken: _tokenFor(diaryId),
    );
    return DiaryEntry(
      diaryId: response['diary_id']?.toString() ?? diaryId,
      date: _parseDate(response['date']),
      content: response['content'] as String? ?? '',
    );
  }

  @override
  Future<void> upsertDiaryEntry(
      {required String diaryId,
      required DateTime date,
      required String content}) async {
    await _client.put(
      '/api/v1/diaries/${Uri.encodeComponent(diaryId)}/entries/${_formatDate(date)}',
      body: <String, dynamic>{'content': content},
      accessToken: _tokenFor(diaryId),
    );
  }

  @override
  Future<void> updateDiaryAccess(
      {required String id,
      required bool isPublic,
      String? password,
      String? publicPassword}) async {
    final body = <String, dynamic>{'is_public': isPublic};
    if (password != null) body['password'] = password.trim();
    if (publicPassword != null) body['public_password'] = publicPassword.trim();
    await _client.patch(
      '/api/v1/diaries/${Uri.encodeComponent(id)}/access',
      body: body,
      accessToken: _tokenFor(id),
    );
  }

  void _activate(String diaryId) {
    if (_activeDiaryId == diaryId) return;
    _activeDiaryId = diaryId;
    _accessToken = null;
  }

  String _tokenFor(String diaryId) {
    if (_activeDiaryId != diaryId) {
      _activate(diaryId);
    }
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw const BackendFailure(
        code: 'access_required',
        message: 'Unlock this diary before loading or saving entries.',
      );
    }
    return token;
  }

  String _readToken(Map<String, dynamic> response) {
    final token = response['access_token'];
    if (token is! String || token.isEmpty) {
      throw const BackendFailure(
        code: 'invalid_response',
        message: 'Backend did not return an access token.',
      );
    }
    return token;
  }

  Diary _diaryFrom(Object? value) {
    if (value is! Map) {
      throw const BackendFailure(
          code: 'invalid_response',
          message: 'Backend returned an invalid diary.');
    }
    return Diary(
      id: value['id']?.toString() ?? '',
      name: value['name'] as String? ?? '',
      content: '',
      isPublic: value['is_public'] == true,
      accessRequired: value['access_required'] == true,
    );
  }

  DateTime _parseDate(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    throw const BackendFailure(
        code: 'invalid_response',
        message: 'Backend returned an invalid entry date.');
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
