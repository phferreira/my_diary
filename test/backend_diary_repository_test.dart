import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/data/clients/dio_diary_api_client.dart';
import 'package:my_diary/data/clients/diary_api_client.dart';
import 'package:my_diary/data/repositories/backend_diary_repository.dart';

void main() {
  group('BackendDiaryRepository', () {
    test('trims lookup and maps safe diary metadata without password fields',
        () async {
      final api = _FakeDiaryApiClient()
        ..postResponse = {
          'diary': {
            'id': 'd1',
            'name': 'Leituras',
            'is_public': true,
            'access_required': true,
          },
        };
      final repository = BackendDiaryRepository(api);
      final diary = await repository.findByName(' Leituras ');
      expect(api.lastPath, '/api/v1/diaries/lookup');
      expect(api.lastBody, {'name': 'Leituras'});
      expect(diary?.name, 'Leituras');
      expect(diary?.accessRequired, isTrue);
      expect(diary?.password, isNull);
      expect(diary?.publicPassword, isNull);
    });

    test(
        'retains access tokens privately and attaches them to dated entry calls',
        () async {
      final api = _FakeDiaryApiClient()
        ..postResponse = {
          'diary': {
            'id': 'd1',
            'name': 'Diário',
            'is_public': false,
            'access_required': false
          },
          'access_token': 'secret-token',
          'can_edit': true,
        };
      final repository = BackendDiaryRepository(api);
      await repository.findByName('Diário');
      await repository.upsertDiaryEntry(
        diaryId: 'd1',
        date: DateTime(2026, 10, 7, 18),
        content: 'entry',
      );
      expect(api.lastPath, '/api/v1/diaries/d1/entries/2026-10-07');
      expect(api.lastAccessToken, 'secret-token');
      expect(api.lastBody, {'content': 'entry'});
    });

    test('maps password denial to null and retains successful unlock scope',
        () async {
      final api = _FakeDiaryApiClient();
      final repository = BackendDiaryRepository(api);
      const diary =
          Diary(id: 'd1', name: 'Diário', content: '', accessRequired: true);
      api.postError = const BackendFailure(
        code: 'invalid_password',
        message: 'Password is incorrect.',
        statusCode: 401,
      );
      expect(await repository.unlockDiary(diary: diary, password: 'wrong'),
          isNull);
      api.postError = null;
      api.postResponse = {'access_token': 'write-token', 'can_edit': true};
      final result =
          await repository.unlockDiary(diary: diary, password: 'right');
      await repository.findEntryByDate(
          diaryId: 'd1', date: DateTime(2026, 10, 7));
      expect(result?.canEdit, isTrue);
      expect(result?.diaryId, 'd1');
      expect(api.lastAccessToken, 'write-token');
    });

    test('duplicate diary creation is a typed failure, not a success value',
        () async {
      final api = _FakeDiaryApiClient()
        ..postError = const BackendFailure(
          code: 'diary_name_conflict',
          message: 'A diary with this name already exists.',
          statusCode: 409,
        );
      final repository = BackendDiaryRepository(api);
      await expectLater(
        repository.createDiary(name: 'Diary', password: null, isPublic: false),
        throwsA(isA<BackendFailure>()),
      );
    });

    test('failed entry save is not reported as success', () async {
      final api = _FakeDiaryApiClient()
        ..postResponse = {
          'diary': {
            'id': 'd1',
            'name': 'D',
            'is_public': false,
            'access_required': false
          },
          'access_token': 'token',
          'can_edit': true,
        }
        ..putError = const BackendFailure(
          code: 'service_unavailable',
          message: 'Backend is unavailable.',
          statusCode: 503,
        );
      final repository = BackendDiaryRepository(api);
      await repository.findByName('D');
      await expectLater(
        repository.upsertDiaryEntry(
          diaryId: 'd1',
          date: DateTime(2026, 10, 7),
          content: 'unsaved',
        ),
        throwsA(isA<BackendFailure>()),
      );
    });

    test('clears tokens when active diary changes or session ends', () async {
      final api = _FakeDiaryApiClient()
        ..postResponse = {
          'diary': {
            'id': 'd1',
            'name': 'D1',
            'is_public': false,
            'access_required': false
          },
          'access_token': 'token-1',
          'can_edit': true,
        };
      final repository = BackendDiaryRepository(api);
      await repository.findByName('D1');
      api.postResponse = {
        'diary': {
          'id': 'd2',
          'name': 'D2',
          'is_public': false,
          'access_required': false
        },
      };
      await repository.findByName('D2');
      await expectLater(
        repository.upsertDiaryEntry(
            diaryId: 'd1', date: DateTime(2026), content: 'x'),
        throwsA(isA<BackendFailure>()),
      );
      repository.clearSession();
      await expectLater(
        repository.upsertDiaryEntry(
            diaryId: 'd2', date: DateTime(2026), content: 'x'),
        throwsA(isA<BackendFailure>()),
      );
    });
  });

  test('invalid backend configuration and Dio timeouts become typed failures',
      () async {
    expect(
      () => DioDiaryApiClient(baseUrl: 'not-a-url'),
      throwsA(isA<BackendConfigurationFailure>()),
    );
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        )),
      ));
    final client =
        DioDiaryApiClient(baseUrl: 'http://localhost:8000', dio: dio);
    await expectLater(
      client.get('/api/v1/diaries/x/entries/2026-10-07'),
      throwsA(isA<BackendFailure>()
          .having((error) => error.code, 'code', 'request_timeout')),
    );
    final errorDio = Dio()
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 409,
            data: {
              'error': {
                'code': 'diary_name_conflict',
                'message': 'A diary with this name already exists.',
              },
            },
          ),
        )),
      ));
    final errorClient =
        DioDiaryApiClient(baseUrl: 'http://localhost:8000', dio: errorDio);
    await expectLater(
      errorClient.post('/api/v1/diaries', body: {'name': 'Diary'}),
      throwsA(isA<BackendFailure>().having(
        (error) => error.code,
        'code',
        'diary_name_conflict',
      )),
    );
  });
}

class _FakeDiaryApiClient implements DiaryApiClient {
  String? lastPath;
  String? lastAccessToken;
  Map<String, dynamic>? lastBody;
  Map<String, dynamic> postResponse = {};
  BackendFailure? postError;
  BackendFailure? putError;

  @override
  Future<Map<String, dynamic>> get(String path, {String? accessToken}) async {
    lastPath = path;
    lastAccessToken = accessToken;
    return {'diary_id': 'd1', 'date': '2026-10-07', 'content': 'entry'};
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body, String? accessToken}) async {
    lastPath = path;
    lastBody = body;
    lastAccessToken = accessToken;
    if (postError case final error?) throw error;
    return postResponse;
  }

  @override
  Future<Map<String, dynamic>> put(String path,
      {required Map<String, dynamic> body, String? accessToken}) async {
    lastPath = path;
    lastBody = body;
    lastAccessToken = accessToken;
    if (putError case final error?) throw error;
    return {'diary_id': 'd1', 'date': '2026-10-07', 'content': 'entry'};
  }

  @override
  Future<Map<String, dynamic>> patch(String path,
      {required Map<String, dynamic> body, required String accessToken}) async {
    lastPath = path;
    lastBody = body;
    lastAccessToken = accessToken;
    return {};
  }
}
