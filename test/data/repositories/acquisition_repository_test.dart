import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/acquisition_service.dart';
import 'package:qulo_v2/data/models/acquisition_channel_model.dart';
import 'package:qulo_v2/data/repositories/acquisition_repository.dart';

/// "Bizi nereden duydun?" — edinim kanali verisi (pazarlama kararlarini besliyor).
///
/// Sunucu sozlesmesi (qulo-server `acquisition.validator.ts`): `channel_id`
/// (uuid) YA DA `skipped: true` zorunlu; `freeform_text` en fazla 280. Yanit
/// `{channels}`. Istemci 2.0.12'den itibaren `skipped` GONDERMEZ (Atla kalkti,
/// kacis yolu `dont_remember` kanali). Tek cagiran `acquisition_sheet.dart`,
/// serbest metin alani `maxLength: 280`.
class _FakeAcquisitionService implements AcquisitionService {
  _FakeAcquisitionService({this.channelsResponse, this.error});

  final dynamic channelsResponse;
  final DioException? error;

  Map<String, dynamic>? lastAnswer;

  @override
  Future<dynamic> getChannels() async {
    if (error != null) throw error!;
    return channelsResponse;
  }

  @override
  Future<dynamic> submitAnswer(Map<String, dynamic> data) async {
    lastAnswer = data;
    if (error != null) throw error!;
    return {'success': true};
  }
}

Future<Map<String, dynamic>?> _payloadOf({String? channelId, String? freeformText}) async {
  final service = _FakeAcquisitionService();
  await AcquisitionRepository(service)
      .submitAnswer(channelId: channelId, freeformText: freeformText);
  return service.lastAnswer;
}

void main() {
  group('getChannels', () {
    test('{channels} modele parse edilir', () async {
      final service = _FakeAcquisitionService(channelsResponse: {
        'channels': [
          {'id': 'c1', 'key': 'tiktok', 'label': 'TikTok'},
          {'id': 'c2', 'key': 'other', 'label': 'Diger', 'is_freeform': true},
        ],
      });

      final result = await AcquisitionRepository(service).getChannels();

      final channels = result.when(success: (c) => c, failure: (_) => <AcquisitionChannel>[]);
      expect(channels.map((c) => c.key), ['tiktok', 'other']);
      expect(channels.last.isFreeform, isTrue);
    });

    test('channels alani yoksa cokmez — UnknownFailure (sheet bos liste gosterir)', () async {
      final result = await AcquisitionRepository(_FakeAcquisitionService(channelsResponse: {})).getChannels();

      expect(result.when(success: (_) => null, failure: (f) => f), isA<UnknownFailure>());
    });
  });

  group('submitAnswer — payload sunucu kurallariyla uyumlu', () {
    test('kanal secimi yalnizca channel_id tasir', () async {
      expect(await _payloadOf(channelId: 'c1'), {'channel_id': 'c1'});
    });

    test('serbest metin eklenir', () async {
      expect(await _payloadOf(channelId: 'c2', freeformText: 'Arkadasim onerdi'),
          {'channel_id': 'c2', 'freeform_text': 'Arkadasim onerdi'});
    });

    test('bos serbest metin gonderilmez', () async {
      expect(await _payloadOf(channelId: 'c2', freeformText: ''), {'channel_id': 'c2'});
    });

    test('hicbir alan verilmezse bos govde gider — sunucu 400 verir (sessiz varsayim)', () async {
      // Tip sistemi tutmuyor; bugun guvenli cunku Devam butonu kanal secilmeden
      // kapali. Bu test varsayimi gorunur kilar.
      expect(await _payloadOf(), isEmpty);
    });

    test('ag hatasi Failure olur', () async {
      final repo = AcquisitionRepository(_FakeAcquisitionService(
        error: DioException(
          requestOptions: RequestOptions(path: '/acquisition/answer'),
          type: DioExceptionType.connectionError,
        ),
      ));

      final result = await repo.submitAnswer(channelId: 'c1');

      expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
    });
  });
}
