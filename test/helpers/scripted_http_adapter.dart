import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Gercek Dio'ya takilan senaryolu adapter: interceptor zinciri uretimdeki
/// gibi calisir, yalnizca "sunucu" sahtedir. Ag yok.
class ScriptedHttpAdapter implements HttpClientAdapter {
  ScriptedHttpAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  /// Gonderim anindaki Authorization basligi. Tekrar gonderim ayni
  /// `RequestOptions`'i degistirdigi icin `requests[i].headers` sonradan
  /// okunursa hep son hali gorulur.
  final sentAuthHeaders = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    sentAuthHeaders.add(options.headers['Authorization']);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Dio scriptedDio(ScriptedHttpAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
