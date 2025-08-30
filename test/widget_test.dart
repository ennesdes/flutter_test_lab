// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_test_lab/app/app.dart';

void main() {
  testWidgets('Flutter Test Lab smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlutterTestLabApp());

    // Verify that the app title is displayed.
    expect(find.text('Flutter Test Lab'), findsOneWidget);
    
    // Verify that the welcome message is displayed.
    expect(find.text('Bem-vindo ao Flutter Test Lab!'), findsOneWidget);
    
    // Verify that the feature cards are displayed.
    expect(find.text('Gravação de Áudio'), findsOneWidget);
    expect(find.text('Funcionalidade 2'), findsOneWidget);
  });
}
