import 'package:dio/dio.dart';

class SupportTicketService {
  final Dio _dio;

  SupportTicketService(this._dio);

  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support-tickets',
      data: data,
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getMyTickets() async {
    final response = await _dio.get<List<dynamic>>('/support-tickets');
    return (response.data ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getTicket(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/support-tickets/$id',
    );
    return response.data ?? const <String, dynamic>{};
  }
}
