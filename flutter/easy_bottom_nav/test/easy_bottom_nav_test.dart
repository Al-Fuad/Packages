import 'package:easy_bottom_nav/easy_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders labels and current index', (tester) async {
    var selectedIndex = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: EasyBottomNav(
            currentIndex: selectedIndex,
            onTap: (index) => selectedIndex = index,
            items: const [
              EasyBottomNavItem(icon: Icon(Icons.home), label: 'Home'),
              EasyBottomNavItem(icon: Icon(Icons.search), label: 'Search'),
              EasyBottomNavItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.currentIndex, 1);
  });

  testWidgets('calls onTap with tapped index', (tester) async {
    var tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: EasyBottomNav(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
            items: const [
              EasyBottomNavItem(icon: Icon(Icons.home), label: 'Home'),
              EasyBottomNavItem(icon: Icon(Icons.search), label: 'Search'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(tappedIndex, 1);
  });

  testWidgets('asserts when currentIndex is out of range', (tester) async {
    expect(
      () => EasyBottomNav(
        currentIndex: 2,
        onTap: (_) {},
        items: const [
          EasyBottomNavItem(icon: Icon(Icons.home), label: 'Home'),
          EasyBottomNavItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
      throwsAssertionError,
    );
  });
}
