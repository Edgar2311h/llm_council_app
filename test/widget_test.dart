import 'package:flutter_test/flutter_test.dart';
import 'package:llm_council_app/main.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const LLMCouncilApp());

    // Wait for initial loading
    await tester.pump();

    // App should render without errors
    expect(find.byType(LLMCouncilApp), findsOneWidget);
  });
}
