// test/auth_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/widgets/bc_button.dart';
import 'package:twende_flutter/widgets/bc_text_input.dart';
import 'package:twende_flutter/widgets/bc_switch.dart';
import 'package:twende_flutter/widgets/booking_status_badge.dart';
import 'package:twende_flutter/screens/auth/sign_in_screen.dart';

void main() {
  group('BcButton widget tests', () {
    testWidgets('renders label in uppercase and triggers onPress',
        (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BcButton(
              label: 'Sign In',
              onPress: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('SIGN IN'), findsOneWidget);
      await tester.tap(find.text('SIGN IN'));
      expect(pressed, isTrue);
    });

    testWidgets('displays loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BcButton(
              label: 'Loading Button',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('LOADING BUTTON'), findsNothing);
    });
  });

  group('BcTextInput widget tests', () {
    testWidgets('renders input, accepts text and displays helper text',
        (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BcTextInput(
              label: 'Email',
              controller: controller,
              helperText: 'Required field',
            ),
          ),
        ),
      );

      expect(find.text('Required field'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      expect(controller.text, 'test@example.com');
      // Clear button should be visible
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(controller.text, '');
    });
  });

  group('BcSwitch widget tests', () {
    testWidgets('toggles value when tapped', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => BcSwitch(
                label: 'Stay connected',
                value: value,
                onValueChange: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Stay connected'), findsOneWidget);
      await tester.tap(find.text('Stay connected'));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });
  });

  group('BookingStatusBadge widget tests', () {
    testWidgets('renders correct status label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BookingStatusBadge(status: 'pending'),
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
    });
  });

  group('SignInScreen widget tests', () {
    testWidgets('renders sign-in form correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('SIGN IN'), findsWidgets);
      expect(find.text('SIGN UP'), findsOneWidget);
      expect(find.text('Stay connected'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('renders clean sign in form without demo credentials box',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SignInScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Demo account credentials'), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });
}
