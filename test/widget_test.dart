import 'package:chagas_predictor/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Chagas Predict sign-in screen', (tester) async {
    await tester.pumpWidget(const ChagasPredictorApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in securely'), findsOneWidget);
  });
}
