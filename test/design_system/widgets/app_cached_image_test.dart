import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/design_system/widgets/images/app_cached_image.dart';

void main() {
  group('AppCachedImage Unit & Widget Tests', () {
    testWidgets('renders errorWidget when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: null,
              errorWidget: KeyedSubtree(
                key: Key('custom_error'),
                child: Text('Error!'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom_error')), findsOneWidget);
      expect(find.text('Error!'), findsOneWidget);
    });

    testWidgets('renders errorWidget when imageUrl is empty string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: '   ',
              errorWidget: Icon(Icons.error, key: Key('error_icon')),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('error_icon')), findsOneWidget);
    });

    testWidgets('renders default error fallback icon when no custom error widget provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: '',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('calls custom errorBuilder when url is empty or invalid', (tester) async {
      bool builderCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: '',
              errorBuilder: (context, url, error) {
                builderCalled = true;
                return const Text('Builder Error');
              },
            ),
          ),
        ),
      );

      expect(builderCalled, isTrue);
      expect(find.text('Builder Error'), findsOneWidget);
    });

    testWidgets('renders custom placeholder when network image is loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
              placeholder: KeyedSubtree(
                key: Key('custom_placeholder'),
                child: Text('Loading...'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom_placeholder')), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('renders CachedNetworkImage with correct dimensions and fit for network URL',
        (tester) async {
      const testUrl = 'https://d123456abcdef.cloudfront.net/posts/img1.jpg';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: testUrl,
              width: 250,
              height: 180,
              fit: BoxFit.contain,
              memCacheWidth: 500,
              memCacheHeight: 360,
            ),
          ),
        ),
      );

      final cachedImageFinder = find.byType(CachedNetworkImage);
      expect(cachedImageFinder, findsOneWidget);

      final cachedImage = tester.widget<CachedNetworkImage>(cachedImageFinder);
      expect(cachedImage.imageUrl, testUrl);
      expect(cachedImage.width, 250);
      expect(cachedImage.height, 180);
      expect(cachedImage.fit, BoxFit.contain);
      expect(cachedImage.memCacheWidth, 500);
      expect(cachedImage.memCacheHeight, 360);
    });

    testWidgets('applies borderRadius clipping when borderRadius is specified',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/test.jpg',
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      );

      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsOneWidget);

      final clipRRect = tester.widget<ClipRRect>(clipRRectFinder);
      expect(clipRRect.borderRadius, const BorderRadius.all(Radius.circular(16)));
    });

    testWidgets('renders Image.asset when imageUrl points to an asset path',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'assets/images/logo.png',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // CachedNetworkImage should not be created for asset paths
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
