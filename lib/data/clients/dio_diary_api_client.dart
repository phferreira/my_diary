import 'package:dio/dio.dart';
import 'package:my_diary/core/config/app_environment.dart';
import 'package:my_diary/data/clients/diary_api_client.dart';

class BackendFailure implements Exception {
  const BackendFailure(
      {required this.code, required this.message, this.statusCode});
  final String code;
  final String message;
  final int? statusCode;
  @override
  String toString() => 'BackendFailure($code): $message';
}

class BackendConfigurationFailure extends BackendFailure {
  const BackendConfigurationFailure(String message)
      : super(code: 'backend_not_configured', message: message);
}

class DioDiaryApiClient implements DiaryApiClient {
  factory DioDiaryApiClient(
      {String? baseUrl,
      Dio? dio,
      Duration connectTimeout = const Duration(seconds: 5),
      Duration receiveTimeout = const Duration(seconds: 15),
      Duration sendTimeout = const Duration(seconds: 15)}) {
    final origin = _validateBaseUrl(baseUrl ?? AppEnvironment.apiBaseUrl);
    final client = dio ?? Dio();
    client.options = client.options.copyWith(
        baseUrl: origin,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json);
    return DioDiaryApiClient._(client);
  }
  DioDiaryApiClient._(this._dio);
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> get(String path, {String? accessToken}) =>
      _request(() => _dio.get<dynamic>(path, options: _options(accessToken)));

  @override
  Future<Map<String, dynamic>> post(String path,
          {Map<String, dynamic>? body, String? accessToken}) =>
      _request(() =>
          _dio.post<dynamic>(path, data: body, options: _options(accessToken)));

  @override
  Future<Map<String, dynamic>> put(String path,
          {required Map<String, dynamic> body, String? accessToken}) =>
      _request(() =>
          _dio.put<dynamic>(path, data: body, options: _options(accessToken)));

  @override
  Future<Map<String, dynamic>> patch(String path,
          {required Map<String, dynamic> body, required String accessToken}) =>
      _request(() => _dio.patch<dynamic>(path,
          data: body, options: _options(accessToken)));

  Options _options(String? token) => Options(
      headers: token == null ? null : {'Authorization': 'Bearer $token'});

  Future<Map<String, dynamic>> _request(
      Future<Response<dynamic>> Function() send) async {
    try {
      final data = (await send()).data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const BackendFailure(
          code: 'invalid_response',
          message: 'Backend returned an invalid response.');
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  BackendFailure _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = error.response?.data;
    if (payload is Map && payload['error'] is Map) {
      final envelope = payload['error'] as Map;
      return BackendFailure(
          code: envelope['code']?.toString() ?? 'request_failed',
          message: envelope['message']?.toString() ?? 'Backend request failed.',
          statusCode: statusCode);
    }
    if (const {
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout
    }.contains(error.type)) {
      return BackendFailure(
          code: 'request_timeout',
          message: 'The backend request timed out.',
          statusCode: statusCode);
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return BackendFailure(
          code: 'service_unavailable',
          message: 'The backend is unavailable.',
          statusCode: statusCode);
    }
    return BackendFailure(
        code: 'request_failed',
        message: 'Backend request failed.',
        statusCode: statusCode);
  }

  static String _validateBaseUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    final localHttp = uri?.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '::1'}.contains(uri?.host);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && !localHttp) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const BackendConfigurationFailure(
          'Configure API_BASE_URL as a backend HTTPS origin.');
    }
    return uri.replace(path: '').toString().replaceFirst(RegExp(r'/$'), '');
  }
}
