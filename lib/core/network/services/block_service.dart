import 'package:dio/dio.dart';

class BlockService {
  final Dio _dio;

  BlockService(this._dio);

  Future<void> blockUser(Map<String, dynamic> data) async {
    await _dio.post<void>('/blocks', data: data);
  }

  Future<void> unblockUser(String userId) async {
    await _dio.delete<void>('/blocks/$userId');
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final response = await _dio.get<List<dynamic>>('/blocks');
    return (response.data ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
