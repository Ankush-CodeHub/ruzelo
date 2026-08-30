import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruzelo_frontend/core/theme/ruzelo_glass_card.dart';
import 'package:ruzelo_frontend/core/theme/specular_border.dart';

void main() {
  group('RuzeloGlassCard Widget Tests', () {
    testWidgets('Renders BackdropFilter, ClipRRect, and child content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RuzeloGlassCard(
              blur: 20.0,
              borderRadius: 24.0,
              child: const Text('Ruzelo Glass Test'),
            ),
          ),
        ),
      );

      // Verify child text is rendered
      expect(find.text('Ruzelo Glass Test'), findsOneWidget);

      // Verify BackdropFilter is present
      expect(find.byType(BackdropFilter), findsOneWidget);

      // Verify ClipRRect is present with Radius.circular(24.0)
      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsOneWidget);
      final clipRRect = tester.widget<ClipRRect>(clipRRectFinder);
      expect(clipRRect.borderRadius, equals(BorderRadius.circular(24.0)));

      // Verify RepaintBoundary wraps the card
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('Triggers onTap callback when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RuzeloGlassCard(
              onTap: () {
                tapped = true;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('SpecularBorder renders CustomPaint with SpecularBorderPainter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpecularBorder(
              borderRadius: 20.0,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
