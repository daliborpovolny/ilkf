import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilkf_frontend/main.dart';

void main() {
  testWidgets('Vintage login screen rendering smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that the vintage branding elements are rendered
    expect(find.text('I L K F'), findsOneWidget);
    expect(find.text('A Deliberate Messaging App'), findsOneWidget);
    expect(find.text('Write your name in the Guest Book'), findsOneWidget);

    // Verify that the ElevatedButton with 'Open writing desk' exists
    expect(find.text('Open writing desk'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
