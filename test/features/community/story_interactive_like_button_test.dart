import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_interactive_like_button.dart';

void main() {
  group('StoryInteractiveLikeButton Tests', () {
    testWidgets('Test 1: Viewer mode (showCount = false) hides numeric count and shows outlined heart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StoryInteractiveLikeButton(
                isLiked: false,
                likesCount: 24,
                showCount: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.text('24'), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('Test 2: Viewer mode (showCount = false) liked state shows filled heart without count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StoryInteractiveLikeButton(
                isLiked: true,
                likesCount: 25,
                showCount: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('25'), findsNothing);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('Test 3: Owner mode (showCount = true) displays numeric count alongside heart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StoryInteractiveLikeButton(
                isLiked: true,
                likesCount: 125,
                showCount: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('125'), findsOneWidget);
    });

    testWidgets('Test 4: Tapping unliked button in viewer mode triggers celebration animation', (tester) async {
      bool tapped = false;
      int likes = 24;
      bool isLiked = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: StoryInteractiveLikeButton(
                    isLiked: isLiked,
                    likesCount: likes,
                    showCount: false,
                    onTap: () {
                      tapped = true;
                      setState(() {
                        isLiked = true;
                        likes = 25;
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(StoryInteractiveLikeButton));
      expect(tapped, isTrue);

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('25'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('25'), findsNothing);
    });

    testWidgets('Test 5: Tapping liked button in viewer mode unlikes smoothly without errors', (tester) async {
      bool isLiked = true;
      int likes = 25;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: StoryInteractiveLikeButton(
                    isLiked: isLiked,
                    likesCount: likes,
                    showCount: false,
                    onTap: () {
                      setState(() {
                        isLiked = false;
                        likes = 24;
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.text('24'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('Test 6: Rapid like and unlike taps do not throw exceptions in viewer mode', (tester) async {
      bool isLiked = false;
      int likes = 10;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: StoryInteractiveLikeButton(
                    isLiked: isLiked,
                    likesCount: likes,
                    showCount: false,
                    onTap: () {
                      setState(() {
                        isLiked = !isLiked;
                        likes += isLiked ? 1 : -1;
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.tap(find.byType(StoryInteractiveLikeButton));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      expect(find.byType(StoryInteractiveLikeButton), findsOneWidget);
    });

    testWidgets('Test 7: Count formatting handles large numbers when showCount is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StoryInteractiveLikeButton(
                isLiked: false,
                likesCount: 15400,
                showCount: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('15.4k'), findsOneWidget);
    });
  });
}
