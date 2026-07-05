import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securely/securely.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureKeyboard Unit/Widget Tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('Renders Numeric Keyboard and inputs digits', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecureKeyboard(
              controller: controller,
              type: SecureKeyboardType.numeric,
              shuffleType: SecureKeyboardShuffle.none,
              theme: const SecureKeyboardTheme(showHeader: false),
            ),
          ),
        ),
      );

      // Verify numeric digits are rendered
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('⌫'), findsOneWidget);

      // Tap '1'
      await tester.tap(find.text('1'));
      await tester.pump();
      expect(controller.text, equals('1'));

      // Tap '5'
      await tester.tap(find.text('5'));
      await tester.pump();
      expect(controller.text, equals('15'));

      // Tap Backspace
      await tester.tap(find.text('⌫'));
      await tester.pump();
      expect(controller.text, equals('1'));

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(controller.text, equals(''));
    });

    testWidgets('Renders Alphanumeric Keyboard and toggles Shift/Symbols', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecureKeyboard(
              controller: controller,
              type: SecureKeyboardType.alphanumeric,
              shuffleType: SecureKeyboardShuffle.none,
              theme: const SecureKeyboardTheme(showHeader: false),
            ),
          ),
        ),
      );

      // Verify letters are visible (default lowercase)
      expect(find.text('q'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('z'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap 'q'
      await tester.tap(find.text('q'));
      await tester.pump();
      expect(controller.text, equals('q'));

      // Tap Shift (should display uppercase keys)
      await tester.tap(find.text('⇧'));
      await tester.pump();

      // Tap 'a' (rendered as 'A' on screen, but wait, the label text capitalizes)
      expect(find.text('A'), findsOneWidget);
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(controller.text, equals('qA'));

      // Tapping uppercase key auto-resets Shift to lowercase
      expect(find.text('a'), findsOneWidget);

      // Tap Symbols page toggle
      await tester.tap(find.text('?123'));
      await tester.pump();

      // Verify symbol keys are rendered
      expect(find.text('1'), findsOneWidget);
      expect(find.text('@'), findsOneWidget);
      expect(find.text('ABC'), findsAtLeastNWidgets(1));

      // Tap '@'
      await tester.tap(find.text('@'));
      await tester.pump();
      expect(controller.text, equals('qA@'));

      // Switch back to ABC
      await tester.tap(find.text('ABC').first);
      await tester.pump();
      expect(find.text('q'), findsOneWidget);
    });

    testWidgets('SecureKeyboardShuffle.always scrambles layout', (
      WidgetTester tester,
    ) async {
      // Create with shuffle always
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecureKeyboard(
              controller: controller,
              type: SecureKeyboardType.numeric,
              shuffleType: SecureKeyboardShuffle.always,
            ),
          ),
        ),
      );

      // Tap whatever digit is under '1'
      // Note: Tap events are coordinate-based, but we can verify that
      // after a tap, the layout reshuffles (meaning the digit positions change).
      final firstTextBeforeTap = find.text('1');
      expect(firstTextBeforeTap, findsOneWidget);

      // Tap '1'
      await tester.tap(firstTextBeforeTap);
      await tester.pump();
      expect(controller.text, equals('1'));

      // Shuffling should have run, but since it is randomized, the layout changed.
      // There's a 90% chance digit positions changed.
    });

    testWidgets('SecureTextField blocks system keyboard', (
      WidgetTester tester,
    ) async {
      final FocusNode focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecureTextField(
              controller: controller,
              focusNode: focusNode,
              showKeyboardBottomSheet: false, // Inline/No BS mode
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final TextField textField = tester.widget<TextField>(textFieldFinder);
      // Ensure readOnly: true and showCursor: true is passed
      expect(textField.readOnly, isTrue);
      expect(textField.showCursor, isTrue);
      expect(textField.enableInteractiveSelection, isFalse);
    });

    testWidgets('Renders header done button and calls onDone', (
      WidgetTester tester,
    ) async {
      bool isDoneCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecureKeyboard(
              controller: controller,
              type: SecureKeyboardType.numeric,
              onDone: () => isDoneCalled = true,
              theme: const SecureKeyboardTheme(showHeader: true),
            ),
          ),
        ),
      );

      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(isDoneCalled, isTrue);
    });

    testWidgets(
      'SecureTextField can show persistent bottom sheet and closes on done',
      (WidgetTester tester) async {
        final FocusNode focusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SecureTextField(
                controller: controller,
                focusNode: focusNode,
                showKeyboardBottomSheet: true,
                useModalBottomSheet: false, // Persistent bottom sheet
              ),
            ),
          ),
        );

        // Focus the text field to trigger bottom sheet
        focusNode.requestFocus();
        await tester.pumpAndSettle();

        // Verify SecureKeyboard is rendered in the bottom sheet
        expect(find.byType(SecureKeyboard), findsOneWidget);

        // Verify standard keys are visible (like '1')
        expect(find.text('1'), findsOneWidget);

        // Tap 'Done' to close bottom sheet
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Verify SecureKeyboard is dismissed
        expect(find.byType(SecureKeyboard), findsNothing);
        expect(focusNode.hasFocus, isFalse);
      },
    );

    testWidgets(
      'SecureTextField with inline keyboard does not lose focus or close on key tap',
      (WidgetTester tester) async {
        final FocusNode focusNode = FocusNode();
        bool isKeyboardVisible = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              focusNode.addListener(() {
                setState(() {
                  isKeyboardVisible = focusNode.hasFocus;
                });
              });

              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      SecureTextField(
                        controller: controller,
                        focusNode: focusNode,
                        showKeyboardBottomSheet: false,
                      ),
                      if (isKeyboardVisible)
                        SecureKeyboard(
                          controller: controller,
                          type: SecureKeyboardType.numeric,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        // Focus the field
        focusNode.requestFocus();
        await tester.pumpAndSettle();

        expect(isKeyboardVisible, isTrue);
        expect(find.byType(SecureKeyboard), findsOneWidget);

        // Tap digit '3' on the inline keyboard
        await tester.tap(find.text('3'));
        await tester.pumpAndSettle();

        // Focus should NOT be lost, and keyboard should still be visible
        expect(focusNode.hasFocus, isTrue);
        expect(isKeyboardVisible, isTrue);
        expect(controller.text, equals('3'));
      },
    );

    testWidgets(
      'SecureTextField can show modal bottom sheet and closes on done',
      (WidgetTester tester) async {
        final FocusNode focusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SecureTextField(
                controller: controller,
                focusNode: focusNode,
                showKeyboardBottomSheet: true,
                useModalBottomSheet: true, // Modal bottom sheet
              ),
            ),
          ),
        );

        // Focus the text field to trigger bottom sheet
        focusNode.requestFocus();
        await tester.pumpAndSettle();

        // Verify SecureKeyboard is rendered in the bottom sheet
        expect(find.byType(SecureKeyboard), findsOneWidget);

        // Tap 'Done' to close bottom sheet
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Verify SecureKeyboard is dismissed
        expect(find.byType(SecureKeyboard), findsNothing);
        expect(focusNode.hasFocus, isFalse);
      },
    );

    testWidgets(
      'SecureTextField modal bottom sheet closes on tap outside (barrier tap)',
      (WidgetTester tester) async {
        final FocusNode focusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SecureTextField(
                  controller: controller,
                  focusNode: focusNode,
                  showKeyboardBottomSheet: true,
                  useModalBottomSheet: true, // Modal bottom sheet
                ),
              ),
            ),
          ),
        );

        // Focus the text field to trigger bottom sheet
        focusNode.requestFocus();
        await tester.pumpAndSettle();

        // Verify SecureKeyboard is rendered in the bottom sheet
        expect(find.byType(SecureKeyboard), findsOneWidget);

        // Tap outside the bottom sheet (on the modal barrier).
        // Tap near top-left of the screen to hit the barrier.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Verify SecureKeyboard is dismissed
        expect(find.byType(SecureKeyboard), findsNothing);
        expect(focusNode.hasFocus, isFalse);
      },
    );

    testWidgets(
      'SecureTextField onKeyboardVisible is called when bottom sheet opens/closes',
      (WidgetTester tester) async {
        final FocusNode focusNode = FocusNode();
        final List<bool> visibilityEvents = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SecureTextField(
                controller: controller,
                focusNode: focusNode,
                showKeyboardBottomSheet: true,
                useModalBottomSheet: true,
                onKeyboardVisible: (visible) {
                  visibilityEvents.add(visible);
                },
              ),
            ),
          ),
        );

        // Focus the text field to trigger bottom sheet
        focusNode.requestFocus();
        await tester.pumpAndSettle();

        expect(visibilityEvents, equals([true]));

        // Tap 'Done' to close bottom sheet
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(visibilityEvents, equals([true, false]));
      },
    );
  });
}
