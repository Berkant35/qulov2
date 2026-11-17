import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/services/report_service.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/repositories/report_repository.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_report_mixin.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Quiz başlığındaki şikâyet girişi (2.0.19): şikâyet çözülen soruyla (`question_id`)
/// gider; medya kategorisi yalnız medyalı soruda sunulur.
class _FakeReportService implements ReportService {
  Map<String, dynamic>? lastPayload;
  bool fail = false;

  @override
  Future<void> createReport(Map<String, dynamic> data) async {
    lastPayload = data;
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

QuizQuestionModel _question({String? voiceUrl, String? imageUrl}) => QuizQuestionModel(
      sessionId: 's1',
      questionNumber: 1,
      totalQuestions: 2,
      questionId: 'q-42',
      questionText: 'Q?',
      answers: const [QuizAnswerOption(index: 0, text: 'A')],
      timeLimitSeconds: 10,
      voiceUrl: voiceUrl,
      imageUrl: imageUrl,
    );

class _Host extends ConsumerStatefulWidget {
  const _Host({required this.question});
  final QuizQuestionModel question;

  @override
  ConsumerState<_Host> createState() => HostState();
}

class HostState extends ConsumerState<_Host> with QuizReportMixin<_Host> {
  @override
  String get reportedUserId => 'owner-1';

  @override
  QuizQuestionModel? get reportedQuestion => widget.question;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<(HostState, _FakeReportService)> _pump(WidgetTester tester, QuizQuestionModel q) async {
  final service = _FakeReportService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(ReportRepository(service))],
      child: MaterialApp(home: _Host(question: q)),
    ),
  );
  return (tester.state<HostState>(find.byType(_Host)), service);
}

void main() {
  testWidgets('şikâyet question_id ile gider', (tester) async {
    final (state, service) = await _pump(tester, _question());

    final ok = await state.sendQuestionReport(
      category: 'INAPPROPRIATE_CONTENT',
      reason: 'kötü',
      questionId: 'q-42',
    );

    expect(ok, isTrue);
    expect(service.lastPayload, {
      'reported_id': 'owner-1',
      'category': 'INAPPROPRIATE_CONTENT',
      'reason': 'kötü',
      'question_id': 'q-42',
    });
  });

  testWidgets('sunucu hatası false döner (sessiz kayıp yok)', (tester) async {
    final (state, service) = await _pump(tester, _question());
    service.fail = true;

    final ok = await state.sendQuestionReport(category: 'SPAM', questionId: 'q-42');

    expect(ok, isFalse);
  });

  testWidgets('medya kategorisi yalnız medyalı soruda sunulur', (tester) async {
    var (state, _) = await _pump(tester, _question());
    expect(state.includeMediaReportCategory, isFalse);

    (state, _) = await _pump(tester, _question(voiceUrl: 'https://m/v.m4a'));
    expect(state.includeMediaReportCategory, isTrue);

    (state, _) = await _pump(tester, _question(imageUrl: 'https://m/i.jpg'));
    expect(state.includeMediaReportCategory, isTrue);
  });
}
