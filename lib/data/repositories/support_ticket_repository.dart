import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/support_ticket_service.dart';
import 'package:qulo_v2/data/models/support_ticket_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class SupportTicketRepository implements ISupportTicketRepository {
  final SupportTicketService _service;

  SupportTicketRepository(this._service);

  @override
  Future<Result<SupportTicketModel>> createTicket({
    required String subject,
    required String message,
    required String category,
  }) async {
    try {
      final response = await _service.createTicket({
        'subject': subject,
        'message': message,
        'category': category,
      });
      return Success(SupportTicketModel.fromJson(response));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<List<SupportTicketModel>>> getMyTickets() async {
    try {
      final response = await _service.getMyTickets();
      final tickets = response.map(SupportTicketModel.fromJson).toList();
      return Success(tickets);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<SupportTicketModel>> getTicket(String id) async {
    try {
      final response = await _service.getTicket(id);
      return Success(SupportTicketModel.fromJson(response));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
