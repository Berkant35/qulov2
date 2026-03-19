import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';

part 'exchange_service.g.dart';

@RestApi()
abstract class ExchangeService {
  factory ExchangeService(Dio dio) = _ExchangeService;

  @POST('/exchange/convert')
  Future<ConvertResponse> convert(@Body() Map<String, dynamic> data);

  @POST('/exchange/buy-power')
  Future<BuyPowerResponse> buyPower(@Body() Map<String, dynamic> data);

  @GET('/exchange/inventory')
  Future<InventoryResponse> getInventory();

  @GET('/exchange/rates')
  Future<RatesResponse> getRates();
}
