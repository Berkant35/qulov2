import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'support_ticket_service.g.dart';

@RestApi()
abstract class SupportTicketService {
  factory SupportTicketService(Dio dio) = _SupportTicketService;

  @POST('/support-tickets')
  Future<dynamic> createTicket(@Body() Map<String, dynamic> data);

  @GET('/support-tickets')
  Future<List<dynamic>> getMyTickets();

  @GET('/support-tickets/{id}')
  Future<dynamic> getTicket(@Path('id') String id);
}
