import 'package:easy_bottom_nav/easy_bottom_nav.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('renders bottom navigation labels', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    final navFinder = find.byType(EasyBottomNav);

    expect(
      find.descendant(of: navFinder, matching: find.text('Home')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navFinder, matching: find.text('Search')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navFinder, matching: find.text('Profile')),
      findsOneWidget,
    );
  });
}
