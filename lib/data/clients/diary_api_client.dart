abstract interface class DiaryApiClient {
  Future<Map<String, dynamic>> get(String path, {String? accessToken});
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body, String? accessToken});
  Future<Map<String, dynamic>> put(String path,
      {required Map<String, dynamic> body, String? accessToken});
  Future<Map<String, dynamic>> patch(String path,
      {required Map<String, dynamic> body, required String accessToken});
}
