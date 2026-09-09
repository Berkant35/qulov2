import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/report_service.dart';
import 'package:qulo_v2/data/repositories/report_repository.dart';

/// Şikayet repository'si — moderasyon yolu, mağaza gereksinimi.
///
/// Buradaki payload sunucu şemasıyla (`report.validator.ts`) birebir olmalı:
///   `reported_id` (uuid) + `category` (10 değerli enum) zorunlu,
///   `reason` opsiyonel — **2026-09-09'da opsiyonel yapıldı**. Eskiden zorunluydu
///   ve istemci sebep yazılmadığında alanı hiç göndermediği için şikayet 400
///   alıyordu; çağrı yerleri `Result`'ı kontrol etmediği için de kullanıcı hata
///   görmüyordu. Sessiz kayıp.
class _FakeReportService implements ReportService {
  _FakeReportService({this.error});

  final DioException? error;

  Map<String, dynamic>? lastPayload;
  int callCount = 0;

  @override
  Future<void> createReport(Map<String, dynamic> data) async {
    callCount++;
    lastPayload = data;
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeReportService.${invocation.memberName}');
}

DioException _dio(DioExceptionType type, {int? status, dynamic body}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: status,
              data: body,
            ),
    );

void main() {
  test('sebepsiz sikayet gonderilebilir — payload yalnizca id ve kategori', () async {
    // Sunucu artik bunu kabul ediyor; kategori sikayetin ozunu tasiyor.
    final fake = _FakeReportService();

    final result = await ReportRepository(fake)
        .createReport(reportedId: 'u2', category: 'HARASSMENT');

    expect(fake.lastPayload, {'reported_id': 'u2', 'category': 'HARASSMENT'});
    expect(result.isSuccess, isTrue);
  });

  test('sebep yazilirsa eklenir', () async {
    final fake = _FakeReportService();

    await ReportRepository(fake).createReport(
      reportedId: 'u2', category: 'SPAM', reason: 'Surekli reklam atiyor',
    );

    expect(fake.lastPayload!['reason'], 'Surekli reklam atiyor');
  });

  test('BOS sebep gonderilmez — sunucu min(5) istiyor, bos metin 400 alirdi', () async {
    final fake = _FakeReportService();

    await ReportRepository(fake).createReport(
      reportedId: 'u2', category: 'SPAM', reason: '',
    );

    expect(fake.lastPayload!.containsKey('reason'), isFalse);
  });

  test('payload SADECE sozlesmedeki alanlari tasir', () async {
    // `description` diye bir alan sunucu semasinda YOK; parametresi de
    // kaldirildi (hicbir cagri yeri vermiyordu).
    final fake = _FakeReportService();

    await ReportRepository(fake).createReport(
      reportedId: 'u2', category: 'FAKE_PROFILE', reason: 'Baskasinin fotosu',
    );

    expect(fake.lastPayload!.keys.toSet(), {'reported_id', 'category', 'reason'});
  });

  test('hata ServerFailure olarak doner ve servis TAM BIR KEZ cagrilir', () async {
    // Cift sikayet, moderasyon kuyrugunda mukerrer kayit demek.
    final fake = _FakeReportService(
      error: _dio(DioExceptionType.badResponse,
          status: 429, body: {'error': {'code': 'RATE_LIMITED'}}),
    );

    final result = await ReportRepository(fake)
        .createReport(reportedId: 'u2', category: 'SPAM');

    final failure = result.when<AppFailure?>(success: (_) => null, failure: (f) => f);
    expect((failure as ServerFailure).code, 'RATE_LIMITED');
    expect(fake.callCount, 1);
  });

  test('ag hatasi Failure olur — sikayet gitti sanilmasin', () async {
    final fake = _FakeReportService(error: _dio(DioExceptionType.connectionError));

    final result = await ReportRepository(fake)
        .createReport(reportedId: 'u2', category: 'SPAM');

    expect(result.when<AppFailure?>(success: (_) => null, failure: (f) => f),
        isA<NetworkFailure>());
  });
}
