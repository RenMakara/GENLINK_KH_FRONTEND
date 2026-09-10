import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_canvas_renderer.dart';

void main() {
  group('Story Label / Tag Animation & Visual Identity Tests', () {
    testWidgets('Hashtag layer renders with AnimatedContainer and blue-to-purple identity',
        (tester) async {
      final hashtagLayer = MovableStoryLayer(
        id: 'layer_hashtag_1',
        type: LayerType.hashtag,
        text: '#CampusLinkKH',
        offset: const Offset(0.5, 0.5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StoryCanvasRenderer(
                canvasSize: const Size(390, 844),
                layers: [hashtagLayer],
                isInteractive: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('#CampusLinkKH'), findsOneWidget);

      final textFinder = find.text('#CampusLinkKH');
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(Colors.white));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w600));

      final animContainerFinder = find.ancestor(
        of: textFinder,
        matching: find.byType(AnimatedContainer),
      );
      expect(animContainerFinder, findsWidgets);

      final animWidget =
          tester.widget<AnimatedContainer>(animContainerFinder.first);
      expect(animWidget.duration, equals(const Duration(milliseconds: 200)));
      expect(animWidget.curve, equals(Curves.easeOutCubic));

      final decoration = animWidget.decoration as BoxDecoration;
      expect(
        decoration.color,
        equals(AppColors.communityAccent.withValues(alpha: 0.9)),
      );
      expect(decoration.borderRadius, equals(BorderRadius.circular(16)));
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('Mention layer renders with AnimatedContainer and AnimatedDefaultTextStyle',
        (tester) async {
      final mentionLayer = MovableStoryLayer(
        id: 'layer_mention_1',
        type: LayerType.mention,
        text: 'sokuntheara',
        offset: const Offset(0.5, 0.5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StoryCanvasRenderer(
                canvasSize: const Size(390, 844),
                layers: [mentionLayer],
                isInteractive: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('@sokuntheara'), findsOneWidget);

      final textFinder = find.text('@sokuntheara');
      final animContainerFinder = find.ancestor(
        of: textFinder,
        matching: find.byType(AnimatedContainer),
      );
      expect(animContainerFinder, findsWidgets);

      final animWidget =
          tester.widget<AnimatedContainer>(animContainerFinder.first);
      expect(animWidget.duration, equals(const Duration(milliseconds: 200)));
      expect(animWidget.curve, equals(Curves.easeInOut));

      final animStyleFinder = find.ancestor(
        of: textFinder,
        matching: find.byType(AnimatedDefaultTextStyle),
      );
      expect(animStyleFinder, findsWidgets);

      final animStyleWidget =
          tester.widget<AnimatedDefaultTextStyle>(animStyleFinder.first);
      expect(animStyleWidget.duration, equals(const Duration(milliseconds: 200)));
      expect(animStyleWidget.style.fontWeight, equals(FontWeight.w900));
    });

    testWidgets('Location layer renders with AnimatedContainer and AnimatedDefaultTextStyle',
        (tester) async {
      final locationLayer = MovableStoryLayer(
        id: 'layer_location_1',
        type: LayerType.location,
        text: 'Phnom Penh Campus',
        offset: const Offset(0.5, 0.5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StoryCanvasRenderer(
                canvasSize: const Size(390, 844),
                layers: [locationLayer],
                isInteractive: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Phnom Penh Campus'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);

      final textFinder = find.text('Phnom Penh Campus');
      final animContainerFinder = find.ancestor(
        of: textFinder,
        matching: find.byType(AnimatedContainer),
      );
      expect(animContainerFinder, findsWidgets);

      final animWidget =
          tester.widget<AnimatedContainer>(animContainerFinder.first);
      expect(animWidget.duration, equals(const Duration(milliseconds: 200)));
      expect(animWidget.curve, equals(Curves.easeInOut));

      final animStyleFinder = find.ancestor(
        of: textFinder,
        matching: find.byType(AnimatedDefaultTextStyle),
      );
      expect(animStyleFinder, findsWidgets);

      final animStyleWidget =
          tester.widget<AnimatedDefaultTextStyle>(animStyleFinder.first);
      expect(animStyleWidget.duration, equals(const Duration(milliseconds: 200)));
      expect(animStyleWidget.style.fontWeight, equals(FontWeight.bold));
    });
  });
}
