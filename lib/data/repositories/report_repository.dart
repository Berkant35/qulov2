import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/report_service.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class ReportRepository implements IReportRepository {
  final ReportService _service;

  ReportRepository(this._service);

  @override
  /// `description` parametresi kaldirildi (2026-09-09): hicbir cagri yeri
  /// vermiyordu ve sunucu semasinda (report.validator.ts) boyle bir alan yok —
  /// gonderilse sessizce atilirdi.
  ///
  /// `reason` opsiyonel kalmaya devam ediyor; sunucu tarafi da artik opsiyonel
  /// (eskiden zorunluydu ve sebepsiz sikayet 400 aliyordu).
  Future<Result<void>> createReport({
    required String reportedId,
    required String category,
    String? reason,
  }) async {
    try {
      await _service.createReport({
        'reported_id': reportedId,
        'category': category,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
