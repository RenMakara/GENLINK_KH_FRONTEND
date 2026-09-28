import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/design_system/widgets/avatar/app_avatar.dart';

void main() {
  group('AppAvatar Unit & Widget Tests', () {
    testWidgets('renders fallback initials "?" when name and imageUrl are null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: null,
              name: null,
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('renders single initial for single-word name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: null,
              name: 'Sophea',
            ),
          ),
        ),
      );

      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('renders two initials for multi-word name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: null,
              name: 'Sophea Pich',
            ),
          ),
        ),
      );

      expect(find.text('SP'), findsOneWidget);
    });

    testWidgets('renders correct radius based on size parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              size: 60,
              name: 'Dara',
            ),
          ),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      expect(avatarFinder, findsOneWidget);
      final avatar = tester.widget<CircleAvatar>(avatarFinder);
      expect(avatar.radius, 30.0);
    });

    testWidgets('configures CachedNetworkImageProvider with memory downsampling for remote URL',
        (tester) async {
      const url = 'https://d123456abcdef.cloudfront.net/avatars/u1.jpg';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              size: 40,
              imageUrl: url,
              name: 'John Doe',
            ),
          ),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      expect(avatarFinder, findsOneWidget);
      final avatar = tester.widget<CircleAvatar>(avatarFinder);

      expect(avatar.foregroundImage, isNotNull);
      expect(avatar.foregroundImage, isA<CachedNetworkImageProvider>());

      final provider = avatar.foregroundImage as CachedNetworkImageProvider;
      expect(provider.url, url);
      // High-density memory downsampling: (40 * 3) = 120 (clamped between 64 and 512)
      expect(provider.maxWidth, 120);
      expect(provider.maxHeight, 120);
    });

    testWidgets('uses AssetImage when imageUrl is an asset path', (tester) async {
      const assetPath = 'assets/images/default_avatar.png';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: assetPath,
              name: 'Default User',
            ),
          ),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      final avatar = tester.widget<CircleAvatar>(avatarFinder);

      expect(avatar.foregroundImage, isNotNull);
      expect(avatar.foregroundImage, isA<AssetImage>());
      final assetProvider = avatar.foregroundImage as AssetImage;
      expect(assetProvider.assetName, assetPath);
    });

    testWidgets('falls back to initials when imageUrl is empty string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: '   ',
              name: 'Chanthy Chea',
            ),
          ),
        ),
      );

      final avatarFinder = find.byType(CircleAvatar);
      final avatar = tester.widget<CircleAvatar>(avatarFinder);

      expect(avatar.foregroundImage, isNull);
      expect(find.text('CC'), findsOneWidget);
    });
  });
}
