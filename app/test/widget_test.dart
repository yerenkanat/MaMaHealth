import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mama/features/kick_counter/widgets/kick_heart_button.dart';

void main() {
  testWidgets('KickHeartButton увеличивает счётчик по тапу', (tester) async {
    var count = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: KickHeartButton(count: count, onKick: () => count++),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byType(KickHeartButton));
    await tester.pump(const Duration(milliseconds: 200));

    expect(count, 1);
  });
}
