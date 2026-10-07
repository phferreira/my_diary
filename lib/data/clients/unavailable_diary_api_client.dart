import 'package:my_diary/data/clients/diary_api_client.dart';
import 'package:my_diary/data/clients/dio_diary_api_client.dart';

class UnavailableDiaryApiClient implements DiaryApiClient {
  const UnavailableDiaryApiClient(this.failure);

  final BackendFailure failure;

  Never _throw() => throw failure;

  @override
  Future<Map<String, dynamic>> get(String path, {String? accessToken}) async =>
      _throw();

  @override
  Future<Map<String, dynamic>> post(String path,
          {Map<String, dynamic>? body, String? accessToken}) async =>
      _throw();

  @override
  Future<Map<String, dynamic>> put(String path,
          {required Map<String, dynamic> body, String? accessToken}) async =>
      _throw();

  @override
  Future<Map<String, dynamic>> patch(String path,
          {required Map<String, dynamic> body,
          required String accessToken}) async =>
      _throw();
}
