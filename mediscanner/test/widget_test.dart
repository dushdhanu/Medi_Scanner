import 'package:flutter_test/flutter_test.dart';
import 'package:mediscanner/main.dart';

void main() {
  testWidgets('MedScan AI app smoke test', (WidgetTester tester) async {
    // Build MedScanApp and trigger a frame.
    await tester.pumpWidget(const MedScanApp());

    // Verify app title exists
    expect(find.text('MedScan AI'), findsOneWidget);

    // Verify key UI actions exist
    expect(find.text('Camera Scan'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });
}
