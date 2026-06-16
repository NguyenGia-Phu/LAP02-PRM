import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JournalTrendApp());
    expect(find.text('Journal Trend Analyzer'), findsOneWidget);
  });
}
