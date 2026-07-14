import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/app.dart';

void main() {
  testWidgets('GenLink KH app shell builds', (tester) async {
    await tester.pumpWidget(const GenLinkKhApp());

    expect(find.text('GenLink KH'), findsNothing);
  });
}
