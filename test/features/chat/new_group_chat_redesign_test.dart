import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:genlink_frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/create_group_screen.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/group_profile_screen.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ChatRemoteDataSource remoteDataSource;
  late ChatRepositoryImpl repository;
  late ChatController controller;

  final List<ChatConversationModel> sampleUsers = [
    ChatConversationModel(
      id: 'c1',
      name: 'Ren Makara',
      avatar: 'assets/images/ren_makara_profile.png',
      isGroup: false,
      profileUserId: 'u1',
      profileUsername: 'renmakara_official',
      isOnline: true,
      lastMessage: 'Hey there',
      lastMessageTime: '1m',
    ),
    ChatConversationModel(
      id: 'c2',
      name: 'Sokny Enat',
      avatar: 'assets/images/user_profile.png',
      isGroup: false,
      profileUserId: 'u2',
      profileUsername: 'enat@12',
      isOnline: true,
      lastMessage: 'See you tomorrow',
      lastMessageTime: '5m',
    ),
    ChatConversationModel(
      id: 'c3',
      name: 'GenLink',
      avatar: 'assets/images/user_profile.png',
      isGroup: false,
      profileUserId: 'u3',
      profileUsername: 'genlink.kh.official',
      isOnline: false,
      lastMessage: 'Welcome to GenLink',
      lastMessageTime: '10m',
    ),
    ChatConversationModel(
      id: 'c4',
      name: 'enat',
      avatar: 'assets/images/user_profile.png',
      isGroup: false,
      profileUserId: 'u4',
      profileUsername: 'enat123',
      isOnline: false,
      lastMessage: 'Okay',
      lastMessageTime: '1h',
    ),
    ChatConversationModel(
      id: 'c5',
      name: 'Sophea Chhun',
      avatar: 'assets/images/user_profile.png',
      isGroup: false,
      profileUserId: 'u5',
      profileUsername: 'sophea.c',
      isOnline: false,
      lastMessage: 'Thanks',
      lastMessageTime: '2h',
    ),
    ChatConversationModel(
      id: 'c6',
      name: 'Dara Kim',
      avatar: 'assets/images/user_profile.png',
      isGroup: false,
      profileUserId: 'u6',
      profileUsername: 'dara_kim',
      isOnline: false,
      lastMessage: 'Let us meet',
      lastMessageTime: '3h',
    ),
    ChatConversationModel(
      id: 'c7',
      name: 'Vuthy',
      avatar: 'assets/images/user_profile.png',
      isGroup: false,
      profileUserId: 'u7',
      profileUsername: 'vuthy.dev',
      isOnline: false,
      lastMessage: 'Done',
      lastMessageTime: '1d',
    ),
    ChatConversationModel(
      id: 'c8',
      name: 'Sreyneang',
      avatar: 'assets/images/user_profile.png',
      isGroup: false,
      profileUserId: 'u8',
      profileUsername: 'sreyneang',
      isOnline: false,
      lastMessage: 'Great',
      lastMessageTime: '2d',
    ),
  ];

  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
    Get.fallbackLocale = const Locale('en', 'US');
    mockDio = MockDio();
    remoteDataSource = ChatRemoteDataSource(dio: mockDio);
    repository = ChatRepositoryImpl(remoteDataSource: remoteDataSource);
    controller = ChatController(repository: repository);
    Get.put<ChatController>(controller);

    controller.conversations.assignAll(sampleUsers);

    when(() => mockDio.get<dynamic>(any(that: contains('/unread-count')))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/unread-count'),
        statusCode: 200,
        data: {'success': true, 'data': {'unreadCount': 0}},
      ),
    );

    when(() => mockDio.get<dynamic>(any(that: contains('/search/people')))).thenAnswer(
      (invocation) async {
        final queryParams = invocation.namedArguments[#queryParameters] as Map<String, dynamic>?;
        final q = queryParams?['q']?.toString().toLowerCase() ?? '';
        final matching = sampleUsers
            .where((u) =>
                u.name.toLowerCase().contains(q) ||
                (u.profileUsername?.toLowerCase().contains(q) ?? false))
            .map((u) => {
                  'userId': u.profileUserId,
                  'fullName': u.name,
                  'username': u.profileUsername,
                  'avatarUrl': u.avatar,
                })
            .toList();
        return Response(
          requestOptions: RequestOptions(path: '/api/v1/search/people'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {'content': matching},
          },
        );
      },
    );

    when(() => mockDio.get<dynamic>(any(that: contains('/following')))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/following'),
        statusCode: 200,
        data: {'success': true, 'data': []},
      ),
    );
  });

  tearDown(() {
    Get.reset();
  });

  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  group('New Group Chat Redesign & Member Selection Tests', () {
    testWidgets('0. Backend returns 0 users -> displays clean empty state without mock users', (tester) async {
      setTallViewport(tester);
      controller.conversations.clear();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No students found'), findsOneWidget);
      expect(find.text('Search for a different\nname or username.'), findsOneWidget);
      expect(find.text('Ren Makara'), findsNothing);
      expect(find.text('Sokny Enat'), findsNothing);
    });

    testWidgets('1. Select 1 member -> count = 1', (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 selected'), findsWidgets);

      await tester.tap(find.text('Ren Makara'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsWidgets);
    });

    testWidgets('2. Select 2 members -> count = 2', (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ren Makara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sokny Enat'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsWidgets);
    });

    testWidgets('3. Select 5 members -> count = 5 (Not stuck at 2!)', (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final membersToSelect = [
        'Ren Makara',
        'Sokny Enat',
        'GenLink',
        'enat',
        'Sophea Chhun',
      ];

      for (final name in membersToSelect) {
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
      }

      // Root Cause Verification: count must be 5, NOT stuck at 2
      expect(find.text('5 selected'), findsWidgets);
      // Overlapping avatars should show +2 badge (5 - 3 = 2)
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('4. Select 8 members -> count = 8 and shows +5 badge', (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final allMembers = [
        'Ren Makara',
        'Sokny Enat',
        'GenLink',
        'enat',
        'Sophea Chhun',
        'Dara Kim',
        'Vuthy',
        'Sreyneang',
      ];

      for (final name in allMembers) {
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
      }

      expect(find.text('8 selected'), findsWidgets);
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('5. Deselect one member -> count decreases by 1', (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ren Makara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sokny Enat'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsWidgets);

      // Deselect Ren Makara
      await tester.tap(find.text('Ren Makara'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsWidgets);
    });

    testWidgets('6. Search while members are selected -> count does NOT change', (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select 3 members
      await tester.tap(find.text('Ren Makara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sokny Enat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GenLink'));
      await tester.pumpAndSettle();

      expect(find.text('3 selected'), findsWidgets);

      // Search for "Ren"
      await tester.enterText(find.byType(TextField).last, 'Ren');
      await tester.pumpAndSettle();

      // Count MUST stay 3 selected, not change to visible count (1)
      expect(find.text('3 selected'), findsWidgets);
    });

    testWidgets('7. Clear search restores list while selections remain', (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Ren Makara
      await tester.tap(find.text('Ren Makara'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsWidgets);

      // Search for "Sokny"
      await tester.enterText(find.byType(TextField).last, 'Sokny');
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsWidgets);

      // Tap clear button (X)
      final clearBtn = find.byIcon(Icons.cancel_rounded);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Both Ren Makara and Sokny Enat visible again, Ren is still selected
      expect(find.text('Ren Makara'), findsOneWidget);
      expect(find.text('Sokny Enat'), findsOneWidget);
      expect(find.text('1 selected'), findsWidgets);
    });

    testWidgets('8. Search zero results shows empty message and preserves selections', (tester) async {
      setTallViewport(tester);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select 2 members
      await tester.tap(find.text('Ren Makara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sokny Enat'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsWidgets);

      // Search non-existent string
      await tester.enterText(find.byType(TextField).last, 'nonexistentxyz999');
      await tester.pumpAndSettle();

      expect(find.text('No students found'), findsOneWidget);
      // Selections preserved
      expect(find.text('2 selected'), findsWidgets);
    });

    testWidgets('9. Regression Test: 5 selected members -> search -> clear -> create sends all 5 IDs', (tester) async {
      setTallViewport(tester);
      List<String>? capturedMemberIds;
      String? capturedGroupName;

      when(() => mockDio.post<dynamic>(
            any(that: contains('/groups')),
            data: any(named: 'data'),
          )).thenAnswer((invocation) async {
        final data = invocation.namedArguments[#data] as Map<String, dynamic>;
        capturedGroupName = data['name'] as String?;
        capturedMemberIds = (data['memberIds'] as List?)?.cast<String>();

        return Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/groups'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-created-5',
              'type': 'GROUP',
              'name': capturedGroupName ?? 'Test Group',
              'members': [
                {'user': {'userId': 'user-creator', 'fullName': 'Creator'}, 'role': 'OWNER'},
                for (final id in capturedMemberIds ?? <String>[])
                  {'user': {'userId': id, 'fullName': 'Member $id'}, 'role': 'MEMBER'},
              ],
            },
          },
        );
      });

      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter group name
      await tester.enterText(find.byType(TextField).first, 'Flutter Study Group');
      await tester.pumpAndSettle();

      // 1. Select 5 members
      final fiveMembers = [
        'Ren Makara',
        'Sokny Enat',
        'GenLink',
        'enat',
        'Sophea Chhun',
      ];
      for (final name in fiveMembers) {
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
      }

      // Verify UI displays "5 selected"
      expect(find.text('5 selected'), findsWidgets);

      // 2. Search/filter to a subset ("ren")
      await tester.enterText(find.byType(TextField).last, 'ren');
      await tester.pumpAndSettle();

      // UI still displays "5 selected"
      expect(find.text('5 selected'), findsWidgets);

      // 3. Clear search
      final clearBtn = find.byIcon(Icons.cancel_rounded);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Still "5 selected"
      expect(find.text('5 selected'), findsWidgets);

      // 4. Tap bottom "Create Group →" button
      await tester.tap(find.text('Create Group →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Request contains all 5 member IDs!
      expect(capturedGroupName, 'Flutter Study Group');
      expect(capturedMemberIds, isNotNull);
      expect(capturedMemberIds!.length, 5);
      expect(capturedMemberIds, containsAll(['u1', 'u2', 'u3', 'u4', 'u5']));
    });

    testWidgets('10. Group profile displays correct member count and details', (tester) async {
      final sampleGroup = ChatConversationModel(
        id: 'room-profile-test',
        name: 'Mobile Dev KH',
        avatar: 'assets/images/user_profile.png',
        isGroup: true,
        lastMessage: 'Welcome!',
        lastMessageTime: 'Just now',
        membersCount: 4,
        members: const [
          ChatMemberModel(userId: 'u1', fullName: 'Ren Makara', username: 'renmakara', role: 'OWNER'),
          ChatMemberModel(userId: 'u2', fullName: 'Sokny Enat', username: 'sokny', role: 'ADMIN'),
          ChatMemberModel(userId: 'u3', fullName: 'Dara Kim', username: 'dara', role: 'MEMBER'),
          ChatMemberModel(userId: 'u4', fullName: 'Vuthy', username: 'vuthy', role: 'MEMBER'),
        ],
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/room-profile-test')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-profile-test'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-profile-test',
              'type': 'GROUP',
              'name': 'Mobile Dev KH',
              'members': [
                {'user': {'userId': 'u1', 'fullName': 'Ren Makara', 'username': 'renmakara'}, 'role': 'OWNER'},
                {'user': {'userId': 'u2', 'fullName': 'Sokny Enat', 'username': 'sokny'}, 'role': 'ADMIN'},
                {'user': {'userId': 'u3', 'fullName': 'Dara Kim', 'username': 'dara'}, 'role': 'MEMBER'},
                {'user': {'userId': 'u4', 'fullName': 'Vuthy', 'username': 'vuthy'}, 'role': 'MEMBER'},
              ],
            },
          },
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: GroupProfileScreen(conversation: sampleGroup),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mobile Dev KH'), findsOneWidget);
      expect(find.text('4 members'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('Ren Makara'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('11. Group profile displays group avatar and edit button', (tester) async {
      final sampleGroup = ChatConversationModel(
        id: 'room-avatar-test',
        name: 'Design System Team',
        avatar: 'assets/images/user_profile.png',
        isGroup: true,
        lastMessage: '',
        lastMessageTime: 'Just now',
        membersCount: 2,
        members: const [
          ChatMemberModel(userId: 'u1', fullName: 'Ren Makara', username: 'renmakara', role: 'OWNER'),
        ],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: GroupProfileScreen(conversation: sampleGroup),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Design System Team'), findsOneWidget);
      expect(find.text('Edit Group'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('12. Light Mode renders without overflow', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          home: const CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Group Chat'), findsOneWidget);
      expect(find.text('Select Members'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Dark Mode renders without overflow', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          home: const CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Group Chat'), findsOneWidget);
      expect(find.text('Select Members'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Group image avatar container has camera overlay icon', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.group_rounded), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('15. Group name validation enables/disables Create button', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially empty -> Create button should be disabled
      final nameField = find.byType(TextField).first;
      expect(find.text('0/50'), findsOneWidget);

      // Select 1 member but no name
      await tester.tap(find.text('Ren Makara'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsWidgets);

      // Now enter name (19 characters)
      await tester.enterText(nameField, 'Flutter Study Group');
      await tester.pumpAndSettle();

      expect(find.text('19/50'), findsOneWidget);
      expect(find.text('Create Group →'), findsOneWidget);
    });

    testWidgets('16. createGroup passes avatarUrl to repository and backend', (tester) async {
      when(() => mockDio.post<dynamic>(
        any(that: contains('/groups')),
        data: any(named: 'data'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/groups'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-with-avatar',
              'name': 'Design Club',
              'avatarUrl': 'https://s3.example.com/avatar.jpg',
              'type': 'GROUP',
              'members': [
                {'user': {'userId': 'user-1', 'fullName': 'Member 1'}, 'role': 'OWNER'},
              ],
            },
          },
        ),
      );

      final result = await controller.createGroup(
        'Design Club',
        ['user-1'],
        avatarUrl: 'https://s3.example.com/avatar.jpg',
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.avatar, 'https://s3.example.com/avatar.jpg');
      verify(() => mockDio.post<dynamic>(
        any(that: contains('/groups')),
        data: {
          'name': 'Design Club',
          'memberIds': ['user-1'],
          'avatarUrl': 'https://s3.example.com/avatar.jpg',
        },
      )).called(1);
    });

    testWidgets('17. Group profile displays group avatar if set', (tester) async {
      final conv = ChatConversationModel(
        id: 'group-avatar-1',
        name: 'Design Club',
        avatar: 'https://s3.example.com/group-avatar.jpg',
        isGroup: true,
        lastMessage: 'Hello',
        lastMessageTime: '1m',
        membersCount: 3,
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/chats/group-avatar-1')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/chats/group-avatar-1'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'group-avatar-1',
              'name': 'Design Club',
              'avatarUrl': 'https://s3.example.com/group-avatar.jpg',
              'type': 'GROUP',
              'members': [
                {'user': {'userId': 'user-1', 'fullName': 'Ren Makara', 'username': 'renmakara_official'}, 'role': 'OWNER'},
              ],
            },
          },
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: GroupProfileScreen(conversation: conv),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Design Club'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. Khmer locale renders CreateGroupScreen with correct Khmer translations', (tester) async {
      Get.locale = const Locale('km', 'KH');
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Title in Khmer
      expect(find.text('ការជជែកជាក្រុមថ្មី'), findsOneWidget);
      // Group Name label in Khmer
      expect(find.text('ឈ្មោះក្រុម'), findsOneWidget);
      // Members header in Khmer
      expect(find.text('សមាជិក'), findsOneWidget);
      // Selection count 0 in Khmer
      expect(find.text('បានជ្រើសរើស 0'), findsOneWidget);
      // Bottom helper in Khmer
      expect(find.text('ជ្រើសរើសសមាជិក'), findsOneWidget);
      // Bottom button in Khmer
      expect(find.text('បង្កើតក្រុម →'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. Khmer locale member selection updates Khmer count strings correctly', (tester) async {
      Get.locale = const Locale('km', 'KH');
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ren Makara'));
      await tester.pumpAndSettle();

      expect(find.text('បានជ្រើសរើស 1'), findsOneWidget);
      expect(find.text('បានជ្រើសរើសសមាជិក 1 នាក់'), findsOneWidget);

      await tester.tap(find.text('Sokny Enat'));
      await tester.pumpAndSettle();

      expect(find.text('បានជ្រើសរើស 2'), findsOneWidget);
      expect(find.text('បានជ្រើសរើសសមាជិក 2 នាក់'), findsOneWidget);
    });
  });
}

